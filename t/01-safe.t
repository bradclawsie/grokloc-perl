package main;
use v5.40;
use Crypt::Misc             qw( random_v4uuid );
use English                 qw(-no_match_vars);
use Test2::V0               qw( dies done_testing note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Safe;

# ABSTRACT: test Models

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    VarChar->new(value => random_v4uuid);
    VarChar->new(value => '.' x $VarChar::STR_MAX);
  },
) or note($EVAL_ERROR);

for my $fail ('', '.' x ($VarChar::STR_MAX + 1),
  '""', "''", '``', 'drop table', 'create index', 'insert ', 'update ', '&gt;',
  '&lt;', 'window.')
{
  ok(
    dies {
      VarChar->new(value => $fail);
    },
  ) or note($EVAL_ERROR);
}

done_testing;
