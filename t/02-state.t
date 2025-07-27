package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use GrokLOC::App::State;

# ABSTRACT: test App::State

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    my $st = State->new(
      api_version  => 1,
      master_dsn   => $ENV{POSTGRES_APP_URL},
      replica_dsns => [ $ENV{POSTGRES_APP_URL} ],
    );

    is($st->master->db->ping, 1, 'master ping');
    for my $replica (@{$st->replicas}) {
      is($replica->db->ping, 1, 'replica ping');
    }
  },
) or note($EVAL_ERROR);

done_testing;
