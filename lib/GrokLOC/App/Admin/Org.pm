package GrokLOC::App::Admin::Org;
use v5.42;
use strictures 2;
use Object::Pad;
use GrokLOC::Models;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org :does(WithID) : does(WithMeta) {
  use Carp::Assert::More qw( assert_is assert_isa assert_nonblank );
  use GrokLOC::Models;
  use GrokLOC::Safe;

  field $name :param : reader;
  field $owner :param : reader;

  ADJUST {
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
      id    => ID->default,
      meta  => $meta,
      name  => VarChar->rand,
      owner => ID->default
    );
  }

  method insert ($db,
                 $owner_display_name,
                 $owner_email,
                 $owner_password,
                 $owner_key_version,
                 $version_key) {
    assert_isa($db, 'Mojo::Pg::Database', 'db is not type Mojo::Pg::Database');
    assert_isa($owner_display_name, 'VarChar',
      'owner_display_name not type VarChar');
    assert_isa($owner_email,    'VarChar',  'owner_email not type VarChar');
    assert_isa($owner_password, 'Password', 'owner_password not type Password');
    assert_nonblank($owner_key_version, 'owner_key_version malformed');
    assert_isa($version_key, 'VersionKey', 'version_key not type VersionKey');

    # If $id is not $ID::NIL, then it is likely that this Org
    # has already been inserted; the db generates $id.
    assert_is($self->id->value, $ID::NIL, 'db generates id on insert');

    my $q = <<~'INSERT_ORG';
    insert into orgs
    (name, owner, role, schema_version, status)
    values
    ($1, $2, $3, $4, $5)
    returning id, ctime, mtime, signature
    INSERT_ORG

    my $results = $db->query(
      $q,
      $name->value,

      # The owner isn't known yet, so put in NIL
      # until the owner is inserted, then update
      # and set this org to status active (as of
      # this statement it is still unconfirmed).
      $ID::NIL,
      $self->meta->role->value,
      $self->meta->schema_version,
      $self->meta->status->value
    );

    return $results;
  }

  method TO_JSON {
    return {
      id    => $self->id->TO_JSON,
      meta  => $self->meta->TO_JSON,
      name  => $name->TO_JSON,
      owner => $owner->TO_JSON
    };
  }
}

__END__
