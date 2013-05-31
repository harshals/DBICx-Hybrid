#
#===============================================================================
#
#         FILE:  Attachment.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  04/27/2011 17:11:40 IST
#     REVISION:  ---
#===============================================================================


package DBICx::Hybrid::ResultSet::Attachment;

use strict;
use warnings;
use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub _build_template_prefix {
	
	return "attachment";
}

sub attachments_for {

	my $self = shift;
	my $class = shift;
	my $id = shift;
	my $uuid = shift;

	my $search = {};

	croak "DBIC: Can't find attachments without requisite class " unless $class;

	$search->{owner_class} = $class;
	$search->{owner_id} = $id if $id;
	$search->{owner_uuid} = $id if $uuid;

	return $self->look_for($search );
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
