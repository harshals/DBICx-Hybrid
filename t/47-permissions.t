#
#===============================================================================
#
#         FILE:  47-permissions.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  10/10/2011 12:35:54 IST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More ;
use Data::Dumper;

BEGIN { use_ok 'Schema' }
BEGIN { use_ok 'Master' }

my %args = ( @ARGV );
my $size = $args{"size"}  || "small";
my $dbname =  $args{"dbname"} || "t/var/" . $size . ".db";
my $masterdb =  "t/var/master.db";
my $dbtype = $args{"dbtype"} || "SQLite";
my $password = $args{"p"};
my $username = $args{"u"};
my $host = $args{"h"};

##auto correct db types

$dbtype = "SQLite" if $dbtype =~ /sqlite/i;
$dbtype = "mysql" if $dbtype =~ /mysql/i;
$dbtype = "PostgreSQL" if $dbtype =~ /pg|postgre/i;

my $schema = Schema->init_schema($dbname, $dbtype, $username, $password , $host);
my $master = Master->init_schema($masterdb, $dbtype, $username, $password , $host);

isa_ok($schema, 'DBIx::Class::Schema', "Schema initialised properly");

$schema->user(1);
$master->user(1);

$schema->shared(1);
$schema->app(1);

my $book_rs = $schema->resultset("Book");

my $old_book = $book_rs->fetch(2);

is($old_book->id, 2, "Found 2nd book");

ok($old_book->has_access("read"), "Has read access");
ok($old_book->has_access("write"), "Has read access");

my $parents = [2,4];


$schema->parents(1);
$schema->acl(1);
$schema->read_parents($parents);

$old_book->grant_access("read");

$old_book->update;

my $new_book = $book_rs->fetch_new();

$new_book->save({
	
	isbn => rand() * 1000000,
	classification => $old_book->classification,
	price => $old_book->price,
	title => $old_book->title,
	publish_date => $old_book->publish_date,
	publish_year => $old_book->publish_year,
	subtitle => $old_book->subtitle,
	description => $old_book->description,
	toc => $old_book->toc,
	category_id => $old_book->category_id
});

$schema->user(2);


ok($old_book->has_access, "Parents have read access");
ok(!$old_book->has_access("write"), "Parents do not have write access");
ok($new_book->has_access, "Parents have built in read access");
ok(!$new_book->has_access("write"), "Parents do not have built in write access");

$schema->user(1);
$schema->write_parents($parents);
$old_book->grant_access("write");

ok($new_book->has_access("write"), "now Parents have write access");

## deleting newly created records
$new_book->remove;
$new_book->purge;

done_testing;

