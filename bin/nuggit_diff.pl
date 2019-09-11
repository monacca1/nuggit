#!/usr/bin/perl -w


use Getopt::Long;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";

use Cwd qw(getcwd);

# Usage
#
# nuggit_diff.pl
#   No arguments - get all the differences between the working copy of 
#      files and the local repository
#
# nuggit_diff.pl ../path/to/file.c
#   One argument: Argument is a particular file, which may be in a submodule (or not) -
#      get the differences of the specified file between the 
#      working copy of the file and the local repository
#
# nuggit_diff.pl ../path/to/dir
#   One argument: Argument is a particular directory, which may be in a submodule (or not) -
#      get the differences of the specified directory between the 
#      working copy of the file and the local repository
#
# nuggit_diff.pl origin/<branch> <branch>
#   two arguments, diff between the two branches
#


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

my $arg_count = 0;
my $root_dir;
my $starting_dir;

my $filename;
my $path;

my $branches;
my $root_repo_branch;
my $diff_object1 = "";
my $diff_object2 = "";

$starting_dir = getcwd();
$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;


print "nuggit root directory is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

ParseArgs();



$branches = `git branch`;
$root_repo_branch = get_selected_branch($branches);

print "The checked out branch is $root_repo_branch\n";


if($arg_count == 0)
{
  # Get the diff of everything
  print `git diff @ARGV`;
  print `git submodule foreach --recursive git diff @ARGV`;  
}
elsif($arg_count == 1)
{
  # get the diff of one file
  
  print "Get the diff of one object: $diff_object1\n";
  
  if(-e $diff_object1)
  {
    print "object $diff_object1 exists!  yay!\n";
    
    # is this a directory?
    if(-d $diff_object1) 
    {
      $path = $diff_object1;
    }
    else # if it exists and is not a directory, assume it is a file to be diffed
    {
      $filename = `basename $diff_object1`;
      chomp($filename);
      $path     = `dirname  $diff_object1`;
      chomp($path);
      print "filename is $filename\n";
    }

    print "path is $path\n";
    print "current directory is " . getcwd() . "\n";
    
    chdir $path or die "failed to switch directories";
    print `git diff $filename`;
  }
  else
  {
    print "object $diff_object1 does not exist!  Boo!\n";
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
  my $flag_example_bool = 0;

  # Gobble up any know flags and options

  Getopt::Long::GetOptions(
       "flag"  => \$flag_example_bool   
     );

  $arg_count = @ARGV;
  print "Number of arguments $arg_count \n";
 
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
