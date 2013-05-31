package DBICx::Hybrid::Result;

use strict;
use warnings;
use Moose;
use namespace::clean -except => 'meta';
use Carp qw/croak confess/;

use JSON::XS qw/encode_json /;
#use base qw/DBIx::Class/;
extends qw/DBIx::Class/;

# ABSTRACT: Result/Row Class
=head1 NAME

DBICx::Hybrid::Result

Some common routines i generally use combined in form of ResultSet, ResultClass and Result Classes.

=head1 DESCRIPTION


Just a simple hack to store comma sperated values inside a table column.
Module exports simple functions to search, add and delete values from a
comma sperated list inside a column.

Internally it stores the values in ,el1,el2,el3, format to make it searchable
via 'LIKE' .

=head1 METHODS

=head2 add_base_columns

USAGE: __PACKAGE__-->add_base_columns

adds fixed set of columns for metadata operations. Assumes the schema will use
id as primary key and _id as UUID column

defines created_on and updated_on for basic timestamps.

access_read and access_write for row-wise permissions.

data to store storable blob and (active, status) as status indicators.

=head2 has_access

$row->has_access("read", $user_id) ;

performs simple check if give user id has "read" permission on this row object or not.

returns boolean value.

=head2 grant_access, remove_access

similar to has_access, but does the actual adding and removal part of the operation.

=head2 has_status

$row->has_status("delete") ; 

simply checks if current row has defined status or not

As of now , only three status are defined: active,delete and dirty

returns boolean value

=head2 remove_status, set_status


=cut

=head2 active and status fields

active is a boolean flag to say if record can be searched or not

status is user defined field, where a user can have comma separted list of status.

DBIC::Hybrid provides 3 basic status which the object moves through -

(0) new ----> (1) active -----> (2) deleted 
					^					|
					|-------------------v

=cut



__PACKAGE__->load_components(qw/FrozenColumns UUIDColumns InflateColumn::CSV TimeStamp  Core/);


sub add_base_columns {

    my $self = shift;

	my $source = $self->result_source_instance;

    $self->add_columns(

		"id", { data_type => "integer", is_nullable => 0, is_base => 1, is_auto_increment => 1},
		
		"_id", { data_type => "varchar", size=> 100, is_nullable => 0, is_base => 1},
		
		"created_on", { data_type => "DATETIME" ,set_on_create => 1 , is_base => 1}, 

		"updated_on" , { data_type => "DATETIME" ,set_on_create => 1, set_on_update => 1, is_base => 1},
	
		"access_read" , { data_type => "TEXT" , is_csv => 1, is_base => 1},

		"access_write" , { data_type => "TEXT" , is_csv => 1, is_base => 1},

		"active", { data_type => "INTEGER", is_base => 1 , is_nullable => 0},

		"status", { data_type => "TEXT" , is_csv => 1, is_base => 1 , is_nullable => 0},
		
        "data", { data_type => "BLOB", is_nullable => 1},
		
		"app_id", { data_type => "integer", is_nullable => 0, is_base => 1 },

		"log" , { data_type => "TEXT" , is_csv => 0, is_base => 1, is_nullable => 0},
    );
	
	
    $self->add_frozen_columns(
        data => $self->extra_columns 
    );
	my $name = $source->name;
 	$self->add_unique_constraint(
    	"${name}_id_app_id" => [ qw/id app_id/ ],
  	);

	$self->uuid_columns('_id');
}

sub base_columns {
	
	return qw/id _id created_on updated_on access_read access_write active status data log app_id/;
}

sub extra_columns {
    
    return qw/form_template /;
}

sub my_relations {
	
	return ();
}
## perform authorization checks only if acl is set to false 

has "is_readable" => (isa => "Bool", is => "ro", lazy_build => 1);
has "is_writeable" => (isa => "Bool", is => "ro", lazy_build => 1);

## by default, conduct ACL checks on all resultsets

sub _build_is_readable { return 0; }
sub _build_is_writeable { return 0; }

=pod
after 'table' => sub {

	my $class = shift;
	
    my $source = $class->result_source_instance;
	if ($source->resultset_class ne 'Schema::Base::ResultSet') {
		$source->resultset_class("Schema::Base::ResultSet");
	}
};
=cut

sub is_valid {

	my $self = shift;

 	## do necessary user validation  
	
	my $schema = $self->result_source->schema;
    
	my $status = $self->active;

	return ($schema->shared) ? ($status && ($self->app_id eq $schema->app)) : $status;

}

sub has_access {

	my ($self, $permission, $user) = @_;

	$permission ||= "read";
	return $self  unless $self->result_source->schema->acl ;

	my $action = "is_${permission}able";
	
	return $self if $self->$action;

	$user = $self->result_source->schema->user unless $user;


	croak ("need to pass the permission type") unless $permission;
	croak ("need to pass the user_id ") unless $user;
	croak ("No such column exists access_$permission") unless $self->has_column("access_$permission");
	
	## verify if the user exists and is active
	
	$self->find_in_csv("access_$permission", $user);

}

