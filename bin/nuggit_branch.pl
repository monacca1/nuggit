#!/usr/bin/perl -w


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

print "nuggit_branch.pl --- to do\n";


my $root_repo_branches;
my $selected_branch;

$root_repo_branches = `git branch`;
$selected_branch = $root_repo_branches;
$selected_branch =~ m/\*.*/;
$selected_branch = $&;

print "Root repo is on branch: \n";
print $selected_branch . "\n";
print "Full list of root rebo branches is: \n";
print $root_repo_branches . "\n";

# --------------------------------------------------------------------------------------
# TO DO --------------------------------------------------------------------------------
# now check each submodule to see if it is on the selected branch
# for any submodules that are not on the selected branch, display them
# show the command to set each submodule to the same branch as root repo
