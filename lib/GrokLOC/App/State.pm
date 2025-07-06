package GrokLOC::App::State;
use v5.40;
use strictures 2;
use Object::Pad;

# ABSTRACT: JWT management.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class State {
  use Carp qw( croak );
  use Carp::Assert::More
    qw (assert_arrayref_nonempty assert_nonnegative_integer);
  use DBI ();

  #<<V
  field $api_version :param :reader;
  field $master_dsn :param ;
  field $master :reader ;
  field $replica_dsns :param ;
  field $replicas :reader ;
  # field $valkey_conn_dsn :param :reader;
  # field $signing_key :param :reader;
  # field $repository_base :param :reader;
  # field $version_key :param :reader;
  # field $default_role :param :reader;
  # field $root_org :param :reader;
  # field $root_user :param :reader;
  #>>V

  sub dsn_parts ($dsn) {
    my $ampersand_delim = qw{\@};
    my $colon_delim     = qw{\:};
    my $slash_delim     = qw{\/};
    my $postgres_prefix = 'postgres';
    my $dsn_re          = qr{^
      $postgres_prefix$colon_delim$slash_delim$slash_delim
      (?<username> [^$colon_delim]+)
      $colon_delim
      (?<password> [^$ampersand_delim]+)
      $ampersand_delim
      (?<hostname> [^$slash_delim]+)
      $colon_delim
      (?<port> \d{1,5})
      $slash_delim
      (?<database_name> \w+)
      $}x;
    if ($dsn =~ /$dsn_re/x) {
      return (
        ${^CAPTURE}{username}, ${^CAPTURE}{password},
        ${^CAPTURE}{hostname}, ${^CAPTURE}{port},
        ${^CAPTURE}{database_name}
      );
    }
    croak 'parse dsn';
  }

  sub dbh ($username, $password, $hostname, $port, $database_name) {
    my $data_source =
      "dbi:Pg:database=${database_name};host=${hostname};port=${port}";
    my $dbh = DBI->connect(
      $data_source,
      $username,
      $password,
      {
        RaiseError      => 1,
        AutoCommit      => 1,
        InactiveDestroy => 1,
      }
    ) || croak $DBI::errstr;
    return $dbh;
  }

  # `new` should be wrapped in `try/catch`.
  ADJUST {
    # Check fields in order above.

    # api_version
    assert_nonnegative_integer($api_version, 'api_version not nonnegative int');

    # master
    $master = dbh(dsn_parts($master_dsn));

    # replicas
    assert_arrayref_nonempty($replica_dsns,
      'replica_dsns not nonempty arrayref');
    $replicas = [];
    for my $replica_dsn (@{$replica_dsns}) {
      push(@{$replicas}, dbh(dsn_parts($replica_dsn)));
    }
  }

  method random_replica {
    return $replicas->[ int rand @{$replicas} ];
  }
}

__END__
