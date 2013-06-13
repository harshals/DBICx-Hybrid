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

foreach my $source ($schema->sources) {

	my $rs = $schema->resultset($source);
	isa_ok($rs, 'DBICx::Hybrid::ResultSet');

}

is($schema->user, 1, "Schema user set to 1 ");

$schema->app(1);
is($schema->app, 1, "Schema App set to 1 ");
ok(!$schema->shared, "Default setting is not shared ");

my $author_rs = $schema->resultset("Author");
isa_ok($author_rs, 'Schema::ResultSet::Author');

my $book_rs = $schema->resultset("Book");
isa_ok($book_rs, 'Schema::ResultSet::Book');

done_testing;
