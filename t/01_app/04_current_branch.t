use strict;
use warnings;
use t::Util;
use Test::More;
use Test::Flatten;
use File::chdir;
use Try::Tiny;


my $grm = new_grm;
$grm->{_NO_LOG} = 1;
my $GIT = $grm->{_GIT} = '/usr/bin/env git';


subtest 'simulation using git' => sub {
    local $CWD = ( my $dir = tempdir );
    my $commit_id;

    exec_commands (
        qq{ $GIT init },
        qq{ touch foo },
        qq{ $GIT add foo },
        qq{ $GIT commit -m "commit-1." },  # created master branch
    );

    is $grm->current_branch(), 'master';

    exec_commands (
        qq{ touch bar },
        qq{ $GIT add bar },
        qq{ $GIT commit -m "commit-2." },  # created master branch
        qq{ $GIT branch hoge },            # created branch "hoge"
    );

    is $grm->current_branch(), 'master';

    exec_commands (
        qq{ $GIT checkout hoge },  # created branch "hoge"
    );

    is $grm->current_branch(), 'hoge';


    # commit-id of 1 before "master" branch
    $commit_id = $grm->_exec_cmd(qq{ $GIT log --pretty=oneline | head -n 2 | tail -n 1 | awk '{print(\$1)}' });

    exec_commands (
        qq{ $GIT checkout hoge~ },
    );
    is $grm->current_branch, $commit_id;
};


done_testing;
