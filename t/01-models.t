package main;
use v5.40;
use Cpanel::JSON::XS        ();
use Crypt::Misc             qw( random_v4uuid );
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Models;

# ABSTRACT: test Models

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

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

ok(
  lives {
    my $now = time;
    Meta->new(
      ctime          => $now,
      mtime          => $now,
      role           => $role,
      schema_version => 0,
      signature      => random_v4uuid,
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
      signature      => random_v4uuid,
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
      signature      => random_v4uuid,
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
      signature      => random_v4uuid,
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
      signature      => random_v4uuid,
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
      signature      => random_v4uuid,
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
      signature      => random_v4uuid,
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
      signature      => random_v4uuid,
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
          signature      => random_v4uuid,
          status         => $status
        )
      )
    );
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $now = time;
    Base->new(
      id   => random_v4uuid,
      meta => Meta->new(
        ctime          => $now,
        mtime          => $now,
        role           => $role,
        schema_version => 0,
        signature      => random_v4uuid,
        status         => $status
      )
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Base->new(
      id   => '',
      meta => Meta->new(
        ctime          => $now,
        mtime          => $now,
        role           => $role,
        schema_version => 0,
        signature      => random_v4uuid,
        status         => $status
      )
    );
  },
) or note($EVAL_ERROR);

ok(
  dies {
    my $now = time;
    Base->new(
      id   => random_v4uuid,
      meta => undef
    );
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $now = time;
    $json->decode(
      $json->encode(
        Base->new(
          id   => random_v4uuid,
          meta => Meta->new(
            ctime          => $now,
            mtime          => $now,
            role           => $role,
            schema_version => 0,
            signature      => random_v4uuid,
            status         => $status
          )
        )
      )
    );
  },
) or note($EVAL_ERROR);

done_testing;
