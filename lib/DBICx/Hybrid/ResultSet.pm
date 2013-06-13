
package DBICx::Hybrid::ResultSet;
use strict;
use warnings;
use Moose;
use namespace::clean -except => 'meta';
use Carp qw/croak confess/;
use JSON::XS qw/encode_json/;
use constant DEBUG => 0;
use DateTime;

# ABSTRACT: Basic ResultSet Class
#use base ;

extends qw/DBIx::Class::ResultSet/;

sub my_prefetch_condition {
	
	return [];
}

## perform authorization checks only if acl is set to false 

=head1 ACCESSORS

=head2 is_readable, is_writable

set true if you want everyone to read or write irrespective of 
their ownership. by default its set to true.

=cut

has "is_readable" => (isa => "Bool", is => "ro", lazy_build => 1);
has "is_writeable" => (isa => "Bool", is => "ro", lazy_build => 1);

=head2 template_prefix 

overide this accessor to look for templates in different preifx folder.
This needs to be set to be functional. its required. 

=cut

has "result_key" => (isa => "Str", is => "rw", lazy_build => 1, predicate => "has_result_key");
has 'template_prefix' => ( is => 'ro', lazy_build => 1 , isa => "Str" , required => 1, predicate => "has_template_prefix");

## by default, conduct ACL checks on all resultsets

sub _build_is_readable { return 0; }
sub _build_is_writeable { return 0; }

sub _build_result_key { return '' };

sub has_access{

	my ($self, $permission, $user, $alias) = @_;

	return $self unless $self->result_source->schema->acl;

	$permission ||= "read";
	my $action = "is_${permission}able";

#	return $self if ($self->$action && $self->{_attrs}->{is_not_readable});

	$user = $self->result_source->schema->user unless $user;

 	## do necessary user validation  
	
	croak ("need to pass the user_id ") unless $user;
	croak ("No such column exists access_$permission") unless $self->result_source->has_column("access_$permission");

	$alias ||= $self->current_source_alias;

	return $self->search_rs( { "$alias.access_$permission" => { 'like' , '%,' . $user . ',%'}} );

}
sub remove_access {

	my ($self, $permission, $user) = @_;
	
	croak ("need to pass the permission type") unless $permission;
	croak ("need to pass the user_id ") unless $user;
	croak ("No such column exists access_$permission") unless $self->result_source->has_column("access_$permission");

	## verify if the user exists and is active

	while(my $row = $self->next) {
		$row->remove_access($permission, $user);
		$row->update;
	}

	return 1;
}
sub grant_access {

	my ($self, $permission, $user) = @_;
	
	croak ("need to pass the permission type") unless $permission;
	croak ("need to pass the user_id ") unless $user;
	croak ("No such column exists access_$permission") unless $self->result_source->has_column("access_$permission");

	## verify if the user exists and is active

	while(my $row = $self->next) {
		$row->grant_access($permission, $user);
		$row->update;
	}

	return 1;
}
sub has_status {

	my ($self, $status) = @_;
	
	croak ("Unkown status type") unless $status =~ m/\w+/;

	my $alias ||= $self->current_source_alias;

	return $self->search_rs( { "$alias.status" => { 'like' , '%,' . $status. ',%'}} );
	
}
sub fetch {

	my $self = shift;
	my $id = shift;
	my $user = $self->result_source->schema->user;
	
	croak("Need primary key to find the object") unless $id;	

	my $attributes = {};
	my $alias ||= $self->current_source_alias;

	my $search = { "$alias.id" => $id };
	
	my $schema = $self->result_source->schema;

	#$search->{app_id} = $schema->app if $schema->shared;
	my $source_name = $self->result_source->name;
	$attributes->{key} = "${source_name}_id_app_id" if $schema->shared;

	my $unreadable = delete $attributes->{not_readable};	
	
	my $rs = ($unreadable) ? $self->has_access : $self;
	$rs = ($self->is_readable) ? $rs : $rs->has_access;
	
	my $object = $rs->is_valid->find( $search, $attributes);

	croak("object you are looking for is not found") unless $object;	

	croak("you don;t seem to have requisite permission to read this object") unless $object->has_access;
	
	croak("Object is not valid ") unless $object->is_valid;

	return $object;
}

