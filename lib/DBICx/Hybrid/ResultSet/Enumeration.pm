#
#===============================================================================
#
#         FILE:  Enumeration.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  04/26/2011 15:53:38 IST
#     REVISION:  ---
#===============================================================================


package DBICx::Hybrid::ResultSet::Enumeration;

use strict;
use warnings;
use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub _build_template_prefix {
	
	return "enumeration";
}

sub groups {

	my $self = shift;

	my $attr = {
		select => [qw/class attr /, { count => 'id' } ],
		as => [qw/class attr total/ ],
		group_by => [ qw/class attr/],
		order_by => { -asc => [qw/class attr/] }
	};

	return $self->look_for(undef, $attr);
}

sub create_default_dates {

	my ($self, $app_id, $admin_id,  $begin_date, $end_date) = @_;
	my $date = $self->fetch_new();
	my $data = {
		class => 'Master',
		attr => 'begin_date',
		is_default => 1,
		sequence => 1,
		value => '2011-04-01',
		description => 'Beginning of FY',
	};

	$data->{app_id} = $app_id if $app_id;
	$date->grant_access("read", $admin_id);
	$date->grant_access("write", $admin_id);
	$date->save($data);
	$date = $self->fetch_new();
	$data->{attr} = 'end_date';
	$data->{value} = '2012-03-31';
	$data->{description} = 'End of the FY';
	$data->{app_id} = $app_id if $app_id;
	$date->grant_access("read", $admin_id);
	$date->grant_access("write", $admin_id);
	$date->save($data);

}

# ABSTRACT: ResultSet Class for Enumeration
=head1 NAME

DBICx::Hybrid::ResultSet::Enumeration

Some common routines for Enumeration resultclass

=head1 METHODS

=head2 resultset->for($table, $field) 

finds list of all enumerable properties for a particular table & its field

$rs->for("Task", "task_status")

by default it only returns column resultset 

=cut

sub increment {

	my ($self, $class, $attr, $category, $step) = @_;

	$step ||= 1;

	my $rs = $self->for($class, $attr, $category);

	while (my $row = $rs->next) {
		
		$row->value( $row->value + $step);
		$row->update;
	}	

}

sub for {

	my ($self, $class, $attr, $category) = @_;

	my $alias = $self->current_source_alias;
	
	my $search = { "$alias.class" => $class , "$alias.attr" => $attr };

	$search->{"$alias.category"} = $category if $category;

	my $sattr = {  order_by => {  -asc => 'sequence'} };

	$sattr->{cache_for } =  	86400 unless $category;

	my $rs = $self->is_valid->search_rs( $search, $sattr );

	return $rs;

}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
