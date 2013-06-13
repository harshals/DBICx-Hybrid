package Master::Result::User;

use strict;
use warnings;

use Moose;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

extends qw/DBICx::Hybrid::Result/;
with 'DBICx::Hybrid::ResultRole::User';

__PACKAGE__->table("user");

__PACKAGE__->set_up;

after 'set_up'	=>	sub {

	my $self = shift;
	my $source = $self->result_source_instance;

};
sub my_relations {

	my $self = shift;
	return qw/application/;

};


sub extra_columns {

	my $class = shift;

	my @columns = $class->next::method(@_);

	push @columns, (qw//);

	return @columns;

};

sub collegues {

	my $self = shift;
	my $params = shift;

	my $search  = {};

	## my search parameters are title, publish_date, price and classification
	$self->application->users;

};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
# You can replace this text with custom content, and it will be preserved on regeneration
1;
