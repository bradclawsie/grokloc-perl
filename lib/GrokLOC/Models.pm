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

  sub default ($self) {
    return $self->new(value => $NORMAL);
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

  sub default ($self) {
    return $self->new(value => $UNCONFIRMED);
  }

  method TO_JSON {
    return $value;
  }
}

class Meta {
  use Carp::Assert::More
    qw( assert assert_isa assert_nonnegative assert_numeric );
  use UUID qw( clear is_null parse unparse uuid4 version );

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
    my $bin = 0;
    assert(parse($signature, $bin) == 0
        && (version($bin) == 4 || is_null($bin)),
      'signature not uuidv4');
    assert_isa($status, 'Status', 'status not type Status');
  }

  sub default ($self) {
    my ($bin, $str);
    clear($bin);    # null uuid
    unparse($bin, $str);
    return $self->new(
      ctime          => 0,
      mtime          => 0,
      role           => Role->default,
      schema_version => 0,
      signature      => $str,
      status         => Status->default,
    );
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
  use Readonly           ();
  use UUID               qw( clear is_null parse unparse uuid4 version );

  Readonly::Scalar our $NIL => '00000000-0000-0000-0000-000000000000';

  field $value :param : reader;

  sub rand ($self) {
    return $self->new(value => uuid4);
  }

  ADJUST {
    my $bin = 0;
    assert(parse($value, $bin) == 0 && version($bin) == 4, 'value not uuidv4');
    assert(!is_null($bin), 'value is nil uuidv4');
  }

  method TO_JSON {
    return $value;
  }
}

__END__
