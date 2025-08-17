package GrokLOC::App::Admin::Org;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org {
  use Carp::Assert::More qw( assert_isa assert_nonblank );
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
    $meta->set_role(Role->new(value => $Role::TEST));
    return $self->new(
      id    => ID->rand,
      meta  => $meta,
      name  => VarChar->rand,
      owner => ID->rand
    );
  }

  method insert ($txn,
                 $owner_display_name,
                 $owner_email,
                 $owner_password,
                 $owner_key_version,
                 $version_key) {
    assert_isa($txn, 'Mojo::Pg::Transaction',
      'txn is not type Mojo::Pg::Transaction');
    assert_isa($owner_display_name, 'VarChar',
      'owner_display_name not type VarChar');
    assert_isa($owner_email,    'VarChar',  'owner_email not type VarChar');
    assert_isa($owner_password, 'Password', 'owner_password not type Password');
    assert_nonblank($owner_key_version, 'owner_key_version malformed');
    assert_isa($version_key, 'VersionKey', 'version_key not type VersionKey');
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
