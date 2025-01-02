package main;
use v5.40;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Models;
use GrokLOC::Safe;
use GrokLOC::App::Admin::Org;

# ABSTRACT: test Org

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    Org->new(name => VarChar->rand(), owner => ID->rand());
  },
) or note($EVAL_ERROR);

done_testing;
