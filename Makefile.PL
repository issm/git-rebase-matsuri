use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'App::gitrebasematsuri',
    VERSION_FROM => 'lib/App/gitrebasematsuri.pm',
    ABSTRACT => 'git-rebase matsuri.',
    PREREQ_PM => {
        'ExtUtils::MakeMaker' => 6.31,
        'ExtUtils::Install'   => 1.46,
        'Log::Minimal'        => 0.09,
    },
    LICENSE => 'perl',
    EXE_FILES => [ 'bin/git-rebase-matsuri' ],
);
