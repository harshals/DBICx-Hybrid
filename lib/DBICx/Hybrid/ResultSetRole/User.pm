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
#      CREATED:  04/27/2011 17:11:40 IST
#     REVISION:  ---
#===============================================================================
package DBICx::Hybrid::ResultSetRole::User;

use strict;
use warnings;

use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub _build_template_prefix {

	return "user";

};

sub my_prefetch_condition {

	return [ qw/contact/ ];

};

sub users {

	my $self = shift;

	my $alias = $self->current_source_alias;

	return $self->look_for({ "$alias.role" => { '-not_in' , [qw/admin god guest/ ] } } );

};

sub my_users {

	my ($self, $search, $attributes, $params) = @_;

	my $alias = $self->current_source_alias;

	return $self->look_for({ "$alias.role" => { '-not_in' , [qw/admin god guest/ ] } } , { not_readable => 1 })->from_cgi_params($params);

};

sub authenticate {

	my $self = shift;

	my $search = shift;

	$self->search($search)->first;

};

sub by_profile {

	my $self = shift;
	my $profile_id = shift;

	my $alias = $self->current_source_alias;

	$self->search({ "$alias.contact_id" => $profile_id })->first;

};

# You can replace this text with custom content, and it will be preserved on regeneration
1;
