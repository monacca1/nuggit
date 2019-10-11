#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";

do_upcurse();

# TODO: Detect if fetch fails
print `git fetch --all --recurse-submodules`;
#print `git submodule foreach --recursive git fetch --all`;
