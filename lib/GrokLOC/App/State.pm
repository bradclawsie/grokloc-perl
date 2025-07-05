package GrokLOC::App::State;
use v5.40;
use strictures 2;
use Object::Pad;

# ABSTRACT: JWT management.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class State {
  use Carp               qw( croak );
  use Carp::Assert::More qw (assert_nonnegative_integer);

  #<<V
  field $api_version :param :reader;
  field $master :param :reader;
  field $replicas :param :reader;
  field $valkey_conn_dsn :param :reader;
  field $signing_key :param :reader;
  field $repository_base :param :reader;
  field $version_key :param :reader;
  field $default_role :param :reader;
  field $root_org :param :reader;
  field $root_user :param :reader;
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

  ADJUST {
    assert_nonnegative_integer($api_version, 'api_version not nonnegative int');
  }
}

__END__
