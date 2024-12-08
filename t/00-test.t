package main;
use v5.40;
use Test2::V0 qw( done_testing is isnt );
use strictures 2;

# ABSTRACT: test tests

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

is(1, 1);
isnt(1, 0);

done_testing;
