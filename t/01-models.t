package main;
use v5.40;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use lib '../lib';
use GrokLOC::Models;

# ABSTRACT: test Models

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    Role->new(value => $Role::normal);
    Role->new(value => $Role::admin);
    Role->new(value => $Role::test);
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Role->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Role->new(value => $Role::none);
  },
) or note($EVAL_ERROR);

my $role;

ok(
  lives {
    $role = Role->new(value => $Role::normal);
  },
) or note($EVAL_ERROR);

my $json = Cpanel::JSON::XS->new->convert_blessed([true]);
is($Role::normal, $json->encode($role));

ok(
  lives {
    Status->new(value => $Status::unconfirmed);
    Status->new(value => $Status::active);
    Status->new(value => $Status::inactive);
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Status->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Status->new(value => $Status::none);
  },
) or note($EVAL_ERROR);

my $status;

ok(
  lives {
    $status = Status->new(value => $Status::active);
  },
) or note($EVAL_ERROR);

is($Status::active, $json->encode($status));

done_testing;
