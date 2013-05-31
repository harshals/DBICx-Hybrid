package DBICx::Hybrid::Result::Template;

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

sub set_up {

	my $self = shift;

	my $source = $self->result_source_instance;

	$self->add_columns(

		"name", { data_type => "VARCHAR(200)", is_nullable => 0 },
		"prefix", { data_type => "VARCHAR(200)", is_nullable => 1 },
	);

$self->add_base_columns;

$self->set_primary_key("id");

}

around 'extra_columns' => sub {
    
    my $orig = shift;
    my $class = shift;

	my @columns = $class->$orig(@_);

	push @columns , qw/tt_template pdf_template/;

	return @columns;
};
# Created by DBIx::Class::DB::Schema::Loader v0.04006 @ 2009-08-13 21:11:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:obZUGgvkve3e6mzPk8GEEg

# You can replace this text with custom content, and it will be preserved on regeneration




1;

