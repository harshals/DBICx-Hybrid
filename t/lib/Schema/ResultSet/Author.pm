package Schema::ResultSet::Author;

use strict;
use warnings;

use Moose;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

extends qw/DBICx::Hybrid::ResultSet/;

__PACKAGE__->meta->make_immutable(inline_constructor => 0 );
# You can replace this text with custom content, and it will be preserved on regeneration
1;
