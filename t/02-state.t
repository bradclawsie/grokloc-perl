package main;
use v5.40;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use lib '../lib';
use GrokLOC::App::State;

# ABSTRACT: test App::State

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    my $dsn = 'postgres://user:pass@host:5432/db';
    my ($username, $password, $hostname, $port, $database_name) =
      State::dsn_parts($dsn);
    is($username,      'user');
    is($password,      'pass');
    is($hostname,      'host');
    is($port,          5432);
    is($database_name, 'db');
  },
) or note($EVAL_ERROR);

ok(
  dies {
    State::dsn_parts('mysql://user:pass@host:5432/db');
  },
) or note($EVAL_ERROR);

ok(
  dies {
    State::dsn_parts('://user:pass@host:5432/db');
  },
) or note($EVAL_ERROR);

ok(
  dies {
    State::dsn_parts('postgres://user:pass@host/db');
  },
) or note($EVAL_ERROR);

ok(
  dies {
    State::dsn_parts('postgres://user:pass@host:5432/');
  },
) or note($EVAL_ERROR);

done_testing;
