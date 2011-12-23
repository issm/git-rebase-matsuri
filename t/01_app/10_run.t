use strict;
use warnings;
use t::Util;
use Test::More;
use Test::Flatten;
use File::chdir;
use String::Random qw/random_regex/;
use Try::Tiny;


my $GIT     = '/usr/bin/env git';
my $GIT_LOG = "$GIT log --pretty=oneline";

sub commit_list {
    my $log = shift;
    my $ret = [ map { ( split / +/ )[0] } split /\n/, $log || '' ];
    return $ret;
}

sub commands {
    my $type = shift;
    # touch - add - commit
    if ( $type eq 'touch_add_commit' ) {
        my $file    = random_regex('\w{16}');
        my $comment = random_regex('\w{64}');
        return ( qq{ touch $file }, qq{ $GIT add $file }, qq{ $GIT commit -m $comment } );
    }
}


subtest 'show version' => sub {
    subtest 'option: -V' => sub {
        my ($fh, $f) = tempfile();
        open $fh, '>', $f  or  die "$f: $!";
        no strict 'refs';
        local *STDOUT = $fh;
        my $exit = new_grm->run(qw/ -V /);
        close $fh;
        is $exit, 0;
        is new_grm->_slurp($f), "git-rebase-matsuri (App::gitrebasematsuri) $App::gitrebasematsuri::VERSION\n";
    };

    subtest 'option: --version' => sub {
        my ($fh, $f) = tempfile();
        open $fh, '>', $f  or  die "$f: $!";
        no strict 'refs';
        local *STDOUT = $fh;
        my $exit = new_grm->run(qw/ --version /);
        close $fh;
        is $exit, 0;
        is new_grm->_slurp($f), "git-rebase-matsuri (App::gitrebasematsuri) $App::gitrebasematsuri::VERSION\n";
    };
};


subtest 'simple simulation using git' => sub {
    subtest 'simple 1' => sub {
        local $CWD = tempdir();

        my $grm = new_grm;
        $grm->{_NO_LOG} = 1;

        my $log;

        exec_commands (
            qq{ $GIT init },
            commands('touch_add_commit'),                  # branch master
            qq{ $GIT checkout -b A master },               # branch A - master
            ( map commands('touch_add_commit'), 1 .. 3 ),  # branch A - master
            qq{ $GIT checkout -b B A },                    # branch B - A
            ( map commands('touch_add_commit'), 1 .. 3 ),  # branch B - A
            qq{ $GIT checkout -b C A },                    # branch C - A
            ( map commands('touch_add_commit'), 1 .. 3 ),  # branch C - A
        );
        # master --- A ---- B
        #             \
        #              --- C

        my ($fh, $conf_file) = tempfile();
        open $fh, '>', $conf_file or die "$conf_file: $!";
        my $out = << '        ...';
B -> C
        ...
        print $fh $out;
        close $fh;

        $grm->run( '-c', $conf_file );  # no "--doit"
        # tree is not changed
        is_deeply (
            commit_list( $grm->_exec_cmd("$GIT_LOG master..B") ),
            [
                @{commit_list( $grm->_exec_cmd("$GIT_LOG A..B") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG master..A") )},
            ],
        );
        is_deeply (
            commit_list( $grm->_exec_cmd("$GIT_LOG master..C") ),
            [
                @{commit_list( $grm->_exec_cmd("$GIT_LOG A..C") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG master..A") )},
            ],
        );

        $grm->run( '-c', $conf_file, '--doit' );
        # master --- A ---- C --- B'

        is_deeply (
            commit_list( $grm->_exec_cmd("$GIT_LOG master..B") ),
            [
                @{commit_list( $grm->_exec_cmd("$GIT_LOG C..B") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG A..C") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG master..A") )},
            ],
        );
    };
};


done_testing;
