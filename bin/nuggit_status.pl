#!/usr/bin/perl -w

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
# nuggit_status.pl
# or
# nuggit_status.pl --cached
#       show the files that are in the staging area
#       that will be committed on the next commit.
#
#
# to help with machine readability each file that is staged is printed on a line beginning with S
#
# Example:
#
#/project/sie/users/monacc1/root_repo/fsw_core/apps> nuggit_status.pl --cached
#=============================================
#Root repo staging area (to be committed):
#  Root dir: /project/sie/users/monacc1/root_repo 
#  Branch: jira-xyz
#S   ../../.gitignore
#=============================================
#Submodule staging area (to be committed):
#Submodule: fsw_core/apps/appx
#Submodule and root repo on same branch: jira-xyz
#S   ../../fsw_core/apps/appx/readme_appx
#=============================================
#Submodule staging area (to be committed):
#Submodule: fsw_core/apps/appy
#Submodule and root repo on same branch: jira-xyz
#S   ../../fsw_core/apps/appy/readme_appy
#
#
#


sub ParseArgs();

#my $root_dir;
#my $relative_path_to_root;
my $cached_bool = 0; # If set, show only staged changes
my $unstaged_bool = 0; # If set, and cached not set, show only unstaged changes
my $untracked_bool = 0; # If set, ignore untracked objects (git -uno command). This has no effect on cached or unstaged modes (which always ignore untracked files)
my $verbose = 0;

ParseArgs();
my $root_repo_branch;

my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;

print "nuggit root dir is: $root_dir\n" if $verbose;
print "nuggit cwd is ".getcwd()."\n" if $verbose;
print "nuggit relative_path_to_root is ".$relative_path_to_root . "\n" if $verbose;

#print "changing directory to root: $root_dir\n";
chdir $root_dir;

# Get Status with specified options
my $status;

if($cached_bool)
{
    $status = nuggit_status("cached", $untracked_bool, $relative_path_to_root);
}
elsif($unstaged_bool)
{
    $status = nuggit_status("unstaged", $untracked_bool, $relative_path_to_root);
}
else
{
    $status = nuggit_status("status", $untracked_bool, $relative_path_to_root);
}

die("Unable to retrieve Nuggit repository status") unless defined($status);

$root_repo_branch = $status->{'branch'};
print_nuggit_status($status);

# Debug
#use Data::Dumper;
#say Dumper($status);

# TODO: indent-level printing (including for raw, unless we parse raw message)
sub print_nuggit_status
{
    my $obj = shift; # Hash Reference
    my $level = shift || 0;

    if ($obj->{'status'} ne "clean" || ($obj->{'branch'} ne $root_repo_branch)) {
        say "===========================";
        if ($level == 0) {
            say "Root repository status ".$obj->{'status'};
        } else {
            say "Submodule $obj->{'name'}: $obj->{'status'}";
        }
        say "Branch: $obj->{'branch'}";
        say colored("\tWarning: Submodule does not match root branch $root_repo_branch",'red') if ($level && $root_repo_branch ne $obj->{'branch'});
        say "SHA1: $obj->{'hash'}" if defined($obj->{'hash'}); # VERIFY
    }

    if ($obj->{'raw'}) {
        say "Details:";
        print $obj->{'raw'}; # TODO: Parsing of raw output into detailed status is TODO
    }

    # Output status of any children (submodules)
    if ($obj->{'children'}) {
        my $children = $obj->{'children'};
        foreach my $sub (@$children) {
            print_nuggit_status($sub, $level+1);
        }
    }
}



sub ParseArgs()
{
  Getopt::Long::GetOptions(
                           "cached|staged"  => \$cached_bool, # Allow --cached or --staged
                           "unstaged"=> \$unstaged_bool,
                           "verbose!" => \$verbose,
                           "uno" => \$untracked_bool,
     );
}

# NOTE: Status functions moved to nuggit.pm for usage by other user applications

