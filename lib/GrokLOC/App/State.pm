package GrokLOC::App::State;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: state management.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class State {
  use Carp::Assert::More
    qw (assert_arrayref_nonempty assert_nonblank assert_nonnegative_integer);
  use Mojo::Pg;
  use Mojo::Redis;

  field $api_version :param : reader;
  field $master_dsn :param;
  field $master :reader;
  field $replica_dsns :param;
  field $replicas :reader;
  field $valkey_dsn :param;
  field $valkey :reader;

  # field $signing_key :param :reader;
  # field $repository_base :param :reader;
  # field $version_key :param :reader;
  # field $default_role :param :reader;
  # field $root_org :param :reader;
  # field $root_user :param :reader;

  # `new` should be wrapped in `try/catch`.
  ADJUST {
    # Check fields in order above.

    # api_version
    assert_nonnegative_integer($api_version, 'api_version not nonnegative int');

    # master
    $master = Mojo::Pg->new($master_dsn);

    # replicas
    assert_arrayref_nonempty($replica_dsns,
      'replica_dsns not nonempty arrayref');
    $replicas = [];
    for my $replica_dsn (@{$replica_dsns}) {
      push(@{$replicas}, Mojo::Pg->new($replica_dsn));
    }

    # valkey
    assert_nonblank($valkey_dsn, 'valkey_dsn malformed');
    $valkey = Mojo::Redis->new($valkey_dsn);
  }

  method random_replica {
    return $replicas->[ int rand @{$replicas} ];
  }

  sub unit ($self) {
    return $self->new(
      api_version  => 1,
      master_dsn   => $ENV{POSTGRES_APP_URL},
      replica_dsns => [ $ENV{POSTGRES_APP_URL} ],
      valkey_dsn   => $ENV{REDIS_SERVER},
    );
  }
}

__END__
