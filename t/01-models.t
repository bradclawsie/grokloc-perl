package main;
use v5.42;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use UUID                    qw( clear is_null parse unparse uuid4 );
use strictures 2;
use GrokLOC::Models;

# ABSTRACT: test Models

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

is(Role->default->value, $Role::NORMAL, 'default role');

ok(
  lives {
    Role->new(value => $Role::NORMAL);
    Role->new(value => $Role::ADMIN);
    Role->new(value => $Role::TEST);
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
    $role = Role->new(value => $Role::NORMAL);
  },
) or note($EVAL_ERROR);

ok($role isa Role);
my $json = Cpanel::JSON::XS->new->convert_blessed([true]);
is($Role::NORMAL, $json->encode($role));

is($Role::NORMAL, Role->default()->value);

is(Status->default->value, $Status::UNCONFIRMED, 'status default');

ok(
  lives {
    Status->new(value => $Status::UNCONFIRMED);
    Status->new(value => $Status::ACTIVE);
    Status->new(value => $Status::INACTIVE);
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
    $status = Status->new(value => $Status::ACTIVE);
  },
) or note($EVAL_ERROR);

ok($status isa Status);
is($Status::ACTIVE, $json->encode($status));

is($Status::UNCONFIRMED, Status->default()->value);

my $meta = Meta->default;
is($meta->ctime,          0, 'meta ctime');
is($meta->mtime,          0, 'meta mtime');
is($meta->role->value,    Role->default->value);
is($meta->schema_version, 0, 'meta schema_version');
my ($bin, $str);
clear($bin);    # null uuid
unparse($bin, $str);
is($meta->signature,     $str,                   'meta signature');
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

is(parse($ID::NIL, $bin), 0, 'nil id is not uuid');
is(is_null($bin),         1, 'nil id is not NULL uuid');
unparse($bin, $str);
is($str, $ID::NIL, 'nil id does not round trip');

is(ID->default->value, $ID::NIL, 'ID default');

ok(
  lives {
    ID->rand();
    ID->new(value => uuid4());
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

done_testing;
