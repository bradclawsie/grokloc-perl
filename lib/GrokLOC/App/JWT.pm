package GrokLOC::App::JWT;
use v5.40;
use strictures 2;
use Object::Pad;

# ABSTRACT: JWT management.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class JWT {
  use Carp qw( croak );
  use Carp::Assert::More
    qw (assert assert_cmp assert_is assert_isa assert_like assert_positive_integer);
  use Crypt::JWT qw( decode_jwt encode_jwt );
  use Net::IP    qw( ip_is_ipv4 ip_is_ipv6 );
  use Readonly   ();
  use GrokLOC::Models;

  Readonly::Scalar our $TOKEN_TYPE => 'Bearer';

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
    assert_cmp($exp, '>=', $now, 'exp expired');
    assert_positive_integer($nbf, 'nbf not posint');
    assert_cmp($nbf, '<=', $now, 'nbf fail');
    assert_is($iss, 'GrokLOC.com', 'iss is not GrokLOC.com');
    assert_isa($sub, 'ID', 'sub is not type ID');
    assert_like($cip, qr/[.:]/x, 'cip not ip string');
    assert(ip_is_ipv4($cip) || ip_is_ipv6($cip), 'cip not ip');
  }

  sub decode ($self, $token, $signing_key) {
    my $token_fields = decode_jwt(token => $token, key => $signing_key);
    return $self->new(
      exp => $token_fields->{exp},
      nbf => $token_fields->{nbf},
      iss => $token_fields->{iss},
      sub => ID->new(value => $token_fields->{sub}),
      cip => $token_fields->{cip}
    );
  }

  method encode ($signing_key) {
    return encode_jwt(
      payload => {
        exp => $exp,
        nbf => $nbf,
        iss => $iss,
        sub => $sub->value,
        cip => $cip
      },
      alg => 'HS256',
      key => $signing_key
    );
  }

  sub from_header ($self, $header, $signing_key) {
    if ($header =~ /^$TOKEN_TYPE\s+(\S+)\s*$/x) {
      return $self->decode($1, $signing_key);
    }
    croak 'no header value found';
  }

  method to_header ($signing_key) {
    return $TOKEN_TYPE . q{ } . $self->encode($signing_key);
  }
}

__END__
