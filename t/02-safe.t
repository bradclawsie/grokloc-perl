package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( dies done_testing is note ok );
use Test2::Tools::Exception qw( lives );
use UUID                    qw( uuid4 );
use strictures 2;
use GrokLOC::Safe;

# ABSTRACT: test Safe

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    VarChar->default;
    VarChar->rand;
    VarChar->new(value => uuid4);
    VarChar->new(value => '.' x $VarChar::STR_MAX);
    my $varchar = VarChar->trusted(uuid4);
    is($varchar ? true : false, true, 'boolean context');
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

  # Let through anything if tested => true.
  ok(
    lives {
      VarChar->new(value => $fail, trust => true);
      VarChar->trusted($fail);
    }
  ) or note($EVAL_ERROR);
}

done_testing;
