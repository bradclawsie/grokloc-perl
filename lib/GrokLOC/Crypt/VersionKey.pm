package GrokLOC::Crypt::VersionKey;
use v5.42;
use strictures 2;
use Data::Checks qw( HashRef Str );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method );

# ABSTRACT: Cryptographic VersionKey.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class VersionKey {
  use Carp::Assert::More qw( assert assert_defined assert_isa );
  use UUID               qw( parse uuid4 version );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;
  use GrokLOC::Crypt::Key;

  field $key_map :param : Checked(HashRef);
  field $current :param : reader : Checked(Str);

  ADJUST {
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

  method get ($key :Checked(Str)) {
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
