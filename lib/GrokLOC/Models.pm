package GrokLOC::Models;
use v5.42;
use strictures 2;
use Object::Pad;

# ABSTRACT: Core types relevant to all model instances.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Role {
  use Carp::Assert::More qw( assert );
  use Readonly           ();
  use feature 'keyword_any';
  no warnings 'experimental::keyword_any';

  Readonly::Scalar our $NONE   => 0;
  Readonly::Scalar our $NORMAL => 1;
  Readonly::Scalar our $ADMIN  => 2;
  Readonly::Scalar our $TEST   => 3;

  field $value :param : reader;

  ADJUST {
    assert(any { $_ == $value } ($NORMAL, $ADMIN, $TEST), 'value');
  }

  method TO_JSON {
    return $value;
  }
}

class Status {
  use Carp::Assert::More qw( assert );
  use feature 'keyword_any';
  no warnings 'experimental::keyword_any';

  Readonly::Scalar our $NONE        => 0;
  Readonly::Scalar our $UNCONFIRMED => 1;
  Readonly::Scalar our $ACTIVE      => 2;
  Readonly::Scalar our $INACTIVE    => 3;

  field $value :param : reader;

  ADJUST {
    assert(any { $_ == $value } ($UNCONFIRMED, $ACTIVE, $INACTIVE), 'value');
  }

  method TO_JSON {
    return $value;
  }
}

class Meta {
  use Carp::Assert::More
    qw( assert assert_isa assert_nonnegative assert_numeric );
  use Crypt::Misc qw( is_v4uuid random_v4uuid );

  field $ctime :param : reader;
  field $mtime :param : reader;
  field $role :param : reader;
  field $schema_version :param : reader;
  field $signature :param : reader;
  field $status :param : reader;

  ADJUST {
    my $now = time;
    assert(int($ctime) == $ctime && $ctime >= 0 && $ctime <= $now, 'ctime');
    assert(
      int($mtime) == $mtime
        && $mtime >= 0
        && $mtime >= $ctime
        && $mtime <= $now,
      'mtime',
    );
    assert_isa($role, 'Role', 'role is not type Role');
    assert_numeric($schema_version, 'schema_version');
    assert_nonnegative($schema_version, 'schema_version');
    assert(is_v4uuid($signature), 'signature not uuidv4');
    assert_isa($status, 'Status', 'status not type Status');
  }

  method TO_JSON {
    return {
      ctime          => $ctime,
      mtime          => $mtime,
      role           => $role->TO_JSON,
      schema_version => $schema_version,
      signature      => $signature,
      status         => $status->TO_JSON,
    };
  }
}

class ID {
  use Carp::Assert::More qw( assert );
  use Crypt::Misc        qw( is_v4uuid random_v4uuid );

  field $value :param : reader;

  sub rand ($self) {
    return $self->new(value => random_v4uuid());
  }

  ADJUST {
    assert(is_v4uuid($value), 'value not uuidv4');
  }

  method TO_JSON {
    return $value;
  }
}

__END__
