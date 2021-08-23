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
use Getopt::Long;
use Pod::Usage;
use Cwd qw(getcwd);
use Term::ANSIColor;
use File::Spec;
use Git::Nuggit;
use JSON;

=head1 SYNOPSIS

List or create branches.

To create a branch, "ngt branch BRANCH_NAME"

To list branches, "ngt branch".  Note the output of "ngt status" with optional "-a" and "-d" flags will also display the currently checked out branches along with additional details.

To list all branches, "ngt branch -a"

To delete a branch, "ngt branch -d BRANCH_NAME".  See below for additional options.

NOTE: The "-r" syntax for deleting remote repositories in Nuggit differs from native git. In git this command requires specifying a branch in the form 'origin/branch' and only removes them locally.  Nuggit does not require the prefix, and removes them locally and remotely.

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item -d | --delete

Delete specified branch from the root repository, and all submodules, providing that said branch has been merged. 

Equivalent to "git branch -d", deleting the specified branch name only if it has been merged into HEAD.  This version will apply said change to all submodules.

=item -D | --delete-force

This flag forces deletion of the branch regardless of merged state. Usage is otherwise the same as -d above and mirrors "git branch -D"

=item -r | remote

Apply operation to the remote (server) branch.  

This flag currently applies only branch deletion operations, and is explicitly documented below as '-rd' and '-rD'.

Typical usage is: "ngt branch -rd branch" or "ngt branch -rD branch".

Note: Unlike the native git branch command, no 'origin' prefix is required here.

=item -rd

This will delete the specified branch from the remote origin for the root repository, and all submodules, providing that said branch has been merged into HEAD [as known to local system].  Precede this commmand with a "ngt fetch" to ensure local knowledge is up to date with the current state of the origin to improve accuracy of this check.

This check is meant to supplement server-side hooks/settings to help minimize user errors, but does not replace the utility of additional server-side checks.

=item -rD

Delete specified branch from the remote origin for the root repository, and all submodules, unconditionally.

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

my $ngt = Git::Nuggit->new() || die("Not a nuggit!");

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
my $show_json = 0;
my $selected_branch = undef;

# print "nuggit_branch.pl\n";

ParseArgs();
my $root_dir = $ngt->root_dir();

chdir $root_dir;

if($delete_branch_flag)
{
  $ngt->start(level=> 1, verbose => $verbose);
  say "Deleting merged branch across all submodules: " . $selected_branch;
  delete_branch($selected_branch, "-D");
} 
elsif ($delete_merged_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting branch across all submodules: " . $selected_branch;
    delete_merged_branch($selected_branch);
}
elsif ($delete_remote_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting branch from origin across all submodules: " . $selected_branch;
    delete_remote_branch($selected_branch);
}
elsif ($delete_merged_remote_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting merged branch from origin across all submodules: " . $selected_branch;
    delete_merged_remote_branch($selected_branch);
}
elsif (defined($selected_branch)) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    create_new_branch($selected_branch);
}
else
{
    $ngt->start(level=> 0, verbose => $verbose);
    if ($show_json) {
        verbose_display_branches();
    } else {
        display_branches();
    }
}

sub verbose_display_branches
{
    # TODO: This may will eventually replace display_branches below, with a new text-output added here
    # TODO: If user requests to check all submodules, call get_branches on all submodules
    #        and verify branch is consistent throughout (similar to below, but saving output for more display options)
    # Output would then be either:
    # - Text listing similar to current, but extend by noting branches for any submodule that differs
    # - JSON output
    #   - is_consistent: bool
    #   - branches: Root branches object
    #   - submodules: Object where key is submodule path and value is branch listing

    my $branches = get_branches({
        all => $show_all_flag,
        merged => $show_merged_bool,
       });
    say encode_json($branches);
}