sub fetch_new {

	my $self = shift;
	my $data = shift || {};

	my $object = $self->new({});

    $object->active(1);
	$object->grant_access("read" );
	$object->grant_access("write");

	$object->set_status("active");
	$object->set_status("new");
	
	my $schema = $self->result_source->schema;

	$object->app_id($schema->app) if ($schema->shared);

	return $object;
}



sub purge {

	my $self = shift;

    $self->delete;
}

sub is_valid {

	my $self = shift;

 	## do necessary user validation  
	
	my $alias ||= $self->current_source_alias;
	my $schema = $self->result_source->schema;
    
    my $search = {};
    
    $search->{"$alias.active"}  = 1 ;

	croak "Application id is not set " if  (!($schema->app) && $schema->shared);

	$search->{ "$alias.app_id" }  = $schema->app if $schema->shared;

	$self->search_rs( $search, undef );
}

sub is_deleted {
	
	my $self = shift;
	my $alias = shift;

	$alias ||= $self->current_source_alias;

	return $self->search_rs( { "$alias.active" => 0, "$alias.status" => { 'like' , '%,' . 'deleted' . ',%'} } );
}
sub look_for {
	
	my ($self, $search, $attributes ) = @_;

    ## do necessary user validation  
	
	#$attributes->{prefetch} ||= $self->my_prefetch_condition if scalar @{ $self->my_prefetch_condition };
	
	my $unreadable = delete $attributes->{not_readable};	
	
	my $rs = ($unreadable) ? $self->has_access : $self;
	$rs = ($self->is_readable) ? $rs : $rs->has_access;
	
	return $rs->is_valid->search_rs( $search, $attributes);
}

=head2 resultset->from_cgi_prams($cgi_hashref) 

converts given cgi hash into search hash and prepares the resultset

maps all date columns to date range queries similar to
$col => -and [ { $col >= $from_date } , { $col <= $to_date } ]

the cgi hashref should contain keys with prefix from_ and to_ for each date column

maps all columns with like_ prefix to LIKE queries

rest all columns are treated for equal operators
=cut


sub from_cgi_params {

	my ($self, $cgi) = @_;

	my $search;
	my $hidden = {};

	my $alias = $self->current_source_alias;
	if ( defined $cgi && (ref $cgi eq 'HASH')){

		foreach my $column 	( $self->result_source->columns ) {
			
			## trying to contstruct a search hash 
			## $col => -and [ { $col >= $from_date } , { $col <= $to_date } ]
			
			if (defined $cgi->{"from_$column"} && defined $cgi->{"to_$column"}) {
				
				$search->{"${alias}.$column"} = { -between , [ $cgi->{"from_$column"}, $cgi->{"to_$column"} ] };

			}elsif (defined $cgi->{"from_$column"}) {

				$search->{"${alias}.$column"} = { '>=' , $cgi->{"from_$column"} };
			
			}elsif (defined $cgi->{"to_$column"}) {

				$search->{"${alias}.$column"}= { '<=' , $cgi->{"to_$column"} };
			}elsif (defined $cgi->{"like_$column"}) {
				
				$search->{"${alias}.$column"} = { 'LIKE' , '%' . $cgi->{"like_$column"} .'%' };
			} elsif (defined $cgi->{"in_$column"}) {
				
				unless(ref ($cgi->{"in_$column"}) eq 'ARRAY' ) {
					$cgi->{"in_$column"} = [ split(/,/, $cgi->{"in_$column"}) ]
				}
				$search->{"${alias}.$column"} = { -in , $cgi->{"in_$column"}   };

			} elsif (defined $cgi->{"not_in_$column"}) {
				
				unless(ref ($cgi->{"not_in_$column"}) eq 'ARRAY' ) {
					$cgi->{"not_in_$column"} = [ split(/,/, $cgi->{"not_in_$column"}) ]
				}
				$search->{"${alias}.$column"} = { -not_in , $cgi->{"not_in_$column"}   };

			} elsif (defined $cgi->{"not_$column"}) {
				
				$search->{"${alias}.$column"} = { '!=' , $cgi->{"not_$column"}   };
			}
			elsif (defined $cgi->{$column}) {

				$search->{"${alias}.$column"} = { '=' , $cgi->{$column}  };
			}

		}
	
		my $dummy_row = $self->new({});
		
		foreach my $column ($dummy_row->frozen_columns_list){

			if ($cgi->{"like_$column"}) {
				
				$hidden->{$column} = 'like_'  . $cgi->{"like_$column"};

			} elsif ($cgi->{$column}) {

				$hidden->{$column} = 'is_'  . $cgi->{$column};
			}
		}
		undef $dummy_row;

		#$self->hidden_search_columns($hidden) if scalar( keys %$hidden);
	}
	
	return $self->look_for($search, { frozen_columns => $hidden } );

}

