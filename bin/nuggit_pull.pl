#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path

require "nuggit.pm";


# usage: 
#
# nuggit_pull.pl
#

print "nuggit_pull.pl\n";

my $skip_status_check = 1;
my $commit_message;
my $edit_flag = 1; # Mirrors Git's edit/no-edit flag
my $verbose = 0;

GetOptions(
           'verbose!' => \$verbose,

           # TODO: Support for pulling from other branch, remote, or repo (for advanced users)

           # The following options if defined are passed-through to nuggit_merge
           'message=s'  => \$commit_message, # Specify message to use for any commits upon merge (optional; primarily for purposes of automated testing). If omitted, user will be prompted for commit message.  An automated message will be used if a conflict has been automatically resolved.
           'edit!' => \$edit_flag,
           'skip-status-check!' => \$skip_status_check
           );

my $root_dir = do_upcurse();

if (!$skip_status_check) {
    my $status = get_status();
    if (!status_check($status))
    {
        say colored("Local changes detected.  Please commit or stash all changes before running pull.", 'red');
        say colored(" If you wish to attempt the pull anyway, re-run this command with '--skip-status-check' flag.", 'yellow');
        say "\nCurrent repository status is: ";
        pretty_print_status();
        die "Pull aborted due to dirty working directory.  Please commit, or re-run with --skip-status-check";
    }
}


# Execute a Fetch
# TODO: Make this a lib fn and add checks to confirm fetch succeeded
require("$FindBin::Bin/nuggit_fetch.pl");

# Execute Nuggit Merge of remotes/origin/$selected_branch
#  TODO: support for alternate remotes
my $args = "--log-as-pull";
$args .= " --message \"$commit_message\"" if defined($commit_message);
$args .= " --no-edit" if !$edit_flag; # Default is edit
$args .= " --verbose" if $verbose;
exec("$FindBin::Bin/nuggit_merge.pl $args");


# Done (exec never returns)

