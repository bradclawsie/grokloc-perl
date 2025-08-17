package GrokLOC::App::State;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: state management.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class State {
  use Carp::Assert::More qw (assert assert_arrayref_nonempty assert_isa
    assert_nonblank assert_nonnegative_integer);
  use Mojo::Pg;
  use Mojo::Redis;
  use UUID qw( uuid4 );
  use GrokLOC::Crypt;
  use GrokLOC::Models;

  field $api_version :param : reader;
  field $default_role :param : reader;
  field $master_dsn :param;
  field $master :reader;
  field $replica_dsns :param;
  field $replicas :reader;
  field $repository_base :param : reader;
  field $signing_key :param : reader;
  field $valkey_dsn :param;
  field $valkey :reader;
  field $version_key :param : reader;

  # field $root_org :param :reader;
  # field $root_user :param :reader;

  # `new` should be wrapped in `try/catch`.
  ADJUST {
    # Check fields in order above.

    # api_version
    assert_nonnegative_integer($api_version, 'api_version not nonnegative int');

    # default_role
    assert_isa($default_role, 'Role', 'role not type Role');

    # master
    $master = Mojo::Pg->new($master_dsn);

    # replicas
    assert_arrayref_nonempty($replica_dsns,
      'replica_dsns not nonempty arrayref');
    $replicas = [];
    for my $replica_dsn (@{$replica_dsns}) {
      push(@{$replicas}, Mojo::Pg->new($replica_dsn));
    }

    # repository_base
    assert(-d $repository_base, 'repository_base is not a dir');

    # signing_key
    assert_nonblank($signing_key, 'signing_key malformed');

    # valkey
    assert_nonblank($valkey_dsn, 'valkey_dsn malformed');
    $valkey = Mojo::Redis->new($valkey_dsn);

    # version_key
    assert_isa($version_key, 'VersionKey',
      'version_key is not type VersionKey');
  }

  sub unit ($self) {
    return $self->new(
      api_version     => 1,
      default_role    => Role->new(value => $Role::TEST),
      master_dsn      => $ENV{POSTGRES_APP_URL},
      replica_dsns    => [ $ENV{POSTGRES_APP_URL} ],
      repository_base => $ENV{REPOSITORY_BASE},
      signing_key     => uuid4,
      valkey_dsn      => $ENV{REDIS_SERVER},
      version_key     => VersionKey->unit,
    );
  }

  method random_replica {
    return $replicas->[ int rand @{$replicas} ];
  }

}

__END__
