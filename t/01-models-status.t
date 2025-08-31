package main;
use v5.42;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC::Models::Status;

# ABSTRACT: Test Status.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

is(Status->default->value, $Status::UNCONFIRMED, 'status default');

ok(
  lives {
    Status->unconfirmed;
    Status->active;
    Status->inactive;
  },
) or note($EVAL_ERROR);

ok(
  Status->unconfirmed->value < Status->active->value < Status->inactive->value);

ok(
  dies {
    Status->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    Status->new(value => $Status::NONE);
  },
) or note($EVAL_ERROR);

my $status;

ok(
  lives {
    $status = Status->active;
    is($status ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$status";
  },
) or note($EVAL_ERROR);

ok($status isa Status);

my $json = Cpanel::JSON::XS->new->convert_blessed([true]);
is($Status::ACTIVE, $json->encode($status));

is($Status::UNCONFIRMED, Status->default()->value);

done_testing;
