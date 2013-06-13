use warnings;
use strict;

use lib "t/lib";

use Test::More 'no_plan';
use Data::Dumper;

BEGIN { use_ok 'Schema' }

my $dbname = "t/var/small.db";
my $schema = Schema->init_schema($dbname);

isa_ok($schema, 'DBIx::Class::Schema', "Schema initialised properly");

$schema->user(1);

my $author_rs = $schema->resultset("Author");

my $book_rs = $schema->resultset("Book");

done_testing;
