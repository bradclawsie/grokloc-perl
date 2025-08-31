package GrokLOC::App::Admin::Org;
use v5.42;
use strictures 2;
use Data::Checks qw( Isa Str );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method sub );
use GrokLOC::Models::ID;
use GrokLOC::Models::Meta;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org :does(WithID) : does(WithMeta) {
  use Carp               qw( croak );
  use Carp::Assert::More qw( assert_defined assert_is );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;
  use GrokLOC::App::Admin::User;
  use GrokLOC::Models::ID;
  use GrokLOC::Models::Meta;
  use GrokLOC::Models::Role;
  use GrokLOC::Models::Status;
  use GrokLOC::Safe;

  field $name :param : reader : Checked(Isa('VarChar'));
  field $owner :param : reader : Checked(Isa('ID'));

  # Create a new Org with key fields initialized.
  # This is what is used to create a new Org for insertion.
  sub default ($self, $name :Checked(Isa('VarChar'))) {
    return $self->new(
      id    => ID->default,
      meta  => Meta->default,
      name  => $name,
      owner => ID->default
    );
  }

  sub rand ($self) {
    my $meta = Meta->default;
    $meta->set_role(Role->test);
    return $self->new(
      id    => ID->default,
      meta  => $meta,
      name  => VarChar->rand,
      owner => ID->default
    );
  }

  sub read ($self,
            $db :Checked(Isa('Mojo::Pg::Database')),
            $id :Checked(Isa('ID'))) {
    my $org_read_query = 'select * from orgs where id = $1';
    my $org_row        = $db->query($org_read_query, $id->value)->hash;

    # Croak on errors that are catch-able.
    croak 'no rows' unless (defined($org_row));

    # Convert role and status from numeric to object representation.
    $org_row->{role}   = Role->new(value => $org_row->{role});
    $org_row->{status} = Status->new(value => $org_row->{status});

    my $meta = Meta->new(%{$org_row});

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

  method insert ($db :Checked(Isa('Mojo::Pg::Database')),
                 $owner_display_name :Checked(Isa('VarChar')),
                 $owner_email :Checked(Isa('VarChar')),
                 $owner_password :Checked(Isa('Password')),
                 $owner_key_version :Checked(Str),
                 $version_key :Checked(Isa('VersionKey'))) {

    # If id is true in the boolean context, then
    # the id value has been set; but only the db
    # creates ids, so it should not be set yet.
    croak 'id value is not undef' if $self->id;

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
    $owner_user->meta->set_status(Status->active);
    $owner_user->insert($db, $version_key);

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

    my $update_org_results = $db->query(
      $update_org_query,     $owner->value,
      Status->active->value, $self->id->value
    );
    my $update_org_returning = $update_org_results->hash;

    # Reset metadata to reflect update active state etc.
    $self->set_meta(
      Meta->new(
        ctime          => $insert_org_returning->{ctime},
        mtime          => $update_org_returning->{mtime},
        role           => Role->new(value => $self->meta->role->value),
        schema_version => $self->meta->schema_version,
        signature      => $update_org_returning->{signature},
        status         => Status->active
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

  method users ($db :Checked(Isa('Mojo::Pg::Database'))) {
    my $users =
      $db->query('select id from users where org = $1', $self->id->value);
  }

  method TO_STRING {
    my $self_id   = $self->id;
    my $id_       = "$self_id";
    my $self_meta = $self->meta;
    my $meta_     = "$self_meta";
    my $name_     = "$name";
    my $owner_    = "$owner";

    return
        "Org(id => $id_, "
      . "meta => $meta_, "
      . "name => $name_, "
      . "owner => $owner_)";
  }

  # Will not evaluate to true unless populated with
  # db metadata.
  method TO_BOOL {
    return
         defined($self->id)
      && $self->id
      && defined($self->meta)
      && ($self->meta->ctime != 0)
      && ($self->meta->mtime != 0)
      && ($self->meta->signature ne q{})
      && defined($name)
      && defined($owner)
      && ($owner->value ne $ID::NIL);
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
