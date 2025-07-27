package main;
use v5.42;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC::Env;

# ABSTRACT: test Env

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    Env->new(value => $Env::UNIT);
    Env->new(value => $Env::DEV);
    Env->new(value => $Env::STAGE);
    Env->new(value => $Env::PROD);
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
    $env = Env->new(value => $Env::UNIT);
  },
) or note($EVAL_ERROR);

ok($env isa Env);
my $json = Cpanel::JSON::XS->new->convert_blessed([true]);
is($Env::UNIT, $json->encode($env));

done_testing;
