package main;
use v5.40;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Crypt;

# ABSTRACT: test Crypt

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    IV->new(value => IV->rand()->value);
  },
) or note($EVAL_ERROR);

for my $fail ('', 'a' x ($IV::LEN + 1), 'x' x $IV::LEN) {
  ok(
    dies {
      IV->new(value => $fail);
    },
  ) or note($EVAL_ERROR);
}

done_testing;
