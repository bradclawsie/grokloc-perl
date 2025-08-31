package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use GrokLOC::Crypt::AESGCM;
use GrokLOC::Crypt::Key;
use GrokLOC::Crypt::IV;

# ABSTRACT: Test Crypt::AESGCM.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $iv  = IV->rand;
my $key = Key->rand;
my $s   = 'hello';
my $e;

ok(
  lives {
    $e = AESGCM->encrypt($s, $key->value, $iv->value);
  },
) or note($EVAL_ERROR);

my $pt;

ok(
  lives {
    $pt = AESGCM->decrypt($e, $key->value);
  },
) or note($EVAL_ERROR);

is($pt, $s);

done_testing;
