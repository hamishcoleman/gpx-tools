
use Test::More 'no_plan';

use_ok('SplitList');

my $sl = SplitList->new();
isa_ok($sl,'SplitList');

is($sl->_add_split(10,'test10'), 1);
is($sl->_add_split(5,'test5'), undef, "Adding out-of-order should fail");
is($sl->_add_split(15,'test15'), 1);
is($sl->_add_split(20,'test20'), 1);

is($sl->_lookup_bucket(6), undef, 'cannot match anything');
is($sl->_lookup_bucket(15), 'test15', 'start of test15 (no cache yet)');
is($sl->_lookup_bucket(16), 'test15', 'test15 (should use cache of test15)');
is($sl->_lookup_bucket(11), 'test10', 'test11 (should fail cache of test15)');
is($sl->_lookup_bucket(17), 'test15', 'test15 (should fail cache of test10)');
is($sl->_lookup_bucket(20), 'test20', 'start of test20 (should fail cache of test10');
is($sl->_lookup_bucket(21), 'test20', 'test20 (should use cache with no max ts)');

is($sl->add_split('2017-02-02T01:00:00+10','dt1'), 1);
is($sl->add_split('2017-02-02T01:00:00Z','dt2'), 1);
is($sl->add_split('enotatime','foo'), undef);