sub display_branches
{
    my $flag = ($show_all_flag ? "-a" : "");
    if (defined($show_merged_bool)) 
    {
        if ($show_merged_bool) 
        {
            $flag .= " --merged";
        }
        else
        {
            $flag .= " --no-merged";
        }
    }

    $root_repo_branches = `git branch $flag`;
    $selected_branch    = get_selected_branch($root_repo_branches);
    
    # Note: If showing merged/no-merged, selected branch may be unknown
    say "Root repo is on branch: ".colored($selected_branch, 'bold') if $selected_branch;
    if ($root_repo_branches) 
    {
        print color('bold');
        print "All " if $show_all_flag;
        if (defined($show_merged_bool))
	{
            if ($show_merged_bool) 
	    {
                print "Merged ";
            }
	    else
	    {
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
    my ($help, $man, $remote_flag);
    Getopt::Long::Configure("no_ignore_case", "bundling");
    Getopt::Long::GetOptions(
        "delete|d!"  => \$delete_merged_flag,
        "delete-force|D!"  => \$delete_branch_flag,
        "remote|r"    => \$remote_flag,
        "merged!"    => \$show_merged_bool,
        "all|a!" => \$show_all_flag,
        "verbose|v!" => \$verbose,
        "json!" => \$show_json, # For branch listing command only
        "help"            => \$help,
        "man"             => \$man,
      ) || pod2usage(1);
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    if ($remote_flag) {
        if ($delete_branch_flag) { $delete_branch_flag = 0; $delete_remote_flag = 1; }
        if ($delete_merged_flag) { $delete_merged_flag = 0; $delete_merged_remote_flag = 1; }
    }
    die "Error: Please specify only one of '-d' or '-D' flags." if ($delete_branch_flag+$delete_remote_flag+$delete_merged_flag+$delete_merged_remote_flag) > 1;

    if ( ($delete_branch_flag + $delete_merged_flag + $delete_remote_flag + $delete_merged_remote_flag) > 1) {
        die "ERROR: Please specify only one version of delete flags (-d -D -rd -rD) at a time.";
    }

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
  print "Checking submodule status . . . ";

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

# Delete a branch only if it is merged at all levels
sub delete_merged_branch
{
    my $branch = shift;
    if (check_branch_merged_all($branch)) {
        delete_branch($branch, "-d");
    } else {
        die "This branch is not known, or has not been merged into HEAD.  Use '-D' to force deletion anyway.\n";
    }
}

# Base function to (unconditionally) delete a local branch, failing on first error
sub delete_branch
{
  my $branch = shift;
  my $flag = shift || "-d";

  my $cmd = "git branch $flag $branch";

  $ngt->run_die_on_error(0);
  $ngt->foreach({
      'depth_first' => sub {
          my $in = shift;
          say "DBG1";
          my ($err, $stdout, $stderr) = $ngt->run($cmd);
          say "\tDBG2";
            if ($err) {
                say colored("Deletion of $branch failed for ".($in->{'subname'} ? $in->{'subname'} : "/"), 'warn');
            }
      },
      'run_root' => 1
     });
}

# Delete a remote branch (unconditionally)
sub delete_remote_branch
{
    my $branch = shift;
    my $cmd = "git push origin --delete $branch";
    
    $ngt->run_die_on_error(0);
    $ngt->foreach({
        'depth_first' => sub {
            my $in = shift;
            my ($err, $stdout, $stderr) = $ngt->run($cmd);
            if ($err) {
                say colored("Deletion of branch $branch on remote failed for ".($in->{'subname'} ? $in->{'subname'} : "/"), 'warn');
            }
        },
        'run_root' => 1
       });
}

# Delete Remote branch, only if it is merged at all levels
sub delete_merged_remote_branch
{
    my $branch = shift;

    if (check_branch_merged_all($branch, "origin")) {
        delete_remote_branch($branch); 
    } else {
        say "This branch is not known locally, or has not been merged into HEAD.  Use '-rD' to force deletion any<way.  It may not be possible to recover branches that have been deleted remotely.";
    }
}

# TODO: Make this an option to call directly, ie: ngt branch -a --merged ? Or ngt branch --check-merged $branch
# TODO: TEST
sub check_branch_merged_all
{
    my $branch = shift;
    my $remote = shift;
    my $status = 1; # Consider it successful, unless we find a branch that is not merged

    # TODO: Replace remotes with origin for local detection?
    my $check_cmd = "git branch -a --merged";
    
    $ngt->foreach( {'depth_first' => sub {
                           my $state = `$check_cmd`;
                           if (!$state) {
                               $status = 0;
                               say "Branch ($branch) not merged/found at ".getcwd() if $verbose;
                           } else {
                               my @lines = split('\n', $state);
                               my $linefound = 0;
                               foreach my $line (@lines) {
                                   $line =~ /(remotes\/(?<remote>\w+)\/)?(?<branch>[\w\d\-\_\/]+)/;
                                   if ($remote && $+{remote} && $+{remote} eq $remote && $+{branch} eq $branch) {
                                       $linefound = 1; # Match for remote branch
                                       last;
                                   } elsif (!$remote && !$+{remote} && $branch eq $+{branch}) {
                                       $linefound = 1; # Match for local branch
                                       last;
                                   }
                               }
                               if (!$linefound) {
                                   $status = 0;
                                   say "Branch (line not found) not merged/found at ".getcwd() if $verbose;
                               }
                           }
                       },
                    'run_root' => 1
                   }
                  );
    return $status;
}

