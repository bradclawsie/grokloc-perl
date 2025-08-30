package GrokLOC::Models::ID;
use v5.42;
use strictures 2;
use Data::Checks qw( Isa Maybe Str );
use Object::Pad;
use Object::Pad::FieldAttr::Checked;
use Signature::Attribute::Checked;
use Sublike::Extended qw( method sub );

# ABSTRACT: Models ID.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class ID {
  use Carp::Assert::More qw( assert );
  use Readonly           ();
  use UUID               qw( parse uuid4 version );
  use overload '""' => \&TO_STRING, 'bool' => \&TO_BOOL, fallback => 0;

  Readonly::Scalar our $NIL => '00000000-0000-0000-0000-000000000000';

  field $value :param : reader : Checked(Maybe(Str)) = undef;

  ADJUST {
    if (defined $value) {
      my $bin = 0;
      assert(parse($value, $bin) == 0 && version($bin) == 4,
        'value not uuidv4');
    }
  }

  sub default ($self) {
    return $self->new();
  }

  sub rand ($self) {
    return $self->new(value => uuid4);
  }

  method TO_STRING {
    my $value_ = (defined $value) ? $value : 'UNDEF';
    return "ID(value => $value_)";
  }

  method TO_BOOL {
    return defined($value) ? true : false;
  }

  method TO_JSON {
    return $value;
  }
}

role WithID {
  use Carp::Assert::More qw( assert_defined );

  field $id :param : reader : Checked(Isa('ID'));

  method set_id ($id_ :Checked(Isa('ID'))) {
    assert_defined($id_->value, 'is value is undefined');
    $id = $id_;
    return $self;
  }
}

__END__
