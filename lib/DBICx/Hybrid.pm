package DBICx::Hybrid;
use strict;
use warnings;

## Authered for MK Software 
# ABSTRACT: my take on SQL + NoSQL hybrid ORM

=head1 NAME

DBICx::Hybrid - 

Some common routines i generally use combined in form of ResultSet, ResultClass and Result Classes.

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';

1;
__END__
=head1 SYNOPSIS

Load this component and declare columns as csv column.

	package My::Schema;
	extends qw/DBIx::Class::Schema/;

	use Moose;

	has 'user'=> { isa => 'Str', is => 'rw'  };

	1;

	package Schema::Result::Author;
	extends qw/DBICx::Hybrid::Result/;

	#define your result class

	1;

	
	package Schema::ResultSet::Author;
	extends qw/DBICx::Hybrid::ResultSet/;

	# define custom resultset methods		

	1;

	in your code
	
	$rs->recent(5) ; ## returns last 5 updated or created rows
	$rs->single->save({ some importnat data }); ## customized save method

=head1 DESCRIPTION

customised exentions for DBIC::Result and ResultSets. Basically allows you to 
modify schema on quick and dirty basis. Uses DBIx::Class::FrozenColumns to store
data as Storable within a column. Please refer to individual classes for more detail explaination.

only pre-requisite is that overlaying schema must define a `user` attribute, having current user_id 
or session_id.


=head1 AUTHOR

Harshal Shah (harshal.shah@gmail.com)

=head1 BUGS

shoot an email to harshal.shah@gmail.com

=head1 COPYRIGHT & LICENSE

Copyright (C) 2013 Harshal Shah

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



=cut
