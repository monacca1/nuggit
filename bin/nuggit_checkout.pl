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




if($create_branch == 0)
{
  system("git checkout $branch");
  
  #########################################################################
  # TO DO
  #########################################################################
  # we may need to create the branch recursively if this is the first time
  # we are checking out this branch.  Or we may just need to checkout the 
  # branch recursively.  
  #########################################################################
  
  #system("git submodule foreach --recursive git checkout $branch");
  
  # for now always try to create the branch in each submodule
  system("git submodule foreach --recursive git checkout -b $branch");
}
else
{
  # we shouldnt need to do this with the planned workflow but keep it
  system("git checkout -b $branch");
  system("git submodule foreach --recursive git checkout -b $branch");
}
