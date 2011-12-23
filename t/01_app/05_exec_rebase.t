use strict;
use warnings;
use t::Util;
use Test::More;
use Test::Flatten;
use File::chdir;
use String::Random qw/random_regex/;
use Try::Tiny;


my $grm = new_grm;
$grm->{_NO_LOG} = 1;
my $GIT = $grm->{_GIT} = '/usr/bin/env git';


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


subtest 'simple simulation using git' => sub {
    subtest 'simple 1' => sub {
        local $CWD = tempdir();
        my $log;
        my $GIT_LOG = "$GIT log --pretty=oneline";

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

        $grm->exec_rebase('C', 'B');
        # master --- A ---- B --- C'

        is_deeply (
            commit_list( $grm->_exec_cmd("$GIT_LOG master..C") ),
            [
                @{commit_list( $grm->_exec_cmd("$GIT_LOG B..C") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG A..B") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG master..A") )},
            ],
        );
    };

    subtest 'simple 2' => sub {
        local $CWD = tempdir();
        my $log;
        my $GIT_LOG = "$GIT log --pretty=oneline";

        exec_commands (
            qq{ $GIT init },
            commands('touch_add_commit'),                  # branch master
            qq{ $GIT checkout -b A master },               # branch A - master
            ( map commands('touch_add_commit'), 1 .. 3 ),  # branch A - master
            qq{ $GIT checkout -b B A },                    # branch B - A
            ( map commands('touch_add_commit'), 1 .. 3 ),  # branch B - A
            qq{ $GIT checkout -b C A },                    # branch C - A
            ( map commands('touch_add_commit'), 1 .. 3 ),  # branch C - A
            qq{ $GIT checkout -b D A },                    # branch D - A
            ( map commands('touch_add_commit'), 1 .. 3 ),  # branch D - A
        );
        # master --- A ---- B
        #             \
        #              ---- C
        #              \
        #               --- D

        $grm->exec_rebase('D', 'C');
        $grm->exec_rebase('B', 'D');
        # master --- A ---- C --- D' --- B'

        is_deeply (
            commit_list( $grm->_exec_cmd("$GIT_LOG A..B") ),
            [
                @{commit_list( $grm->_exec_cmd("$GIT_LOG D..B") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG C..D") )},
                @{commit_list( $grm->_exec_cmd("$GIT_LOG A..C") )},
            ],
        );
    };
};


done_testing;