=head2 resultset->serialize($option_no, $index_key)

front end method to use serialize_with_options

all permituations and combinations are as follows

option	include_relationships	include_base_columns	index		index_key	current_status
	
1			yes					yes						yes			index_key	works only with `id`
2			yes					yes						no			null
3			yes					no						yes			index_key
4			yes					no						no			null , 
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
	my ($option_no, $index_key, $page_no, $page_length) = @_;
	
	$option_no ||= 10;
	my $options = {};
	
	$index_key ||= 'id';
	
	$options->{no_serialization} = 1 if $option_no eq 11;

	$options->{default_relationships} = 1 if $option_no eq 9 || $option_no eq 10;

	$options->{'include_relationships'} =  ( $option_no <=4  ) ? 1 : 0;
	
	## for backword compatibility
	$options->{'only_keys'} =  0;

	$options->{'include_base_columns'} = ($option_no eq 1 || $option_no eq 2 
											|| $option_no eq 5 || $option_no eq 6  ) ?1 : 0;

	$options->{'indexed_by'} = (($option_no % 2)) ? $index_key : 0;

	$options->{'page_length'} = $page_length || 'all';

	$options->{'page_no'} = $page_no  if $page_length;

	$self->serialize_with_options($options);

}

=head2 resultset->serialize_with_options ($options) 

serilizes blessed DBIC resultset into plain hold perl hash

accepts options hash as -

$options->{
	include_relationships , # says it all
	only_keys, # fetch only specific key (mainly primary) from relationships
	key , # specific key to be fetched only if only_kyes is set
	include_base_columns , # set to null by default
	indexed_by, # have each row indexed by key, set to null by default
	index, # shortcut for indexed_by => id
};
=cut

