package SplitList;
#
# Keep a list of timestamps to perform splits on
#

use List::MoreUtils qw( firstidx lastidx );

sub new {
    my $class = shift;
    my $self = {};
    $self->{index} = [];
    $self->{entry} = [];
    bless($self, $class);
    return $self;
}

# Add a new split entry
# - timestamp in unixtime
# - entry is blob
# New entries must be in sorted order
sub _add_split {
    my $self = shift;
    my $timestamp = shift;
    my $entry = shift;

    my $prev_timestamp = $self->{index}[-1] || 0;

    if ($timestamp <= $prev_timestamp) {
        return undef;
        #die("split timestamps must be added in sorted order");
    }

    push @{$self->{index}}, $timestamp;
    push @{$self->{entry}}, $entry;
    return 1;
}

# Return the split bucket that the given timestamp is found in
sub _lookup_bucket {
    my $self = shift;
    my $timestamp = shift;

    if (defined($self->{cache})) {
        # we can check against the the cached values
        my $ts_min = $self->{cache}{min};
        my $ts_max = $self->{cache}{max};

        if ($ts_min <= $timestamp) {
            if (!defined($ts_max) || $timestamp < $ts_max) {
                return $self->{entry}[$self->{cache}{idx}];
            }
        }

        # cache failed, delete the data and fall through
        delete $self->{cache};
    }

    my $idx = lastidx { $_ <= $timestamp } @{$self->{index}};
    return undef if ($idx<0);

    $self->{cache}{idx} = $idx;
    $self->{cache}{min} = $self->{index}[$idx];
    $self->{cache}{max} = $self->{index}[$idx+1];

    return $self->{entry}[$idx];
}

1;
