package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing note ok );
use Test2::Tools::Exception qw( lives );
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
    Org->default;
    Org->rand;
  },
) or note($EVAL_ERROR);

my $st = State->unit;

done_testing;
