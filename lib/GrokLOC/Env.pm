package GrokLOC::Env;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Describe the execution environment.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Env {
  Readonly::Scalar our $none  => -1;
  Readonly::Scalar our $unit  => 0;
  Readonly::Scalar our $dev   => 1;
  Readonly::Scalar our $stage => 2;
  Readonly::Scalar our $prod  => 3;

  field $value :param : reader;

  ADJUST {
    use Carp           qw( croak );
    use List::AllUtils qw( any );
    croak '$value malformed'
      unless any { $_ == $value } ($unit, $dev, $stage, $prod);
  }

  sub TO_JSON ($self) {
    return $self->value;
  }
}
