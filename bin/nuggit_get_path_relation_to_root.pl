#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use Git::Nuggit;

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

my ($root_dir, $relative_path_to_root) = find_root_dir();
if ($root_dir) {
    say "Root directory found: $root_dir";
    say "Relative path: $relative_path_to_root";
} else {
    die("Not a Nuggit!");
}
