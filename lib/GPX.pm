package GPX;
use warnings;
use strict;
#
# Represent and operate on bits of GPX files
#
# Ingest XML::Twig elements to modify the current state of the GPX stream.
# each modification might result in old state being streamed out.
#

sub new {
    my $class = shift;
    my $self = {};
    $self->{state} = 'empty';
    bless($self, $class);
    return $self;
}

sub _output_gpx_head {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= "<gpx\n";
    $output .= " creator=\"HC GPX.pm\"\n";
    $output .= " version=\"1.1\"\n";
    $output .= " xmlns=\"http://www.topografix.com/GPX/1/1\"\n";
    $output .= " xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n";

    $self->{state} = $newstate;

    return $output;
}

sub _output_trk_head {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= " <trk>\n";
    $output .= "  <name>" . $self->{trk}{name} . "</name>\n";

    delete $self->{trk}{name};
    $self->{state} = $newstate;

    return $output;
}

sub _output_trkseg_head {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= "  <trkseg>\n";

    $self->{state} = $newstate;

    return $output;
}

my $states = {
    'empty' => {
        'have_trk_name' => \&_output_gpx_head,
    },
    'have_trk_name' => {
        'have_trkseg' => \&_output_trk_head,
    },
    'have_trkseg' => {
        'have_trkpt' => \&_output_trkseg_head,
    },
};

# Change the current object state, which could flush some old data
sub _state {
    my ($self,$newstate) = @_;

    my $oldstate = $self->{state};
    my $output;

    # TODO - put a loop counter here

    while ($oldstate ne $newstate) {
        if (!defined($states->{$oldstate})) {
            die("Cannot transition from state $oldstate");
        }
        if (!defined($states->{$oldstate}{$newstate})) {
            die("Cannot transition from state $oldstate to $newstate");
        }

        $output .= $states->{$oldstate}{$newstate}($self, $oldstate, $newstate);
        $oldstate = $self->{state};
    }
    return $output;
}

# record the name for this trk
sub _add_trk_name {
    my ($self,$name) = @_;

    $self->{trk}{name} = $name;
    return $self->_state('have_trk_name');
}

sub _add_trkseg {
    my ($self) = @_;
    return $self->_state('have_trkseg');
}

sub _add_trkpt {
    my ($self, $lat, $lon, $ele, $time) = @_;
    # TODO - support trkpt extensions

    $self->{trk}{trkseg}{trkpt}{lat} = $lat;
    $self->{trk}{trkseg}{trkpt}{lon} = $lat;
    $self->{trk}{trkseg}{trkpt}{ele} = $lat;
    $self->{trk}{trkseg}{trkpt}{time} = $lat;

    return $self->_state('have_trkpt');
}

1;
