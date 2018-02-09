
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

my $expect_trkseg_head = "  <trkseg>\n" .
    "   <trkpt lat=\"22.3\" lon=\"113.9\">\n" .
    "    <ele>-22.45</ele>\n" .
    "    <time>2018-01-19T14:01:33Z</time>\n" .
    "   </trkpt>\n";

is($obj->_add_trkpt('22.3','113.9',-22.45,'2018-01-19T14:01:33Z'), $expect_trkseg_head);

my $expect_flush =
    "  </trkseg>\n" .
    " </trk>\n" .
    "</gpx>\n";

is($obj->_flush(), $expect_flush);
