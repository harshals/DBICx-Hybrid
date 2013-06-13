package DBICx::Hybrid::ResultRole::Task;

use strict;
use warnings;

use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub set_up {

	my $self = shift;

	my $source = $self->result_source_instance;

	$self->add_columns(

		"name", { data_type => "VARCHAR(200)", is_nullable => 0 },
		"assigned_by", { data_type => "INTEGER", is_nullable => 0 },
		"assigned_to", { data_type => "INTEGER", is_nullable => 0 },
		"place", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"due_date", { data_type => "DATETIME", is_nullable => 1 },
		"category", { data_type => "VARCAHR(200)", is_nullable => 1 },
		"task_status", { data_type => "VARCAHR(20)", is_nullable => 1 },
		"parent_id", { data_type => "INTEGER", is_nullable => 1 },

	);

	$self->add_base_columns;

	$self->set_primary_key("id");

	$self->belongs_to(
		"owner",
		"Schema::Result::Contact",
		{ "foreign.id" => "self.assigned_to" },
	);

	$self->belongs_to(
		"created_by",
		"Schema::Result::Contact",
		{ "foreign.id" => "self.assigned_by" },
	);

}

# Created by DBIx::Class::DB::Schema::Loader v0.04006 @ 2009-08-13 21:11:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:obZUGgvkve3e6mzPk8GEEg

around 'extra_columns' => sub {

	my $orig = shift;
	my $class = shift;

	my @columns = $class->$orig(@_);

	push @columns, qw/notes description attachment attachment_name tag_1 tag_2 tag_3 tag_4 tag_5 tag_6 tag_7 tag_8 tag_9 tag_10/;

	return @columns;

};

sub my_relations {

	my $self = shift;
	return qw/owner created_by/;

}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
