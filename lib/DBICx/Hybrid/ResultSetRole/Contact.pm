#
#===============================================================================
#
#         FILE:  Contact.pm
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
package DBICx::Hybrid::ResultSetRole::Contact;

use strict;
use warnings;

use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub _build_template_prefix {

	return "contact";

};

sub profile {

	my $self = shift;
	my $user_id = shift;
	my $alias = $self->current_source_alias;

	$self->search({ "$alias.user_id" => $user_id })->first;

};

sub companies {

	my $self = shift;
	my $alias = $self->current_source_alias;

	$self->search_rs({  "is_human" => 0 });

};

sub company {

	my $self = shift;
	my $company_name = shift;
	my $alias = $self->current_source_alias;

	$self->companies->search({ "$alias.name" => $company_name })->first;

};

sub people {

	my $self = shift;
	my $alias = $self->current_source_alias;

	$self->search_rs({  "is_human" => 1 });

};

# You can replace this text with custom content, and it will be preserved on regeneration
1;
