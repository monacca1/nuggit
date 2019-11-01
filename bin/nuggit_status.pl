#!/usr/bin/env perl
# This file will replace nuggit_status.pl upon completion

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Data::Dumper; # Debug and --dump option
require "nuggit.pm";
use Git::Nuggit::Status;

my $cached_bool = 0; # If set, show only staged changes
my $unstaged_bool = 0; # If set, and cached not set, show only unstaged changes
my $verbose = 0;
my $do_dump = 0; # Output Dumper() of raw status (debug-only)
my $do_json = 0; # Outptu in JSON format
my $flags = {
             "uno" => 0, # If set, ignore untracked objects (git -uno command). This has no effect on cached or unstaged modes (which always ignore untracked files)
             "ignored" => 0, # If set, show ignored files
            };
my $color_submodule = 'yellow';

  Getopt::Long::GetOptions(
                           "cached|staged"  => \$cached_bool, # Allow --cached or --staged
                           "unstaged"=> \$unstaged_bool,
                           "verbose!" => \$verbose,
                           "uno!" => \$flags->{uno},
                           "ignored!" => \$flags->{ignored},
                           'dump' => \$do_dump,
                           'json' => \$do_json,
     );

my $root_repo_branch;

my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;

print "nuggit root dir is: $root_dir\n" if $verbose;
print "nuggit cwd is ".getcwd()."\n" if $verbose;
print "nuggit relative_path_to_root is ".$relative_path_to_root . "\n" if $verbose;

#print "changing directory to root: $root_dir\n";
chdir $root_dir;

# Get Status with specified options
my $status = get_status($flags); # TODO: Flags for untracked? show all?

die("Unable to retrieve Nuggit repository status") unless defined($status);

# EXPERIMENTAL: If a file/dir argument is given, filter results. Output parsing may be inconsistent for files
if (@ARGV) {
    $status = file_status($status, $ARGV[0]);
    die("Unable to find status for $ARGV[0]") unless $status;
}


say Dumper($status) if $do_dump;

if ($do_json) {
    require JSON;
    JSON->import();
    say encode_json($status);
}
else
{
    if (-e "$root_dir/.nuggit/merge_conflict_state") {
        say colored("Nuggit Merge in Progress.  Complete with \"ngt merge --resume\" or \"ngt merge --abort\"",'red');
    }
    pretty_print_status($status, $relative_path_to_root, $verbose);
    #say colored("Warning: Above output may not reflect if submodules are not initialized, on the wrong branch, or out of sync with upstream", $warnColor);
}







