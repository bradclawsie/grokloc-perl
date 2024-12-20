package GrokLOC::Crypt;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Cryptographic utilities.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class IV {
  Readonly::Scalar our $LEN           => 16;
  Readonly::Scalar our $RAND_SIZE     => 500;
  Readonly::Scalar our $RAND_STRENGTH => 1;
  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    use Carp qw( croak );
    croak 'not iv' unless ($value =~ /^[\da-f]{$LEN}$/x);
  }

  sub rand ($self) {
    use Crypt::Random         qw( makerandom );
    use Crypt::Digest::SHA256 qw( sha256_b64 );
    my $r = makerandom(Size => $RAND_SIZE, Strength => $RAND_STRENGTH);
    my $s = substr unpack('H*', sha256_b64($r)), 0, $LEN;
    return $self->new(value => $s);
  }
}

__END__
