#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);

# to do


print `git fetch`;
print `git submodule foreach --recursive git fetch`;
