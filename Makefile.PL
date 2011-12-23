use ExtUtils::MakeMaker;

my @TEST_TARGET = qw{ t/*.t t/*/*.t };

WriteMakefile(
    NAME => 'App::gitrebasematsuri',
    VERSION_FROM => 'lib/App/gitrebasematsuri.pm',
    ABSTRACT => 'git-rebase matsuri.',
    PREREQ_PM => {
        'ExtUtils::MakeMaker' => 6.31,
        'ExtUtils::Install'   => 1.46,
        'Log::Minimal'        => 0.09,

        # test requires
        'Test::Flatten'       => 0.06,
        'File::chdir'         => 0.1006,
        'String::Random'      => 0.22,
    },
    test => {
        TESTS => join( ' ', @TEST_TARGET ),
    },
    LICENSE => 'perl',
    EXE_FILES => [ 'bin/git-rebase-matsuri' ],
);
