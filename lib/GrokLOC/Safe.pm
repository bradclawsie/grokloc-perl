package GrokLOC::Safe;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Safe types for database use.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class VarChar {
  use Carp qw( croak );
  Readonly::Scalar our $STR_MAX => 8192;
  #<<V
  field $value :param :reader;
  #>>V

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

  ADJUST {
    croak 'varchar' unless varchar($value);
  }

  method TO_JSON {
    return $value;
  }
}

__END__
