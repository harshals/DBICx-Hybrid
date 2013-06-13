use warnings;
use strict;

use lib "t/lib";

use Test::More ;

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

$schema->app(1);
$schema->shared(1);

my $book_rs = $schema->resultset("Book");

my $old_book = $book_rs->fetch(2);
is($old_book->id, 2, "Found 2nd book");

my $new_book = $book_rs->fetch_new();

ok($new_book->has_status( 'new'), "Has new status");
ok($new_book->app_id, "App id is set");

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

ok(!$new_book->has_status( 'new'), "Has no longer new status");
ok($new_book->has_status( 'active'), "My new book is in the DB");

my $id = $new_book->id;

isnt($id, 2, "This is not the 2nd book");

$new_book->set_status("cancelled");
$new_book->update;

ok($new_book->has_status( 'cancelled'), "My new book is in the DB");
ok($book_rs->look_for->has_status('cancelled')->count, "Found my cancelled invoice");

$new_book->remove;
$new_book->purge;

ok($new_book->has_status( 'deleted'), "My new book has been deleted");
ok(!eval { $book_rs->fetch($id) } , $@ );

done_testing;
