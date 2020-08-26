#!/usr/bin/env perl

#*******************************************************************************
##                           COPYRIGHT NOTICE
##      (c) 2019 The Johns Hopkins University Applied Physics Laboratory
##                         All rights reserved.
##
##  Permission is hereby granted, free of charge, to any person obtaining a 
##  copy of this software and associated documentation files (the "Software"), 
##  to deal in the Software without restriction, including without limitation 
##  the rights to use, copy, modify, merge, publish, distribute, sublicense, 
##  and/or sell copies of the Software, and to permit persons to whom the 
##  Software is furnished to do so, subject to the following conditions:
## 
##     The above copyright notice and this permission notice shall be included 
##     in all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
##  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
##  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
##  DEALINGS IN THE SOFTWARE.
##
#*******************************************************************************/

use strict;
use warnings;
use v5.10;
use Pod::Usage;
use Getopt::Long;
use Cwd;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use IPC::Run3; # Utility to execute application and capture both stdout and stderr
use Storable qw(store retrieve); # Serialization of merge in progress state

use Git::Nuggit;
use Git::Nuggit::Status;
use Git::Nuggit::Log;

=head1 Nuggit Merge

This script performs a submodule-aware merge, automatically resolving submodule reference-only conflicts in a manner consistent with the nuggit workflow.  If the nuggit workflow is not being strictly followed, users should explicitly verify that any automatic merges completed as expected prior to pushing any changes.

NOTE: This script is invoked by nuggit_pull.

=head1 SYNOPSIS

nuggit_merge.pl BRANCH -m "Commit message"

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item --verbose

Display additional details.

=item --default

This flag is an alias to "ngt merge refs/remotes/origin/HEAD" and can be used to safely merge root and all submodules against the default branch of each submodule.

If a branch is specified with this flag, then said branch name will be used for the root repository only.

WARNING: This is dependent on the default branch configuration of the remote server. This does NOT utilize the .gitmodules tracking 'branch' definition.

=item --continue

Resume a merge already in progress.

=item --abort

Abort a merge in progress.

NOTE: This feature is NOT COMPLETE.  The nuggit merge state will be deleted, but your repository may be left in a conflicted state that must be manually reverted at this time.

=item --message

Specify message to use for any commits upon merge

=item --no-edit

If specified, this flag will be passed on to git such that the default merge message will be used for any commits.

=back

=head1 TODO

- If new submodule is detected, automatically handle by running submodule update --init after (assuming all changes committed / no conflicts)
- --abort option only removes state file and does not cleanup repo
   - TODO: How to reset remainder of workspace?  Perhaps instruct user to run nuggit checkout command?

=cut



my $argc;
my $source_branch = "";
my $destination_branch;
my $branch = "";
my $commit_message;
my $verbose = 0;
my $merge_continue_flag = 0; # IF set, attempt to resume existing merge
my $abort_merge_flag = 0;
my $edit_flag = 1; # Mirrors Git's edit/no-edit flag
my $help = 0; my $man = 0;
my $log_as_pull; # For logging/tracing purposes only
my $merge_remote_head = 0;

my ($root_dir, $relative_path_to_root) = find_root_dir();
my $log = Git::Nuggit::Log->new(root => $root_dir);

# Parse Options (positional arguments will be handled after)
GetOptions(
    "help"            => \$help,
    "man"             => \$man,
    'verbose!' => \$verbose,
    'continue' => \$merge_continue_flag,
    'abort'    => \$abort_merge_flag,
    'message=s'  => \$commit_message, # Specify message to use for any commits upon merge (optional; primarily for purposes of automated testing). If omitted, user will be prompted for commit message.  An automated message will be used if a conflict has been automatically resolved.
    'edit!' => \$edit_flag,
           'log-as-pull' => \$log_as_pull, # For logging purposes only in liueue of an OOP call from pull wrapper
           'remote|default!' => \$merge_remote_head,
          );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
die("Not a nuggit!") unless $root_dir;
$log->start(verbose => $verbose, level => 1, log_as_child => $log_as_pull);

my $merge_conflict_file = "$root_dir/.nuggit/merge_conflict_state";

