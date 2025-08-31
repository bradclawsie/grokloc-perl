package main;
use v5.42;
use Cpanel::JSON::XS        ();
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use UUID                    qw( uuid4 );
use strictures 2;
use GrokLOC::Models::ID;

# ABSTRACT: Test ID.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

is(ID->default->value, undef, 'ID default');

ok(
  lives {
    ID->rand();
    my $id = ID->new(value => uuid4());
    is($id ? true : false, true, 'boolean context');
    $id = ID->rand;
    is($id ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$id";
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $id = ID->default;
    is($id ? true : false, false, 'boolean context');

    # TO_STRING
    my $quoted = "$id";

  },
) or note($EVAL_ERROR);

ok(
  dies {
    ID->new(value => '');
  },
) or note($EVAL_ERROR);

ok(
  lives {
    my $json =
      Cpanel::JSON::XS->new->convert_blessed([true])->allow_nonref([true]);
    ID->new(value => $json->decode($json->encode(ID->new(value => uuid4()))));
  },
) or note($EVAL_ERROR);

# WithID.
use Object::Pad;

class WithIDTest :does(WithID) { }

ok(
  lives {
    WithIDTest->new(id => ID->rand)->set_id(ID->rand);
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithIDTest->new(id => 'not an ID');
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithIDTest->new(id => ID->rand)->set_id('not an ID');
  }
) or note($EVAL_ERROR);

ok(
  dies {
    WithIDTest->new(id => ID->rand)->set_id(ID->default);
  }
) or note($EVAL_ERROR);

done_testing;
