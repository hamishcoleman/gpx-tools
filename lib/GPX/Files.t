use warnings;
use strict;

use Test::More 'no_plan';

my $class = 'GPX::Files';
use_ok($class);

my $obj = $class->new();
isa_ok($obj,$class);