sub remove_access {

	my ($self, $permission, $user) = @_;
	
	$user = $self->result_source->schema->user unless $user;
	croak ("need to pass the permission type") unless $permission;
	croak ("need to pass the user_id ") unless $user;
	croak ("No such column exists access_$permission") unless $self->has_column("access_$permission");

	## verify if the user exists and is active
	
	$self->remove_from_csv("access_$permission", $user);

}

sub grant_access {

	my ($self, $permission, $user) = @_;
	
	my $schema = $self->result_source->schema;
	
	$user = $schema->user unless $user;
	croak ("need to pass the permission type") unless $permission;
	croak ("need to pass the user_id ") unless $user;
	croak ("No such column exists access_$permission") unless $self->has_column("access_$permission");

	## verify if the user exists and is active
	
	$self->add_to_csv("access_$permission", $user);

	my $predicate = "${permission}_parents";

	if ($schema->parents && $schema->$predicate) {
		
		$self->add_to_csv("access_$permission", $_) foreach  (@{ $schema->$predicate });
	}

}
sub has_status {

	my ($self, $status) = @_;
	
	croak ("Unkown status type") unless $status =~ m/\w+/;

	## verify if the user exists and is active
	
	$self->find_in_csv("status", $status);
}
sub remove_status {

	my ($self, $status) = @_;
	
	croak ("You do not have requisite permission") unless $self->has_access("write");
	croak ("Unkown status type") unless $status =~ m/\w+/;

	## verify if the user exists and is active
	
	$self->remove_from_csv("status", $status);
}
sub set_status {

	my ($self, $status) = @_;
	
	croak ("You do not have requisite permission") unless $self->has_access("write");
	croak ("Unkown status type") unless $status =~ m/\w+/;

	## verify if the user exists and is active
	
	$self->add_to_csv("status", $status);

}
=head2 get_expanded_columns 

	$row->get_expanded_columns($include_base_columns) 

returns expaned hash with or without base columns

=cut


sub get_expanded_columns {

	my $self = shift;
	my $include_base_columns = shift;
	my %object = $self->get_columns;
	
	## remove base columns

	unless ($include_base_columns) {
		delete $object{$_} foreach (qw/created_on updated_on status active access_read access_write/) ;
	}

	## thaw the frozen columns
  #  unless ($self->in_storage) {
		
	#	my %frozen_data = $self->frozen_columns;
		
	#	%object = (%object, %frozen_data );
    #}
	
	delete $object{'data'};
	
	## remove undefined columns
	delete $object{$_} foreach ( grep { !defined $object{$_} } keys %object );

	return \%object;
}

=head2 result->serialize($option_no, $index_key)

front end method to use serialize_with_options

all permituations and combinations are as follows

option	include_relationships	include_base_columns	index		index_key	current_status
	
1			yes					yes						yes			index_key	works only with `id`
2			yes					yes						no			null
3			yes					no						yes			index_key
4			yes					no						no			null
5			no					yes						yes			index_key	doesnt	 work, bug in resultclass.pm
6			no					yes						no			null		doesnt	 work, bug in resultclass.pm 
7			no					no						yes			index_key
8			no					no						no			null
9			yes					no						yes			index_key , now only fetch default relationships
10			yes					no						no			null , now only fetch default relationships
11																	do not serialize, pass DBIx Object as is

same urls can be called upon as serialize($option_no, $index_key )

index_key stands for key used in indexing the return array

=cut


sub serialize {
	
	my $self = shift;
	my ($option_no, $index_key) = @_;
	
	$option_no ||= 10;
	my $options = {};
	
	$index_key ||= 'id';
	$options->{no_serialization} = 1 if $option_no eq 11;

	$options->{'include_relationships'} =  ( $option_no <=4  ) ? 1 : 0;
	
	$options->{'default_relationships'} = 	( $option_no eq 9 || $option_no eq 10 ) ? 1 : 0;

	## for backword compatibility
	$options->{'only_keys'} =  0;

	$options->{'include_base_columns'} = ($option_no eq 1 || $option_no eq 2 
											|| $option_no eq 5 || $option_no eq 6  ) ?1 : 0;

	$options->{'indexed_by'} = (($option_no % 2)) ? $index_key : 0;

	$self->serialize_with_options($options);

}
=head2 serialize_with_options

$row->serialize_with_options ($options) 

serilizes blessed DBIC row into plain hold perl hash

accepts options hash as -

$options->{
	include_relationships , # says it all , set to 1 by default
	skip_relationships, # stupid, overrides previous one , set to null by default
	only_keys, # fetch only specific key (mainly primary) from relationships
	key , # specific key to be fetched only if only_kyes is set, default is `id`
	include_base_columns , # set to null by default
	indexed_by , # have row indexed by key, set to null by default
};

