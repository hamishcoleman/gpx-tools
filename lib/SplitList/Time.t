
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

my @buckets = sort $sl->_lookup_timerange(16,21);
is_deeply(\@buckets,
    [ 'test15', 'test20' ]
);

# two identical times, with different zones - to confirm the zones are working
is($sl->add_split('2017-02-02T01:00:00+10','dt1'), 1);
is($sl->{cache}{min}, undef, 'cache cleared by add_split');
is($sl->add_split('2017-02-02T01:00:00Z','dt2'), 1);

is($sl->lookup_bucket('2017-02-01T14:00:00Z'), 'test20');
is($sl->lookup_bucket('2017-02-01T15:00:00Z'), 'dt1');
is($sl->lookup_bucket('2017-02-02T02:00:00Z'), 'dt2');

@buckets = sort $sl->lookup_timerange('1970-01-01T00:00:16Z','2017-02-02T01:00:01+10');
is_deeply(\@buckets,
    [ 'dt1', 'test15', 'test20' ]
);


# an unparseable time string
is($sl->add_split('enotatime','foo'), undef);

@buckets = sort $sl->buckets();
is_deeply(\@buckets,
    [ 'dt1', 'dt2', 'test10', 'test15', 'test20' ]
);

#
use IO::File;

my $input = <<"EOM";
# Test input file
2017-02-01T14:00:00Z
    trip-1 # a comment
enotatime # a bad date line
    badline
2017-02-01T18:00:00Z
EOM

my $fh = IO::File->new(\$input,"r");

$sl = SplitList::Time->new();

ok($sl->parse_fd($fh));

is_deeply($sl, {
    'entry' => [
        'trip-1',
        '__END.gpx'
    ],
    'index' => [
        1485957600,
        1485972000
    ]
});
