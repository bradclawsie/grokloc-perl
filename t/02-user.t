package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing note ok );
use Test2::Tools::Exception qw( lives );
use UUID                    qw( uuid4 );
use strictures 2;
use GrokLOC::App::Admin::User;
use GrokLOC::Models;
use GrokLOC::Safe;

# ABSTRACT: test User

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    User->rand(ID->rand, uuid4);
  },
) or note($EVAL_ERROR);

done_testing;
