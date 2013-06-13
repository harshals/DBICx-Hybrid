#
#===============================================================================
#
#         FILE:  User.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  02/11/2011 18:27:43 IST
#     REVISION:  ---
#===============================================================================
package Schema::ResultSet::Contact;

use strict;
use warnings;

use Moose;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

extends qw/DBICx::Hybrid::ResultSet/;
with qw/DBICx::Hybrid::ResultSetRole::Contact/;

=head2 resultset->profile($user_id)
Find a given contact by user_id (User)
Returns a result row
=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0 );
# You can replace this text with custom content, and it will be preserved on regeneration
1;
