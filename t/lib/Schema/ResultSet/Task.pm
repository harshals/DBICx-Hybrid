#
#===============================================================================
#
#         FILE:  Task.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  02/12/2011 12:01:54 IST
#     REVISION:  ---
#===============================================================================
package Schema::ResultSet::Task;

use strict;
use warnings;

use Moose;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

extends qw/DBICx::Hybrid::ResultSet/;
with qw/DBICx::Hybrid::ResultSetRole::Task/;

=head2 resultset->updated_on($days)
finds a record updated in last # of $days
=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0 );
# You can replace this text with custom content, and it will be preserved on regeneration
1;
