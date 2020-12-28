use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Git::Nuggit',
    AUTHOR       => [q{Chris Monaco <chris.monaco@jhuapl.edu>}, q{David Edell <david.edell@jhuapl.edu>} ],
    VERSION_FROM => 'lib/Git/Nuggit.pm',
    ABSTRACT     => 'Git Toolkit for Submodule-Aware workflows',
              ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
              EXE_FILES  => [
                             'bin/ngt',
                             'bin/list_all_submodules.pl',
                             'bin/nuggit_add.pl',
                             'bin/nuggit_branch.pl',
                             'bin/nuggit_clone.pl',
                             'bin/nuggit_commit.pl',
                             'bin/nuggit_diff.pl',
                             'bin/nuggit_fetch.pl',
                             'bin/nuggit_foreach.pl',
                             'bin/nuggit_log.pl',
                             'bin/nuggit_ops.pl',
                             'bin/nuggit_mv.pl',
                             'bin/nuggit_push.pl',
                             'bin/nuggit_reset.pl',
                             'bin/nuggit_rm.pl',
                             'bin/nuggit_status.pl',
                            ],
    PREREQ_PM => {
                  'FindBin'      => 0,
                  'Getopt::Long' => 0,
                  'IPC::Run3'    => 0,
                  'Term::ANSIColor' => 4,
                  'Complete::File' => 0,
                  'Complete::Bash' => 0,
                  'IO::Page' => 0,
                  'JSON' => 0,
                  'File::Slurp'     => 0,
                  'File::Spec'      => 0
                 },
    TEST_REQUIRES => {
        'Test::Compile'             => 0,
        'Test2::V0'                 => 0,
        'Test2::Plugin::BailOnFail' => 0,
                      'File::pushd'     => 0,
                     },
              test => {TESTS => 'test/*.t'}
             );
