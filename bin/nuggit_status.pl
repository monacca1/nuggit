#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);


# usage: 
#
# nuggit_status.pl
# or
# nuggit_status.pl --cached
#       show the files that are in the staging area
#       that will be committed on the next commit.
#
#
# to help with machine readability each file that is staged is printed on a line beginning with S
#
# Example:
#
#/project/sie/users/monacc1/root_repo/fsw_core/apps> nuggit_status.pl --cached
#=============================================
#Root repo staging area (to be committed):
#  Root dir: /project/sie/users/monacc1/root_repo 
#  Branch: jira-xyz
#S   ../../.gitignore
#=============================================
#Submodule staging area (to be committed):
#Submodule: fsw_core/apps/appx
#Submodule and root repo on same branch: jira-xyz
#S   ../../fsw_core/apps/appx/readme_appx
#=============================================
#Submodule staging area (to be committed):
#Submodule: fsw_core/apps/appy
#Submodule and root repo on same branch: jira-xyz
#S   ../../fsw_core/apps/appy/readme_appy
#
#
#


sub ParseArgs();
sub git_status_of_all_submodules();
sub git_diff_cached_of_all_submodules();
sub get_selected_branch($);

my $root_dir;
my $relative_path_to_root;
#my $git_status_cmd = "git status --porcelain --ignore-submodules";
my $git_status_cmd = "git status --porcelain";
my $git_diff_cmd   = "git diff --name-only --cached";
my $cached_bool;

$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}

# the relative path to root is used in the output.
# it is used before each file in each submodule with a status change.
# this is done so the user can copy the entire path and call
# nuggit_add.pl or nuggit_diff.pl on that path and it is valid
$relative_path_to_root = `nuggit_get_path_relation_to_root.pl`;
chomp $relative_path_to_root;

#print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";
#print $relative_path_to_root . "\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;

ParseArgs();

if($cached_bool)
{
  git_diff_cached_of_all_submodules();
}
else
{
  git_status_of_all_submodules();
}



sub ParseArgs()
{
  Getopt::Long::GetOptions(
     "--cached"  => \$cached_bool
     );
}



# check all submodules to see if the branch exists
sub git_status_of_all_submodules()
{
  my $status;
  my $root_dir = getcwd();
  my $branches;
  my $root_repo_branch;
  my $submodule_branch;
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;

  # identify the checked out branch of root repo
  # execute git branch
  $branches = `git branch`;
  $root_repo_branch = get_selected_branch($branches);

  $status = `$git_status_cmd`;
  
  if($status ne "")
  {
    print "=================================\n";
    print "Root repo with changes:\n";
    print "  Root dir: $root_dir \n";
    print "  Branch: $root_repo_branch\n";
#    print "\n";

    # add the repo path to the output from git that just shows the file
    $status =~ s/^(...)/$1$relative_path_to_root/mg;
    print $status;
  }
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;

    $branches = `git branch`;
    $submodule_branch = get_selected_branch($branches);

    $status = `$git_status_cmd`;
    if(($status ne "") || ($submodule_branch ne $root_repo_branch))
    {
      print "=================================\n";
      print "Submodule: $_\n";
      print "Submodule on branch $submodule_branch, root repo on branch $root_repo_branch\n";
    }

    if($status ne "")
    {
      
      # add the repo path to the output from git that just shows the file
      $status =~ s/^(...)/$1$relative_path_to_root$_\//mg;
      
      print $status;
     
    }

    # =============================================================================
    # to do - detect if there are any remote changes
    # with this workflow you should be keeping the remote branch up to date and 
    # fully consitent across all submodules
    # - show any commits on the remote that are not here.
    # =============================================================================
#    print "TO DO - SHOW ANY COMMITS ON THE REMOTE THAT ARE NOT HERE ??? or make this a seperate command?\n";
    
    # return to root directory
    chdir $root_dir;
  }

} # end git_status_of_all_submodules()



# do almost the same thing as git_status_of_all_submodules()
# except use the command: 
#   git diff --name-only --cached
# this will print the the list of files that are in the staging
# area and ready to be committed
sub git_diff_cached_of_all_submodules()
{
  my $status;
  my $root_dir = getcwd();
  my $branches;
  my $root_repo_branch;
  my $submodule_branch;
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;

  # identify the checked out branch of root repo
  # execute git branch
  $branches = `git branch`;
  $root_repo_branch = get_selected_branch($branches);

  $status = `$git_diff_cmd`;
  
  if($status ne "")
  {
    print "=============================================\n";
    print "Root repo staging area (to be committed):\n";
    print "  Root dir: $root_dir \n";
    print "  Branch: $root_repo_branch\n";
#    print "\n";

    # add the repo path to the output from git that just shows the file
    $status =~ s/^(.)/S   $relative_path_to_root$1/mg;
    print $status;
  }
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;

    $status = `$git_diff_cmd`;
    if($status ne "")
    {
      print "=============================================\n";
      print "Submodule staging area (to be committed):\n";
      print "Submodule: $_\n";

      $branches = `git branch`;
      $submodule_branch = get_selected_branch($branches);
      if($submodule_branch ne $root_repo_branch)
      {
        print "Submodule on branch $submodule_branch, root repo on branch $root_repo_branch\n";
      }      
      else
      {
        print "Submodule and root repo on same branch: $root_repo_branch\n";
      }
#      print "\n";

      # add the repo path to the output from git that just shows the file
      $status =~ s/^(.)/S   $relative_path_to_root$_\/$1/mg;
      
      print $status;
      
      #===========================================================================================
      # TO DO - FIGURE OUT HOW TO SHOW THE STATUS FOR EACH FILE USING THE RELATIVE PATH FROM
      # THE LOCATION WHERE nuggit_status.pl WAS EXECUTED.  CURRENTLY IT IS JUST SHOWING THE 
      # FILENAME WITHOUT ANY PATH AT ALL, i.e. 
      # M .gitmodules
      #===========================================================================================
      
    }
    else
    {
#      print "submodule with no changes: $_\n";
    }

    # =============================================================================
    # to do - detect if there are any remote changes
    # with this workflow you should be keeping the remote branch up to date and 
    # fully consitent across all submodules
    # - show any commits on the remote that are not here.
    # =============================================================================
#    print "TO DO - SHOW ANY COMMITS ON THE REMOTE THAT ARE NOT HERE ??? or make this a seperate command?\n";
    
    # return to root directory
    chdir $root_dir;
  }

}



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
