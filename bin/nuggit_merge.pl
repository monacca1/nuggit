#!/usr/bin/perl -w


use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";


# nuggit_merge.pl master -m "commit message"

# TO DO - GET THE COMMIT MESSAGE



#
#
# in the submodule directory
#   git fetch
#   git merge
#
#   if you didnt make any changes, and you are on master, I think that is the same as
#   git pull
#
# git submodule update --remote
#  goes into the directory, fetch and update
#
#


# if there are changes upstream and local we can either merge or rebase?
#
# git submodule update --remote --merge
#    merge the changes into my branch???
#
#
# the rebase option:
# git submodule update --remote --rebase
#
#


# ------------------------------------------------------------------------------------------------------------------
# the following assumes you want to merge the branch into master at the command line
# and then push to master... this is not allowed in some workflows.  In those workflows
# you have to push to a remote branch and then use a pull request on the server to 
# perform the merge
#
# git checkout master
# git merge <branch>
#    I tried this on a clean merge and it resulted in a fast forward merge... no commit
#    you can either try to force a commit.  There is an argument to pass to git merge --no-ff 
#    you can pass in a -m to git merge and
#    you will have to do this recursively in each repo, and then add and commit as you go up the tree.
# ------------------------------------------------------------------------------------------------------------------


sub merge_recursive($$);
sub get_selected_branch_here();
sub get_selected_branch($);

my $root_dir;
my $argc;
my $source_branch = "";
my $destination_branch;
my $branch = "";
my $commit_message = "Nuggit: this is an automated merge commit";
my $inhibit_commit = 0;
my $local_time;


$local_time = localtime();
#print "Local time is: $local_time\n";
$commit_message = "$commit_message, $local_time";


$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}

print "nuggit_merge.pl\n";

my $nuggit_log_file = get_nuggit_log_file_path();
nuggit_log_entry("=====================================", $nuggit_log_file);
nuggit_log_entry("nuggit merge", $nuggit_log_file);


$argc = @ARGV;  # get the number of arguments.
if($argc == 1)
{
  $source_branch      = $ARGV[0];
  $destination_branch = get_selected_branch_here();
  
  print "Source branch is: $source_branch\n";
  print "Destination branch is the current branch: $destination_branch\n";
}
else
{
  print "usage: nuggit_merge.pl <source_branch>\n";
}

nuggit_log_entry("merge src branch:  $source_branch",      $nuggit_log_file);
nuggit_log_entry("merge dest branch: $destination_branch", $nuggit_log_file);

merge_recursive($root_dir, 0);
#print "changing directory to root: $root_dir\n";
#print "chdir to $root_dir\n";
chdir $root_dir;



sub indent($)
{
  my $i = 0;
  my $limit = $_[0];
  for($i = 0; $i < $limit; $i = $i + 1)
  {
    print "  ";
  }
}



sub merge_recursive($$)
{
  my $dir = $_[0];
  my $cwd;
  my $submodules; 
  my $depth = $_[1]; 
  my $base_dir;

  $cwd = getcwd(); 
  $base_dir = $dir;
#  print indent($depth) . "chdir 1 to $dir, base dir = $base_dir\n";
  chdir $base_dir;

#  print indent($depth) . "========PUSH======  Current directory $base_dir =================== \n";

  # get a list of the submodules  
  if(-e ".gitmodules")
  {
    my $submodules = `list_submodules.sh`;
  
    # put each submodule entry into its own array entry
    my @submodules = split /\n/, $submodules;

#    print indent($depth) . "------------merge recursive in dir $base_dir----------------\n";
    
    foreach (@submodules)
    {
      # switch directory into the sumbodule
#      print indent($depth) . "(in foreach) chdir 2 to $_\n";
      chdir $_;

      ##########################################################
      merge_recursive($base_dir . "/" . $_, $depth+1);
      ##########################################################    
      
#      print indent($depth) . "merge_recurse() returned\n";

      # return to the original dir    
#      print indent($depth) . "chdir 3 to $base_dir\n";
      chdir $base_dir;
      $cwd = getcwd() or die;
#      print indent($depth) . "cwd $cwd\n";
#      print indent($depth) . "dir $base_dir\n";
#      print indent($depth) . "git status: \n";
#      print indent($depth) . "git add: $_\n";
      
      if($inhibit_commit == 0)
      {
        print `git status`;
        print `git add $_`;
      }
      else
      {
        print indent($depth) . "Inhibit commit\n";
        print indent($depth) . "git status";
        print indent($depth) . "git add $_";        
      }

    }
  }
  else
  {
#    print indent($depth) . "Current dir ($base_dir) has no submodules\n";
  }

#  print indent($depth) . "Do the git merge here in dir $base_dir\n";
  $cwd = getcwd();  
#  print indent($depth) . "cwd $cwd\n";


  if($inhibit_commit == 0)
  {
    print `git merge $source_branch --no-ff -m "$commit_message"`;
    print `git commit -m "$commit_message"`;  
  }
  else
  {
    print indent($depth) . "Inhibit commit\n";
    print indent($depth) . "git merge $source_branch --no-ff -m \"$commit_message\"\n";
    print indent($depth) . "git commit -m \"$commit_message\"\n";  
  }
       
#  print indent($depth) . "====POP=========================================================\n";

}





