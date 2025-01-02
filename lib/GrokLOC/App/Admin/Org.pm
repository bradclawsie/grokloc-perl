package GrokLOC::App::Admin::Org;
use v5.40;
use strictures 2;
use Object::Pad;
use lib '../../../lib';
use GrokLOC::Models;

# ABSTRACT: Organization model support.

our $VERSION   = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

class Org :isa(Base) { }

__END__
