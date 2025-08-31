package main;
use v5.42;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC::Models::Role;

# ABSTRACT: Test Roles.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# Role.
is(Role->default->value, $Role::NORMAL, 'default role');

ok(
  lives {
    Role->normal;
    Role->admin;
    Role->test;
  },
) or note($EVAL_ERROR);

ok(Role->normal->value < Role->admin->value < Role->test->value);

ok(
  dies {
    Role->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Role->new(value => $Role::NONE);
  },
) or note($EVAL_ERROR);

my $role;

ok(
  lives {
    $role = Role->normal;
    is($role ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$role";
  },
) or note($EVAL_ERROR);

ok($role isa Role);
my $json = Cpanel::JSON::XS->new->convert_blessed([true]);
is($Role::NORMAL, $json->encode($role));

is($Role::NORMAL, Role->default()->value);

done_testing;
