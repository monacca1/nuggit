#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);


# usage: 
#
# to create a branch
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_branch.pl <branch_name>
# 
# to view all branches just use:
# nuggit_branch.pl
#
# If you are on the same branch across all submodules, just indicate the branch
# If you are on different branches across the submodules... if any submodule is 
# on a different branch, show it, and complain, recommend the nuggit_checkout command
# to switch branches to be consistent

sub get_selected_branch($);
sub is_branch_selected_here($);
sub is_branch_selected_throughout($);

my $root_dir;
my $cwd = getcwd();
my $root_repo_branches;
my $selected_branch;

# print "nuggit_branch.pl\n";

$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

print "nuggit root directory is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;

$root_repo_branches = `git branch`;
$selected_branch    = get_selected_branch($root_repo_branches);

print "Root repo is on branch: \n";
print "* ".  $selected_branch . "\n";
print "\n";
print "Full list of root repo branches is: \n";
print $root_repo_branches . "\n";

# --------------------------------------------------------------------------------------
# now check each submodule to see if it is on the selected branch
# for any submodules that are not on the selected branch, display them
# show the command to set each submodule to the same branch as root repo
# --------------------------------------------------------------------------------------


is_branch_selected_throughout($selected_branch);




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


# check all submodules to see if the branch exists
sub is_branch_selected_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;

#  print "Is branch selected throughout?\n";
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;
    
    if(is_branch_selected_here($branch) == 0)
    {
      print "**** branch $branch is not selected in submodule: $_\n";
      print "**** Please run:\n";
      print "****       nuggit checkout [branch]\n";
      print "\n";
      
      return 0;
    }
    
    # return to root directory
    chdir $root_dir;
  }

  print "All submodules are are the same branch\n";

  return 1;
}


# check of the branch exists in the current repo (based on the current directory)
sub is_branch_selected_here($)
{
  my $branch = $_[0];
  my $branches;
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  # execute git branch
  $branches = `git branch`;

  $selected_branch = get_selected_branch($branches);
  
  if($selected_branch eq $branch)
  {
#    print "branch $branch was selected\n";
    return 1;
  }
  else
  {
    print "**** Branch discrepancy, please correct.\n";
    print "**** checked out branch is $selected_branch, expected branch $branch to be checked out\n";  
    return 0;
  }
  
}
