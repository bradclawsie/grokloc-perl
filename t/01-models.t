package main;
use v5.42;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is isnt note ok );
use Test2::Tools::Exception qw( dies lives );
use UUID                    qw( clear is_null parse unparse uuid4 );
use strictures 2;
use GrokLOC::Models;

# ABSTRACT: test Models

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# Role.
is(Role->default->value, $Role::NORMAL, 'default role');

ok(
  lives {
    Role->normal;
    Role->admin;
    Role->test;
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Role->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Role->new(value => $Role::NONE);
  },
) or note($EVAL_ERROR);

my $role;

ok(
  lives {
    $role = Role->normal;
    is($role ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$role";
  },
) or note($EVAL_ERROR);

ok($role isa Role);
my $json = Cpanel::JSON::XS->new->convert_blessed([true]);
is($Role::NORMAL, $json->encode($role));

is($Role::NORMAL, Role->default()->value);

# Status.
is(Status->default->value, $Status::UNCONFIRMED, 'status default');

ok(
  lives {
    Status->unconfirmed;
    Status->active;
    Status->inactive;
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Status->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Status->new(value => $Status::NONE);
  },
) or note($EVAL_ERROR);

my $status;

ok(
  lives {
    $status = Status->active;
    is($status ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$status";
  },
) or note($EVAL_ERROR);

ok($status isa Status);
is($Status::ACTIVE, $json->encode($status));

is($Status::UNCONFIRMED, Status->default()->value);

# ID.
my ($bin, $str);
is(parse($ID::NIL, $bin), 0, 'nil id is not uuid');
is(is_null($bin),         1, 'nil id is not NULL uuid');
unparse($bin, $str);
is($str, $ID::NIL, 'nil id does not round trip');

is(ID->default->value, $ID::NIL, 'ID default');

ok(
  lives {
    ID->rand();
    my $id = ID->new(value => uuid4());
    is($id ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$id";
  },
) or note($EVAL_ERROR);

ok(
  dies {
    ID->new(value => undef);
  },
) or note($EVAL_ERROR);

# nil ID is allowed
ok(
  lives {
    ID->new(value => $ID::NIL);
  },
) or note($EVAL_ERROR);

ok(
  dies {
    ID->new(value => '');
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $json =
      Cpanel::JSON::XS->new->convert_blessed([true])->allow_nonref([true]);
    ID->new(value => $json->decode($json->encode(ID->new(value => uuid4()))));
  },
) or note($EVAL_ERROR);

# WithID.
use Object::Pad;

class WithIDTest :does(WithID) { }

ok(
  lives {
    WithIDTest->new(id => ID->rand)->set_id(ID->rand);
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithIDTest->new(id => 'not an ID');
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithIDTest->new(id => ID->rand)->set_id('not an ID');
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithIDTest->new(id => ID->rand)->set_id(ID->default);
  }
) or note($EVAL_ERROR);

# Meta.
my $meta = Meta->default;

# Boolean context fails as signature is undefined.
is($meta ? true : false, false, 'boolean context');

# Signature must be set as uuid4.
ok(
  dies {
    $meta->set_signature('not a uuid');
  }
) or note($EVAL_ERROR);
ok(
  lives {
    $meta->set_signature(uuid4);
  }
) or note($EVAL_ERROR);

# Boolean context succeeds as signature is defined.
is($meta ? true : false, true, 'boolean context');

# TO_STRING
my $quoted = "$meta";

is($meta->ctime,          0, 'meta ctime');
is($meta->mtime,          0, 'meta mtime');
is($meta->role->value,    Role->default->value);
is($meta->schema_version, 0, 'meta schema_version');
ok(parse($bin, $meta->signature));
is($meta->status->value, Status->default->value, 'meta status');

ok(
  lives {
    my $now = time;
    Meta->new(
      ctime          => $now,
      mtime          => $now,
      role           => $role,
      schema_version => 0,
      signature      => uuid4,
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Meta->new(
      ctime          => -1,
      mtime          => $now,
      role           => $role,
      schema_version => 0,
      signature      => uuid4,
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Meta->new(
      ctime          => $now + 1000,
      mtime          => $now,
      role           => $role,
      schema_version => 0,
      signature      => uuid4,
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Meta->new(
      ctime          => $now,
      mtime          => -1,
      role           => $role,
      schema_version => 0,
      signature      => uuid4,
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $now = time;
    Meta->new(
      ctime          => $now - 1000,
      mtime          => $now - 100,
      role           => $role,
      schema_version => 0,
      signature      => uuid4,
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Meta->new(
      ctime          => $now,
      mtime          => $now,
      role           => undef,
      schema_version => 0,
      signature      => uuid4,
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Meta->new(
      ctime          => $now,
      mtime          => $now,
      role           => $role,
      schema_version => -1,
      signature      => uuid4,
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Meta->new(
      ctime          => $now,
      mtime          => $now,
      role           => $role,
      schema_version => 0,
      signature      => '',
      status         => $status
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Meta->new(
      ctime          => $now,
      mtime          => $now,
      role           => $role,
      schema_version => 0,
      signature      => uuid4,
      status         => undef
    );
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $now = time;
    $json->decode(
      $json->encode(
        Meta->new(
          ctime          => $now,
          mtime          => $now,
          role           => $role,
          schema_version => 0,
          signature      => uuid4,
          status         => $status
        )
      )
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $meta = Meta->default;
    $meta->set_role('not a Role instance');
  },
) or note($EVAL_ERROR);

$meta = Meta->default;
is($meta->role, Role->default);
ok(
  lives {
    $meta->set_role(Role->new(value => $Role::TEST))
  }
) or note($EVAL_ERROR);
is($meta->role, Role->new(value => $Role::TEST));

ok(
  dies {
    my $meta = Meta->default;
    $meta->set_status('not a Status instance');
  },
) or note($EVAL_ERROR);

$meta = Meta->default;
is($meta->status, Status->default);
ok(
  lives {
    $meta->set_status(Status->new(value => $Status::INACTIVE));
  }
) or note($EVAL_ERROR);
is($meta->status, Status->new(value => $Status::INACTIVE));

# WithMeta.
class WithMetaTest :does(WithMeta) { }

ok(
  lives {
    my $m_ = Meta->default;
    $m_->set_role(Role->new(value => $Role::ADMIN));
    $m_->set_status(Status->new(value => $Status::INACTIVE));
    my $m = WithMetaTest->new(meta => Meta->default);

    # Verify they are different before assigning.
    isnt($m->meta->role,   $m_->role,   'role');
    isnt($m->meta->status, $m_->status, 'status');
    $m->set_meta($m_);
    is($m->meta->role,   $m_->role,   'role');
    is($m->meta->status, $m_->status, 'status');
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithMetaTest->new(meta => 'not a Meta');
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithMetaTest->new(meta => Meta->default)->set_meta('not a Meta');
  }
) or note($EVAL_ERROR);

done_testing;
