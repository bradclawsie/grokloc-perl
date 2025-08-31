package GrokLOC::App::Admin::User;
use v5.42;
use strictures 2;
use Data::Checks qw( Isa Str );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method sub );
use GrokLOC::Models::ID;
use GrokLOC::Models::Meta;

# ABSTRACT: User model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class User :does(WithID) : does(WithMeta) {
  use Carp qw( croak );
  use Carp::Assert::More
    qw( assert assert_defined assert_is assert_isa assert_nonblank );
  use Crypt::Digest::SHA256 qw( sha256_hex );
  use Crypt::PK::Ed25519    ();
  use GrokLOC::Crypt;
  use GrokLOC::Models::ID;
  use GrokLOC::Models::Meta;
  use GrokLOC::Models::Role;
  use GrokLOC::Safe;
  use UUID qw( parse uuid4 version );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  field $api_key :param : reader : Checked(Str);
  field $api_key_digest :param : reader : Checked(Str);
  field $display_name :param : reader : Checked(Isa('VarChar'));
  field $display_name_digest :param : reader : Checked(Str);
  field $email :param : reader : Checked(Isa('VarChar'));
  field $email_digest :param : reader : Checked(Str);
  field $org :param : reader : Checked(Isa('ID'));
  field $password :param : reader : Checked(Isa('Password'));
  field $key_version :param : reader : Checked(Str);

  ADJUST {
    # Although api_key may be user provided, it is not
    # displayed content, so it doesn't need to be passed
    # through VarChar.
    assert_nonblank($api_key, 'api_key is malformed');

    assert_is($api_key_digest, sha256_hex($api_key), 'api_key_digest');
    assert_is($display_name_digest, sha256_hex($display_name->value),
      'display_name_digest');
    assert_is($email_digest, sha256_hex($email->value), 'email_digest');

    my $bin = 0;
    assert(parse($key_version, $bin) == 0 && version($bin) == 4,
      'key_version not uuidv4');
  }

  # Create a new User with key fields initialized.
  # This is what is used to create a new User for insertion.
  sub default ($self,
               $display_name :Checked(Isa('VarChar')),
               $email :Checked(Isa('VarChar')),
               $org :Checked(Isa('ID')),
               $password :Checked(Isa('Password')),
               $key_version :Checked(Str)) {

    my $display_name_digest = sha256_hex($display_name->value);
    my $email_digest        = sha256_hex($email->value);

    my $pk                = Crypt::PK::Ed25519->new->generate_key;
    my $private_key       = $pk->export_key_jwk('private');
    my $public_key        = $pk->export_key_jwk('public');
    my $public_key_digest = sha256_hex($public_key);

    # Caller gets new User and their private key.
    return (
      $self->new(
        id                  => ID->default,
        meta                => Meta->default,
        api_key             => $public_key,
        api_key_digest      => $public_key_digest,
        display_name        => $display_name,
        display_name_digest => $display_name_digest,
        email               => $email,
        email_digest        => $email_digest,
        org                 => $org,
        password            => $password,
        key_version         => $key_version
      ),
      $private_key
    );
  }

  # Return a random User as if it was read from the
  # database (decrypted). Also return private key
  # and plaintext password.
  # If a real $org and $key_version are provided,
  # the returned User is insertable.
  sub rand ($self,
            $org :Checked(Isa('ID')),
            $key_version :Checked(Str)) {
    my $pt       = uuid4;                 # Plaintext password.
    my $password = Password->from($pt);

    my $display_name = VarChar->rand;
    my $email        = VarChar->rand;

    my ($user, $private_key) =
      $self->default($display_name, $email, $org, $password, $key_version);

    # Random user should have test role.
    $user->meta->set_role(Role->test);
    return ($user, $private_key, $pt);
  }

  sub read ($self,
            $db :Checked(Isa('Mojo::Pg::Database')),
            $id :Checked(Isa('ID')),
            $version_key :Checked(Isa('VersionKey'))) {
    my $user_read_query = 'select * from users where id = $1';
    my $user_row        = $db->query($user_read_query, $id->value)->hash;

    # Croak on errors that are catch-able.
    croak 'no rows' unless (defined($user_row));

    # Convert role and status from numeric to object representation.
    $user_row->{role}   = Role->new(value => $user_row->{role});
    $user_row->{status} = Status->new(value => $user_row->{status});

    my $meta = Meta->new(%{$user_row});

    for my $col (
      qw(id api_key api_key_digest display_name
      display_name_digest email email_digest org password key_version)
      )
    {
      assert_defined($user_row->{$col}, "$col not defined");
    }

    my $encryption_key = $version_key->get($user_row->{key_version});
    my $decrypted_api_key =
      AESGCM->decrypt($user_row->{api_key}, $encryption_key->value);
    my $decrypted_display_name =
      AESGCM->decrypt($user_row->{display_name}, $encryption_key->value);
    my $decrypted_email =
      AESGCM->decrypt($user_row->{email}, $encryption_key->value);

    return $self->new(
      id                  => ID->new(value => $user_row->{id}),
      meta                => $meta,
      api_key             => $decrypted_api_key,
      api_key_digest      => $user_row->{api_key_digest},
      display_name        => VarChar->trusted($decrypted_display_name),
      display_name_digest => $user_row->{display_name_digest},
      email               => VarChar->trusted($decrypted_email),
      email_digest        => $user_row->{email_digest},
      org                 => ID->new(value => $user_row->{org}),
      password            => Password->new(value => $user_row->{password}),
      key_version         => $user_row->{key_version}
    );
  }

  method insert ($db :Checked(Isa('Mojo::Pg::Database')),
                 $version_key :Checked(Isa('VersionKey'))) {

    # If id is true in the boolean context, then
    # the id value has been set; but only the db
    # creates ids, so it should not be set yet.
    croak 'id value is not undef' if $self->id;

    # Catch an undefined Org; this is always an error.
    croak 'org is undef' unless $self->org;

    my $encryption_key = $version_key->get($key_version);
    assert_isa($encryption_key, 'Key', 'encryption_key is not type Key');

    my $iv = IV->rand;
    my $encrypted_api_key =
      AESGCM->encrypt($api_key, $encryption_key->value, $iv->value);
    my $encrypted_display_name =
      AESGCM->encrypt($display_name->value, $encryption_key->value, $iv->value);
    my $encrypted_email =
      AESGCM->encrypt($email->value, $encryption_key->value, $iv->value);

    my $insert_user_query = <<~'INSERT_USER';
    insert into users
    (api_key,
    api_key_digest,
    display_name,
    display_name_digest,
    email,
    email_digest,
    key_version,
    org,
    password,
    role,
    schema_version,
    status)
    values
    ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
    returning id, ctime, mtime, signature
    INSERT_USER

    my $insert_user_results = $db->query(
      $insert_user_query,       $encrypted_api_key,
      $api_key_digest,          $encrypted_display_name,
      $display_name_digest,     $encrypted_email,
      $email_digest,            $key_version,
      $org->value,              $password->value,
      $self->meta->role->value, $self->meta->schema_version,
      $self->meta->status->value
    );

    my $insert_user_returning = $insert_user_results->hash;
    $self->set_id(ID->new(value => $insert_user_returning->{id}));
    my $meta = Meta->new(
      ctime          => $insert_user_returning->{ctime},
      mtime          => $insert_user_returning->{mtime},
      role           => $self->meta->role,
      schema_version => $self->meta->schema_version,
      signature      => $insert_user_returning->{signature},
      status         => $self->meta->status
    );
    $self->set_meta($meta);
  }

  # Omitted fields not intended for distribution.
  method TO_STRING {
    my $self_id       = $self->id;
    my $id_           = "$self_id";
    my $self_meta     = $self->meta;
    my $meta_         = "$self_meta";
    my $display_name_ = "$display_name";
    my $email_        = "$email";
    my $org_          = "$org";

    return
        "User(id => $id_, "
      . "meta => $meta_, "
      . "api_key => $api_key, "
      . "api_key_digest => $api_key_digest, "
      . "display_name => $display_name_, "
      . "display_name_digest => $display_name_digest, "
      . "email => $email_, "
      . "email_digest => $email_digest, "
      . "org => $org_, "
      . "key_version => $key_version)";
  }

  # Will not evaluate to true unless populated with
  # db metadata.
  method TO_BOOL {
    return
         defined($self->id)
      && $self->id
      && defined($self->meta)
      && $self->meta
      && ($self->meta->ctime != 0)
      && ($self->meta->mtime != 0)
      && ($self->meta->signature ne q{})
      && defined($api_key)
      && defined($api_key_digest)
      && defined($display_name)
      && defined($display_name_digest)
      && defined($email)
      && defined($email_digest)
      && defined($org)
      && ($org->value ne $ID::NIL)
      && defined($password)
      && defined($key_version);
  }

  # Omitted fields not intended for distribution.
  method TO_JSON {
    return {
      id                  => $self->id->TO_JSON,
      meta                => $self->meta->TO_JSON,
      api_key             => $api_key->TO_JSON,
      api_key_digest      => $api_key_digest,
      display_name        => $display_name->TO_JSON,
      display_name_digest => $display_name_digest,
      email               => $email->TO_JSON,
      email_digest        => $email_digest,
      org                 => $org->TO_JSON,
    };
  }
}

__END__
