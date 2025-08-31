package GrokLOC::Crypt::Password;
use v5.42;
use strictures 2;
use Data::Checks qw( Str StrMatch );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method sub );

# ABSTRACT: Cryptographic Password.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Password {
  use Bytes::Random::Secure qw( random_bytes_hex );
  use Crypt::Argon2         qw( argon2_verify argon2id_pass );
  use Readonly              ();
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $SALT_LEN => 16;

  field $value :param : reader : Checked(StrMatch(qr/\$argon2/x));

  sub from ($self, $pt :Checked(Str)) {
    my $salt = random_bytes_hex(int($SALT_LEN / 2));
    return $self->new(value => argon2id_pass($pt, $salt, 1, '32M', 1, 16));
  }

  sub rand ($self) {
    return $self->from(random_bytes_hex(8));
  }

  method test ($pt :Checked(Str)) {
    return argon2_verify($value, $pt);
  }

  method TO_STRING {
    return "Password(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {    # No public serialization.
    return '*****';
  }
}

__END__
