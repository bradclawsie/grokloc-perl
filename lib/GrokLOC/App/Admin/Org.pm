package GrokLOC::App::Admin::Org;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org {
  use Carp::Assert::More qw( assert_isa );
  use GrokLOC::Models;
  use GrokLOC::Safe;

  field $id :param : reader;
  field $meta :param : reader;
  field $name :param : reader;
  field $owner :param : reader;

  ADJUST {
    assert_isa($id,    'ID',      'id is not type ID');
    assert_isa($meta,  'Meta',    'meta is not type Meta');
    assert_isa($name,  'VarChar', 'name is not type VarChar');
    assert_isa($owner, 'ID',      'owner is not type ID');
  }

  sub default ($self) {
    return $self->new(
      id    => ID->default,
      meta  => Meta->default,
      name  => VarChar->default,
      owner => ID->default
    );
  }

  sub rand ($self) {
    my $meta = Meta->default;
    $meta->Role = $Role::TEST;
    return $self->new(
      id    => ID->rand,
      meta  => $meta,
      name  => VarChar->rand,
      owner => ID->rand
    );
  }

  method TO_JSON {
    return {
      id    => $id->TO_JSON,
      meta  => $meta->TO_JSON,
      name  => $name->TO_JSON,
      owner => $owner->TO_JSON
    };
  }
}

__END__
