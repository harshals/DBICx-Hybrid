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
package DBICx::Hybrid::ResultSet::Contact;

use strict;
use warnings;
use Moose::Role;
use namespace::clean -except => 'meta';
use Carp qw/croak confess/;

# ABSTRACT: ResultSet Class for Contact
=head1 NAME

DBICx::Hybrid::ResultSet::Contact

Some common routines for Contact resultclass

=head1 METHODS

=head2 resultset->profile($user_id) 

Find a given contact by user_id (User)

Returns a result row

=cut

sub _build_template_prefix {
	
	return "contact";
}


sub profile {
    
    my $self = shift;
    my $user_id = shift;
	my $alias = $self->current_source_alias;

    $self->search({ "$alias.user_id" => $user_id })->first;
}

sub companies{
    
    my $self = shift;
	my $alias = $self->current_source_alias;

    $self->search_rs({  "is_human" => 0 });
}
sub company{
    
    my $self = shift;
    my $company_name = shift;
	my $alias = $self->current_source_alias;
	
	$self->companies->search({ "$alias.name" => $company_name })->first;
}
sub people{
    
    my $self = shift;
	my $alias = $self->current_source_alias;

    $self->search_rs({  "is_human" => 1 });
}

1;