if ($merge_continue_flag) {
    resume_merge($root_dir);
    exit()
} elsif ($abort_merge_flag) {
    abort_merge_state();
    exit();
} elsif (-e $merge_conflict_file) {
    die "ERROR: Cannot start a new merge when one is already in progress.  Run 'nuggit merge --continue' to complete the merge, after resolving any conflicts, or with '--abort' to abandon it.";
} else { # Else start a fresh merge
    my $source = $ARGV[0];
    if (!defined($ARGV[0])) {
        # Use remote for current branch; This is the default git behavior
        say "No branch specified for merge, assuming default remote";
        $source = "";
    }
    
    # TODO: Need to handle merge from master with varying branches

    chdir($root_dir);
    my $merge = {
                 "source" => $source,
                 "destination" => get_selected_branch_here(),
                 "submodules" => get_submodules(),
                 "merge_default" => $merge_remote_head,
                };

    if ($merge_remote_head) {
        say "Source Branch: Remote Default (per-repository)";
    } else {
        say "Source branch is: $source";
    }
    say "Destination branch is the current branch: ".$merge->{destination};

    do_merge_recursive($merge);
}

# Recursive Merge Driver
sub do_merge_recursive
{
    my $merge = shift;
    my $branch;

    if ($merge->{'merge_default'}) {
        # User has requested to merge against the tracking branch (ie: from .gitmodules)
        $branch = "refs/remotes/origin/HEAD"; # TODO: Make remote name configurable
    } else {
        $branch = $merge->{'source'}; # Typical case
    }

    say colored("do_merge_recursive() at ".cwd(),'green') if $verbose;
    
    while(my $repo = shift(@{$merge->{submodules}} ) ) {
        my $dir = File::Spec->catdir($root_dir,$repo);
        
        $merge->{'conflicted'} = $repo; # log last repo parsed for easy save/restore
        chdir($dir) || exit_save_merge_state("Internal Error: Failed to enter directory $repo");

        do_merge($merge, $branch) || exit_save_merge_state($merge);
    }
    chdir($root_dir);
    if ($merge->{'merge_default'} && !$merge->{'source'}) {
        $branch = "refs/remotes/origin/HEAD";
    } else {
        $branch = $merge->{'source'};
    }
    do_merge($merge, $branch) || exit_save_merge_state($merge);

    return;
    
}

=head1 do_merge

Perform actual Merge operation on current directory (no recursion).
Caller is responsible for changing cwd prior to executing, and for calling this on submodules in the desired order (depth-first)

If an error is detected during the merge, this function will throw an exception (die) to abort execution.  Merge process can be restarted once the conflict/error has been resolved.

=cut

sub do_merge
{
    my $merge = shift; # Merge Configuration Object
    my $source_branch = shift; # Branch to merge
    say colored("do_merge($source_branch) at ".cwd(),'green') if $verbose;
    
    # Are we in a detached head?
    # If so, abort -- nominal workflow assumes this shouldn't be the case
    # DEFERRED/TODO: A merge from a detached head is not recommended, but not fatal, so we can add this check later

    # Execute merge, capture STDOUT and STDERR as needed
    my $merge_cmd = "git merge $source_branch";
    my ($stdout, $stderr);
    run3($merge_cmd, undef, \$stdout, \$stderr);
    $log->cmd($merge_cmd);

    # Did merge fail due to specified branch/ref being invalid?
    # TODO

    # Are there any conflicts
    if ($stdout =~ /Automatic merge failed/) {
        # Split stdout into lines
        my @lines = split("\n",$stdout);

        my $num_submodule_conflicts = 0;
        my $num_unresolved_conflicts = 0;

        # Parse Output
        foreach my $line (@lines) {
            # Is this a submodule conflict?
            if ($line =~ /CONFLICT \(submodule\)\: Merge conflict in ([\w\/\-]+)/) {                
                # In Nuggit Workflow, we have pulled latest from branch, and therefore will assume current commit is valid
                # NOTE: This will always work when invoked via pull, but MAY cause issues when merging branches in an atypical state.

                my $conflicted = $1;

                # Verify we havce identified an actual submodule (or at least a valid directory)
                if (!-d $conflicted) {
                    die "Internal Error: $conflicted is not a directory. This may be a bug or unhandled condition.\n Currently in "
                    .cwd()
                    .", and git reported: \n $stdout \n $stderr";
                }

                # Stage file and increment counter
                my $cmd = "git add $conflicted";
                system($cmd);
                $log->cmd($cmd);
                $num_submodule_conflicts++;
                say "Automatically resolving submodule reference conflict for $conflicted";
            } elsif ($line =~ /CONFLICT/) {
                say $line;
                $num_unresolved_conflicts++;
            }
        }

        if ($num_submodule_conflicts > 0) {
            say "$num_submodule_conflicts conflicted submodule references have been automatically resolved under ".cwd().". If you have diverged from the nominal Nuggit workflow, please confirm that all conflicts were resolved as expected prior to pushing.";
        }

        # Abort if we have unresolved conflicts
        return 0 if $num_unresolved_conflicts > 0;
        
        # Commit the resolved conflicts and verify state
        if ($num_submodule_conflicts > 0) {
            commit_conflict_resolution($merge);
        }
        
    }

    # If we reach this point, there are no unresolved conflicts

    # Did this merge introduce any new submodules? If so, explicitly checkout/initialize them
    # TODO: git submodule update --init $new_submodule_path
    # TODO: Ensure nuggit consistency by checking out correct branch?

    return 1;
    
}

