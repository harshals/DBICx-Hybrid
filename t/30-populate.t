use warnings;
use strict;

use lib "t/lib";
use Schema;
use Master;

use Test::More;
use Text::CSV::Slurp;
use Data::Dumper;
use Archive::Zip;

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

my $user = 1;
my $app = 1;

$schema->user($user);
$schema->app($app);
$master->user($user);

my $zipped = "t/var/data.zip";
my $filename = "t/var/data.csv";

SKIP: {
	skip "unzipping the zipped version", 1 if -f $filename;
	ok( -f $zipped , "Found the zipped version");
	my $zip = Archive::Zip->new();
	unless ( $zip->read( $zipped) == Archive::Zip::AZ_OK ) {
		warn "Cannot open zip file";
		done_testing;
	}
	$zip->extractTree('', 't/var/');
}

ok(-f $filename, "Data filename found.");

my $data = Text::CSV::Slurp->load(file => $filename );

my $author_rs = $schema->resultset("Author");

my $book_rs = $schema->resultset("Book");

my $category_rs = $schema->resultset("Category");

my $affiliate_rs = $schema->resultset("Affiliate");

my $author_book_rs = $schema->resultset("AuthorBooks");

my $author_affiliate_rs = $schema->resultset("AuthorAffiliations");

my $author_category_rs = $schema->resultset("AuthorCategories");

my %base = ( active => 1, access_read => ",$user," , access_write => ",$user,", status => ",active," , data => '' , app_id => $app, log => "Updated On " . time() );

my $total_rows;

## override $total_rows
$total_rows = 20  if ($size =~ m/small/);
$total_rows = 500  if ($size =~ m/large/);
$total_rows = scalar(@$data) if ($size =~ m/very_large/);
#diag("inserting $total_rows rows just for kicks");

foreach my $row  (splice( @$data, 0, $total_rows)) {

	next unless $row->{ISBN};

	my ($category, $book, $category_id);

	$category = $category_rs->find_or_create({ category => $row->{'Discipline'} , %base}, { key => 'category_category' }) if $row->{Discipline};

	$category_id = (defined $category) ? $category->id : '';

	$book = $book_rs->find_or_create({
		isbn => $row->{ISBN},
		classification => $row->{Classification},
		price => $row->{Price},
		title => $row->{Title},
		publish_date => $row->{PubDate},
		publish_year => $row->{PrintYear},
		subtitle => $row->{Subtitle},
		description => $row->{Description},
		toc => $row->{TOC},
		category_id => $category_id,
		%base
	} , { key => 'book_isbn' });

	foreach my $author_id (1..5) {

		next unless $row->{"AuthorFirst$author_id"};

		my ($author, $affiliate);

		$affiliate = $affiliate_rs->find_or_create(
					{ affiliate	=>	$row->{ "AuthorAffiliation$author_id" }, %base },
					{ key => 'affiliate_affiliate' })
					if $row->{ "AuthorAffiliation$author_id" };

		$author = $author_rs->find_or_create(
					{ first_name => $row->{ "AuthorFirst$author_id" },
					  last_name => $row->{ "AuthorLast$author_id" },
					  review => $row->{Reviews},
					  country => $row->{AuthorCountry},
					  url => $row->{ "AuthorURL$author_id" }, %base },
					{ key => 'author_first_name_last_name' } );

		$author_affiliate_rs->find_or_create(
					{ author_id => $author->id,
						affiliate_id => $affiliate->id })
					if ($author && $affiliate);

		$author_book_rs->find_or_create(
					{ author_id => $author->id,
					  book_id => $book->id });

		$author_category_rs->find_or_create(
					{ author_id => $author->id,
					  category_id => $category->id })
					if ($author && $category);

	}

}

is($book_rs->count, $total_rows, "Found $total_rows books");

my $now = DateTime->now();

foreach $filename (qw/task contact attachment enumeration/) {

	my $path = "t/var/$filename.csv";

	$data = Text::CSV::Slurp->load(file => $path);

	my $rs = $schema->resultset(ucfirst($filename));

	my $count = 0;

	foreach my $row (@$data) {

		$count++;

		my $later = $now->clone->add( days => $count );

		next unless $row->{id};

		## hack to avoid null user id
		delete $row->{user_id} if ($filename eq 'contact' && !$row->{user_id});

		$row->{due_date} = $later->ymd if ($filename eq 'task' && $row->{task_status} eq 'Incomplete' );

		$rs->find_or_create({ %$row, %base }) ;

	}

	ok($rs, "inserted " . scalar(@$data) . " records in $filename");

}

foreach $filename (qw/user application/) {

	my $path = "t/var/$filename.csv";

	$data = Text::CSV::Slurp->load(file => $path);

	my $rs = $master->resultset(ucfirst($filename));

	foreach my $row  (@$data) {

		next unless $row->{id};
		$rs->find_or_create({ %$row, %base });

	}

	ok($rs, "inserted " . scalar(@$data) . " records in $filename");

}

## populating other tables

done_testing;
