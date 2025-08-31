package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC::Env;

# ABSTRACT: Test Env.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    Env->unit;
    Env->dev;
    Env->stage;
    Env->prod;
  },
) or note($EVAL_ERROR);

ok(Env->unit->value < Env->dev->value < Env->stage->value < Env->prod->value);

ok(
  dies {
    Env->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Env->new(value => $Env::NONE);
  },
) or note($EVAL_ERROR);

done_testing;
