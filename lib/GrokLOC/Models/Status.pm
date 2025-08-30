package GrokLOC::Models::Status;
use v5.42;
use strictures 2;
use Data::Checks qw( NumRange );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;

# ABSTRACT: Model Status.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Status {
  use Readonly ();
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $NONE        => 0;
  Readonly::Scalar our $UNCONFIRMED => 1;
  Readonly::Scalar our $ACTIVE      => 2;
  Readonly::Scalar our $INACTIVE    => 3;

  field $value :param : reader : Checked(NumRange(1,4));

  sub default ($self) {
    return $self->new(value => $UNCONFIRMED);
  }

  sub unconfirmed ($self) {
    return $self->new(value => $UNCONFIRMED);
  }

  sub active ($self) {
    return $self->new(value => $ACTIVE);
  }

  sub inactive ($self) {
    return $self->new(value => $INACTIVE);
  }

  method TO_STRING {
    return "Status(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {
    return $value;
  }
}

__END__
