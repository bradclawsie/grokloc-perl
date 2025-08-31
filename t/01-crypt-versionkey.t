package main;
use v5.42;
use strictures 2;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use UUID                    qw( uuid4 );
use GrokLOC::Crypt::Key;
use GrokLOC::Crypt::VersionKey;

# ABSTRACT: Test Crypt::VersionKey.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  dies {
    VersionKey->new();
  },
) or note($EVAL_ERROR);

ok(
  dies {
    VersionKey->new(key_map => 1);
  },
) or note($EVAL_ERROR);

my $key     = Key->rand;
my $current = uuid4;
my %key_map = ($current => $key, uuid4() => Key->rand());

ok(
  dies {
    VersionKey->new(key_map => \%key_map);
  },
) or note($EVAL_ERROR);

my $version_key;

ok(
  lives {
    $version_key = VersionKey->new(key_map => \%key_map, current => $current);
    is($version_key ? true : false, true, 'boolean context');

    # TO_STRING
    my $quoted = "$version_key";
  },
) or note($EVAL_ERROR);

ok(
  dies {
    $version_key->get(uuid4());
  },
) or note($EVAL_ERROR);

my $get_key;

ok(
  lives {
    $get_key = $version_key->get($current);
    $version_key->current;
  },
) or note($EVAL_ERROR);

is($get_key->value, $key->value);

done_testing;
