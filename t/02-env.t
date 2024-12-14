package main;
use v5.40;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Env;

# ABSTRACT: test Env

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    Env->new(value => $Env::unit);
    Env->new(value => $Env::dev);
    Env->new(value => $Env::stage);
    Env->new(value => $Env::prod);
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Env->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Env->new(value => $Env::none);
  },
) or note($EVAL_ERROR);

my $env;

ok(
  lives {
    $env = Env->new(value => $Env::unit);
  },
) or note($EVAL_ERROR);

my $json = Cpanel::JSON::XS->new->convert_blessed([true]);
is($Env::unit, $json->encode($env));

done_testing;
