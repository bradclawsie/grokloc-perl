package GrokLOC::Models;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Core types relevant to all model instances.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Role {
  use Carp           qw( croak );
  use List::AllUtils qw( any );
  Readonly::Scalar our $NONE   => 0;
  Readonly::Scalar our $NORMAL => 1;
  Readonly::Scalar our $ADMIN  => 2;
  Readonly::Scalar our $TEST   => 3;

  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    croak 'value'
      unless any { $_ == $value } ($NORMAL, $ADMIN, $TEST);
  }

  method TO_JSON {
    return $value;
  }
}

class Status {
  use Carp           qw( croak );
  use List::AllUtils qw( any );
  Readonly::Scalar our $NONE        => 0;
  Readonly::Scalar our $UNCONFIRMED => 1;
  Readonly::Scalar our $ACTIVE      => 2;
  Readonly::Scalar our $INACTIVE    => 3;

  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    croak 'value'
      unless any { $_ == $value } ($UNCONFIRMED, $ACTIVE, $INACTIVE);
  }

  method TO_JSON {
    return $value;
  }
}

class Meta {
  use Carp        qw( croak );
  use Crypt::Misc qw( is_v4uuid );
  #<<V
  field $ctime :param :reader;
  field $mtime :param :reader;
  field $role :param :reader;
  field $schema_version :param :reader;
  field $signature :param :reader;
  field $status :param :reader;
  #>>V

  ADJUST {
    my $now = time;
    croak 'ctime' if int($ctime) != $ctime || $ctime < 0 || $ctime > $now;
    croak 'mtime' if int($mtime) != $mtime || $mtime < 0 || $mtime > $now;
    croak 'role' unless $role isa Role;
    croak 'schema_version'
      if int($schema_version) != $schema_version || $schema_version < 0;
    croak 'signature' unless is_v4uuid($signature);
    croak 'status'    unless $status isa Status;
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

class Base {
  use Carp        qw( croak );
  use Crypt::Misc qw( is_v4uuid );
  #<<V
  field $id :param :reader;
  field $meta :param :reader;
  #>>V

  ADJUST {
    croak 'id'   unless is_v4uuid($id);
    croak 'meta' unless $meta isa Meta;
  }

  method TO_JSON {
    return {
      id   => $id,
      meta => $meta->TO_JSON,
    };
  }
}

__END__