sub resume_merge
{
    my $base_dir = shift;
    chdir($base_dir);
    my $merge = load_merge_state();
    my $current_branch = get_selected_branch_here();
    say colored("resume_merge() at ".$merge->{'conflicted'},'green') if $verbose;
    
    # Verify current branch matches that in saved merge state, else give an error
    if ($current_branch ne $merge->{'destination'}) {
        die("Repository not in expected state for resumption. Merge began on branch $merge->{'destination'} but we are on $current_branch");
    }

    # Enter conflicted repo
    chdir($merge->{'conflicted'}) || die("Failed to return to conflicted submodule at ".$merge->{'conflicted'});
    
    # Commit the resolved conflicts and verify state
    commit_conflict_resolution($merge);

    # Complete the merge
    do_merge_recursive($merge);


    # Clear conflict state file
    unlink($merge_conflict_file);

    return;
    
}

sub commit_conflict_resolution
{
    my $merge = shift;
    say colored("commit_conflict_resolution at ".cwd(),'green') if $verbose;
    
    # Get status of conflicted repo (this fn works from current dir down)
    my $status = get_status({uno => 1});

    # Unless all changes (aside from refs) are staged (ie: conflicts resolved), abort
    if ($status->{'status'} >= STATE('UNTRACKED')) {
        if ($status->{'unstaged_files_cnt'} > 0) {
            say "Unable to complete merge.  You have $status->{'unstaged_files_cnt'} unresolved/unstaged files remaining under ".cwd();
            exit_save_merge_state($merge);
        } else {
            # Add all submodules (directory objects) at this level
            foreach my $file (keys %{$status->{'objects'}}) {
                if (-d $file) {
                    # This is a directory, auto-stage it; this should be a submodule that's already been merged
                    my $cmd = "git add $file";
                    system($cmd);
                    $log->cmd($cmd);
                    say "Automatically staging $file";
                } else {
                    # This case indicates a bug in the merge algorithm or status check
                    say "Error completing merge (BUG?). Expected $file to be a submodule but it is not a directory";
                    exit_save_merge_state($merge);
                }
            }
        }
    }
    
    # Commit changes at this level to complete the merge
    my $cmd = "git commit";
    if ($commit_message) {
        $cmd .= " -m \"$commit_message\"";
    } elsif (!$edit_flag) {
        $cmd .= " --no-edit";
    }
    system($cmd);
    $log->cmd($cmd);

    # Re-test status to confirm success (ignore untracked)
    $status = get_status({uno => 1});
   
    #say "commit_conflict_resolution() status is: ".Dumper($status);

    # TODO: We should probably save state here
    die "Failed to resolve conflict at ".cwd().".  See above output for details." unless status_check($status);

}

sub exit_save_merge_state
{
    my $obj = shift; # Hashref of state to be saved

    store($obj, $merge_conflict_file) || die("Merge aborted with conflicts. Internal error saving nuggit state, resolve manually");

    # And exit; we 'die' since we want to exit with an error state
    die("Merge aborted with conflicts.  Please resolve (stash or edit & stage) then run \"nuggit merge --continue\" to continue.");
}
sub load_merge_state
{
    die("Error: No Nuggit Merge in progress. If a merge was started outside of nuggit, it must be finished without it.") unless -e $merge_conflict_file;
    my $state = retrieve($merge_conflict_file);
    die("Error loading merge_conflict_state") unless defined($state);
    return $state;
}
sub abort_merge_state
{
    if (-e $merge_conflict_file) {
        # NOTE: This makes no guarantees that repo is in a usable state
        # We will backup the conflict information for debug purposes
        rename($merge_conflict_file, "$merge_conflict_file.aborted");

        say "Aborted merge in progress. No guarantees are made as to the current state of the repository.  Reversion of changes, including any git merges in progress are TODO";
    } else {
        say "ERROR: No Merge in progress to abort";
    }
}


