package GrokLOC::App::Admin::Org;
use v5.40;
use strictures 2;
use Object::Pad;
use lib '../../../lib';
use GrokLOC::Safe;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org {
  use Carp::Assert::More qw( assert_isa );

  #<<V
  field $name :param :reader;
  field $owner :param :reader;
  #>>V

  ADJUST {
    assert_isa($name,  'VarChar', 'name is not type VarChar');
    assert_isa($owner, 'ID',      'owner is not type ID');
  }
}

__END__
