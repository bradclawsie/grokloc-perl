package GrokLOC::Env;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Describe the execution environment.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Env {
  use Carp::Assert::More qw (assert);
  use List::AllUtils     qw( any );

  Readonly::Scalar our $NONE  => -1;
  Readonly::Scalar our $UNIT  => 0;
  Readonly::Scalar our $DEV   => 1;
  Readonly::Scalar our $STAGE => 2;
  Readonly::Scalar our $PROD  => 3;

  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    assert(any { $_ == $value } ($UNIT, $DEV, $STAGE, $PROD), 'value');
  }

  sub TO_JSON ($self) {
    return $self->value;
  }
}
