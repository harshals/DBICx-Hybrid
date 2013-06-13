package Schema::Result::Contact;

use strict;
use warnings;

use Moose;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

extends qw/DBICx::Hybrid::Result/;
with 'DBICx::Hybrid::ResultRole::Contact';

__PACKAGE__->table("contact");

__PACKAGE__->set_up;

after 'set_up'	=>	sub {

	my $self = shift;
	my $source = $self->result_source_instance;

};

sub extra_columns {

	my $class = shift;

	my @columns = $class->next::method(@_);

	push @columns, (qw//);

	return @columns;

};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
# You can replace this text with custom content, and it will be preserved on regeneration
1;
