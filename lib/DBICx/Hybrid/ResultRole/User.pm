package DBICx::Hybrid::ResultRole::User;

use strict;
use warnings;

use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub set_up {

	my $self = shift;

	my $source = $self->result_source_instance;

	$self->add_columns(

		"username", { data_type => "VARCHAR(200)", is_nullable => 0 },
		"password", { data_type => "VARCHAR(200)", is_nullable => 0 },
		"contact_id", { data_type => "INTEGER", is_nullable => 1 },
		"profile_id", { data_type => "INTEGER", is_nullable => 1 },
		"application_id", { data_type => "INTEGER", is_nullable => 1 },
		"read_parents" , { data_type => "TEXT" , is_csv => 1 , is_nullable => 1},
		"write_parents" , { data_type => "TEXT" , is_csv => 1 , is_nullable => 1},
		"role", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"office_role", { data_type => "VARCHAR(200)", is_nullable => 1 },
		"name", { data_type => "VARCHAR(200)", is_nullable => 1 },

	);

	$self->add_base_columns;

	$self->set_primary_key("id");

	$self->add_unique_constraint("username_unique", ["username", "app_id"]);

	$self->belongs_to(
		"application",
		"Application",
		{"foreign.id" => "self.app_id" },
		{is_foreign_key_constraint => 0 }
	);

	$self->belongs_to(
		"contact",
		"Contact",
		{"foreign.id" => "self.contact_id" },
		{join_type => 'left' },
		{is_foreign_key_constraint => 0 },
	);

}

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-08-13 21:11:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IEbbWr9Imbum+8sUaLrAAg

around 'extra_columns' => sub {

	my $orig = shift;
	my $class = shift;

	my @columns = $class->$orig(@_);

	push @columns, qw/tel_no email profile_image description /;

	return @columns;

};

sub my_relations {

	my $self = shift;
	return qw/contact application/;

};

around 'save' => sub {

	my $orig = shift;
	my $self = shift;
	my $data = shift;

	my $first_time = !$data->{'id'};

	my $user_id = $self->result_source->schema->user;

	$self->$orig($data, @_);

	my $parent = $self->result_source->resultset->is_valid->find($user_id);

	if ($first_time) {

		$self->grant_access("write", $self->id);
		$self->grant_access("read", $self->id);

		## this should come as a config option from schema itself
		# wether to include ancestory or not
		# if $schema->inherit_user_permissions ?

		$self->add_parent( "all", $parent->id );

		#$self->add_parent( "all", $parent_id ) foreach my $parent_id ( $parent->read_parents );

	}

	$self->update;

};

sub remove_parent{

	my ($self, $permission, $ancestor) = @_;

	$permission ||= "read";

	croak ("need to the ancestor's id") unless $ancestor;
	croak ("No such column exists access_$permission") unless $self->has_column("${permission}_parents");

	## verify if the user exists and is active

	$self->remove_from_csv("${permission}_parents", $ancestor);

}

sub add_parent{

	my ($self, $permission, $ancestor) = @_ ;

	$permission ||= "read";

	my @permissions = ( $permission eq 'all') ? ('read','write') : ( $permission );

	croak ("need to the ancestor's id") unless $ancestor;

	## verify if the user exists and is active
	foreach my $p ( @permissions ) {
		$self->add_to_csv("${p}_parents", $ancestor) 
	}

}

sub ancestors {

	my ($self, $permission ) = @_;

	$permission ||= "read";

	my $rs = $self->result_source->resultset->is_valid->search_rs( id => { -in => [ $self->get_column("${permission}_parents")  ] } );

}

sub ancestors_emails {

	my $self = shift;

	my $ancestors = $self->ancestors->serialize;

	my $emails;

	foreach my $parent (@$ancestors) {
		push @$emails , $parent->{email};
	}

	return $emails;

}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
