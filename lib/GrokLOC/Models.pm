package GrokLOC::Models;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Core types relevant to all model instances.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Role {
  Readonly::Scalar our $none   => 0;
  Readonly::Scalar our $normal => 1;
  Readonly::Scalar our $admin  => 2;
  Readonly::Scalar our $test   => 3;

  field $value :param : reader;

  ADJUST {
    use Carp           qw( croak );
    use List::AllUtils qw( any );
    croak '$value malformed'
      unless any { $_ == $value } ($normal, $admin, $test);
  }

  sub TO_JSON ($self) {
    return $self->value;
  }
}

class Status {
  Readonly::Scalar our $none        => 0;
  Readonly::Scalar our $unconfirmed => 1;
  Readonly::Scalar our $active      => 2;
  Readonly::Scalar our $inactive    => 3;

  field $value :param : reader;

  ADJUST {
    use Carp           qw( croak );
    use List::AllUtils qw( any );
    croak '$value malformed'
      unless any { $_ == $value } ($unconfirmed, $active, $inactive);
  }

  sub TO_JSON ($self) {
    return $self->value;
  }
}

__END__
