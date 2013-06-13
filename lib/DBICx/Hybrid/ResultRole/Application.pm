package DBICx::Hybrid::ResultRole::Application;

use strict;
use warnings;

use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';
use DateTime;

sub set_up {

	my $self = shift;

	my $source = $self->result_source_instance;

	$self->add_columns(

		"name", { data_type => "VARCHAR(200)", is_nullable => 0 },
		"admin_id", { data_type => "INTEGER", is_nullable => 0 },
		"expiry", { data_type => "DATETIME", is_nullable => 1 },
		"schema_class", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"db_name", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"revision", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"app_class", { data_type => "VARCHAR(200)", is_nullable => 1 },

	);

	$self->add_base_columns;

	$self->set_primary_key("id");

	$self->has_many(
		"users",
		"User",
		{"foreign.app_id" => "self.id" },
		{is_foreign_key_constraint => 0 }
	);

	## Force Array return
	$self->has_one(
		"admin",
		"User",
		{"foreign.id" => "self.admin_id" },
		{is_foreign_key_constraint => 0 }
	);

};

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-08-13 21:11:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:obZUGgvkve3e6mzPk8GEEg

around 'extra_columns' => sub {

	my $orig = shift;
	my $class = shift;

	my @columns = $class->$orig(@_);

	push @columns, (qw/ logo db_user db_pass host port driver description
						max_invoices max_depots max_users
						available_invoices available_depots available_users
						available_fax available_sms /);

	return @columns;

};

sub my_relations {

	my $self = shift;
	return qw/users/;

};

## override default is_valid function
sub is_valid {

	my $self = shift;

	my $now = DateTime->now()->ymd;

	#PENDING check if current date is less than that of expiry date

	return 1 if $self->id eq 1;

	return ( $self->active && $self->users->count <= $self->max_users );

}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
