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
use Git::Nuggit::Log;


# usage: 
#
# nuggit_add.pl <path_to_file>
#
# NOTE: Branch consistency check is not required for add, but should run as a pre-commit hook.

sub ParseArgs();
sub add_file($);

my $cwd = getcwd();
my $add_all_bool = 0;
my $patch_bool = 0;

print "nuggit_add.pl\n";

my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!") unless $root_dir;
my $log = Git::Nuggit::Log->new(root => $root_dir);

ParseArgs();
$log->start(1);

chdir($cwd);


my $argc = @ARGV;  # get the number of arguments.
  
if ($argc == 0) {
    # This is only valid if -A flag was set
    if ($add_all_bool) {
        # Run "git add -A" for each submodule that has been modified.
        my $status = get_status({uno => 1});
        add_all($status);
    } else {
        say "Error: No files specified";
        pod2usage(1);
    }
} else {

    foreach(@ARGV)
    {
        add_file($_);
        
        # ensure that we are still at the same starting directory as when the caller
        # called this script.  This is important because all of the paths passed in
        # are relative to it.
        chdir $cwd;
    }
}


sub ParseArgs()
{
    my ($help, $man);
    Getopt::Long::GetOptions(
                           "all|A!"  => \$add_all_bool,
                           "patch|p!"  => \$patch_bool,
                           "help"            => \$help,
                           "man"             => \$man,
                          );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;
}

sub add_all
{
    my $status = shift;

    # Foreach submodule with active changes
    foreach my $child (@{$status->{children}}) {
        add_all($child);
    }

    # And for self
    git_add();
}


sub add_file($)
{
  my $relative_path_and_file = $_[0];
  
  say "Adding file $relative_path_and_file";

  my ($vol, $dir, $file) = File::Spec->splitpath( $relative_path_and_file );

  if (-d $dir) {
      # Easy case
      chdir($dir);
      git_add($file);
  } else {
      # File may have been deleted or renamed.  We need to find the last path in $dir that is valid
      my @dirs = File::Spec->splitdir($dir);
      while(@dirs) {
          my $path = shift(@dirs); # Get first path from dir list
          if (-d $path) {
              chdir($path);
          } else {
              unshift(@dirs, $path); # Put it back for consistency
              last;
          }
      }
      $file = File::Spec->catfile(@dirs, $file);
      git_add($file);
  }
}

sub git_add {
    my $file = shift;
    my $cmd = "git add";
    $cmd .= " -p " if $patch_bool;
    $cmd .= " -A " if $add_all_bool;
    $cmd .= " $file" if $file; # support for -A option
    system($cmd);
    $log->cmd($cmd);
    die "Add of $file failed: $?" if $?;
}

=head1 Nuggit add

Stage the specified file(s) in the repository, automatically handling submodule boundaries.

=head1 SYNOPSIS

Specify one or more files or directories to be added.  A file is required unless help, man, or -A is specified.

Examples: "nuggit_add.pl -A" or "nuggit_add.pl foo/bar" or "nuggit_add.pl -p README.md"

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item -A | --all

Stage all uncommitted changes (excludes untracked and ignored files)

=item -p | --patch

Interactively select which segments of each file to stage.


=back


=cut
