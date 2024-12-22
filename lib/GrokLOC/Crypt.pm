package GrokLOC::Crypt;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Cryptographic utilities.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class IV {
  use Carp        qw( croak );
  use Crypt::Misc qw( random_v4uuid );
  Readonly::Scalar our $LEN => 16;
  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    croak 'not iv' unless ($value =~ /^[\da-f]{$LEN}$/x);
  }

  sub rand ($self) {
    my $s = random_v4uuid;
    $s =~ s/\-//xg;
    return $self->new(value => substr $s, 0, $LEN);
  }
}

class Key {
  use Carp        qw( croak );
  use Crypt::Misc qw( random_v4uuid );
  Readonly::Scalar our $LEN => 32;
  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    croak 'not key' unless ($value =~ /^[\da-f]{$LEN}$/x);
  }

  sub rand ($self) {
    my $s = random_v4uuid;
    $s =~ s/\-//xg;
    return $self->new(value => substr $s, 0, $LEN);
  }
}

class AESGCM {
  use Carp                qw( croak );
  use Crypt::AuthEnc::GCM ();
  Readonly::Scalar our $TAG_LEN => 32;

  sub encrypt ($self, $pt, $key, $iv) {
    my $ae  = Crypt::AuthEnc::GCM->new('AES', $key, $iv);
    my $ct  = unpack('H*', $ae->encrypt_add($pt));
    my $tag = unpack('H*', $ae->encrypt_done());
    return $iv . $tag . $ct;    # this is $e in decrypt
  }

  sub decrypt ($self, $e, $key) {
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

class Password {
  use Carp          qw( croak );
  use Crypt::Argon2 qw( argon2_verify argon2id_pass );
  use Crypt::Misc   qw( random_v4uuid );

  Readonly::Scalar our $SALT_LEN => 16;
  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    croak 'not argon2 password' unless ($value =~ /^\$argon2/x);
  }

  sub from ($self, $pt) {
    my $s = random_v4uuid;
    $s =~ s/\-//xg;
    my $salt = substr $s, 0, $SALT_LEN;
    return $self->new(value => argon2id_pass($pt, $salt, 1, '32M', 1, 16));
  }

  sub rand ($self) {
    return $self->from(random_v4uuid);
  }

  method test ($pt) {
    return argon2_verify($value, $pt);
  }

  method TO_JSON {    # never serialize
    return '*****';
  }
}

__END__
