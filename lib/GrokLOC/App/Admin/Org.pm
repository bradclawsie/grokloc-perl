package GrokLOC::App::Admin::Org;
use v5.42;
use strictures 2;
use Object::Pad;
use GrokLOC::Models;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org :does(WithID) : does(WithMeta) {
  use Carp::Assert::More
    qw( assert_defined assert_is assert_isa assert_nonblank );
  use GrokLOC::App::Admin::User;
  use GrokLOC::Models;
  use GrokLOC::Safe;

  field $name :param : reader;
  field $owner :param : reader;

  ADJUST {
    assert_isa($name,  'VarChar', 'name is not type VarChar');
    assert_isa($owner, 'ID',      'owner is not type ID');
  }

  # Create a new Org with key fields initialized.
  # This is what is used to create a new Org for insertion.
  sub default ($self, $name) {
    return $self->new(
      id    => ID->default,
      meta  => Meta->default,
      name  => $name,
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

  sub read ($self, $db, $id) {
    assert_isa($db, 'Mojo::Pg::Database', 'db is not type Mojo::Pg::Database');
    assert_isa($id, 'ID',                 'id is not type ID');

    my $org_read_query = 'select * from orgs where id = $1';
    my $org_row        = $db->query($org_read_query, $id->value)->hash;
    my $meta           = Meta->from_hashref($org_row);

    for my $col (qw(id name owner)) {
      assert_defined($org_row->{$col}, "$col not defined");
    }

    return $self->new(
      id    => ID->new(value => $org_row->{id}),
      meta  => $meta,
      name  => VarChar->trusted($org_row->{name}),
      owner => ID->new(value => $org_row->{owner}),
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

    # Insert Org with nil owner for now.
    my $insert_org_query = <<~'INSERT_ORG';
    insert into orgs
    (name, owner, role, schema_version, status)
    values
    ($1, $2, $3, $4, $5)
    returning id, ctime, mtime, signature
    INSERT_ORG

    my $insert_org_results = $db->query(
      $insert_org_query,
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

    my $insert_org_returning = $insert_org_results->hash;
    $self->set_id(ID->new(value => $insert_org_returning->{id}));

    # Create and insert owner.
    my ($owner_user, $owner_private_key) = User->default(
      $owner_display_name, $owner_email, $self->id,
      $owner_password,     $owner_key_version
    );

    # Owner is considered active by default.
    $owner_user->meta->set_status(Status->new(value => $Status::ACTIVE));

    $owner_user->insert($db, $version_key);

    # Reminder: $owner is field in $self.
    $owner = ID->new(value => $owner_user->id->value);

    # Update the org with the actual owner information
    # and set it to active so it can be used.
    my $update_org_query = <<~'UPDATE_ORG';
    update orgs set
    owner = $1,
    status = $2
    where id = $3
    returning mtime, signature
    UPDATE_ORG

    my $update_org_results =
      $db->query($update_org_query, $owner->value,
      Status->new(value => $Status::ACTIVE)->value,
      $self->id->value);
    my $update_org_returning = $update_org_results->hash;

    # Reset metadata to reflect update active state etc.
    $self->set_meta(
      Meta->new(
        ctime          => $insert_org_returning->{ctime},
        mtime          => $update_org_returning->{mtime},
        role           => Role->new(value => $self->meta->role->value),
        schema_version => $self->meta->schema_version,
        signature      => $update_org_returning->{signature},
        status         => Status->new(value => $Status::ACTIVE)
      )
    );

    assert_is($owner_user->org->value, $self->id->value,
      'owner org not org id');
    assert_is($owner_user->id->value,     $owner->value,   'owner id mismatch');
    assert_is($self->meta->status->value, $Status::ACTIVE, 'org not active');
    assert_is($owner_user->meta->status->value,
      $Status::ACTIVE, 'owner not active');

    return $owner;
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
