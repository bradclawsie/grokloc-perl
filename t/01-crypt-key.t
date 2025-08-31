package main;
use v5.42;
use strictures 2;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use GrokLOC::Crypt::Key;

# ABSTRACT: Test Crypt::Key.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';
my $key;

ok(
  lives {
    $key = Key->new(value => Key->rand()->value);
    is($key ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$key";
  },
) or note($EVAL_ERROR);

for my $fail ('', 'a' x ($Key::LEN + 1), 'x' x $Key::LEN) {
  ok(
    dies {
      Key->new(value => $fail);
    },
  ) or note($EVAL_ERROR);
}

done_testing;
