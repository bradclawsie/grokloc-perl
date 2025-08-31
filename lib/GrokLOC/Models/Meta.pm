package GrokLOC::Models::Meta;
use v5.42;
use strictures 2;
use Data::Checks qw( Isa Maybe Num NumGE Str );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method sub );
use GrokLOC::Models::Role;
use GrokLOC::Models::Status;

# ABSTRACT: Models Meta.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Meta {
  use Carp::Assert::More qw( assert );
  use UUID               qw( parse version );
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
    return $self->new(
      ctime          => 0,
      mtime          => 0,
      role           => Role->default,
      schema_version => 0,
      signature      => undef,             # Must come from db.
      status         => Status->default,
    );
  }

  method set_role ($role_ :Checked(Isa('Role'))) {
    $role = $role_;
    return $self;
  }

  method set_status ($status_ :Checked(Isa('Status'))) {
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
  field $meta :param : reader : Checked(Isa('Meta'));

  method set_meta ($meta_ :Checked(Isa('Meta'))) {
    $meta = $meta_;
    return $self;
  }
}

__END__
