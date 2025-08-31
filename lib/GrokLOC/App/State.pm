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
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;
  use GrokLOC::Crypt::VersionKey;
  use GrokLOC::Models::Role;

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

  ADJUST {
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

  method TO_STRING {
    my $default_role_ = "$default_role";
    my $master_dsn_   = "$master_dsn";
    $master_dsn_ =~ s/\:(?:[^\@]+)\@/:****@/sgx;
    my $replica_dsns_ = join(', ', @{$replica_dsns});
    $replica_dsns_ =~ s/\:(?:[^\@]+)\@/:****@/sgx;
    my $version_key_ = "$version_key";
    return
        "State(api_version => $api_version, "
      . "default_role => $default_role_, "
      . "master_dsn => $master_dsn_, "
      . "replica_dsns => [$replica_dsns_], "
      . "repository_base => $repository_base, "
      . "signing_key => $signing_key, "
      . "valkey_dsn => $valkey_dsn, "
      . "version_key => $version_key_)";
  }

  method TO_BOOL {
    return
         defined($api_version)
      && defined($default_role)
      && defined($master_dsn)
      && defined($master)
      && defined($replica_dsns)
      && defined($replicas)
      && defined($repository_base)
      && defined($signing_key)
      && defined($valkey_dsn)
      && defined($version_key) ? true : false;
  }
}

__END__
