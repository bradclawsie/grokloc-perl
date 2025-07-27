package GrokLOC::App::Admin::Org;
use v5.40;
use strictures 2;
use Object::Pad;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org {
  use Carp::Assert::More qw( assert_isa );
  use GrokLOC::Models;
  use GrokLOC::Safe;

  #<<V
  field $id :param :reader;
  field $meta :param :reader;
  field $name :param :reader;
  field $owner :param :reader;
  #>>V

  ADJUST {
    assert_isa($id,    'ID',      'id is not type ID');
    assert_isa($meta,  'Meta',    'meta is not type Meta');
    assert_isa($name,  'VarChar', 'name is not type VarChar');
    assert_isa($owner, 'ID',      'owner is not type ID');
  }
}

__END__
