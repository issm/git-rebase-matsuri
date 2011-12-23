use strict;
use warnings;
use t::Util;
use Test::More;

my $grm = new_grm();
isa_ok $grm, 'App::gitrebasematsuri', 'isa_ok';

done_testing;
