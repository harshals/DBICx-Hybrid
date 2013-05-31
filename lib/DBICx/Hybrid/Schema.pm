#
#===============================================================================
#
#         FILE:  Schema.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  02/01/2011 17:40:41 IST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
package DBICx::Hybrid::Schema;

use Carp qw/croak confess/;
use Moose;
use namespace::clean -except => 'meta';
use Text::CSV::Slurp;
use File::Temp qw/tempfile tempdir/;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
extends 'DBIx::Class::Schema';
=head1 NAME

SneakyCat::Controller::Ideas - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

index just forwards to share.  

=cut

#__PACKAGE__->load_namespaces(

#       result_namespace => ['+DB::Schema::Result', 'Result'],
#        resultset_namespace => [ '+DB::Schema::ResultSet', 'ResultSet'],
#        default_resultset_class => '+DBICx::Hybrid::ResultSet');

## user id who has the permission over this object
has "user" => (isa => "Int", is => "rw", default => 1);

## in case you want to have heirarchial permission resolver
has "parents" => (isa => "Bool", is => "rw", default => 0);


## in case permissions are inherited from parents
has "read_parents" => (isa => 'ArrayRef[Int]', is => "rw" );
has "write_parents" => (isa => 'ArrayRef[Int]', is => "rw");

## only for log purpose
has "user_name" => (isa => "Str", is => "rw", default => 'Guest');

## my debug hack...doesnt work
has "debug" => (isa => "Int", is => "rw", default => 0);

## my custom loggin..again doesnt work
has "logger" => (isa => "FileHandle" , is => 'rw', default => sub { \*STDERR } );

## capture PSGI environment...not available
has "env" => ( is => "rw"  , default => sub { \%ENV } );

## wether to have row level read/write permissions or not
has "acl" => (is => "rw" , default => sub { 0 } );

## is current schema operating in shared mode, as in multiple applications
has "shared" => (is => "rw" , default => sub { 0 } );

## in session app id 
has "app" => (is => "rw" , default => sub { 1 } );

sub init_schema {
    my $self = shift;
	my $name = shift || ':memory:';
	my $db = shift || 'SQLite';
	my $user = shift;
	my $password = shift;
	my $host = shift || 'localhost';

    my $schema = $self->connect("dbi:$db:dbname=$name;host=$host", $user, $password) || die "Could no connect";

	$schema->log("schema instantiated") if $schema;

	return $schema;
}


sub init_debugger {
	
	my $self = shift;
	my $querylog = shift;
	
	if ($querylog) {
		$self->log("Initiating debugger ");
		$self->storage->debug(1);
		$self->storage->debugobj($querylog);
	}
	
	$self;
}


sub log {
	my $self = shift;
	my $message = shift;

	return unless $self->debug;	

	$message = "DBIC: $message";
	
	my $env = $self->env();
    if ($env->{'psgix.logger'}) {
		
        $env->{'psgix.logger'}->(
            {   
				level => 'debug',
                message => $message
            }
        );
    }else {

		say {$self->logger()} $message if $self->debug;
	}
	
}


sub export_to_csv {

    my ($self , $output_dir, $filename, $result_source) = @_;
	
	
	my $tmp = tempdir();

	croak "Output dir not found " unless -d $output_dir;

	my @sources = ($result_source) ? qw/$result_source/ : $self->my_sources;	

	foreach my $source (@sources) {

		my $rs = $self->resultset($source);

		my $list = $rs->look_for->serialize(6);
		
		my $count = scalar @$list;

		next unless $count;

		my $csv = Text::CSV::Slurp->create( input => $list ) ;
		
		my $file = "$tmp/$source.csv";

		open FH, ">", $file;
		print FH $csv;
		close FH;
	}
	

	my $zip = Archive::Zip->new();
	#`tar cvf "$filename" $tmp/*.csv|gzip -f "$filename"`;
	#`cd $tmp;zip  -D -r "$output_dir/$filename.zip" *.csv`;
	$zip->addTreeMatching( $tmp, 'data', '\.csv$' );
	
	unless ( $zip->writeToFileNamed("$output_dir/$filename.zip") == AZ_OK ) {
		die 'Cannot create zip file';
	}
	#tempdir(CLEANUP => 1);

	return "$output_dir/$filename.zip";
}

sub import_from_csv {

	
	my ($self, $result_source, $file, $overwrite) = @_;

	next unless $self->source($result_source);

	my $rs = $self->resultset($result_source);
	
	my $data =  [];

	$data = Text::CSV::Slurp->load(file       => "$file" );
	
	$rs->look_for(undef, {not_readable => 1})->purge if $overwrite;

	my @ids;

	push @ids, $_->{id} foreach @$data;
	
	my $can_import = ( $rs->fetch_new()->can('import_data')) ? 1 : 0;

	foreach my $el (sort { $a->{'id'} <=> $b->{'id'} } @$data) {
		
		unless ($overwrite) {

			my $row = $rs->fetch_new();
			$row->import_data($el) if $can_import;
			$row->save($el);
		}else {
			
			my $row = $rs->new( $el );
			$row->insert_or_update;
		}
	}

	return scalar @$data;
}

sub my_sources {
	
	my $self = shift;

	return grep { !/Enumeration|User|Application/i } $self->sources;
}

__PACKAGE__->meta->make_immutable;
1;


