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

    $self->{state} = 'in_gpx';

    return $output;
}

sub _output_gpx_tail {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= "</gpx>\n";

    $self->{state} = "flush";

    return $output;
}

sub _output_trk_head {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= " <trk>\n";
    if (defined($self->{trk}{name})) {
        $output .= "  <name>" . $self->{trk}{name} . "</name>\n";
    }

    delete $self->{trk}{name};
    $self->{state} = 'in_trk';

    return $output;
}

sub _output_trk_tail {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= " </trk>\n";

    $self->{state} = "in_gpx";

    return $output;
}

sub _output_trkseg_head {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= "  <trkseg>\n";

    $self->{state} = 'in_trkseg';

    return $output;
}

sub _output_trkseg_tail {
    my ($self, $oldstate, $newstate) = @_;
    my $output;
    $output .= "  </trkseg>\n";

    $self->{state} = "in_trk";

    return $output;
}

my $states = {
    'empty' => {
        'in_gpx' => \&_output_gpx_head,
    },
    'in_gpx' => {
        'in_trk' => \&_output_trk_head,
        'flush'  => \&_output_gpx_tail,
    },
    'in_trk' => {
        'in_trkseg' => \&_output_trkseg_head,
        'flush'     => \&_output_trk_tail,
    },
    'in_trkseg' => {
        'in_trk' => \&_output_trkseg_tail,
        'flush'  => \&_output_trkseg_tail,
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
    return $self->_state('in_gpx');
}

sub _add_trkseg {
    my ($self) = @_;
    return $self->_state('in_trk');
}

sub _add_trkpt {
    my ($self, $lat, $lon, $ele, $time) = @_;
    # TODO - support trkpt extensions

    my $output;

    # As this is a terminal state (it doesnt open any new state)
    # we first ensure that we are in the needed starting state
    $output .= $self->_state('in_trkseg');

    # and then output the data immediately
    $output .= sprintf(
        "   <trkpt lat=\"%s\" lon=\"%s\">\n" .
        "    <ele>%s</ele>\n" .
        "    <time>%s</time>\n" .
        "   </trkpt>\n",
        $lat,
        $lon,
        $ele,
        $time,
    );

    return $output;
}

sub _flush {
    my ($self) = @_;
    return $self->_state('flush');
}
1;
