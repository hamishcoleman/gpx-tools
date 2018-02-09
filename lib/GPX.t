
use Test::More 'no_plan';

my $class = 'GPX';
use_ok($class);

my $obj = $class->new();
isa_ok($obj, $class);


