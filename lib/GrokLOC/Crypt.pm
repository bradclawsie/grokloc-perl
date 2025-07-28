package GrokLOC::Crypt;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: Cryptographic utilities.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class IV {
  use Carp::Assert::More qw( assert_like );
  use Crypt::Misc        qw( is_v4uuid random_v4uuid );
  use Readonly           ();

  Readonly::Scalar our $LEN => 16;

  field $value :param : reader;

  ADJUST {
    assert_like($value, qr/^[\da-f]{$LEN}$/x, 'not iv');
  }

  sub rand ($self) {
    my $s = random_v4uuid;
    $s =~ s/\-//xg;
    return $self->new(value => substr $s, 0, $LEN);
  }
}

class Key {
  use Carp::Assert::More qw( assert_like );
  use Crypt::Misc        qw( is_v4uuid random_v4uuid );

  Readonly::Scalar our $LEN => 32;

  field $value :param : reader;

  ADJUST {
    assert_like($value, qr/^[\da-f]{$LEN}$/x, 'not key');
  }

  sub rand ($self) {
    my $s = random_v4uuid;
    $s =~ s/\-//xg;
    return $self->new(value => substr $s, 0, $LEN);
  }
}

class AESGCM {
  use Carp::Assert::More  qw( assert_is );
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
    assert_is(unpack('H*', $tag_out), $tag, 'tag mismatch');
    return $pt;
  }
}

class Password {
  use Carp::Assert::More qw( assert_like );
  use Crypt::Argon2      qw( argon2_verify argon2id_pass );
  use Crypt::Misc        qw( is_v4uuid random_v4uuid );

  Readonly::Scalar our $SALT_LEN => 16;

  field $value :param : reader;

  ADJUST {
    assert_like($value, qr/\$argon2/x, 'password not argon2')
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

class VersionKey {
  use Carp::Assert::More qw(
    assert
    assert_defined
    assert_hashref
    assert_isa
  );
  use Crypt::Misc qw( is_v4uuid random_v4uuid );

  field $key_map :param;
  field $current :param;

  ADJUST {
    assert_hashref($key_map, 'key_map not hashref');
    assert(is_v4uuid($current), 'current not uuidv4');
    my $found_current = false;
    for my $key (keys %{$key_map}) {
      assert(is_v4uuid($key), 'key_map key not uuidv4');
      assert_isa($key_map->{$key}, 'Key', 'key_map value not type Key');
      $found_current = true if $key eq $current;
    }
    assert($found_current, 'current key not in key_map');
  }

  method get ($key) {
    my $value = $key_map->{$key};
    assert_defined($value, 'no value for key in key_map');
    return $value;
  }

  method get_current {
    return get($current);
  }
}

__END__
