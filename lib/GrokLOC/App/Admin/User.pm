package GrokLOC::App::Admin::User;
use v5.42;
use strictures 2;
use Object::Pad;
use GrokLOC::Models;

# ABSTRACT: User model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class User :does(WithID) : does(WithMeta) {
  use Carp::Assert::More    qw( assert assert_isa );
  use Crypt::Digest::SHA256 qw( sha256_hex );
  use Crypt::PK::Ed25519    ();
  use GrokLOC::Crypt;
  use GrokLOC::Models;
  use GrokLOC::Safe;
  use UUID qw( clear is_null parse unparse uuid4 version );

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
    assert_isa($api_key,      'VarChar', 'api_key is not VarChar');
    assert_isa($display_name, 'VarChar', 'display_name is not VarChar');
    assert_isa($email,        'VarChar', 'email is not VarChar');
    assert_isa($org,          'ID',      'org is not type ID');
    my $bin = 0;
    assert(parse($key_version, $bin) == 0
        && (version($bin) == 4 || is_null($bin)),
      'key_version not uuidv4');
  }

  sub default ($self) {
    my ($bin, $str) = (0, q{});
    clear($bin);
    unparse($bin, $str);
    return $self->new(
      id                  => ID->default,
      meta                => Meta->default,
      api_key             => VarChar->default,
      api_key_digest      => q{},
      display_name        => VarChar->default,
      display_name_digest => q{},
      email               => VarChar->default,
      email_digest        => q{},
      org                 => ID->default,
      password            => q{},
      key_version         => $str
    );
  }

  # Return a random User as if it was read from the
  # database (decrypted). Also provide seed plaintext
  # password and api private key.
  sub rand ($self) {
    my $pt       = uuid4;                 # Plaintext password.
    my $password = Password->from($pt);

    my ($display_name, $email) = (uuid4, uuid4);
    my $display_name_digest = sha256_hex($display_name);
    my $email_digest        = sha256_hex($email);

    my $pk                = Crypt::PK::Ed25519->new->generate_key;
    my $private_key       = $pk->export_key_jwk('private');
    my $public_key        = $pk->export_key_jwk('public');
    my $public_key_digest = sha256_hex($public_key);

    my $meta = Meta->default;
    $meta->Role = $Role::TEST;

    my $user = $self->new(
      id                  => ID->rand(),
      meta                => $meta,
      api_key             => VarChar->trusted($public_key),
      api_key_digest      => $public_key_digest,
      display_name        => VarChar->default(),
      display_name_digest => $display_name_digest,
      email               => VarChar->default(),
      email_digest        => $email_digest,
      org                 => ID->default(),
      password            => $password,
      key_version         => uuid4()
    );

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
