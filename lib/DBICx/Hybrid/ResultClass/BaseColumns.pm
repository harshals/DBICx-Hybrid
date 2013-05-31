package DBICx::Hybrid::ResultClass::BaseColumns;
use strict;
use warnings;

use Moose;
use namespace::clean -except => 'meta';
use Storable qw/thaw/;
extends qw/DBIx::Class::ResultClass::HashRefInflator/;

# ABSTRACT: Just my type of hash inflator

# wrapper around original module to
# infalte frozen columns
around 'inflate_result' => sub {
	
	my $orig = shift;
	my $self = shift;
	my $result_source = shift;
	my ($data, $rel_ref ) = @_;

	my $row = $self->$orig($result_source, $data, $rel_ref);
	
	my $inner_data = defined $row->{'data'} ? eval { thaw( $row->{'data'} ) }  || {} : {};
	
	$row = { %$row , %$inner_data };
		
	delete $row->{'data'};

	return $row;
};

__PACKAGE__->meta->make_immutable(inline_constructor => 0 );
1;
