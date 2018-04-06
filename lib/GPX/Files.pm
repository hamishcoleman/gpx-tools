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
    my $return = $self;
    for my $gpx (values(%{$self->{gpx}})) {
        if (! $gpx->add_trkseg() ) {
            $return = undef;
        }
    }
    return $return;
}

sub add_trk_name {
    my $self = shift;
    my $elt = shift;
    my $return = $self;
    for my $gpx (values(%{$self->{gpx}})) {
        if (! $gpx->add_trk_name($elt) ) {
            $return = undef;
        }
    }
    return $return;
}

sub flush {
    my $self = shift;
    my $return = $self;
    for my $gpx (values(%{$self->{gpx}})) {
        if (! $gpx->flush() ) {
            $return = undef;
        }
    }
    return $return;
}

sub add_trkpt {
    my $self = shift;
    my $elt = shift;    

    my $gpxname;
    my $time_elt = $elt->first_child('time');
    if (!defined($time_elt)) {
        # Er..  I dont really have anything to do here
    } else {
        my $time = $time_elt->text();

        $gpxname = $self->{splitlist}->lookup_bucket($time);
    }

    # We had no match, use a bogus name
    if (!defined($gpxname)) {
        $gpxname = "__NONE.gpx";
    }

    my $gpx = $self->_open($gpxname);

    if (defined($self->{prev_gpxname}) and $self->{prev_gpxname} ne $gpxname) {
        $self->{prev_gpx}->close_trkseg();
    }
    $self->{prev_gpxname} = $gpxname;
    $self->{prev_gpx} = $gpx;

    $gpx->add_trkpt($elt);
}

1;
