use warnings;
use strict;

use lib "t/lib";
use Schema;

use Test::More;
use Data::Dumper;
use JSON::XS qw/encode_json/;

my %args = ( @ARGV );
my $size = $args{"size"}  || "small";
my $dbname =  $args{"dbname"} || "t/var/" . $size . ".db";
my $dbtype = $args{"dbtype"} || "SQLite";
my $password = $args{"p"};
my $username = $args{"u"};
my $host = $args{"h"};

##auto correct db types
$dbtype = "SQLite" if $dbtype =~ /sqlite/i;
$dbtype = "mysql" if $dbtype =~ /mysql/i;
$dbtype = "PostgreSQL" if $dbtype =~ /pg|postgre/i;

my $schema = Schema->init_schema($dbname, $dbtype, $username, $password , $host);

my $user = 1;
my $app = 1;

$schema->user($user);
$schema->app($app);

my $book_rs = $schema->resultset("Book");
is($book_rs->count,20, "found 20 books");

## construct CGI hash
my $cgi = {
	in_id => '1,3,5,6,2',
	from_publish_date => '2004-01-05',
	to_publish_date => '2004-01-06',
};

my $books = $book_rs->look_for->from_cgi_params($cgi);
is($books->count, 2, "Found exactly 2 books between 2004-01-05 and 2004-01-06  and ids in range 1,3,5,6,2 ");

## add more parameteres on the fly
$books = $books->look_for({ isbn => '1590593189' })->from_cgi_params ( );
is($books->count, 1, "Found exactly 1 book between 2004-01-05 and 2004-01-06  with ISBN 1590593189");

## further override with custom search query
$books = $books->look_for({ title => { 'LIKE' , '%Distributed%' } });
is($books->count, 1, "Found exactly 1 book between 2004-01-05 and 2004-01-06  with ISBN 1590593189 having title Distributed");

## enabling the shared mode
$schema->shared(1);
$books = $book_rs->look_for({ title => { 'LIKE' , '%Distributed%' } });
is($books->count, 1, "Found exactly 1 book between 2004-01-05 and 2004-01-06  with ISBN 1590593189 having title Distributed in shared schema mode");

my $book = $book_rs->fetch($books->first->id);
is($book->id , $books->first->id, "1st book unearthed");

$schema->app(2);
$books = $book_rs->look_for({ title => { 'LIKE' , '%Distributed%' } });

my @res = $books->serialize;

diag(Dumper(@res));
is($books->count, 0, "Didn't find any books for application 2");

done_testing;
