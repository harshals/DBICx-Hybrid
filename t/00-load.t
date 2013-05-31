use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

BEGIN {
	use_ok( 'DBICx::Hybrid');
	use_ok( 'DBICx::Hybrid::Result');
	use_ok( 'DBICx::Hybrid::ResultClass');
	use_ok( 'DBICx::Hybrid::ResultSet');
}

diag( "Testing DBICx::Hybrid  $DBICx::Hybrid::VERSION, Perl $], $^X" );

