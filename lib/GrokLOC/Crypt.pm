package GrokLOC::Crypt;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Cryptographic utilities.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class IV {
  Readonly::Scalar our $LEN => 16;
  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    use Carp qw( croak );
    croak 'not iv' unless ($value =~ /^[\da-f]{$LEN}$/x);
  }

  sub rand ($self) {
    use Crypt::Misc qw( random_v4uuid );
    my $s = random_v4uuid;
    $s =~ s/\-//xg;
    return $self->new(value => substr $s, 0, $LEN);
  }
}

class Key {
  Readonly::Scalar our $LEN => 32;
  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    use Carp qw( croak );
    croak 'not key' unless ($value =~ /^[\da-f]{$LEN}$/x);
  }

  sub rand ($self) {
    use Crypt::Misc qw( random_v4uuid );
    my $s = random_v4uuid;
    $s =~ s/\-//xg;
    return $self->new(value => substr $s, 0, $LEN);
  }
}

class AESGCM {
  Readonly::Scalar our $TAG_LEN => 32;

  sub encrypt ($self, $pt, $key, $iv) {
    use Crypt::AuthEnc::GCM ();
    my $ae  = Crypt::AuthEnc::GCM->new('AES', $key, $iv);
    my $ct  = unpack('H*', $ae->encrypt_add($pt));
    my $tag = unpack('H*', $ae->encrypt_done());
    return $iv . $tag . $ct;    # this is $e in decrypt
  }

  sub decrypt ($self, $e, $key) {
    use Carp                qw( croak );
    use Crypt::AuthEnc::GCM ();
    my $iv      = substr $e, 0, $IV::LEN;
    my $tag     = substr $e, $IV::LEN, $TAG_LEN;
    my $ct      = substr $e, $IV::LEN + $TAG_LEN;
    my $ae      = Crypt::AuthEnc::GCM->new('AES', $key, $iv);
    my $pt      = $ae->decrypt_add(pack('H*', $ct));
    my $tag_out = $ae->decrypt_done();
    croak 'tag mismatch' unless unpack('H*', $tag_out) eq $tag;
    return $pt;
  }
}

__END__
