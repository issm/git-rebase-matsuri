use strict;
use warnings;
use t::Util;
use Test::More;

my $grm = new_grm();

my $t = << '...';
foo
bar
baz
...

my ($fh, $f) = tempfile;
print $fh $t;
close $fh;

is $grm->_slurp($f), $t;


done_testing;
