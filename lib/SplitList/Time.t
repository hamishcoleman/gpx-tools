
use Test::More 'no_plan';

my $class = 'SplitList::Time';
use_ok($class);

my $sl = SplitList::Time->new();
isa_ok($sl,$class);

is($sl->_add_split(10,'test10'), 1);
is($sl->_add_split(5,'test5'), undef, "Adding out-of-order should fail");
is($sl->_add_split(15,'test15'), 1);
is($sl->_add_split(20,'test20'), 1);

is($sl->_lookup_bucket(6), undef, 'cannot match anything');
is($sl->{cache}{min}, undef, 'should have no cache');
is($sl->_lookup_bucket(15), 'test15', 'start of test15 (no cache yet)');
is($sl->{cache}{min}, 15, 'should have filled the cache');
is($sl->_lookup_bucket(16), 'test15', 'test15 (should use cache of test15)');
is($sl->{cache}{min}, 15, 'cache didnt change');
is($sl->_lookup_bucket(16), 'test15', 'test15 (should use cache of test15)');
is($sl->{cache}{min}, 15, 'cache didnt change');
is($sl->_lookup_bucket(11), 'test10', 'test11 (should fail cache of test15)');
is($sl->{cache}{min}, 10, 'cache changed');
is($sl->_lookup_bucket(17), 'test15', 'test15 (should fail cache of test10)');
is($sl->{cache}{min}, 15, 'cache changed');
is($sl->_lookup_bucket(20), 'test20', 'start of test20 (should fail cache of test10');
is($sl->{cache}{min}, 20, 'cache changed');
is($sl->_lookup_bucket(21), 'test20', 'test20 (should use cache with no max ts)');
is($sl->{cache}{min}, 20, 'cache didnt change');

# two identical times, with different zones - to confirm the zones are working
is($sl->add_split('2017-02-02T01:00:00+1000','dt1'), 1);
is($sl->{cache}{min}, undef, 'cache cleared by add_split');
is($sl->add_split('2017-02-02T01:00:00+0000','dt2'), 1);

is($sl->lookup_bucket('2017-02-01T14:00:00+0000'), 'test20');
is($sl->lookup_bucket('2017-02-01T15:00:00+0000'), 'dt1');
is($sl->lookup_bucket('2017-02-02T02:00:00+0000'), 'dt2');

# an unparseable time string
is($sl->add_split('enotatime','foo'), undef);
