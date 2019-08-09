#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);

# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_find_root.pl
#

# find the .nuggit. This script will only search
# in the current directory and 10 directories up and then give up

my $cwd = getcwd();
my $nuggit_root;

my $max_depth = 10;
my $i = 0;

for($i = 0, $i < $max_depth, $i = $i+1)
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
}

print "ERROR - could not find .nuggit\n";
