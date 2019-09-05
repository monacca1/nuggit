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
# nuggit_add.pl <path_to_file>
#

sub ParseArgs();
sub add_file($);

my $num_args;
my $branch;
my $cwd = getcwd();
my $add_all_bool = 0;


print "nuggit_add.pl\n";


# TO DO - MAKE SURE BRANCH IS CONSISTENT AT ROOT AND THROUGHOUT

ParseArgs();



my $branches;
my $root_repo_branch;
my ($root_dir, $relative_path_to_root) = find_root_dir();
chdir($cwd);
$branches = `git branch`;
$root_repo_branch = get_selected_branch($branches);

my $date = `date`;
chomp($date);
system("echo ===========================================         >> $root_dir/.nuggit/nuggit_log.txt");
system("echo nuggit_add.pl, branch = $root_repo_branch, $date    >> $root_dir/.nuggit/nuggit_log.txt");





if($add_all_bool)
{
  # add all changes
  
  # find all changes, and for each change
  # call add_file?
  # or go into each submodule and root repo and do a git add -A
  
  print "Adding all with -A is not yet supported\n";
  exit();
}
else
{
  # add just the specified changes
  print "Add just the specified changes\n";
  
  my $argc = @ARGV;  # get the number of arguments.
  
#  print "Arg count " . $argc . "\n";
  
  foreach(@ARGV)
  {
     add_file($_);
     
     # ensure that we are still at the same starting directory as when the caller
     # called this script.  This is important because all of the paths passed in
     # are relative to it.
     chdir $cwd;
  }
  
}


sub ParseArgs()
{
  Getopt::Long::GetOptions(
     "-A"  => \$add_all_bool
     );
}



sub add_file($)
{
  my $relative_path_and_file = $_[0];
  my $path = "";
  my @path_array;
  my $dir_count;
  my $file = "";
  my $i;
  
  print "Adding file $relative_path_and_file\n";

  @path_array = split /\//, $relative_path_and_file;
  $dir_count = @path_array;
  
#  print "components of path: " . $dir_count . "\n";
  
  $i = 0;
  foreach(@path_array)
  {
    $i = $i + 1;
    if($i == $dir_count)
    {
      $file = $_;
      last;
    }

    $path = $path . $_ . "/";
  }
  
#  print getcwd() . "\n";
#  print "path is: $path\n";  
#  print "file is $file\n";  

  # if the file is in the current directory, we do not need to chdir
  if($path ne "")
  {
    chdir $path;
  }
  else
  {
#    print "path is null\n";
  }
  print `git add $file`;

  my $dir = getcwd();
  system("echo nuggit_add.pl, directory: $dir, adding file: $file    >> $root_dir/.nuggit/nuggit_log.txt");  
  
}
