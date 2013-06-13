use warnings;
use strict;

use lib "t/lib";
use Schema;
use Master;

use Test::More ;
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
my $master = Master->init_schema("t/var/master.db");

my $user = 1;
my $app = 1;

$schema->user($user);
$master->user($user);

$schema->app($app);
$schema->shared(1);

$user = $master->resultset("User")->find($user);
ok($user, "Found User Object");

my $contact_rs = $schema->resultset("Contact");

my $profile = $contact_rs->profile($user->id);

is($contact_rs->count, 14 , "Found all my contacts");

is($contact_rs->search({ business_city => 'Mumbai'})->count , 3 , "Found my Mumbai Contact");

is($profile->tasks->due_in(3)->count , 1 , "Found one task due in coming 5 days");

my $company = $contact_rs->company('CSI_Industries');
is($company->employees->count, 3, "Found 3 employes of CSI Industries");
is($company->employees->search( { name => { 'LIKE' , '%Hug%' }  })->count, 1,
	" Show all my contacts whih work for company A who have last_name as `Hug`");

my $contact_a = $contact_rs->search({ name => 'Hugo@csindustries.com' } )->single;
is($contact_a->tasks->incomplete_tasks->count, 2, "Found 2 incomplete tasks for Hugo");

#--Show me all the tasks assigned to Contact "A" which were not completed on time last year
#--Show me all contacts who have >90% on time task completion rate between date "A" and date "B" and reside in city "X" or "Y"

is($company->search_related("employees", { title => "Director" })->count, 1, "All employees for company A having job title Director");
is($contact_a->attachments->count, 2, "User A has two documents attached");
is($contact_a->search_related("attachments", { keywords => { 'LIKE', '%cat%'  } } )->count, 1,
	"User Hugo has one document attached with keyword cat");

is($contact_a->attachments->created_in(2)->count,2,
	"User A has uploaded 1 attachment in last 1 day");

#--Update all the contacts with company "A" to company "B"

#ok($company->employees->search({ name => 'Jane@csindustries.com' })->single->delete, "Delted employee Jane from company ");

#--Update all Tasks which I assigned to "A" as "complete"

my $new_company = $contact_rs->fetch_new();
$new_company->save({
	name => 'Harshal@csindustries.com',
	company_id => $company->id,
	business_city => "Mumbai",
	primary_phone => '12312312',
	email => 'crap@adas.com',
	title => 'Partner',
	is_human => 1
});

ok($new_company, "Created new contact Harshal for Company  having city C and primary phone and email");

#--create a new task "A" with due date "B" and description "C"

#--update due date and description of Task "A"

#--Delete document "B" associated with user "A"

done_testing;
