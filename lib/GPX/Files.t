use warnings;
use strict;

use Test::More 'no_plan';

my $class = 'GPX::Files';
use_ok($class);

my $obj = $class->new();
isa_ok($obj,$class);

use_ok('SplitList::Time');
my $splitlist = SplitList::Time->new();
isa_ok($splitlist,'SplitList::Time');

is($splitlist->add_split('2017-02-02T01:00:00+10','split1'), 1);
is($splitlist->add_split('2017-02-02T02:00:00+10','split2'), 1);

# set_splitlist
# Simply prove that what we set is stored
is($obj->set_splitlist($splitlist), $splitlist);

# TODO coverage:
# _open
# add_trkseg
# add_trk_name
# flush
# add_trkpt
