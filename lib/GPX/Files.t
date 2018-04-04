use warnings;
use strict;

use Test::More 'no_plan';

my $class = 'GPX::Files';
use_ok($class);

my $obj = $class->new();
isa_ok($obj,$class);

# set_splitlist
# Simply prove that what we set is stored
my $fake_splitlist_object = "FAKE xyzzy";
is($obj->set_splitlist($fake_splitlist_object), $fake_splitlist_object);

# TODO coverage:
# _open
# add_trkseg
# add_trk_name
# flush
# add_trkpt
