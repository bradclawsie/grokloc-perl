package GrokLOC::App::JWT;
use v5.40;
use strictures 2;
use Object::Pad;

# ABSTRACT: JWT management.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class JWT {
  use Carp::Assert::More
    qw (assert assert_cmp assert_is assert_positive_integer);
  use Net::IP qw( ip_is_ipv4 ip_is_ipv6 );
  use lib '../../../lib';
  use GrokLOC::Models;

  #<<V
  field $exp :param :reader;
  field $nbf :param :reader;
  field $iss :param :reader;
  field $sub :param :reader;
  field $cip :param :reader;
  #>>V

  ADJUST {
    my $now = time;
    assert_positive_integer($exp, 'exp not posint');
    assert_cmp($exp, '>', $now, 'exp expired');
    assert_positive_integer($nbf, 'nbf not posint');
    assert_cmp($nbf, '<', $now, 'nbf fail');
    assert_is($iss, 'GrokLOC.com', 'iss is not GrokLOC.com');
    assert_isa($sub, 'ID', 'sub is not type ID');
    assert(ip_is_ipv4($cip) || ip_is_ipv6($cip), 'cip not ip');
  }
}

__END__
