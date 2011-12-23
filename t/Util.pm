package t::Util;
use strict;
use warnings;
use parent qw/Exporter/;
use App::gitrebasematsuri;
use File::Temp;
use Data::Dumper;

our @EXPORT = qw/
    new_grm
    d
    tempdir
    tempfile
    exec_commands
/;

$Data::Dumper::Terse = 1;


sub new_grm {
    return App::gitrebasematsuri->new;
}

sub d {
    return Dumper @_;
}

sub tempdir {
    return File::Temp::tempdir( CLEANUP => 1, @_ );
}

sub tempfile {
    return File::Temp::tempfile( DIR => tempdir(), @_ );
}

sub exec_commands {
    my @cmds = @_;
    my $ret = [];
    my $grm = new_grm;
    for my $cmd (@cmds) {
        my ($out, $err) = $grm->_exec_cmd($cmd);
        push @$ret, +{ cmd => $cmd, stdout => $out, stderr => $err };
    }
    return $ret;
}

1;
