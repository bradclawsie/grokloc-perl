package main;
use v5.42;
use strictures 2;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use GrokLOC::Crypt::IV;

# ABSTRACT: Test Crypt::IV.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $iv;

ok(
  lives {
    $iv = IV->new(value => IV->rand()->value);
    is($iv ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$iv";
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
