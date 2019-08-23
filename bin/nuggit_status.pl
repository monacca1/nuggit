#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";


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
my $cached_bool;


my $status_cmd;
my $root_repo_branch;
my $status_cmd_mode;


$root_dir = find_root_dir() || die("Not a nuggit!\n");

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
  git_submodule_status("cached");
}
else
{
  git_submodule_status("status");
}



sub ParseArgs()
{
  Getopt::Long::GetOptions(
     "--cached"  => \$cached_bool
     );
}



# check all submodules to see if the branch exists
sub git_submodule_status
{
  my $status;
  my $root_dir = getcwd();
  my $branches;
  my $submodule_branch;

  $status_cmd_mode = shift;  

  # identify the checked out branch of root repo
  # execute git branch
  $branches = `git branch`;
  $root_repo_branch = get_selected_branch($branches);

  if ($status_cmd_mode eq "cached") 
  {
      $status_cmd = "git diff --name-only --cached";
  } 
  else 
  {
      $status_cmd = "git status --porcelain";
  }
  $status = `$status_cmd`;
  
  if($status ne "")
  {
    print "=================================\n";
    print "Root repo with changes:\n";
    print "  Root dir: $root_dir \n";
    print "  Branch: $root_repo_branch\n";
#    print "\n";

    # add the repo path to the output from git that just shows the file
    if ($status_cmd_mode eq "cached") 
    {
        $status =~ s/^(.)/S   $relative_path_to_root$1/mg;
    } else 
    {
        $status =~ s/^(...)/$1$relative_path_to_root/mg;
    }
    
    print $status;
  }

  submodule_foreach(\&get_status);

} # end git_status_of_all_submodules()




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



sub get_status
{
    my ($parent, $name, $substatus, $hash, $label) = (@_);
    my $subpath = $parent . '/' . $name .'/';
    
    my $status;
    my $branches;
    my $submodule_branch;

    
    $branches = `git branch`;
    $submodule_branch = get_selected_branch($branches);

    $status = `$status_cmd`;
    if(($status ne "") || ($submodule_branch ne $root_repo_branch))
    {
      print "=================================\n";
      print "Submodule: $name\n";
      print "Submodule on branch $submodule_branch, root repo on branch $root_repo_branch\n";
      print "Submodule at $hash with parent reference status of ".(($substatus) ? "modified" : "unmodified")."\n";
    }

    if($status ne "")
    {
      
        # add the repo path to the output from git that just shows the file
        if ($status_cmd_mode eq "cached") 
        {
            $status =~ s/^(.)/S   $relative_path_to_root$subpath$1/mg;
        } 
        else 
        {
            $status =~ s/^(...)/$1$relative_path_to_root$subpath/mg;
        }
      
      print $status;
     
    }

    # =============================================================================
    # to do - detect if there are any remote changes
    # with this workflow you should be keeping the remote branch up to date and 
    # fully consitent across all submodules
    # - show any commits on the remote that are not here.
    # =============================================================================
#    print "TO DO - SHOW ANY COMMITS ON THE REMOTE THAT ARE NOT HERE ??? or make this a seperate command?\n";
    
}
