package TestDB;

use strict;
use warnings;

use Moose;
use namespace::clean -except => 'meta';
extends 'DBIx::Class::Schema';


__PACKAGE__->load_namespaces(
        result_namespace => 'Result',
        resultset_namespace => 'ResultSet',
        default_resultset_class => '+DBICx::Hybrid::ResultSet');

has "user" => (isa => "Int", is => "rw", default => 1);


sub init_schema {
  my $self = shift;

  my $dsn = 'dbi:SQLite:dbname=:memory:';
  my $schema = $self->connect($dsn);
  $schema->deploy;

  return $schema;

}

#__PACKAGE__->load_classes;

1;
