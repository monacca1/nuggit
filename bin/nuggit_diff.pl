#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);

# Usage
#
# nuggit_diff.pl
#   No arguments - get all the differences between the working copy of 
#      files and the local repository
# nuggit_diff.pl ../path/to/file.c
#   Argument is a particular file, which may be in a submodule (or not) -
#      get the differences of the specified file between the 
#      working copy of the file and the local repository
#
#  TO DO - ARE THERE USE CASES WHERE WE WANT TO SEE THE DIFFS BETWEEN BRANCHES OR
#  BETWEEN LOCAL AND REMOTE? TO DO
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

sub get_selected_branch($);

my $root_dir;
my $branches;
my $root_repo_branch;


$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

print "nuggit root directory is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;




$branches = `git branch`;
$root_repo_branch = get_selected_branch($branches);

print "The checked out branch is $root_repo_branch\n";

print `git diff @ARGV`;
print `git submodule foreach --recursive git diff @ARGV`;



# get the checked out branch from the list of branches
# The input is the output of git branch (list of branches)
sub get_selected_branch($)
{
  my $root_repo_branches = $_[0];
  my $selected_branch;

  $selected_branch = $root_repo_branches;
  $selected_branch =~ m/\*.*/;
  $selected_branch = $&;
  $selected_branch =~ s/\* //;  
  
  return $selected_branch;
}

