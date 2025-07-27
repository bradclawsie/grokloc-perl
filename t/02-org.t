package main;
use v5.42;
use Crypt::Misc             qw( random_v4uuid );
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use GrokLOC::Models;
use GrokLOC::Safe;
use GrokLOC::App::Admin::Org;

# ABSTRACT: test Org

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $now  = time;
my $meta = Meta->new(
  ctime          => $now,
  mtime          => $now,
  role           => Role->new(value => $Role::TEST),
  schema_version => 0,
  signature      => random_v4uuid,
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

done_testing;
