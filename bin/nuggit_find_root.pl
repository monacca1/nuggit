#!/usr/bin/perl -w
# NOTICE: THIS FILE IS DEPRECATED IN FAVOR OF lib/nuggit.pm's find_root_dir()

use strict;
use warnings;

use Cwd qw(getcwd);

# prints the root directory of the nuggit or 0

# usage: 
#
# nuggit_find_root.pl
#

# find the .nuggit. This script will only search
# in the current directory and 10 directories up and then give up



my $cwd = getcwd();
my $nuggit_root;

my $max_depth = 10;
my $i = 0;

for($i = 0; $i < $max_depth; $i = $i+1)
{
  if(-e ".nuggit") 
  {
     $nuggit_root = getcwd();
#     print "starting path was $cwd\n";
#     print ".nuggit exists at $nuggit_root\n";

     print $nuggit_root . "\n";
     exit();
  }
  chdir "../";
  
#  $cwd = getcwd();
#  print "$i, $max_depth - cwd = " . $cwd . "\n";
  
}

print "-1";
