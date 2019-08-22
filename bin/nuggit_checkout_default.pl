#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);

# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_checkout.pl <branch_name>
#
#
# nuggit_checkout_tracking.pl
#

sub checkout_default_branch_recursively($);

my $num_args;
my $branch;
my $root_dir;
my $cwd = getcwd();



$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}


checkout_default_branch_recursively($root_dir);
chdir $root_dir;


# check all submodules to see if the branch exists
sub checkout_default_branch_recursively($)
{
  my    $tmp;
  my    $default_branch;
  my    $current_dir = $_[0];    # this is the relative path of the directory we want
                                 # to enter relative to the current working directory
  
  print "Entering directory $current_dir\n";
  chdir $current_dir;
        $current_dir = getcwd();   # We do this because this will get us the full path
                                   # when entering this function $current_dir was just
                                   # a relative path and after changing the directory into 
                                   # this folder, $current_dir must be converted to
                                   # and absolute path
  
  
  $tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
  $tmp =~ m/remotes\/origin\/(.*)$/;
  $default_branch = $1;  
#  print $tmp;
  print "default HEAD branch is $default_branch\n";

#  $tmp = `git remote show origin | grep HEAD`;   
#  $tmp =~ m/HEAD branch\: (.*)$/;
#  $default_branch = $1;
  
  print "Tracking branch is: $default_branch\n";
  
  print `git checkout $default_branch`;
  print `git pull`;
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;
    
  foreach (@submodules)
  {
    # recurse
    checkout_default_branch_recursively($_);
   
    # return to root directory
    chdir $current_dir;
  }

}

