use warnings;
use strict;

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
    " >\n";

is($obj->_add_trk_name('larry'), $expect_gpx_head);


is($obj->_add_trkseg(), '');

my $expect_trkseg_head = " <trk>\n" .
    "  <name>larry</name>\n" .
    "  <trkseg>\n" .
    "<trkpt lat=\"22.3\" lon=\"113.9\"><ele>-22.45</ele><time>2018-01-19T14:01:33Z</time></trkpt>\n";

is(join('',$obj->_add_trkpt('22.3','113.9',-22.45,'2018-01-19T14:01:33Z')), $expect_trkseg_head);

my $expect_trkpt2 = "<trkpt lat=\"22.4\" lon=\"113.8\"><time>2018-01-19T14:01:40Z</time></trkpt>\n";
is(join('',$obj->_add_trkpt('22.4','113.8',undef,'2018-01-19T14:01:40Z')), $expect_trkpt2);

my $expect_flush =
    "  </trkseg>\n" .
    " </trk>\n" .
    "</gpx>\n";

is($obj->_flush(), $expect_flush);

use XML::Twig;
use IO::File;

my $t = XML::Twig->new();

$obj = $class->new();
isa_ok($obj, $class);

my $output;
my $output_fh = IO::File->new(\$output,"w");

ok($obj->output_file($output_fh));

$t->parse('<name>larry</name>');
ok($obj->add_trk_name($t->root()));
is($output, $expect_gpx_head);

$output = '';
$output_fh->seek(0,0);
$t->parse('<trkseg><foo>foo2</foo></trkseg>');
ok($obj->add_trkseg($t->root()));
is($output, '');

$output = '';
$output_fh->seek(0,0);
$t->parse('<trkpt lat="22.3" lon="113.9"><ele>-22.45</ele><time>2018-01-19T14:01:33Z</time></trkpt>');
ok($obj->add_trkpt($t->root()));
is($output, $expect_trkseg_head);

$output = '';
$output_fh->seek(0,0);
ok($obj->flush());
is($output, $expect_flush);

# TODO
# - decide if I should be checking the output of the state transitions.
ok(defined(GPX->_output_graphviz()));
