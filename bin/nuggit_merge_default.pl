#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";



# TO DO 
# - this script will 
#       - recurse into each submodule,
#               - identify the default branch
#               - merge that branch into the working branch
#               - add and commit?
#       - as it moves back up the tree, add & commit
#       - or the submodule references will be corrected with the new script
#              - nuggit_relink.pl
#
# 



print "nuggit_merge_default.pl\n";

my $root_dir;
my $root_repo_branch;


$root_dir = find_root_dir() || die("Not a nuggit!\n");