=cut


sub serialize_with_options {

	my $self = shift;
	my $options = shift ;
	
	## set defaults
	foreach my $key (qw/skip_relationships only_keys include_base_columns/) {
		$options->{$key} = 0 unless ( exists $options->{$key}) ;
	}
	$options->{'key'} ||= 'id' if $options->{only_keys};

	my $object = $self->get_expanded_columns($options->{'include_base_columns'} ) ;
	
	my $relationships = {};

	if ($options->{'no_serialization'}) {
		
		return $object;
	
	}elsif ($options->{'default_relationships'} ) {

		foreach my $rel ($self->relationships) {
			
			$relationships->{$rel} = $self->related_resultset($rel)->serialize(8);
			if ($self->relationship_info($rel)->{attrs}->{accessor} =~ /single/is
				&& exists $relationships->{$rel}->[0]) {
				
				$relationships->{$rel}  = $relationships->{$rel}->[0];
			}
		}

	} elsif ($options->{'include_relationships'}) {


		foreach my $rel ($self->my_relations) {
			
			next unless $self->$rel;

			my %new_options  = %{$options};
			my $rel_options = \%new_options;

			## make sure we dont go in a recurrsive loop
			$rel_options->{'include_relationships'} = 0;
			## do not index relationships unless indexing key is either 'id' or '_id'
			$rel_options->{'index_key'} = 'id' unless (defined $rel_options->{'indexed_by'} && $rel_options->{'indexed_by'} ne '_id');

			$relationships->{$rel} = ($rel_options->{'only_keys'}) ?  
			
										[$self->$rel->get_column( $rel_options->{key} )->all ] 
										
										: $self->$rel->serialize_with_options($rel_options);
			undef $rel_options;

		} 

	}

	return { %$object , %$relationships };
}

	
=head2 save 

	$row->save({ col1 => $val1 , col2 => $val2 });

saves current DBIC::Row object with new data. Automatically takes care of
Frozen columns and ignores unwanted columns. 

Additinally it requires user to have write permissinon on the object.

=cut

sub save {

	my $self = shift;
	my $data = shift;

	my $user = $self->result_source->schema->user;
	
	my $user_name = $self->result_source->schema->user_name  || 'Guest';

	croak(" You do not have write permissions") 
		unless $self->has_access("write", $user);

	croak(" Object you are trying to save is not valid")
		unless $self->is_valid ;

	#croak(" Object is dirty . Can't do much") 
	#	if $self->is_dirty;

	$self->remove_status("new");
	$self->set_status("active");

	foreach my $column ($self->columns ) {
	
		next if ($self->result_source->column_info($column)->{"is_base"} || !(exists $data->{$column}));

		($self->result_source->column_info($column)->{"is_csv"}) 
			
			## web server or browser always returns a single element in case of multiple select dropdown or checkboxes 
			# (when only one element is selected. Hence to avoid that we force the element to be an array
			# this logic should go in inflateColumn/CSV.pm
			
			? do { ( ref $data->{$column} eq 'ARRAY' ) 
					? $self->set_inflated_column($column, $data->{$column} )  
					: $self->set_inflated_column($column, [ $data->{$column} ]) }
			
			: $self->set_column($column, $data->{$column}) ;
	}
	my %extra_data;
	foreach my $column ($self->frozen_columns_list){
		
		$self->set_column( $column, $data->{$column}) if exists $data->{$column};
		
	}
	
	my $message = $self->log . ",Saved  by  $user_name at " . $self->get_timestamp ;  

	$self->log($message);

    ($self->id) ? $self->update : $self->insert;
	
}

=head2 remove {

	mark current object as inactive

	$row->active(0);
}

=cut

sub remove {

	my $self = shift;
	my $user = shift ;

	$user = $self->result_source->schema->user unless $user;
	my $user_name = $self->result_source->schema->user_name || 'Guest';
	
	croak(" You do not have write permissions") 
		unless $self->has_access("write", $user);

	croak(" Can't remove unsaved object") 
		if $self->has_status("new");

	$self->remove_status("active");
	$self->set_status("deleted");
	$self->active(0);

	my $message =  $self->log . ",Removed by  $user_name at " . $self->get_timestamp ;  

	$self->log($message);

	$self->insert_or_update;
}

=head2 purge
	
purge the delete object.

=cut

sub purge {

	my $self = shift;
	my $user = shift ;

	$user = $self->result_source->schema->user unless $user;

	croak(" You do not have write permissions") 
		unless $self->has_access("write", $user);


	my $message = ": Purged " . $self->id  . " object by  $user at " . $self->get_timestamp ;  

	$self->log($message);

	$self->delete unless $self->active;
}
__PACKAGE__->meta->make_immutable(inline_constructor => 0 );

1;
