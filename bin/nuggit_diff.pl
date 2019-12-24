#!/usr/bin/env perl

use Getopt::Long;
use strict;
use warnings;
use v5.10;
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;

use Cwd qw(getcwd);

=head1 SYNOPSIS
   No arguments - get all the differences between the working copy of 
      files and the local repository

 nuggit_diff.pl ../path/to/file.c
   One argument: Argument is a particular file, which may be in a submodule (or not) -
      get the differences of the specified file between the 
      working copy of the file and the local repository

 nuggit_diff.pl ../path/to/dir
   One argument: Argument is a particular directory, which may be in a submodule (or not) -
      get the differences of the specified directory between the 
      working copy of the file and the local repository

 nuggit_diff.pl origin/<branch> <branch>
   two arguments, diff between the two branches

The following options are supported:

=over

=item --color | --no-color

By default, all diff output is shown with ANSI terminal colors (--color).  If this is not desired, for example if saving output to a patch file, specify "--no-color" to disable.

=item --cached

If defined, show changes that have been staged.

=back

=cut

# Notes
#
# git branch -a
#
# git diff origin/master master --name-status
# git diff origin/master master --stat
#
# ????
# git diff --submodule
# git diff --cached --submodule


# shows how many commits are on each side since the common ancestor?
#bash-4.2$ git rev-list --left-right --count origin/master...master
#0       2

# git fetch
# git status


sub ParseArgs();

my $verbose = 0;
my $arg_count = 0;
my $show_color = 1;
my $show_cached = 0;
my $root_dir;

my $filename;
my $path;

my $diff_object1 = "";
my $diff_object2 = "";

my $ngt = Git::Nuggit->new("echo_always" => 0);
$root_dir = $ngt->root_dir();

print "nuggit root directory is: $root_dir\n" if $verbose;

ParseArgs();
$ngt->start(level => 0);


if($arg_count == 0)
{
    chdir($root_dir);
    do_diff();
    submodule_foreach(sub {
        my ($parent, $name, $substatus, $hash, $label, $opts) = (@_);
        if ($parent eq ".") {
            do_diff($name);
        } else {
            do_diff("$parent/$name/");
        }
    });

}
elsif($arg_count == 1)
{
  # get the diff of one file
  print "Get the diff of one object: $diff_object1\n" if $verbose;

  if(-e $diff_object1)
  {
    print "object $diff_object1 exists!  yay!\n" if $verbose;

    my ($vol, $dir, $file) = File::Spec->splitpath( $diff_object1 );
    if ($dir) {
        # If file is in a sub-directory, chdir first to ensure we are in correct repository
        chdir($dir) || die "$dir is not a directory";
    }
    do_diff($dir, $file);

  }
  else
  {
      # TODO: Validate argument as branch, or diff between branches.  SHA1 diffs not supported by nuggit

      chdir($root_dir);
      do_diff(undef, $diff_object1);
      submodule_foreach(sub {
             my ($parent, $name, $substatus, $hash, $label, $opts) = (@_);
             if ($parent eq ".") {
                 do_diff($name, $diff_object1);
             } else {
                 do_diff("$parent/$name/", $diff_object1);
             }
         });
  }
}
elsif($arg_count == 2)
{

  # when two arguments are provided, assume these are branches
  print "TWO ARGUMENTS PROVIDED.  Assume these are branch names/locations\n";
  print "This is not yet supported\n";

}



sub ParseArgs()
{
  my ($help, $man);
  # Gobble up any know flags and options

  Getopt::Long::GetOptions(
    "help"            => \$help,
    "man"             => \$man,
   "verbose!"         => \$verbose,
   "color!"           => \$show_color,
   "cached!"           => \$show_cached,
                          );
  pod2usage(1) if $help;
  pod2usage(-exitval => 0, -verbose => 2) if $man;

  $arg_count = @ARGV;
  print "Number of arguments $arg_count \n" if $verbose;

  if($arg_count >= 1)
  {
    $diff_object1 = $ARGV[0];
  }

  # if there is another arg, is it the thing to diff against?
  if($arg_count > 1)
  {
     $diff_object2 = $ARGV[1];
  }

}

sub do_diff
{
    my $cmd = "git diff";
    $cmd .= " --color" if $show_color;
    $cmd .= " --cached" if $show_cached;
    my $rel_path = shift; # Always present
    my $args = shift; # Additional arguments (ie: file, directory, or object)
    $cmd .= " ".$args if $args;

    my ($err, $stdout, $stderr) = $ngt->run($cmd);

    # Normalize Paths
    if ($rel_path) {
        $rel_path .= '/' unless $rel_path =~ /\/$/;
        # We are in a sub-module, prepend dir, ie: replace "--- a/FILE" with "--- a/$rel_path/FILE"
        #  Note; Regex allows for optional ANSI escape sequences when diff includes colorization
        $stdout =~ s/^((\e\[\d+m)*((\+\+\+)|(\-\-\-))\s[ab]\/)/$1$rel_path/mg;
    } else {
        # At root level, no adjustment needed.
        # NOTE: We will always display paths relative to root for consistency in case user decides to use output as a patch file
    }

    say $stdout if $stdout;
}
