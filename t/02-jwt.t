package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use UUID                    qw( uuid4 );
use strictures 2;
use GrokLOC::App::JWT;
use GrokLOC::Models;

# ABSTRACT: test App::JWT

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    my $now   = time;
    my $token = JWT->new(
      exp => $now,
      nbf => $now,
      iss => 'GrokLOC.com',
      sub => ID->rand,
      cip => '127.0.0.1'
    );
    is($token ? true : false, true, 'boolean context');
  },
) or note($EVAL_ERROR);

ok(
  # exp fails
  dies {
    my $now = time;
    JWT->new(
      exp => $now - 10,
      nbf => $now,
      iss => 'GrokLOC.com',
      sub => ID->rand,
      cip => '127.0.0.1'
    );
  },
) or note($EVAL_ERROR);

ok(
  # nbf fails
  dies {
    my $now = time;
    JWT->new(
      exp => $now,
      nbf => $now + 10,
      iss => 'GrokLOC.com',
      sub => ID->rand,
      cip => '127.0.0.1'
    );
  },
) or note($EVAL_ERROR);

ok(
  # sub fails
  dies {
    my $now = time;
    JWT->new(
      exp => $now,
      nbf => $now,
      iss => 'GrokLOC.com',
      sub => '',
      cip => '127.0.0.1'
    );
  },
) or note($EVAL_ERROR);

ok(
  # iss fails
  dies {
    my $now = time;
    JWT->new(
      exp => $now,
      nbf => $now,
      iss => '',
      sub => ID->rand,
      cip => '127.0.0.1'
    );
  },
) or note($EVAL_ERROR);

ok(
  # cip fails
  dies {
    my $now = time;
    JWT->new(
      exp => $now,
      nbf => $now,
      iss => 'GrokLOC.com',
      sub => ID->rand,
      cip => 0
    );
  },
) or note($EVAL_ERROR);

ok(
  # missing fields
  dies {
    JWT->new;
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $now   = time;
    my $token = JWT->new(
      exp => $now + 86400,
      nbf => $now - 86400,
      iss => 'GrokLOC.com',
      sub => ID->rand,
      cip => '127.0.0.1'
    );

    my $signing_key = uuid4;
    my $encoded     = $token->encode($signing_key);
    is($token, JWT->decode($encoded, $signing_key));
  },
) or note($EVAL_ERROR);

ok(
  # decode with the wrong signing_key
  dies {
    my $now   = time;
    my $token = JWT->new(
      exp => $now + 86400,
      nbf => $now - 86400,
      iss => 'GrokLOC.com',
      sub => ID->rand,
      cip => '127.0.0.1'
    );

    my $signing_key = uuid4;
    my $encoded     = $token->encode($signing_key);
    JWT->decode($encoded, uuid4);
  },
) or note($EVAL_ERROR);

ok(
  # decode bad input
  dies {
    JWT->decode('', uuid4);
  },
) or note($EVAL_ERROR);

ok(
  # round trip as headers
  lives {
    my $now   = time;
    my $token = JWT->new(
      exp => $now + 86400,
      nbf => $now - 86400,
      iss => 'GrokLOC.com',
      sub => ID->rand,
      cip => '127.0.0.1'
    );

    my $signing_key = uuid4;
    my $header      = $token->to_header($signing_key);
    is($token, JWT->from_header($header, $signing_key));
  },
) or note($EVAL_ERROR);

ok(
  # decode bad input
  dies {
    JWT->from_header('', uuid4);
  },
) or note($EVAL_ERROR);

done_testing;
