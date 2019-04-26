package SplitList::Time;
use warnings;
use strict;
#
# Keep a list of timestamps to perform splits on
#

use List::MoreUtils qw( lastidx );
use HC::Strptime;

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

    # adding a new entry might invalidate any cache, thus:.
    delete $self->{cache};

    return 1;
}

# Adds a new split entry, expecting a string for the timestamp
# (TODO - expect an output object for the blob)
sub add_split {
    my $self = shift;
    my $timestamp_str = shift;
    my $entry = shift;

    my $dt = HC::Strptime->format()->parse_datetime($timestamp_str);
    return undef if (!defined($dt));

    return $self->_add_split($dt->epoch(),$entry);
}

# Return the split bucket that the given timestamp is found in
sub _lookup_bucket {
    my $self = shift;
    my $timestamp = shift;

    if (defined($self->{cache}{min})) {
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

sub lookup_bucket {
    my $self = shift;
    my $timestamp_str = shift;

    my $dt = HC::Strptime->format()->parse_datetime($timestamp_str);
    return undef if (!defined($dt));

    return $self->_lookup_bucket($dt->epoch());
}

# Return a list of buckets within the given timerange
sub _lookup_timerange {
    my $self = shift;
    my $timestamp1 = shift;
    my $timestamp2 = shift;

    my %seen;
    my @buckets;

    my $idx1 = lastidx { $_ <= $timestamp1 } @{$self->{index}};
    my $idx2 = lastidx { $_ < $timestamp2 } @{$self->{index}};

    for my $entry (@{$self->{entry}}[$idx1..$idx2]) {
        if (!defined ($seen{$entry})) {
            push @buckets, $entry;
        }
        $seen{$entry} ++;
    }
    return @buckets;
}

sub lookup_timerange {
    my $self = shift;
    my $timestamp1_str = shift;
    my $timestamp2_str = shift;

    my $dt1 = HC::Strptime->format()->parse_datetime($timestamp1_str);
    return undef if (!defined($dt1));
    my $dt2 = HC::Strptime->format()->parse_datetime($timestamp2_str);
    return undef if (!defined($dt2));

    return $self->_lookup_timerange($dt1->epoch(),$dt2->epoch());
}

# Return a list of all possible bucket names
sub buckets {
    my $self = shift;

    my %seen;
    my @buckets;

    for my $entry (@{$self->{entry}}) {
        if (!defined ($seen{$entry})) {
            push @buckets, $entry;
        }
        $seen{$entry} ++;
    }

    return @buckets;
}

sub parse_fd {
    my $self = shift;
    my $fd = shift;

    if (!defined($fd)) {
        # We have been handed a file handle that is not useful
        return undef;
    }

    my $prev_line;
    while(<$fd>) {
        s/#.*//; # comments
        s/^\s+//; # space at the beginning
        s/\s+$//; # space at the end
        next if (!$_); # skip anything that is now an empty line

        if (defined($prev_line)) {
            if (!$self->add_split($prev_line, $_)) {
                warn("Unparseable entry: $prev_line, $_\n");
            }
            $prev_line = undef;
        } else {
            $prev_line = $_;
        }
    }

    if (defined($prev_line)) {
        if (!$self->add_split($prev_line, '__END.gpx')) {
            warn("Unparseable entry: $prev_line, '__END.gpx'\n");
        }
    }

    return 1;
}

1;
