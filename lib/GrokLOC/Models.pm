package GrokLOC::Models;
use v5.42;
use strictures 2;
use Data::Checks qw( Isa Maybe Num NumGE NumRange Str );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method sub );

# ABSTRACT: Core types relevant to all model instances.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Role {
  use Carp::Assert::More qw( assert );
  use Readonly           ();
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $NONE   => 0;
  Readonly::Scalar our $NORMAL => 1;
  Readonly::Scalar our $ADMIN  => 2;
  Readonly::Scalar our $TEST   => 3;

  field $value :param : reader : Checked(NumRange(1,4));

  sub default ($self) {
    return $self->new(value => $NORMAL);
  }

  sub normal ($self) {
    return $self->new(value => $NORMAL);
  }

  sub admin ($self) {
    return $self->new(value => $ADMIN);
  }

  sub test ($self) {
    return $self->new(value => $TEST);
  }

  method TO_STRING {
    return "Role(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {
    return $value;
  }
}

class Status {
  use Carp::Assert::More qw( assert );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $NONE        => 0;
  Readonly::Scalar our $UNCONFIRMED => 1;
  Readonly::Scalar our $ACTIVE      => 2;
  Readonly::Scalar our $INACTIVE    => 3;

  field $value :param : reader : Checked(NumRange(1,4));

  sub default ($self) {
    return $self->new(value => $UNCONFIRMED);
  }

  sub unconfirmed ($self) {
    return $self->new(value => $UNCONFIRMED);
  }

  sub active ($self) {
    return $self->new(value => $ACTIVE);
  }

  sub inactive ($self) {
    return $self->new(value => $INACTIVE);
  }

  method TO_STRING {
    return "Status(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {
    return $value;
  }
}

class ID {
  use Carp::Assert::More qw( assert );
  use Readonly           ();
  use UUID               qw( clear is_null parse unparse uuid4 version );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $NIL => '00000000-0000-0000-0000-000000000000';

  field $value :param : reader : Checked(Str);

  ADJUST {
    my $bin = 0;
    assert(parse($value, $bin) == 0 && (version($bin) == 4
        || is_null($bin)),
      'value not uuidv4');
  }

  sub default ($self) {
    return $self->new(value => $NIL);
  }

  sub rand ($self) {
    return $self->new(value => uuid4);
  }

  method TO_STRING {
    return "ID(value => $value)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {
    return $value;
  }
}

role WithID {
  use Carp::Assert::More qw( assert_defined assert_isa assert_isnt );

  field $id :param : reader : Checked(Isa('ID'));

  method set_id ($id_ :Checked(Isa('ID'))) {

    # Setting to $ID::NIL after construction is forbidden.
    assert_isnt($id_->value, $ID::NIL, 'id value is ID::NIL');
    $id = $id_;
    return $self;
  }
}

class Meta {
  use Carp::Assert::More qw( assert assert_defined assert_hashref assert_isa );
  use UUID               qw( clear is_null parse unparse uuid4 version );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  field $ctime :param : reader : Checked(Num);
  field $mtime :param : reader : Checked(Num);
  field $role :param : reader : Checked(Isa('Role'));
  field $schema_version :param : reader : Checked(NumGE(0));
  field $signature :param : reader : Checked(Maybe(Str));
  field $status :param : reader : Checked(Isa('Status'));

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
    if (defined $signature) {
      my $bin = 0;
      assert(parse($signature, $bin) == 0 && version($bin) == 4,
        'signature not uuidv4');
    }
  }

  sub default ($self) {
    my ($bin, $str);
    clear($bin);
    unparse($bin, $str);
    return $self->new(
      ctime          => 0,
      mtime          => 0,
      role           => Role->default,
      schema_version => 0,
      signature      => undef,
      status         => Status->default,
    );

    sub from_hashref ($self, $hashref) {
      assert_hashref($hashref, 'not hashref');

      for my $col (qw(ctime mtime role schema_version signature status)) {
        assert_defined($hashref->{$col}, "$col not defined");
      }

      return $self->new(
        ctime          => $hashref->{ctime},
        mtime          => $hashref->{mtime},
        role           => Role->new(value => $hashref->{role}),
        schema_version => $hashref->{schema_version},
        signature      => $hashref->{signature},
        status         => Status->new(value => $hashref->{status})
      );
    }
  }

  method set_role ($role_) {
    assert_isa($role_, 'Role', 'role is not type Role');
    $role = $role_;
    return $self;
  }

  method set_status ($status_) {
    assert_isa($status_, 'Status', 'status is not type Status');
    $status = $status_;
    return $self;
  }

  method set_signature ($signature_ :Checked(Str)) {
    my $bin = 0;
    assert(parse($signature_, $bin) == 0 && version($bin) == 4,
      'signature not uuidv4');
    $signature = $signature_;
    return $self;
  }

  method TO_STRING {
    my $role_      = "$role";
    my $status_    = "$status";
    my $signature_ = (defined $signature) ? $signature : 'UNDEF';
    return
        "Meta(ctime => $ctime, mtime => $mtime, role => $role_, "
      . "schema_version => $schema_version, signature => $signature_, "
      . "status => $status_)";
  }

  method TO_BOOL {
    return
         defined($ctime)
      && defined($mtime)
      && defined($role)
      && defined($schema_version)
      && defined($signature)
      && defined($status) ? true : false;
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

role WithMeta {
  use Carp::Assert::More qw( assert_defined assert_isa );

  field $meta :param : reader;

  ADJUST {
    assert_defined($meta, 'meta not defined on object');
    assert_isa($meta, 'Meta', 'type of meta is not Meta');
  }

  method set_meta ($meta_) {
    assert_isa($meta_, 'Meta', 'type of meta_ is not Meta');
    $meta = $meta_;
    return $self;
  }
}

__END__
