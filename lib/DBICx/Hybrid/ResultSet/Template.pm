#
#===============================================================================
#
#         FILE:  Template.pm
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


package DBICx::Hybrid::ResultSet::Template;
use strict;
use warnings;
use Moose::Role;
use namespace::clean -except => 'meta';
use Carp qw/croak confess/;

# ABSTRACT: ResultSet Class for Template
=head1 NAME

DBICx::Hybrid::ResultSet::Template

Some common routines for Template resultclass

=head1 METHODS

=head2 resultset->updated_on($days) 

finds a record updated in last # of $days

=cut

sub _build_template_prefix {
	
	return "template";
}


1;
