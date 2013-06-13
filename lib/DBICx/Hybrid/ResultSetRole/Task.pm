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
package DBICx::Hybrid::ResultSetRole::Task;

use strict;
use warnings;

use Moose::Role;
use Carp qw/croak confess/;
use namespace::clean -except => 'meta';

sub _build_template_prefix {

	return "task";

};

sub tasks {

	my ($self, $days) = @_;

	my $alias = $self->current_source_alias;

	return $self;

	#$self->search_rs( { "$alias.category" =>  'task'  });

};

sub messages {

	my ($self, $days) = @_;

	my $alias = $self->current_source_alias;

	$self->search_rs( { "$alias.category" =>  'message'  });

};

sub due_in {

	my ($self, $days) = @_;

	$days++;

	my $now = DateTime->now();

	my $later = $now->clone->add( days => $days );

	my $alias = $self->current_source_alias;

	$self->tasks->incomplete_tasks->search_rs( { "$alias.due_date" => { -between => [ $now->ymd, $later->ymd ] } });

};

sub incomplete_tasks {

	my ($self, $days) = @_;

	my $alias = $self->current_source_alias;

	$self->search_rs( { "$alias.task_status" =>  'Incomplete'  });

};

sub unread_messages {

	my ($self, $days) = @_;

	my $alias = $self->current_source_alias;

	$self->messages->search_rs( { "$alias.task_status" =>  'Unread'  });

};

sub overdue_tasks {

	my ($self, $days) = @_;

	my $alias = $self->current_source_alias;

	my $now = DateTime->now();

	$self->tasks->incomplete_tasks->search_rs( { "$alias.due_date" =>  {  '>', $now->ymd  }   }  );

};

sub completed_tasks {

	my ($self, $days) = @_;

	my $alias = $self->current_source_alias;

	$self->tasks->search_rs( { "$alias.task_status" => { '!=', 'Incomplete' } });

};

sub read_messages {

	my ($self, $days) = @_;

	my $alias = $self->current_source_alias;

	$self->messages->search_rs( { "$alias.task_status" => { '!=', 'Read' } });

};

# You can replace this text with custom content, and it will be preserved on regeneration
1;
