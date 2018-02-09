
use Test::More 'no_plan';

my $class = 'GPX';
use_ok($class);

# TODO
# - call the _state method and confirm that transitioning from an invalid
#   state, or trying an invalide from/to pair does actually die

my $obj = $class->new();
isa_ok($obj, $class);

my $expect_gpx_head = "<gpx\n" .
    " creator=\"HC GPX.pm\"\n" .
    " version=\"1.1\"\n" .
    " xmlns=\"http://www.topografix.com/GPX/1/1\"\n" .
    " xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n";

is($obj->_add_trk_name('larry'), $expect_gpx_head);

my $expect_trk_head = " <trk>\n" .
    "  <name>larry</name>\n";

is($obj->_add_trkseg(), $expect_trk_head);
