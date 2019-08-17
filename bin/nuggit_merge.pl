#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);


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

$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}

print "nuggit_merge.pl\n";




$argc = @ARGV;  # get the number of arguments.
if($argc == 1)
{
  $source_branch      = $ARGV[0];
  $destination_branch = get_selected_branch_here();
  
  print "Source branch is: $source_branch\n";
  print "destination branch is the current branch: $destination_branch\n";
}
else
{
  print "usage: nuggit_merge.pl <source_branch>\n";
}



#print "changing directory to root: $root_dir\n";
chdir $root_dir;
merge_recursive($root_dir, 0);
#print "changing directory to root: $root_dir\n";
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
  my $cwdir;
  my $submodules; 
  my $depth = $_[1]; 
 
  chdir $dir;

  print indent($depth) . "========PUSH======  Current directory $dir =================== \n";

  # get a list of the submodules  
  if(-e ".gitmodules")
  {
    my $submodules = `list_submodules.sh`;
  
    # put each submodule entry into its own array entry
    my @submodules = split /\n/, $submodules;

    print indent($depth) . "------------merge recursive in dir $dir----------------\n";
    
    foreach (@submodules)
    {
      # switch directory into the sumbodule
      chdir $_;

      ##########################################################
      merge_recursive($_, $depth+1);
      ##########################################################    
      
      print indent($depth) . "merge_recurse() returned\n";

      # return to the original dir    
      chdir $dir;
      
      $cwdir = getcwd() or die;
      
      print indent($depth) . "cwdir $cwdir\n";
      print indent($depth) . "dir $dir\n";
      print indent($depth) . "git status: \n";
      print indent($depth) . "git add: $_\n";

    }
  }
  else
  {
    print indent($depth) . "Current dir ($dir) has no submodules\n";
  }

  print indent($depth) . "Do the git merge here in dir $dir\n";
  $cwdir = getcwd();  
  print indent($depth) . "cwdir $cwdir\n";
  
  print indent($depth) . "====POP=========================================================\n";

}





sub merge_recursive_BROKEN($)
{
  my $dir = $_[0];
  my $cwdir;
  my $submodules;  
 
  chdir $dir;

  
  print "========PUSH======  Current directory $dir =================== \n";

  # get a list of the submodules  
  if(-e ".gitmodules")
  {
    my $submodules = `list_submodules.sh`;
  
    # put each submodule entry into its own array entry
    my @submodules = split /\n/, $submodules;

    print "------------merge recursive in dir $dir----------------\n";
    
    foreach (@submodules)
    {
      # switch directory into the sumbodule
      chdir $_;

      ##########################################################
#      merge_recursive($_);
      ##########################################################    
      
      print "merge_recurse() returned\n";

      # return to the original dir    
      chdir $dir;
      
      $cwdir = getcwd() or die;
      
      print "cwdir $cwdir\n";
      print "dir $dir\n";
      print "git status: \n";
      print `git status`;
      print "git add: $_\n";
      print `git add $_`;
    }
  }
  else
  {
    print "Current dir ($dir) has no submodules\n";
  }

  print "Do the git merge here in dir $dir\n";
  $cwdir = getcwd();  
  print "cwdir $cwdir\n";
  print `git merge $source_branch --no-ff -m "$commit_message"`;
  
  print `git commit -m "$commit_message"`;
  
  print "====POP=========================================================\n";

}



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
