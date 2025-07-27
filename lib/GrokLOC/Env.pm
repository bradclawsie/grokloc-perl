package GrokLOC::Env;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: Describe the execution environment.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Env {
  use Carp::Assert::More qw (assert);
  use Readonly           ();
  use feature 'keyword_any';
  no warnings 'experimental::keyword_any';

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

__END__
