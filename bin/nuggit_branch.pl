#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Pod::Usage;
use Cwd qw(getcwd);
use File::Spec;
use Git::Nuggit;

=head1 SYNOPSIS

List or create branches.

To create a branch, "ngt branch BRANCH_NAME"

To list branches, "ngt branch".  Note the output of "ngt status" with optional "-a" and "-d" flags will also display the currently checked out branches along with additional details.

To list all branches, "ngt branch -a"

To delete a branch, "ngt branch -d BRANCH_NAME".  See below for additional options.

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item -d | --delete

Equivalent to "git branch -d", deleting the specified branch name only if it has been merged into HEAD.  This version will apply said change to all submodules.

=item -D | --DELETE

This flag forces deletion of the branch regardless of merged state. Usage is otherwise the same as -d above and mirrors "git branch -D"

=item -rd

Delete specified branch from the remote origin for the root repository, and all submodules, providing that said branch has been merged into HEAD [as known to local system].  Precede this commmand with a "ngt fetch" to ensure local knowledge is up to date with the current state of the origin to improve accuracy of this check.

This check is meant to supplement server-side hooks/settings to help minimize user errors, but does not replace the utility of additional server-side checks.

=item -rD

Delete specified branchf rom the remote origin for the root repository, and all submodules, unconditionally.

=item --all | -a

List all known branches, not just those that exist locally.  Remote branches are typically prefixed with "remotes/origin/".  This is equivalent to the same option to "git branch".

=item --merged | --no-merged

Filter branch listing by merged or not merged state.  If neither option is specified, then all matching branches will be displayed.  This may be combined with the "-a" option, and is equivalent to the same option in "git branch".

NOTE: If the '--no-merged' option is specified, checks for submodule branches matching root will be skipped.

=back

=cut


# usage: 
#
# to view all branches just use:
# nuggit_branch.pl
#     This will also check to see if all submodules are on the same branch and warn you if there are any that are not.
#
# to create a branch
# nuggit_branch.pl <branch_name>
#
# to delete fully merged branch across all submodules
# nuggit_branch.pl -d <branch_name> 
#     TO DO - DO YOU NEED TO CHECK THAT ALL BRANCHES ARE MERGED ACROSS ALL SUBMODULES BEFORE DELETING ANY OF THE BRANCHES IN ANY SUBMODULES???????
#

sub ParseArgs();
sub is_branch_selected_throughout($);
sub create_new_branch($);
sub get_selected_branch_here();

my $ngt = Git::Nuggit->new();

my $cwd = getcwd();
my $root_repo_branches;
my $show_all_flag             = 0; # IF set, show all branches
my $create_branch             = 0;
my $delete_branch_flag        = 0;
my $delete_merged_flag        = 0;
my $delete_remote_flag        = 0;
my $delete_merged_remote_flag = 0;
my $show_merged_bool          = undef; # undef = default, true=merged-only, false=unmerged-only
my $verbose = 0;
my $selected_branch = undef;

# print "nuggit_branch.pl\n";

ParseArgs();
my $root_dir = $ngt->root_dir();

chdir $root_dir;


if($delete_branch_flag)
{
    $ngt->start(level=> 1, verbose => $verbose);
  say "Deleting merged branch across all submodules: " . $selected_branch;
  delete_branch($selected_branch);
} elsif ($delete_merged_flag) {
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting branch across all submodules: " . $selected_branch;
    delete_merged_branch($selected_branch);
} elsif ($delete_remote_flag) {
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting branch from origin across all submodules: " . $selected_branch;
    delete_remote_branch($selected_branch);
} elsif ($delete_merged_remote_flag) {
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting merged branch from origin across all submodules: " . $selected_branch;
    delete_merged_remote_branch($selected_branch);
} elsif (defined($selected_branch)) {
    $ngt->start(level=> 1, verbose => $verbose);
    create_new_branch($selected_branch);
} else {
    $ngt->start(level=> 0, verbose => $verbose);
    display_branches();
}

