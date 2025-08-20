package GrokLOC::App::Admin::User;
use v5.42;
use strictures 2;
use Object::Pad;
use GrokLOC::Models;

# ABSTRACT: User model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class User :does(WithID) : does(WithMeta) {
  use Carp::Assert::More    qw( assert assert_isa assert_nonblank );
  use Crypt::Digest::SHA256 qw( sha256_hex );
  use Crypt::PK::Ed25519    ();
  use GrokLOC::Crypt;
  use GrokLOC::Models;
  use GrokLOC::Safe;
  use UUID qw( is_null parse uuid4 version );

  field $api_key :param : reader;
  field $api_key_digest :param : reader;
  field $display_name :param : reader;
  field $display_name_digest :param : reader;
  field $email :param : reader;
  field $email_digest :param : reader;
  field $org :param : reader;
  field $password :param : reader;
  field $key_version :param : reader;

  ADJUST {
    # Although api_key may be user provided, it is not
    # displayed content, so it doesn't need to be passed
    # through VarChar.
    assert_nonblank($api_key, 'api_key is malformed');

    assert_isa($display_name, 'VarChar',  'display_name is not VarChar');
    assert_isa($email,        'VarChar',  'email is not VarChar');
    assert_isa($org,          'ID',       'org is not type ID');
    assert_isa($password,     'Password', 'password is not type Password');

    my $bin = 0;
    assert(parse($key_version, $bin) == 0
        && (version($bin) == 4 || is_null($bin)),
      'key_version not uuidv4');
  }

  # Create a new User with key fields initialized.
  # This is what is used to create a new User for insertion.
  sub default ($self, $display_name, $email, $org, $password, $key_version) {

    # Check these early as their respective ->values are needed here.
    assert_isa($display_name, 'VarChar', 'display_name is not VarChar');
    assert_isa($email,        'VarChar', 'email is not VarChar');

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
  # If a real $org and $key_version are returned,
  # the returned User is insertable.
  sub rand ($self, $org, $key_version) {
    my $pt       = uuid4;                 # Plaintext password.
    my $password = Password->from($pt);

    my $display_name = VarChar->rand;
    my $email        = VarChar->rand;

    my ($user, $private_key) =
      $self->default($display_name, $email, $org, $password, $key_version);

    # Random user should have test role.
    $user->meta->set_role(Role->new(value => $Role::TEST));
    return ($user, $private_key, $pt);
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
