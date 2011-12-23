use strict;
use warnings;
use t::Util;
use Test::More;
use Test::Flatten;


my $grm = new_grm();


subtest 'returnd as scalar' => sub {
    my $stdout;

    $stdout = $grm->_exec_cmd('echo foo');
    is $stdout, 'foo';
};


subtest 'returned as array' => sub {
    my ($stdout, $stderr);

    ($stdout, $stderr) = $grm->_exec_cmd('echo foo');
    is $stdout, 'foo';
    is $stderr, '';

    ($stdout, $stderr) = $grm->_exec_cmd( q{perl -Mwarnings -e 'warn "foobar"'} );
    is $stdout, '';
    is $stderr, 'foobar at -e line 1.';
};


done_testing;
