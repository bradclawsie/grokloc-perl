package GrokLOC::App::Admin::User;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: User model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class User {
  use Carp::Assert::More qw( assert_isa );
  use GrokLOC::Models;
  use GrokLOC::Safe;
  use UUID qw( is_null parse version );

  field $id :param : reader;
  field $meta :param : reader;
  field $api_key :param : reader;
  field $api_key_digest :param : reader;
  field $display_name :param : reader;
  field $display_name_digest :param : reader;
  field $email :param : reader;
  field $email_digest :param : reader;
  field $org :param : reader;
  field $password :param : reader;
  field $key_version :param : reader;

  ADJUST {
    assert_isa($id,           'ID',      'id is not type ID');
    assert_isa($meta,         'Meta',    'meta is not type Meta');
    assert_isa($api_key,      'VarChar', 'api_key is not VarChar');
    assert_isa($display_name, 'VarChar', 'display_name is not VarChar');
    assert_isa($email,        'VarChar', 'email is not VarChar');
    assert_isa($org,          'ID',      'org is not type ID');
    my $bin = 0;
    assert(parse($key_version, $bin) == 0
        && (version($bin) == 4 || is_null($bin)),
      'key_version not uuidv4');
  }

  # Omitted fields not intended for distribution.
  method TO_JSON {
    return {
      id                  => $id->TO_JSON,
      meta                => $meta->TO_JSON,
      api_key             => $api_key->TO_JSON,
      api_key_digest      => $api_key_digest,
      display_name        => $display_name->TO_JSON,
      display_name_digest => $display_name_digest,
      email               => $email->TO_JSON,
      email_digest        => $email_digest,
      org                 => $org->TO_JSON,
    };
  }
}

__END__
