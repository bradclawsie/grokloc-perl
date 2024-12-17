package GrokLOC::Models;
use v5.40;
use strictures 2;
use Object::Pad;
use Readonly ();

# ABSTRACT: Core types relevant to all model instances.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Role {
  Readonly::Scalar our $none   => 0;
  Readonly::Scalar our $normal => 1;
  Readonly::Scalar our $admin  => 2;
  Readonly::Scalar our $test   => 3;

  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    use Carp           qw( croak );
    use List::AllUtils qw( any );
    croak 'value'
      unless any { $_ == $value } ($normal, $admin, $test);
  }

  method TO_JSON {
    return $value;
  }
}

class Status {
  Readonly::Scalar our $none        => 0;
  Readonly::Scalar our $unconfirmed => 1;
  Readonly::Scalar our $active      => 2;
  Readonly::Scalar our $inactive    => 3;

  #<<V
  field $value :param :reader;
  #>>V

  ADJUST {
    use Carp           qw( croak );
    use List::AllUtils qw( any );
    croak 'value'
      unless any { $_ == $value } ($unconfirmed, $active, $inactive);
  }

  method TO_JSON {
    return $value;
  }
}

class Meta {
  #<<V
  field $ctime :param :reader;
  field $mtime :param :reader;
  field $role :param :reader;
  field $schema_version :param :reader;
  field $signature :param :reader;
  field $status :param :reader;
  #>>V

  ADJUST {
    use Carp        qw( croak );
    use Crypt::Misc qw( is_v4uuid );
    my $now = time;
    croak 'ctime' unless int($ctime) == $ctime && 0 <= $ctime <= $now;
    croak 'mtime' unless int($mtime) == $mtime && 0 <= $mtime <= $now;
    croak 'role'  unless $role isa Role;
    croak 'schema_version'
      unless int($schema_version) == $schema_version
      && $schema_version >= 0;
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
      status         => $status->TO_JSON
    };
  }
}

class Base {
  #<<V
  field $id :param :reader;
  field $meta :param :reader;
  #>>V

  ADJUST {
    use Carp        qw( croak );
    use Crypt::Misc qw( is_v4uuid );
    croak 'id'   unless is_v4uuid($id);
    croak 'meta' unless $meta isa Meta;
  }

  method TO_JSON {
    return {
      id   => $id,
      meta => $meta->TO_JSON
    };
  }
}

__END__
