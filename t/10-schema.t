#
#===============================================================================
#
#         FILE:  01-schema.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Harshal Shah (Hs), <harshal.shah@gmail.com>
#      COMPANY:  MK Software
#      VERSION:  1.0
#      CREATED:  12/18/2010 12:19:20 IST
#     REVISION:  ---
#===============================================================================
use strict;
use warnings;

use Test::More;
use lib "t/lib";

BEGIN {

	use_ok('Schema');

	foreach my $class ( qw/Book Author Category Affiliate AuthorCategories AuthorAffiliations AuthorBooks Task Contact Attachment/) {

		use_ok("Schema::Result::$class");

	}

	foreach my $class ( qw/Book Author Task Contact Enumeration/) {

		use_ok( "Schema::ResultSet::$class");

	}

	use_ok('Master');

	foreach my $class ( qw/ User Application /) {

		use_ok("Master::Result::$class");

	}

	foreach my $class ( qw/Book Author Contact Task /) {

		use_ok("Schema::ResultSet::$class");

	}

	use_ok("Master::ResultSet::User");

}

done_testing;
