use Test::More 'no_plan';

use HC::Strptime;

my $parser = HC::Strptime->format();

# this works on all tested systems
isa_ok($parser->parse_datetime('2017-02-01T14:00:00+0000'), 'DateTime');

# this only works on some, however - this format is needed to support GPX files
isa_ok($parser->parse_datetime('2017-02-01T14:00:00Z'), 'DateTime');

#
# These are the only tested versions:
#
# Not working:
#  libdatetime-format-strptime-perl 1.5600-1
#
# Working:
#  libdatetime-format-strptime-perl 1.7500-1
#
