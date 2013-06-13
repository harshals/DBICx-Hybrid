package DBICx::Hybrid::ResultRole::Form;

use strict;
use warnings;

use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub set_up {

	my $self = shift;

	my $source = $self->result_source_instance;

	$self->load_components('InflateColumn::Serializer');

	$self->add_columns(
		"template_id", { data_type => "INTEGER", is_nullable => 0 },
		"form_data", { data_type => "TEXT", is_nullable => 1 , 'serializer_class'   => 'JSON'},
	);

	$self->add_base_columns;

	$self->set_primary_key("id");

}

# Created by DBIx::Class::DB::Schema::Loader v0.04006 @ 2009-08-13 21:11:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:obZUGgvkve3e6mzPk8GEEg

around 'extra_columns' => sub {

	my $orig = shift;
	my $class = shift;

	my @columns = $class->$orig(@_);

	return @columns;

};

sub my_relations {

	my $self = shift;
	return qw//;

};

# You can replace this text with custom content, and it will be preserved on regeneration
1;
