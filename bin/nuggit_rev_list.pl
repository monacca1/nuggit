#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);

# to do

# Notes
# git branch -a
# git diff  origin/master master --name-status
# git diff origin/master master --stat
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


print "TO DO - NEED TO FIX THIS API... IT SHOULD BE MORE SIMILAR TO THE GIT DIFF COMMAND\n";
print "TO DO - DO THIS AT THE ROOT REPO AND RECURSIVELY AND PUT INTO NICE FORMAT\n\n";

print "Root\n";
print "diff between remote and local for branch $root_repo_branch\n";
print "origin  local\n";
print "commits commits\n";
print "|       |\n";
print `git rev-list --left-right --count origin/$root_repo_branch...$root_repo_branch`;
print `git submodule foreach --recursive git rev-list --left-right --count origin/$root_repo_branch...$root_repo_branch`;


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

