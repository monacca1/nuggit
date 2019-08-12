#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_status.pl
#
sub git_status_of_all_submodules();


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
  my $branch = $_[0];
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;

  $status = `git status -s`;
  
  if($status ne "")
  {
    print "=================================\n";
    print "Root repo with changes:\n";
    print "  Root dir: $root_dir \n";
    print "\n";
    print $status;
  }
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;

    $status = `git status -s`;
    if($status ne "")
    {
      print "=================================\n";
      print "Submodule with changes:\n";
      print "  Submodule: $_\n";
      print "\n";
      print $status;
    }
    else
    {
#      print "submodule with no changes: $_\n";
    }
    
    # return to root directory
    chdir $root_dir;
  }

}
