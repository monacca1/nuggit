#!/usr/bin/env perl

=head1 Nuggit Foreach

This script provides a generic wrapper for commands (got or otherwise) to be executed as-is on each submodule, with all arguments passed along.  This is effectively a wrapper for "git submodule foreach" that invokes the command depth-first, ending with the root level.

Usage is:  "nuggit <cmd> <args>".

NOTICE: Unlike "git submodule foreach", this script may NOT abort on first error, and WILL also be executed at the (nuggit) root level.

=cut

use strict;
use warnings;
use v5.10;

use FindBin;
use lib $FindBin::Bin.'/../lib';
use Term::ANSIColor;
require "nuggit.pm";

my $cmd = join(' ', @ARGV); # $ARGV[0];

say "Nuggit Wrapper; $cmd";

# Start at root Nuggit repo
my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;
chdir $root_dir || die("Error: Can't enter root; $root_dir");


submodule_foreach(sub {
                      my ($parent, $name, $status, $hash, $label) = (@_);
                      say colored("$parent/$name - Executing $cmd", 'green');
                      say `$cmd`;
                  });
say colored("Root ($root_dir) - $cmd", 'green');
say `$cmd`;

# Done
