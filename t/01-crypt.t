package main;
use v5.40;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Crypt;

# ABSTRACT: test Crypt

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $iv;

ok(
  lives {
    $iv = IV->new(value => IV->rand()->value);
  },
) or note($EVAL_ERROR);

for my $fail ('', 'a' x ($IV::LEN + 1), 'x' x $IV::LEN) {
  ok(
    dies {
      IV->new(value => $fail);
    },
  ) or note($EVAL_ERROR);
}

my $key;

ok(
  lives {
    $key = Key->new(value => Key->rand()->value);
  },
) or note($EVAL_ERROR);

for my $fail ('', 'a' x ($Key::LEN + 1), 'x' x $Key::LEN) {
  ok(
    dies {
      Key->new(value => $fail);
    },
  ) or note($EVAL_ERROR);
}

my $s = 'hello';
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

my $pw;

ok(
  lives {
    Password->new(value => Password->rand()->value);
    $pw = Password->from($s);
    Password->new(value => $pw->value);
  },
) or note($EVAL_ERROR);

ok($pw->test($s));

ok(
  dies {
    Password->new(value => $s);
  },
) or note($EVAL_ERROR);

done_testing;
