#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);

# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_checkout.pl <branch_name>
#
#
# nuggit_checkout.pl <branch_name>
# nuggit_checkout.pl -b <branch_name>
#

my $num_args;
my $branch;
my $root_dir;
my $cwd = getcwd();
my $create_branch = 0;


sub does_branch_exist_throughout($);
sub create_branch_where_needed($);
sub does_branch_exist_at_root($);

if($ARGV[0] eq "-b")
{ 
  print "creating new branch\n";
  $branch=$ARGV[1];
  $create_branch = 1;
}
else
{
  print "not creating a branch - using existing\n";
  $branch=$ARGV[0];
}

print "branch = $branch\n";

$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

print "nuggit root dir is: $root_dir\n";
print "nuggit cwd is $cwd\n";

print "changing directory to root: $root_dir\n";
chdir $root_dir;

if($create_branch == 0)
{
  if(does_branch_exist_at_root($branch))
  {
    system("git checkout $branch");
    
    if(does_branch_exist_throughout($branch))
    {
      system("git submodule foreach --recursive git checkout $branch");
    }
    else
    {
      create_branch_where_needed($branch);
    }
  }
  else
  {
    print "Branch does not exist\n";
  }
}
else
{
  # we shouldn't need to do this with the planned workflow but 
  # keep it for general workflow where command line tool is used 
  # to create the branch
  system("git checkout -b $branch");
  system("git submodule foreach --recursive git checkout -b $branch");
}



# check all submodules to see if the branch exists
sub does_branch_exist_throughout($branch)
{
  my $submodules = `list_all_submodules.pl`;
  
  print $submodules;

  print "Does branch exit throughout?\n";
  return 0;
}



# find any submodules where the branch does not exist and create it
sub create_branch_where_needed($branch)
{
  print "Create branch where needed.\n";
  return 1;
}



# check to see if the specified branch already exists at the root level
sub does_branch_exist_at_root($branch)
{
  my $branches;
  my @branches;
  
  print "Does branch exit at root?\n";
  
  # execute git branch and grep the output for branch
  $branches = `git branch | grep $branch\$`;
  
  # the branch name may be a substring or may be the selected branch
  # the selected branch will have a * at the beginning, remove that 
  $branches =~ s/[\*\s]*//;
  
  # split the string into an array where each branch name that included the desired
  # branch name as a substring is an entry
  @branches = split / /, $branches;
  
  # search for an exact match for the branch in each array entry
  foreach(@branches)
  {
    # check for the exact match
    if($_ =~ m/^$branch$/)
    {
      # found the branch return true
      return 1;
    }
  }

  # did not find the branch - return false
  return 0;
}
