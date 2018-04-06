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

# manually construct some gpx objects - the automatic _open() method doesnt
# let us send the output to a string
use_ok('GPX');
my $gpx0 = GPX->new();
my $gpx1 = GPX->new();
my $gpx2 = GPX->new();

my $gpx0_str = '';
my $gpx1_str = '';
my $gpx2_str = '';

my $gpx0_fh = IO::File->new(\$gpx0_str,'w');
my $gpx1_fh = IO::File->new(\$gpx1_str,'w');
my $gpx2_fh = IO::File->new(\$gpx2_str,'w');

$gpx0->output_file($gpx0_fh);
$gpx1->output_file($gpx1_fh);
$gpx2->output_file($gpx2_fh);

$obj->{gpx}{'__NONE.gpx'} = $gpx0;
$obj->{gpx}{split1} = $gpx1;
$obj->{gpx}{split2} = $gpx2;

use_ok('XML::Twig');
my $elt_name = XML::Twig::Elt->parse('<name>a name</name>');
my $elt_pt1 = XML::Twig::Elt->parse('<trkpt
    lat="-1.50" lon="-2.50">
    <ele>-100.50</ele>
    <time>2017-03-01T10:00:00Z</time></trkpt>');

my $elt_pt2 = XML::Twig::Elt->parse('<trkpt
    lat="1.50" lon="2.50">
    <ele>100.50</ele>
    <time>2017-02-02T01:30:00+10</time></trkpt>');

is($obj->add_trk_name($elt_name), $obj);
is($obj->add_trkseg(), $obj);
ok($obj->add_trkpt($elt_pt1));
ok($obj->add_trkpt($elt_pt2));

is($obj->flush(), $obj);

$gpx0_fh->close();
$gpx1_fh->close();
$gpx2_fh->close();

my $expect0 = <<EOF;
<gpx
 creator="HC GPX.pm"
 version="1.1"
 xmlns="http://www.topografix.com/GPX/1/1"
 >
</gpx>
EOF

my $expect1 = <<EOF;
<gpx
 creator="HC GPX.pm"
 version="1.1"
 xmlns="http://www.topografix.com/GPX/1/1"
 >
 <trk>
  <name>a name</name>
  <trkseg>
<trkpt lat="1.50" lon="2.50"><ele>100.50</ele><time>2017-02-02T01:30:00+10</time></trkpt>
  </trkseg>
 </trk>
</gpx>
EOF


my $expect2 = <<EOF;
<gpx
 creator="HC GPX.pm"
 version="1.1"
 xmlns="http://www.topografix.com/GPX/1/1"
 >
 <trk>
  <name>a name</name>
  <trkseg>
<trkpt lat="-1.50" lon="-2.50"><ele>-100.50</ele><time>2017-03-01T10:00:00Z</time></trkpt>
  </trkseg>
 </trk>
</gpx>
EOF

is($gpx0_str, $expect0);
is($gpx1_str, $expect1);
is($gpx2_str, $expect2);

# TODO coverage:
# _open
