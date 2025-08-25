package GrokLOC::Crypt;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: Cryptographic utilities.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class IV {
  use Bytes::Random::Secure qw( random_bytes_hex );
  use Carp::Assert::More    qw( assert_like );
  use Readonly              ();
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $LEN => 16;

  field $value :param : reader;

  ADJUST {
    assert_like($value, qr/^[\da-f]{$LEN}$/x, 'not iv');
  }

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

class Key {
  use Bytes::Random::Secure qw( random_bytes_hex );
  use Carp::Assert::More    qw( assert_like );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $LEN => 32;

  field $value :param : reader;

  ADJUST {
    assert_like($value, qr/^[\da-f]{$LEN}$/x, 'not key');
  }

  sub rand ($self) {
    return $self->new(value => random_bytes_hex(int($LEN / 2)));
  }

  method TO_STRING {
    return "Key(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
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
  use Bytes::Random::Secure qw( random_bytes_hex );
  use Carp::Assert::More    qw( assert_like );
  use Crypt::Argon2         qw( argon2_verify argon2id_pass );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $SALT_LEN => 16;

  field $value :param : reader;

  ADJUST {
    assert_like($value, qr/\$argon2/x, 'password not argon2');
  }

  sub from ($self, $pt) {
    my $salt = random_bytes_hex(int($SALT_LEN / 2));
    return $self->new(value => argon2id_pass($pt, $salt, 1, '32M', 1, 16));
  }

  sub rand ($self) {
    return $self->from(random_bytes_hex(8));
  }

  method test ($pt) {
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

class VersionKey {
  use Carp::Assert::More qw(
    assert
    assert_defined
    assert_hashref
    assert_isa
  );
  use UUID qw( parse uuid4 version );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  field $key_map :param;
  field $current :param : reader;

  ADJUST {
    assert_hashref($key_map, 'key_map not hashref');
    my $bin;
    assert(parse($current, $bin) == 0 && version($bin) == 4,
      'current not uuidv4');
    my $found_current = false;
    for my $key (keys %{$key_map}) {
      assert(parse($key, $bin) == 0 && version($bin) == 4,
        'key_map key not uuidv4');
      assert_isa($key_map->{$key}, 'Key', 'key_map value not type Key');
      $found_current = true if $key eq $current;
    }
    assert($found_current, 'current key not in key_map');
  }

  sub unit ($self) {
    my $key     = Key->rand;
    my $current = uuid4;
    return $self->new(
      current => $current,
      key_map => {$current => $key}
    );
  }

  method get ($key) {
    my $value = $key_map->{$key};
    assert_defined($value, 'no value for key in key_map');
    return $value;
  }

  method TO_STRING {
    my @pairs = ();

    # Avoiding errors on overloaded '.', '.=' etc.
    for my $key (keys %{$key_map}) {
      my $version = "$key_map->{$key}";
      my $key_    = "$key";
      push(@pairs, "{$version : $key_}");
    }
    my $pairs_str = join(', ', @pairs);
    return "VersionKey(current => $current, key_map => [$pairs_str])";
  }

  method TO_BOOL {
    return defined($current) && defined($key_map) ? true : false;
  }
}

__END__
