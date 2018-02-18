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

sub _output_trk_head {
    my ($self) = @_;
    my $output;
    $output .= " <trk>\n";
    if (defined($self->{trk}{name})) {
        $output .= "  <name>" . $self->{trk}{name} . "</name>\n";
    }

    delete $self->{trk}{name};

    return $output;
}

my $transitions = {
    "<gpx>" => {
        newstate => 'in_gpx',
        string => <<"EOM",
<gpx
 creator="HC GPX.pm"
 version="1.1"
 xmlns="http://www.topografix.com/GPX/1/1"
 xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
EOM
    },
    "</gpx>" => {
        newstate => 'flush',
        string => "</gpx>\n",
    },
    "<trk>" => {
        newstate => 'in_trk',
        fn => \&_output_trk_head,
    },
    "</trk>" => {
        newstate => 'in_gpx',
        string => " </trk>\n",
    },
    "<trkseg>" => {
        newstate => 'in_trkseg',
        string => "  <trkseg>\n",
    },
    "</trkseg>" => {
        newstate => 'in_trk',
        string => "  </trkseg>\n",
    },
    "to in_gpx" => {
        newstate => 'in_gpx',
    },
    "to in_trkseg" => {
        newstate => 'in_trkseg',
    },
    "to has_trkpt" => {
        newstate => 'has_trkpt',
    },
    "to maybe_trk" => {
        newstate => 'maybe_trk',
    },
};

my $states = {
    'empty' => {
        'in_gpx'    => $transitions->{'<gpx>'},
        'has_trkpt' => $transitions->{'<gpx>'},
    },
    'in_gpx' => {
        'has_trkpt' => $transitions->{'to maybe_trk'},
        'maybe_trk' => $transitions->{'to maybe_trk'},
        'flush'     => $transitions->{'</gpx>'},
    },
    'in_trk' => {
        'in_gpx'    => $transitions->{'</trk>'},
        'maybe_trk' => $transitions->{'</trk>'},
        'has_trkpt' => $transitions->{'<trkseg>'},
        'flush'     => $transitions->{'</trk>'},
    },
    'in_trkseg' => {
        'in_gpx'    => $transitions->{'</trkseg>'},
        'in_trk'    => $transitions->{'</trkseg>'},
        'maybe_trk' => $transitions->{'</trkseg>'},
        'has_trkpt' => $transitions->{'to has_trkpt'},
        'flush'     => $transitions->{'</trkseg>'},
    },
    'has_trkpt' => {
        'in_trkseg' => $transitions->{'to in_trkseg'},
        'maybe_trk' => $transitions->{'to in_trkseg'},
        'in_gpx'    => $transitions->{'to in_trkseg'},
        'in_trk'    => $transitions->{'to in_trkseg'},
        'flush'     => $transitions->{'to in_trkseg'},
    },
    'maybe_trk' => {
        'has_trkpt' => $transitions->{'<trk>'},
        'in_gpx'    => $transitions->{'to in_gpx'},
        'flush'     => $transitions->{'to in_gpx'},
    },
};

# Change the current object state, which could flush some old data
sub _state {
    my ($self,$newstate) = @_;

    my $oldstate = $self->{state};
    my $output = '';

    # TODO - put a loop counter here

    while ($oldstate ne $newstate) {
        if (!defined($states->{$oldstate})) {
            die("Cannot transition from state $oldstate");
        }
        if (!defined($states->{$oldstate}{$newstate})) {
            die("Cannot transition from state $oldstate to $newstate");
        }

        my $transition = $states->{$oldstate}{$newstate};

        if (defined($transition->{string})) {
            $output .= $transition->{string};
        }
        if (defined($transition->{fn})) {
            $output .= $transition->{fn}($self);
        }
        if (defined($transition->{newstate})) {
            $self->{state} = $transition->{newstate};
        } else {
            $self->{state} = $newstate;
        }

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
    return $self->_state('maybe_trk');
}

sub _add_trkpt {
    my ($self, $lat, $lon, $ele, $time) = @_;
    # TODO - support trkpt extensions

    my @output;

    # As this is a terminal state (it doesnt open any new state)
    # we first ensure that we are in the needed starting state.
    # FIXME - this terminal state is starting to look like a hack.
    if ($self->{state} ne 'has_trkpt') {
        # avoid making a sub call if we can
        push @output, $self->_state('has_trkpt');
    }

    # and then output the data immediately
    push @output, '<trkpt lat="', $lat, '" lon="', $lon, '">';

    # You can get a GPS lock without enough details to get a height, so I
    # assume that sometimes there is no ele tag
    if (defined($ele)) {
        push @output, '<ele>', $ele, '</ele>';
    }

    # You can write a GPX file without time elements, which is naff, but has
    # happened
    if (defined($time)) {
        push @output, '<time>', $time, '</time>';
    }

    push @output, "</trkpt>\n";

    return @output;
}

sub _close_trkseg {
    my ($self) = @_;

    # if we have a trkseg open, we want to close it
    if ($self->{state} eq 'has_trkpt' or $self->{state} eq 'in_trkseg') {
        return $self->_state('in_trk');
    }

    # otherwise, do nothing
    return '';
}

sub _flush {
    my ($self) = @_;
    return $self->_state('flush');
}

####
# an XML::Elt interface - which can be called from handler functions

sub output_file {
    my ($self, $fh) = @_;
    $self->{fh} = $fh;
    return 1;
}

sub add_trk_name {
    my ($self, $elt) = @_;

    $self->{fh}->print($self->_add_trk_name($elt->text()));
}

sub add_trkseg {
    my ($self, $elt) = @_;

    $self->{fh}->print($self->_add_trkseg());
}

sub add_trkpt {
    my ($self, $elt) = @_;

    my $ele_text;
    my $ele = $elt->first_child('ele');
    if (defined($ele)) {
        $ele_text = $ele->text();
    }

    my $time_text;
    my $time = $elt->first_child('time');
    if (defined($time)) {
        $time_text = $time->text();
    }

    $self->{fh}->print($self->_add_trkpt(
        $elt->{'att'}->{'lat'},
        $elt->{'att'}->{'lon'},
        $ele_text,
        $time_text,
    ));
}

sub close_trkseg {
    my ($self, $elt) = @_;

    $self->{fh}->print($self->_close_trkseg());
}

sub flush {
    my ($self) = @_;

    $self->{fh}->print($self->_flush());
}

sub _output_graphviz {
    use Scalar::Util qw(refaddr);

    # Create a back-ref index of the transition names
    my $transitions_ref;
    for my $transition_name (keys(%{$transitions})) {
        my $transition = $transitions->{$transition_name};
        $transitions_ref->{refaddr($transition)} = $transition_name;
    }

    print("# Automatically generated state diagram\n");
    print("#\n");
    print("digraph g {\n");
    print("\n");

    print("# state names\n");
    for my $state (sort(keys(%{$states}))) {
        print("    $state;\n");
    }
    print("\n");
    print("# state transitions\n");
    while (my ($name, $state) = each(%{$states})) {
        my $seen;
        for my $transition (values(%{$state})) {
            my $newstate = $transition->{newstate};
            next if (defined($seen->{$newstate}));
            my $transition_name = $transitions_ref->{refaddr($transition)};
            print("    $name -> $newstate [label=\"$transition_name\"];\n");
            $seen->{$newstate}++;
        }
    }

    # TODO
    # - figure out a way to show the allowed end-state names for each
    #   transition path.

    print("}\n");
}

unless (caller) {
    # only generate output if we are called as a CLI tool
    _output_graphviz();
}

1;
