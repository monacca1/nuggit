#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_status.pl
#
sub git_status_of_all_submodules();
sub get_selected_branch($);

my $root_dir;


$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

#print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;


git_status_of_all_submodules();


# need to parse the output and determine if a change is a file or directory
#  if it is a directory, recurse into it and do the git status again
#  if the change is a file, display the change


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

  $status = `git status -s`;
  
  if($status ne "")
  {
    print "=================================\n";
    print "Root repo with changes:\n";
    print "  Root dir: $root_dir \n";
    print "  Branch: $root_repo_branch\n";
#    print "\n";
    print $status;

    #===========================================================================================
    # TO DO - FIGURE OUT HOW TO SHOW THE STATUS FOR EACH FILE USING THE RELATIVE PATH FROM
    # THE LOCATION WHERE nuggit_status.pl WAS EXECUTED.  CURRENTLY IT IS JUST SHOWING THE 
    # FILENAME WITHOUT ANY PATH AT ALL, i.e. 
    # M .gitmodules
    #===========================================================================================    
  }
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;

    $status = `git status -s`;
    if($status ne "")
    {
      print "=================================\n";
#      print "Submodule with local changes:\n";
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
      $status =~ s/^(...)/$1$_\//mg;
      
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