sub serialize_with_options {

	my ($self ) = shift;
	my $options = shift ;
	

	## by default dun fetch relationships
	foreach my $key (qw/include_relationships only_keys include_base_columns indexed_by/) {
		$options->{$key} = 0 unless ( exists $options->{$key}) ;
	}
	$options->{'key'} ||= 'id' if $options->{only_keys};
	$options->{'indexed_by'}  ||= 'id' if $options->{index};
	
	croak "Cannot index resultset by non-existant columns " 
			if $options->{indexed_by} && !$self->result_source->has_column($options->{indexed_by});

	my ($list, $rs);
		
	if ($options->{'page_length'} && $options->{'page_length'} ne 'all' && $options->{'page_no'} =~ m/\d/) {
		
		$rs = $self->search_rs(undef, { page => $options->{'page_no'} , rows => $options->{'page_length'} });
	}else {
		$rs = $self;
	}

	## serialization flow
	# 1. Do not serialize , pass the DBIx resultset as is
	# 2. serialize manually with expanding each row
	# 3. serialize with HashInflator
	# 	3.1 serialize with prefetching default relationships
	# 	3.2 serialize without relationships, as is

	if ($options->{'no_serialization'}) {
		
		$list = [$rs->all];

	}elsif ($options->{'include_relationships'}) {
		
		# at row level, relationships are fetched by defualt
		# to avoid that set skip_relationships => 1 in the options
		
		if ($options->{'indexed_by'}) {
			$list->{ $_->get_column($options->{indexed_by}) } =  $_->serialize_with_options($options)  foreach $rs->all;
		}else {

			push @$list , $_->serialize_with_options($options) foreach $rs->all;
		}

	} else {
		
		my $result_class = ($options->{'include_base_columns'}) 
							?  	"DBICx::Hybrid::ResultClass::BaseColumns"
							: 	"DBICx::Hybrid::ResultClass";


		if ($options->{'default_relationships'} ) {

			$rs = $self->prefetch	;
		}
		
		$rs->result_class($result_class);

		if ($options->{'indexed_by'}) {
			
			$list->{ $_->{$options->{indexed_by}} } = $_ foreach $rs->all;

		}else {

			$list = [ $rs->all ];
		}
	}


	return ( keys %{ $self->{_attrs}->{frozen_columns} }) ? $self->filter_frozen_columns($list) :  $list;
}

sub to_json{

	my $self = shift;

	my $list = $self->serialize(@_);

	return encode_json( $list || [] );
}

sub recent {

	my ($self, $limit , $sort_by) = @_;

    $limit ||= 3;
	my $alias = $self->current_source_alias;
	$sort_by ||= 'created_on';
	
	my $attr = { order_by => { -desc => "$alias.$sort_by" }  };
	
	$attr->{rows}= $limit  unless ($limit eq 'all' );
	

    return $self->search_rs( undef,  $attr );

}

=head2 resultset->created_in($days) 

finds a record created in last # of $days

makes a query from `tomorrow` - $days ..since tomorrow by default allows for queries
involving today till 12 midnight .

=cut

sub created_in {
	
	my ($self, $days) = @_;

	$days--;
	my $tomorrow = DateTime->now()->add( days => 1);
	my $past = $tomorrow->clone->add( days => -$days );

	my $alias = $self->current_source_alias;
	$self->search_rs( { "$alias.created_on" => { -between => [  $past->ymd , $tomorrow->ymd] } });
}

=head2 resultset->updated_on($days) 

finds a record updated in last # of $days

=cut

sub updated_in{
	
	my ($self, $days) = @_;

	$days--;
	my $tomorrow = DateTime->now()->add( days => 1);
	my $past = $tomorrow->clone->add( days => -$days );

	my $alias = $self->current_source_alias;
	$self->search_rs( { "$alias.udpated_on" => { -between => [  $past->ymd , $tomorrow->ymd] } });
}

=head2 resultset->prefetch($prefetch_condition) 

applies default prefetch condition or one that is supplied


=cut

sub prefetch {
	
	my ($self, $condition ) = @_;

	$condition ||= $self->my_prefetch_condition;

	return $self unless scalar @{ $condition };

	$self->search_rs( undef, { join => $condition, prefetch => $condition } );
}

sub filter_frozen_columns {
	
	my ($self, $list) = @_;

	my $fz = $self->{_attrs}->{frozen_columns};

	my @filtered_list = grep { 
							
							my $status = 1;

							foreach my $key (keys %{ $fz } ) {
								
								my $value = $fz->{$key};
								
								if ( $value =~ s/^like_//is ) {
								
									$status = $status && $_->{ $key } =~ m/$value/is ;

								} elsif ( $value =~ s/^is_//is ) {
								
									$status = $status && $_->{ $key }  eq $value ;
								};
								
							}

							$status;

						} @$list;

	return \@filtered_list;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0 );

1;
