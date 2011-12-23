use strict;
use warnings;
use t::Util;
use Test::More;
use Test::Flatten;
use Try::Tiny;


my $grm = new_grm;
$grm->{_NO_LOG} = 1;


subtest 'valid, simbols' => sub {
    subtest 'using "->"' => sub {
        my $conf = $grm->parse_config( << '        ...' );
foo -> base
bar -> base
baz -> bar
        ...

        isa_ok $conf->{rebase_rules}, 'ARRAY';
        is_deeply $conf->{rebase_rules}, [
            { from => 'foo', onto => 'base' },
            { from => 'bar', onto => 'base' },
            { from => 'baz', onto => 'bar' },
        ];
    };

    subtest 'using "=>"' => sub {
        my $conf = $grm->parse_config( << '        ...' );
foo => base
bar => base
baz => bar
        ...

        isa_ok $conf->{rebase_rules}, 'ARRAY';
        is_deeply $conf->{rebase_rules}, [
            { from => 'foo', onto => 'base' },
            { from => 'bar', onto => 'base' },
            { from => 'baz', onto => 'bar' },
        ];
    };

    subtest 'using "->" and "=>"' => sub {
        my $conf = $grm->parse_config( << '        ...' );
foo  -> base
bar  => base
baz  -> bar
hoge -> fuga
piyo => fuga
        ...

        isa_ok $conf->{rebase_rules}, 'ARRAY';
        is_deeply $conf->{rebase_rules}, [
            { from => 'foo', onto => 'base' },
            { from => 'bar', onto => 'base' },
            { from => 'baz', onto => 'bar' },
            { from => 'hoge', onto => 'fuga' },
            { from => 'piyo', onto => 'fuga' },
        ];
    };
};


subtest 'valid, aliases' => sub {
    my $conf = $grm->parse_config( << '    ...' );
foo  -> base
bar  -> base
baz  -> ^
hoge -> foo
fuga -> ^
piyo -> ^
    ...

    isa_ok $conf->{rebase_rules}, 'ARRAY';
    is_deeply $conf->{rebase_rules}, [
        { from => 'foo',  onto => 'base' },
        { from => 'bar',  onto => 'base' },
        { from => 'baz',  onto => 'bar' },
        { from => 'hoge', onto => 'foo' },
        { from => 'fuga', onto => 'hoge' },
        { from => 'piyo', onto => 'fuga' },
    ];
};


subtest 'valid, comments' => sub {
    my $conf = $grm->parse_config( << '    ...' );
#
foo  -> base
# hogheoge
bar  -> base

# baz  -> ^
piyo -> ^

    ...

    isa_ok $conf->{rebase_rules}, 'ARRAY';
    is_deeply $conf->{rebase_rules}, [
        { from => 'foo',  onto => 'base' },
        { from => 'bar',  onto => 'base' },
        { from => 'piyo', onto => 'bar' },
    ];
};


subtest 'invalid' => sub {
    subtest 'bad format' => sub {
        try {
            $grm->parse_config( << '            ...' );
foo
            ...
            fail 'Should die!';
        } catch {
            my $msg = shift;
            like $msg, qr/\[ERROR\] invalid format:/;
        };
    };

    subtest 'bad alias' => sub {
        try {
            $grm->parse_config( << '            ...' );
foo -> ^
            ...
        } catch {
            my $msg = shift;
            like $msg, qr/\[ERROR\] invalid "\^" usage. previous rule is required:/;
        };
    };
};


done_testing;
