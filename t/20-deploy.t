use warnings;
use strict;

use lib "t/lib";

use Data::Printer;
use Test::More ;

BEGIN { use_ok 'Master' };
BEGIN { use_ok 'Schema' };

#diag("Remove old database if it exists");

my %args = ( @ARGV );
my $size = $args{"size"}  || "small";
my $dbname =  $args{"dbname"} || "t/var/" . $size . ".db";
my $masterdb = "t/var/master.db";
my $dbtype = $args{"dbtype"} || "SQLite";
my $password = $args{"p"};
my $username = $args{"u"};
my $host = $args{"h"};

##auto correct db types

$dbtype = "SQLite" if $dbtype =~ /sqlite/i;
$dbtype = "mysql" if $dbtype =~ /mysql/i;
$dbtype = "PostgreSQL" if $dbtype =~ /pg|postgre/i;

like($dbtype,qr/SQLite|mysql|PostgreSQL/, "Found Correct DB Type");

SKIP: {
	skip "Only Mysql or PostgresSQL specific test", 1 if $dbtype eq 'SQLite';
	ok($dbname && $username && $password && $host, "Found correct DSN");
}

SKIP: {
	skip "Only SQLite specific test", 1 unless $dbtype eq 'SQLite';
	`rm -f $dbname` if -f $dbname;
	`rm -f $masterdb` if -f $masterdb;
	ok(! (-f $dbname), "No existing database");
}

my $schema = Schema->init_schema($dbname, $dbtype, $username, $password , $host);

my $master = Master->init_schema($masterdb, $dbtype, $username, $password , $host);

isa_ok($schema, 'DBIx::Class::Schema', "Schema initialised properly");

isa_ok($master, 'DBIx::Class::Schema', "Master Schema initialised properly");

$schema->user(1);

$master->user(1);

SKIP: {
	skip "Only SQLite specific test", 1 unless $dbtype eq 'SQLite';

	$schema->create_ddl_dir(['SQLite'], '1', 't/var', undef, { add_drop_table => 0 });
	my $filename = $schema->ddl_filename('SQLite', '1', 't/var');
	`sqlite3 $dbname < $filename`;
	#`sqlite3 $dbname < Schema-1.x-$dbtype.sql`;
	ok(-f $dbname, "Deployed $dbname database");

	$master->create_ddl_dir(['SQLite'], '1', 't/var', undef, { add_drop_table => 0 });
	$filename = $master->ddl_filename('SQLite', '1', 't/var');
	`sqlite3 $masterdb < $filename`;
	#`sqlite3 $dbname < Schema-1.x-$dbtype.sql`;
	ok(-f $masterdb , "Deployed $masterdb database");
}

SKIP: {
	skip "Only Mysql or PostgresSQL specific test", 1 if $dbtype eq 'SQLite';

	$schema->deploy;
	$master->deploy;

	isa_ok($schema->storage, "DBIx::Class::Storage", "Deployed $dbname database");
	isa_ok($master->storage, "DBIx::Class::Storage", "Deployed $masterdb database");
}

is($schema->user, 1, "Schema user set to 1 ");

my $author_rs = $schema->resultset("Author");
isa_ok($author_rs, 'Schema::ResultSet::Author');

my $book_rs = $schema->resultset("Book");
isa_ok($book_rs, 'DBICx::Hybrid::ResultSet');

my $category_rs = $schema->resultset("Category");
isa_ok($category_rs, 'DBICx::Hybrid::ResultSet');

my $affiliate_rs = $schema->resultset("Affiliate");
isa_ok($affiliate_rs, 'DBICx::Hybrid::ResultSet');

is($master->user, 1, "Master user set to 1 ");

my $user_rs = $master->resultset("User");
isa_ok($user_rs, 'Master::ResultSet::User');

done_testing;
