package main;
use v5.42;
use English                 qw(-no_match_vars);
use Test2::V0               qw( done_testing is note ok );
use Test2::Tools::Exception qw( lives );
use UUID                    qw( uuid4 );
use strictures 2;
use GrokLOC::App::Admin::User;
use GrokLOC::Models;
use GrokLOC::Safe;
use GrokLOC::App::State;

# ABSTRACT: test User

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    User->rand(ID->rand, uuid4);
  },
) or note($EVAL_ERROR);

my $st = State->unit;
my ($user, $read_user);

ok(
  lives {
    ($user, undef, undef) = User->rand(ID->rand, $st->version_key->current);
    $user->insert($st->master->db, $st->version_key);
    my $replica = $st->random_replica;
    $read_user = User->read($replica->db, $user->id, $st->version_key);
  },
) or note($EVAL_ERROR);

is($user->id,             $read_user->id,             'read id');
is($user->meta,           $read_user->meta,           'read meta');
is($user->api_key,        $read_user->api_key,        'read api_key');
is($user->api_key_digest, $read_user->api_key_digest, 'read api_key');
is($user->display_name,   $read_user->display_name,   'read display_name');
is(
  $user->display_name_digest,
  $read_user->display_name_digest,
  'read display_name'
);
is($user->email,        $read_user->email,        'read email');
is($user->email_digest, $read_user->email_digest, 'read email');
is($user->org,          $read_user->org,          'read org');
is($user->password,     $read_user->password,     'read password');

done_testing;
