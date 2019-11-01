#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_checkout.pl <branch_name>
#
#
# nuggit_checkout_tracking.pl
#

my $num_args;
my $branch;
my $cwd = getcwd();


my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;
nuggit_log_init($root_dir);

check_merge_conflict_state(); # Do not proceed if merge in process; require user to commit via ngt merge --continue

# print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir($root_dir) || die("Can't enter $root_dir");

submodule_foreach(\&checkout_default_branch);

# check all submodules to see if the branch exists
sub checkout_default_branch
{
  my    $tmp;
  my    $default_branch;
  my ($parent, $name, $status, $hash, $label) = (@_);
  my $current_dir = $parent . '/' . $name; # Full Path to Repo Relative to Root
  
  die "DEBUG: Internal Error, Unexpected Args length of ".scalar(@_) unless scalar(@_)>=5;
  $tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
  $tmp =~ m/remotes\/origin\/(.*)$/;
  $default_branch = $1;  
#  print $tmp;
  print "default HEAD branch is $default_branch\n";

#  $tmp = `git remote show origin | grep HEAD`;   
#  $tmp =~ m/HEAD branch\: (.*)$/;
#  $default_branch = $1;
  
  print "Tracking branch is: $default_branch\n";
  print "\t Current Ref Status is $status at $hash of $label\n"; # VERIFY Accuracy/meaning of label
  
  print `git checkout $default_branch`;
  print `git pull`;
  
}

