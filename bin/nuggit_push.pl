#!/usr/bin/perl -w


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_push.pl 
#

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);

sub get_selected_branch($);
sub get_selected_branch_here();

my $root_dir;
my $cwd = getcwd();


$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;


my $branch = get_selected_branch_here();

print "nuggit_push.pl\n";

print "TO DO - NEED TO MAKE SURE THE REPO IS ON THE SAME BRANCH THROUGHOUT ALL SUBMODULES\n";

print `git submodule foreach --recursive git push --set-upstream origin $branch`;
print `git push --set-upstream origin $branch`;




sub get_selected_branch_here()
{
  my $branches;
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  # execute git branch
  $branches = `git branch`;

  $selected_branch = get_selected_branch($branches);  
}


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
