#!/usr/bin/env perl

=head1 Nuggit Foreach

This script provides a generic wrapper for commands (got or otherwise) to be executed as-is on each submodule, with all arguments passed along.  This is effectively a wrapper for "git submodule foreach" that invokes the command depth-first, ending with the root level.

Usage is:  "nuggit <cmd> <args>".

NOTICE: Unlike "git submodule foreach", this script may NOT abort on first error, and WILL also be executed at the (nuggit) root level.

=cut

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use FindBin;
use lib $FindBin::Bin.'/../lib';
use Term::ANSIColor;
use Git::Nuggit;

# Modifier Arguments
my $break_on_error = 1; # If true, die on first child task to exit with a non-zero error code
my $opts = {
            "recursive" => 0,
           };
my $verbose = 0;

# TODO: Parse Command-line arguments.  Arguments must be the first argument, and must end with a '--'
if (0) { #if ($ARGV[0] ~= /^\-/) {
    # Command line arguments to parse

#    if ($ARGV[0] != /\-\-/) {
#        say colored("WARNING: Usage of '--' after foreach arguments is recommended to avoid mangling options ot child task.", 'red');
#    }

    GetOptions(
               "verbose!" => \$verbose,
               "break-on-error!" => \$break_on_error,
               "recursive!" => \$opts->{'recursive'},
               );
}

my $cmd = join(' ', @ARGV); # $Pass all remaining arguments on

say "Nuggit Wrapper; $cmd";

# Start at root Nuggit repo
my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;
chdir $root_dir || die("Error: Can't enter root; $root_dir");


submodule_foreach(sub {
                      my ($parent, $name, $status, $hash, $label) = (@_);
                      say colored("$parent/$name - Executing $cmd", 'green');
                      say `$cmd`;
                      if ($break_on_error) {
                          die("Command failed") if $? != 0;
                      }
                  }, $opts);
say colored("Root ($root_dir) - $cmd", 'green');
say `$cmd`;

# Done
