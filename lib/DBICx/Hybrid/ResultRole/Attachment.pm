package DBICx::Hybrid::ResultRole::Attachment;

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
		"path", { data_type => "VARCHAR(200)", is_nullable => 0 },
		"content_type", { data_type => "VARCHAR(100)", is_nullable => 1 },
		"owner_id", { data_type => "INTEGER", is_nullable => 0 },
		"owner_class", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"owner_uuid", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"keywords", { data_type => "VARCHAR(200)", is_nullable => 1 },

	);

	$self->add_base_columns;

	$self->set_primary_key("id");

};

=pod
	CREATE TABLE attachment(
		owner_class 	VARCHAR(200) NOT NULL,
		owner_uuid 	VARCHAR(100) NOT NULL,
		name			VARCHAR(200) NOT NULL,
		path			VARCHAR(200) NOT NULL,
		owner_id		INTEGER NOT NULL,
		kewords 		VARCHAR(200) ,
		content_type	VARCHAR(100) ,
		id INTEGER 	PRIMARY KEY NOT NULL,
		_id 			VARCHAR(100) NOT NULL,
		created_on 	DATETIME NOT NULL,
		updated_on 	DATETIME NOT NULL,
		access_read 	TEXT NOT NULL,
		access_write 	TEXT NOT NULL,
		active 		INTEGER NOT NULL,
		status 		TEXT NOT NULL,
		data BLOB,
		log TEXT
	);
=cut

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-08-13 21:11:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:obZUGgvkve3e6mzPk8GEEg

around 'extra_columns' => sub {

	my $orig = shift;
	my $class = shift;

	my @columns = $class->$orig(@_);

	push @columns, qw/description/;
	return @columns;

};

sub my_relations {

	my $self = shift;
	return qw//;

};

# You can replace this text with custom content, and it will be preserved on regeneration
1;
