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
require "nuggit.pm";
require Git::Nuggit::Status;

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

Additional use cases may be added in the future.

=back

=cut

my $patch_flag = 0;
my $quiet_flag = 0;
my $mode = "";


my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!") unless $root_dir;
nuggit_log_init($root_dir);

ParseArgs();

my $cwd = getcwd();

my $base_cmd = "git reset ";
$base_cmd .= "-q " if $quiet_flag;
$base_cmd .= "-p " if $patch_flag;

my $argc = @ARGV; # get the number of arguments

if ($argc == 0) {
    # NOTE: This is a simple implementation. We could optimize this by only running in submodules showing changes
    submodule_foreach(sub {
        system($base_cmd);
        nuggit_log_cmd($base_cmd);
                      });

} else {
    # For each given path
    foreach my $arg (@ARGV)
    {
        chdir($cwd);

        my ($vol, $dir, $file) = File::Spec->splitpath( $arg );

        # chdir as far as we can to ensure we can handle deleted or removed directories
        my @dirs = File::Spec->splitdir($dir);
        while(@dirs) {
            my $path = shift(@dirs);
            if (-d $path) {
                chdir($path);
            } else {
                unshift(@dirs, $path);
                last;
            }
            $file = File::Spec->catfile(@dirs, $file);
            my $cmd = "$base_cmd $file";
            system($cmd);
            nuggit_log_cmd($cmd);
        }
        
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
