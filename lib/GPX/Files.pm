package GPX::Files;
use warnings;
use strict;
#
# Keep a database of named GPX objects, each with an open output file
# 
# handle XML::Twig events and route them either to all objects or, in the
# case of trkpt events, perform a splitlist lookup and send to just one
# of the objects

use IO::File;
use GPX;

sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

# open a new name
sub _open {
    my $self = shift;
    my $gpxname = shift;

    if (defined($self->{gpx}{$gpxname})) {
        return $self->{gpx}{$gpxname};
    }

    my $gpx = GPX->new();
    my $fh = IO::File->new($gpxname,"w");
    $gpx->output_file($fh);

    $self->{gpx}{$gpxname} = $gpx;
    return $gpx;
}

sub set_splitlist {
    my $self = shift;
    $self->{splitlist} = shift;
    return $self->{splitlist};
}

sub add_trkseg {
    my $self = shift;
    for my $gpx (values(%{$self->{gpx}})) {
        $gpx->add_trkseg();
    }
}

sub add_trk_name {
    my $self = shift;
    my $elt = shift;
    for my $gpx (values(%{$self->{gpx}})) {
        $gpx->add_trk_name($elt);
    }
}

sub flush {
    my $self = shift;
    for my $gpx (values(%{$self->{gpx}})) {
        $gpx->flush();
    }
}

sub add_trkpt {
    my $self = shift;
    my $elt = shift;    

    my $time = $elt->first_child('time')->text();
    my $gpxname = $self->{splitlist}->lookup_bucket($time);

    # We had no match, use a bogus name
    if (!defined($gpxname)) {
        $gpxname = "NONE";
    }

    my $gpx = $self->_open($gpxname);
    $gpx->add_trkpt($elt);
}

1;
