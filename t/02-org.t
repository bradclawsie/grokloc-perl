package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use UUID                    qw( uuid4 );
use strictures 2;
use GrokLOC::App::State;
use GrokLOC::App::Admin::Org;
use GrokLOC::Crypt;
use GrokLOC::Models;
use GrokLOC::Safe;

# ABSTRACT: test Org

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $now  = time;
my $meta = Meta->new(
  ctime          => $now,
  mtime          => $now,
  role           => Role->new(value => $Role::TEST),
  schema_version => 0,
  signature      => uuid4,
  status         => Status->new(value => $Status::ACTIVE),
);

ok(
  lives {
    Org->new(
      id    => ID->rand(),
      meta  => $meta,
      name  => VarChar->rand(),
      owner => ID->rand()
    );
  },
) or note($EVAL_ERROR);

ok(
  lives {
    Org->default(VarChar->rand);
    Org->rand;
  },
) or note($EVAL_ERROR);

my $st = State->unit;
my ($org, $read_org);

ok(
  lives {
    $org = Org->rand;
    my $tx = $st->master->db->begin;
    my $owner =
      $org->insert($st->master->db, VarChar->rand, VarChar->rand,
      Password->rand, $st->version_key->current,
      $st->version_key);
    $tx->commit;
    my $replica = $st->random_replica;
    $read_org = Org->read($replica->db, $org->id);
  },
) or note($EVAL_ERROR);

is($org->id,    $read_org->id,    'read id');
is($org->meta,  $read_org->meta,  'read meta');
is($org->name,  $read_org->name,  'read name');
is($org->owner, $read_org->owner, 'read owner');

# TODO confirm that $owner is not in db to confirm rollback.
ok(
  dies {
    my $org = Org->rand;

    # Setting id to ID::NIL will preclude insert.
    $org->set_id(ID->default);
    my $tx = $st->master->db->begin;
    my $owner =
      $org->insert($st->master->db, VarChar->rand, VarChar->rand,
      Password->rand, $st->version_key->current,
      $st->version_key);
    $tx->commit;
  },
) or note($EVAL_ERROR);

done_testing;
