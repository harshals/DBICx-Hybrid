#
#===============================================================================
#
#         FILE:  Application.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  10/10/2011 19:15:40 IST
#     REVISION:  ---
#===============================================================================

package DBICx::Hybrid::ResultSet::Application;
use strict;
use warnings;
use Moose::Role;
use namespace::clean -except => 'meta';

sub _build_template_prefix {
	
	return "application";
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
