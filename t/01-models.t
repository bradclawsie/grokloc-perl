package main;
use v5.40;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Models;

# ABSTRACT: test Models

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    Role->new(value => $Role::normal);
  },
) or note($EVAL_ERROR);

done_testing;
