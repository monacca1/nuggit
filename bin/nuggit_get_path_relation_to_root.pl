#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);

# usage: 
#
#   nuggit_get_path_relation_to_root.pl
#

# find the .nuggit. This script will only search
# in the current directory and 10 directories up and then give up
# this script will print out the relative path to the root and assumes you are
# currently inside a nuggit repo.  
# the output format is (examples)
# if in the same directory as .nuggit
# ./ 
# if one directory down from .nuggit
# ../
# if two directories down
# ../../
# etc

my $cwd = getcwd();
my $nuggit_root;
my $path = "";

my $max_depth = 10;
my $i = 0;

for($i = 0; $i < $max_depth; $i = $i+1)
{
  if(-e ".nuggit") 
  {
     $nuggit_root = getcwd();
#     print "starting path was $cwd\n";
#     print ".nuggit exists at $nuggit_root\n";

#     print $nuggit_root . "\n";
#     print $cwd . "\n";
     if($path ne "")
     {
       print $path . "\n";
     }
     else
     {
       print "./" . "\n";
     }
     exit();
  }
  chdir  "../";
  $path = "../" . $path;
  
#  $cwd = getcwd();
#  print "$i, $max_depth - cwd = " . $cwd . "\n";
  
}

print "ERROR - could not find .nuggit\n";
