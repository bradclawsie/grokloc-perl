package GrokLOC::Crypt::AESGCM;
use v5.42;
use strictures 2;
use Data::Checks qw( Str StrMatch );
use Object::Pad;
use Signature::Attribute::Checked;
use Sublike::Extended qw( sub );

# ABSTRACT: Cryptographic Symmetric Encryption.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class AESGCM {
  use Carp::Assert::More  qw( assert_is );
  use Crypt::AuthEnc::GCM ();
  use Readonly            ();

  Readonly::Scalar our $TAG_LEN => 32;

  sub encrypt ($self,
               $pt :Checked(Str),
               $key :Checked(StrMatch(qr/^[\da-f]{32}$/x)),
               $iv :Checked(StrMatch(qr/^[\da-f]{16}$/x))) {

    my $ae  = Crypt::AuthEnc::GCM->new('AES', $key, $iv);
    my $ct  = unpack('H*', $ae->encrypt_add($pt));
    my $tag = unpack('H*', $ae->encrypt_done());
    return $iv . $tag . $ct;    # This is $e in decrypt.
  }

  sub decrypt ($self,
               $e :Checked(Str),
               $key :Checked(StrMatch(qr/^[\da-f]{32}$/x))) {

    my $iv      = substr $e, 0, $IV::LEN;
    my $tag     = substr $e, $IV::LEN, $TAG_LEN;
    my $ct      = substr $e, $IV::LEN + $TAG_LEN;
    my $ae      = Crypt::AuthEnc::GCM->new('AES', $key, $iv);
    my $pt      = $ae->decrypt_add(pack('H*', $ct));
    my $tag_out = $ae->decrypt_done();
    assert_is(unpack('H*', $tag_out), $tag, 'tag mismatch');
    return $pt;
  }
}

__END__
