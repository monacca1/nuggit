#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);


# usage: 
#
# nuggit_commit.pl -m "commit message"
#

print "nuggit_commit.pl --- to do\n";



# to get a list of files that have been staged to commit (by the user) use:
#   git diff --name-only --cached
# use this inside each submodule to see if we need to commit in that submodule.


# for each submodule drill down into that directory:
#    see if there is anything stated to commit
#    if there is something staged to commit, commit the staged files with the commit message provided
#    this will need to be nested or recursive or linear across all submodules... need to design how this will work
#       but will need to traverse all the way back up the tree committing at each level.  Use the commit message 
#       provided by the caller, but for committing submodules that have changed as a result, consider constructing
#       a commit message that is based on the callers commit message... consider adding the branch and submodule name
#       to the commit?
#    

sub ParseArgs();
sub git_diff_cached_of_all_submodules();
sub get_selected_branch($);

my $root_dir;
my $relative_path_to_root;
my $git_diff_cmd   = "git diff --name-only --cached";
my $cached_bool;
my $commit_message_string;
my $inhibit_commit_bool = 1;


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

git_diff_cached_of_all_submodules();

#print $commit_message_string . "\n";


sub ParseArgs()
{
  Getopt::Long::GetOptions(
     "m=s"  => \$commit_message_string
     );
}





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
  my $commit_status;
  
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
    print "Root repo - committing staged files:\n";
    print "  Root dir: $root_dir \n";
    print "  Branch: $root_repo_branch\n";
#    print "\n";

    # add the repo path to the output from git that just shows the file
    $status =~ s/^(.)/S   $relative_path_to_root$1/mg;
    print $status;

    if($inhibit_commit_bool)
    {
      print "for testing - inhibit the commit message\n";
    }
    else
    {
      $commit_status = `git commit -m "N: Branch $root_repo_branch, $commit_message_string"`;
      print "Commit status: \n";
      print $commit_status . "\n";
    }   
  }
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;

    $status = `$git_diff_cmd`;
    if($status ne "")
    {
      print "=============================================\n";
      print "Submodule - committing staged files:\n";
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

      if($inhibit_commit_bool)
      {
        print "for testing - inhibit the commit message\n";
      }
      else
      {
        $commit_status = `git commit -m "N: Branch $submodule_branch, $commit_message_string"`;
        print "Commit status: \n";
        print $commit_status . "\n";      
      }
      
      ###################################################
      #
      # TO DO ----------- TO DO ------------ TO DO ------
      #
      # for each successful submodule commit we need to
      # unroll the path and commit the submodule reference the parent repo
      # and continue to unroll the nest all the way up to the top
      #
      ###################################################
      
    }
  
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