sub display_branches
{
    my $flag = ($show_all_flag ? "-a" : "");
    if (defined($show_merged_bool)) {
        if ($show_merged_bool) {
            $flag .= " --merged";
        } else {
            $flag .= " --no-merged";
        }
    }

    $root_repo_branches = `git branch $flag`;
    $selected_branch    = get_selected_branch($root_repo_branches);
    
    # Note: If showing merged/no-merged, selected branch may be unknown
    say "Root repo is on branch: ".colored($selected_branch, 'bold') if $selected_branch;
    if ($root_repo_branches) {
        print color('bold');
        print "All " if $show_all_flag;
        if (defined($show_merged_bool)) {
            if ($show_merged_bool) {
                print "Merged ";
            } else {
                print "Unmerged ";
            }
        }
        say "Branches:";
        print color('reset');
        say $root_repo_branches;
    }

  # --------------------------------------------------------------------------------------
  # now check each submodule to see if it is on the selected branch
  # for any submodules that are not on the selected branch, display them
  # show the command to set each submodule to the same branch as root repo
  # --------------------------------------------------------------------------------------
    is_branch_selected_throughout($selected_branch) if $selected_branch;

}


sub ParseArgs()
{
    my ($help, $man);
    Getopt::Long::GetOptions(
        "delete|d!"  => \$delete_branch_flag,
        "DELETE|D!"  => \$delete_merged_flag,
        "rd!"        => \$delete_remote_flag,
        "rD!"        => \$delete_merged_remote_flag,
        "merged!"    => \$show_merged_bool,
      "all|a!" => \$show_all_flag,
      "verbose!" => \$verbose,
      "help"            => \$help,
      "man"             => \$man,
      );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    # If a single argument is specified, then it is a branch name. Otherwise user is requesting a listing.
    if (@ARGV == 1) {
        $selected_branch = $ARGV[0];
    }
}

sub create_new_branch($)
{
    my $new_branch = shift;
    $ngt->run_die_on_error(0);
 
  # create a new branch everywhere but do not switch to it.
  say "Creating new branch $new_branch";
  $ngt->run("git branch $new_branch");
  submodule_foreach(sub {
      $ngt->run("git branch $new_branch");
                    });
}



# check all submodules to see if the branch exists
sub is_branch_selected_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  my $branch_consistent_throughout = 1;
  my $cnt = 0;

  submodule_foreach(sub {
      my $subname = File::Spec->catdir(shift, shift);
      
      my $active_branch = get_selected_branch_here();
         
      if ($active_branch ne $branch) {
          say colored("$subname is not on selected branch", 'bold red');
          say "\t Currently on branch $active_branch";
          $cnt++;
                    
          $branch_consistent_throughout = 0;
      }
                    });

  if($branch_consistent_throughout == 1)
  {
      say "All submodules are are the same branch";
  } else {
      say "$cnt submodules are not on the same branch.";
      say "If this is not desired, and no commits have been made to erroneous branches, please resolve with 'ngt checkout $branch'.";
      say "If changes have been erroneously made to the wrong branch, manual resolution may be required in the indicated submodules to merge branches to preserve the desired state.";
  }
  
  return $branch_consistent_throughout;
}

sub delete_merged_branch
{
    delete_branch(shift, "-D");
}

sub delete_branch
{
  my $branch = shift;
  my $flag = shift || "-d";

  $ngt->run("git submodule foreach --recursive git branch $flag $branch");
  $ngt->run("git branch $flag $branch");
}
sub delete_remote_branch
{
    my $branch = shift;
    $ngt->run("git push origin --delete $branch");
    submodule_foreach(sub {
        $ngt->run("git push origin --delete $branch");
                      }
        );
}
sub delete_merged_remote_branch
{
    my $branch = shift;
    my $delete = 1;
    my $check_cmd = "git branch -a --merged | grep 'remotes' | grep $branch";

    say $check_cmd . " = " . `$check_cmd`;
    my $status = `$check_cmd`;
    say "DBG: Not merged" unless $status;
    
    $delete = 0 unless `$check_cmd`;
    submodule_foreach(sub {
        if (`$check_cmd`) {

        } else {
            $delete = 0;
            say "DBG: Branch not found in ".getcwd();
        }
#        $delete = 0 unless `$check_cmd`;
                      });
    
    if ($delete) {
        # Branch was merged locally, so it should be safe to delete remotely
        delete_remote_branch($branch);
    } else {
        say "This branch is not known locally, or has not been merged into HEAD.  Use '-rD' to force deletion anyway.  It may not be possible to recover branches that have been deleted remotely.";
    }
}
