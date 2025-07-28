package GrokLOC::Safe;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: Safe types for database use.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class VarChar {
  use Carp::Assert::More qw( assert );
  use Crypt::Misc        qw( random_v4uuid );
  use Readonly           ();

  Readonly::Scalar our $STR_MAX => 8192;

  field $value :param : reader;

  sub varchar ($s) {
    return false unless (defined $s);
    return false if length $s == 0;
    return false if length $s > $STR_MAX;
    return false if ($s =~ /[\<\>\'\"\`]/msx);
    return false if ($s =~ /drop\s/imsx);
    return false if ($s =~ /create\s/imsx);
    return false if ($s =~ /insert\s/imsx);
    return false if ($s =~ /update\s/imsx);
    return false if ($s =~ /\&gt\;/imsx);
    return false if ($s =~ /\&lt\;/imsx);
    return false if ($s =~ /window[.]/msx);
    return true;
  }

  sub rand ($self) {
    return $self->new(value => random_v4uuid());
  }

  ADJUST {
    assert(varchar($value), 'value not varchar');
  }

  method TO_JSON {
    return $value;
  }
}

__END__
