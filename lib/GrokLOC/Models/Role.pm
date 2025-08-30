package GrokLOC::Models::Role;
use v5.42;
use strictures 2;
use Data::Checks qw( NumRange );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;

# ABSTRACT: Model Role.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Role {
  use Readonly           ();
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $NONE   => 0;
  Readonly::Scalar our $NORMAL => 1;
  Readonly::Scalar our $ADMIN  => 2;
  Readonly::Scalar our $TEST   => 3;

  field $value :param : reader : Checked(NumRange(1,4));

  sub default ($self) {
    return $self->new(value => $NORMAL);
  }

  sub normal ($self) {
    return $self->new(value => $NORMAL);
  }

  sub admin ($self) {
    return $self->new(value => $ADMIN);
  }

  sub test ($self) {
    return $self->new(value => $TEST);
  }

  method TO_STRING {
    return "Role(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {
    return $value;
  }
}

__END__
