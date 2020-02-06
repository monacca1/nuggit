#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use File::Spec;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Status;
use Git::Nuggit::Log;

=head1 SYNOPSIS

A wrapper for a simplified subset of "git reset" functionality.  The following uses are supported:

Unstage a given file (or all staged files/objects):

- ngt reset [-p | -q] <paths>

=over

=item  -p | --patch  

Interactively select the sections of a file to un-stage.

=item -q | --quiet | --no-quiet

If set, only errors will be output. 


For other use cases, git reset must be executed manually at each desired level, or (with caution) using "ngt foreachgit reset".  For example, "ngt foreach git reset HEAD".  Due to the nature of submodules, commands such as resetting to HEAD~1 are NOT supported by nuggit.  

Additional use cases may be added in the future.  For example, a "ngt reset HEAD~1" would execute the equivalent git command at the root level only, followed by a 'git submodule update --init --recursive'.

=back

=cut

my $patch_flag = 0;
my $quiet_flag = 0;
my $mode = "";

my ($root_dir, $relative_path_to_root) = find_root_dir();
my $log = Git::Nuggit::Log->new(root => $root_dir);

ParseArgs();
die("Not a nuggit!") unless $root_dir;
$log->start(1);

my $cwd = getcwd();

my $base_cmd = "git reset ";
$base_cmd .= "-q " if $quiet_flag;
$base_cmd .= "-p " if $patch_flag;

my $argc = @ARGV; # get the number of arguments

if ($argc == 0) {
    say "No arguments specified, unstaging all";
    # NOTE: This is a simple implementation. We could optimize this by only running in submodules showing changes
    submodule_foreach(sub {
        system($base_cmd);
        $log->cmd($base_cmd);
                      });

} else {
    # For each given path
    foreach my $arg (@ARGV)
    {        
        say "Unstaging $arg";

        # Start at original working dir
        chdir($cwd);

        # Get name of parent dir
        my ($vol, $dir, $file) = File::Spec->splitpath( $arg );

        # Enter it. We do not currently handle case where parent dir was deleted (TODO)
        if ($dir) {
            chdir($dir) || die ("Error: $dir doesn't exist");
        }
        
        my $cmd = "$base_cmd $file";
        system($cmd);
        $log->cmd($cmd);
        
    }
}


sub ParseArgs
{
    my ($help, $man);
    Getopt::Long::GetOptions(
                           "quiet|q!"  => \$quiet_flag,
                           "patch|p!"  => \$patch_flag,
                           "help"            => \$help,
                           "man"             => \$man,
                          );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;
}
