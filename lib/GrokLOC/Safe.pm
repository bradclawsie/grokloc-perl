package GrokLOC::Safe;
use v5.42;
use strictures 2;
use Data::Checks qw( Str );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( sub );

# ABSTRACT: Safe types for database use.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class VarChar {
  use Carp::Assert::More qw( assert );
  use Readonly           ();
  use UUID               qw( uuid4 );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $STR_MAX => 8192;

  field $trust :param : reader = false;    # Skip check if true.
  field $value :param : reader : Checked(Str);

  sub varchar ($s :Checked(Str)) {
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

  ADJUST {
    unless ($trust) {
      assert(varchar($value), 'value not varchar');
    }
  }

  sub default ($self) {
    return $self->new(value => q{}, trust => true);
  }

  sub rand ($self) {
    return $self->new(value => uuid4, trust => true);
  }

  sub trusted ($self, $value :Checked(Str)) {
    return $self->new(value => $value, trust => true);
  }

  method TO_STRING {
    return "VarChar(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {
    return $value;
  }
}

__END__
