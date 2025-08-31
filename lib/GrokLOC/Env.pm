package GrokLOC::Env;
use v5.42;
use strictures 2;
use Data::Checks qw( NumRange );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;

# ABSTRACT: Describe the execution environment.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Env {
  use Readonly ();

  Readonly::Scalar our $NONE  => 0;
  Readonly::Scalar our $UNIT  => 1;
  Readonly::Scalar our $DEV   => 2;
  Readonly::Scalar our $STAGE => 3;
  Readonly::Scalar our $PROD  => 4;

  field $value :param : reader : Checked(NumRange(1,5));

  sub unit ($self) {
    return $self->new(value => $UNIT);
  }

  sub dev ($self) {
    return $self->new(value => $DEV);
  }

  sub stage ($self) {
    return $self->new(value => $STAGE);
  }

  sub prod ($self) {
    return $self->new(value => $PROD);
  }
}

__END__
