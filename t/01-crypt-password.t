package main;
use v5.42;
use strictures 2;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use GrokLOC::Crypt::Password;

# ABSTRACT: Test Crypt::IV.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $pw;
my $s = 'my-password';

ok(
  lives {
    Password->new(value => Password->rand()->value);
    $pw = Password->from($s);
    is($pw ? true : false, true, 'boolean context');
    Password->new(value => $pw->value);

    # TO_STRING
    my $quoted = "$pw";
  },
) or note($EVAL_ERROR);

ok($pw->test($s));

ok(
  dies {
    Password->new(value => $s);
  },
) or note($EVAL_ERROR);

done_testing;
