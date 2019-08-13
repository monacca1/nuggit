#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);


# usage: 
#
# nuggit_pull.pl
#

print "nuggit_pull.pl\n";


my $root_dir;
my $relative_path_to_root;
my $git_status_cmd = "git status --porcelain --ignore-submodules";
my $git_diff_cmd   = "git diff --name-only --cached";
my $cached_bool;

$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}

# the relative path to root is used in the output.
# it is used before each file in each submodule with a status change.
# this is done so the user can copy the entire path and call
# nuggit_add.pl or nuggit_diff.pl on that path and it is valid
$relative_path_to_root = `nuggit_get_path_relation_to_root.pl`;
chomp $relative_path_to_root;

#print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";
#print $relative_path_to_root . "\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;

print `git pull`;
print `git submodule foreach --recursive git pull`;


