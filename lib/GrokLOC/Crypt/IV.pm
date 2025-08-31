package GrokLOC::Crypt::IV;
use v5.42;
use strictures 2;
use Data::Checks qw( StrMatch );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;

# ABSTRACT: Cryptographic IV.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class IV {
  use Bytes::Random::Secure qw( random_bytes_hex );
  use Readonly              ();
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $LEN => 16;

  field $value :param : reader : Checked(StrMatch(qr/^[\da-f]{16}$/x));

  sub rand ($self) {
    return $self->new(value => random_bytes_hex(int($LEN / 2)));
  }

  method TO_STRING {
    return "IV(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }
}

__END__
