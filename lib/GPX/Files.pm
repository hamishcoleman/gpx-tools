package GPX::Files;
use warnings;
use strict;
#
# Keep a database of named GPX objects, each with an open output file
# 
# handle XML::Twig events and route them either to all objects or, in the
# case of trkpt events, perform a splitlist lookup and send to just one
# of the objects

# TODO
# - the current filtering is a hack.
#   instead, a bucket name to output filehandle hash should be given to
#   the object, which allows the caller to manage the destination for
#   all the output, and buckets without an entry in the hash could just
#   be filtered.
#   it would also allow tests to be written for the _open function.

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

    # TODO
    # - stdout hack should go as part of filtering
    my $fh;
    if ($gpxname eq '-') {
        $fh = *STDOUT;
    } else {
        $fh = IO::File->new($gpxname,"w");
    }

    my $gpx = GPX->new();
    $gpx->output_file($fh);

    $self->{gpx}{$gpxname} = $gpx;
    return $gpx;
}

sub set_splitlist {
    my $self = shift;
    $self->{splitlist} = shift;
    return $self->{splitlist};
}

# TODO
# - filtering should be replaced
sub set_filter2console {
    my $self = shift;
    $self->{filter2console} = shift;
    return $self->{filter2console};
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

    my $gpx;
    # TODO
    # - filtering should be replaced
    if (defined($self->{filter2console})) {
        if ($gpxname eq $self->{filter2console}) {
            $gpx = $self->_open('-');
        } else {
            $gpx = undef;
        }
    } else {
        $gpx = $self->_open($gpxname);
    }

    if (defined($self->{prev_gpxname}) and $self->{prev_gpxname} ne $gpxname) {
        if (defined($self->{prev_gpx})) {
            $self->{prev_gpx}->close_trkseg();
        }
    }
    $self->{prev_gpxname} = $gpxname;
    $self->{prev_gpx} = $gpx;

    if (defined($gpx)) {
        $gpx->add_trkpt($elt);
    }
}

1;
