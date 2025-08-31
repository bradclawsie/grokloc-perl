package GrokLOC::App::JWT;
use v5.42;
use strictures 2;
use Data::Checks qw( Isa NumGT Str StrEq StrMatch );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method sub );

# ABSTRACT: JWT management.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class JWT {
  use Carp               qw( croak );
  use Carp::Assert::More qw ( assert assert_cmp );
  use Crypt::JWT         qw( decode_jwt encode_jwt );
  use Net::IP            qw( ip_is_ipv4 ip_is_ipv6 );
  use Readonly           ();
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;
  use GrokLOC::Models::ID;

  Readonly::Scalar our $TOKEN_TYPE => 'Bearer';

  field $exp :param : reader : Checked(NumGT(0));
  field $nbf :param : reader : Checked(NumGT(0));
  field $iss :param : reader : Checked(StrEq('GrokLOC.com'));
  field $sub :param : reader : Checked(Isa('ID'));
  field $cip :param : reader : Checked(StrMatch(qr/[.:]/x));

  ADJUST {
    my $now = time;
    assert_cmp($exp, '>=', $now, 'exp expired');
    assert_cmp($nbf, '<=', $now, 'nbf fail');
    assert(ip_is_ipv4($cip) || ip_is_ipv6($cip), 'cip not ip');
  }

  sub decode ($self,
              $token :Checked(Str),
              $signing_key :Checked(Str)) {
    my $token_fields = decode_jwt(token => $token, key => $signing_key);
    return $self->new(
      exp => $token_fields->{exp},
      nbf => $token_fields->{nbf},
      iss => $token_fields->{iss},
      sub => ID->new(value => $token_fields->{sub}),
      cip => $token_fields->{cip}
    );
  }

  method encode ($signing_key :Checked(Str)) {
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

  sub from_header ($self,
                   $header :Checked(Str),
                   $signing_key :Checked(Str)) {
    if ($header =~ /^$TOKEN_TYPE\s+(\S+)\s*$/x) {
      return $self->decode($1, $signing_key);
    }
    croak 'no header value found';
  }

  method to_header ($signing_key :Checked(Str)) {
    return $TOKEN_TYPE . q{ } . $self->encode($signing_key);
  }

  method TO_STRING {
    my $sub_ = "$sub";
    return "JWT(exp => $exp, nbf => $nbf, iss => $iss, "
      . "sub => $sub_, cip => $cip)";
  }

  method TO_BOOL {
    return
         defined($exp)
      && defined($nbf)
      && defined($iss)
      && defined($sub)
      && defined($cip) ? true : false;
  }
}

__END__
