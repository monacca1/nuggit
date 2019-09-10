#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";


my $nuggit_log_file = get_nuggit_log_file_path();
nuggit_log_entry("=====================================", $nuggit_log_file);
nuggit_log_entry("nuggit fetch", $nuggit_log_file);

print `git fetch --all`;
print `git submodule foreach --recursive git fetch --all`;
