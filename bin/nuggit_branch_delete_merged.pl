#!/usr/bin/env perl

# This script is used to delete branches that have already been merged
# This operates on the local repository AND the the remote (central) repository


use strict;
use warnings;
use v5.10;
use File::Spec;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;


# usage: 
#
# nuggit_branch_delete_merged.pl <branch_to_delete>
#

sub ParseArgs();


my $argc = @ARGV;  # get the number of arguments.
my $cwd = getcwd();
my $branch_to_delete = "";

print "nuggit_branch_delete_merged.pl\n";


my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!") unless $root_dir;
my $log = Git::Nuggit::Log->new(root => $root_dir);

ParseArgs();
$log->start(1);

chdir($cwd);


if ($argc != 1) 
{
  print "Number of arguments: $argc\n";
  say "Error: No branch specified";
#  pod2usage(1);
  exit(0);
}
else
{

  print "TO DO - CLEAN THIS UP\n";
  print "TO DO - add nuggit log entry\n";
  print "TO DO - consider folding in to the nuggit branch command?\n";
  

  `ngt foreach git push origin --delete $branch_to_delete`;
  `ngt foreach git branch -d $branch_to_delete`;

}


sub ParseArgs()
{
  print "to do\n";
  $branch_to_delete = $ARGV[0];
  
  if($argc >= 1)
  {
    print "branch to delete is $branch_to_delete\n";
  }
}

