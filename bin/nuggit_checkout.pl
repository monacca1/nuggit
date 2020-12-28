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
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Term::ANSIColor;
warn "nuggit_checkout.pl is DEPRECATED in favor of 'nuggit_ops.pl checkout --strategy=branch', or 'nuggit_ops.pl checkout' for recommended ref-first";

=head1 SYNOPSIS

nuggit checkout [options] <object|file>

This script mirrors "git checkout" in the context of nuggit.  It includes a subset of the functions available with the "git checkout" command, with matching usage, plus a number of additional options to aide the submodule-aware user.

Checkout a given commit object (hash, branch name, or tag name), or checkout (aka revert) a given file to HEAD.  Specify "-b" to create a new branch.  To checkout a file that has been deleted (or to checkout a directory), explicitly include the "--file" flag to avoid ambiguities.  

Use "--man" to display additional usage information and examples.


=head1 Options

NOTE: This script is written to be highly configurable, with sensible defaults provided for the most commonly envisioned Nuggit usage scenario.  In the future, this may be extended to allow defaults to be overridden per nuggit workspace to reflect project preferences.  

The following additional options are supported:

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item --branch or -b

Create the specified branch.  This command may fail if the branch already exists.

=item --follow-branch | --no-follow-branch

Checkout the specified branch at each level (default)

=item --follow-commit | --no-follow-commit

Checkout the committed reference for each submodule (git submodule update --init --recursive)

=item --default

If specified, checkout the default branch for each repository.  If a tracking branch is defined in the .gitmodules definition, then that branch will be checked out.  If not, nuggit will attempt to identify the default branch from the remote server.  Note that the latter case will always identify the correct commit, but may, in some cases, infer the wrong branch if the state is ambiguous.

If a branch name is also specified, than said branch will be checked out at the root level, otherwise a default remote branch will be inferred as described above.

=item --init-submodules | --no-init-submodules

If set (default), a "git submodule update --init" will be automatically executed within each repository.  This step is required for consistent behavior when checking out a branch that introduces a new submodule.

Consequently, if enabled, changes may be lost if uncommitted submodule references exist in the current workspace in some cases.  It is generally recommended that all changes should be committed prior to changing branches, however if that is not the case executing with '--no-init-submodules' may be beneficial.

=item --file

Specify this flag to un-ambiguously specify that you wish to checkout/restore a file, and not a branch.  This option is required to unambiguously checkout a deleted file.

=item --safe

This mode ensures that no action is taken that will affect the current file state. This means that the specified (or implied) branch will only be checked out if doing so does not alter the currently checked out commit.  This can be used to resolve detached head conditions, or as a tool for advanced users when manually performing a partial merge.

If new submodules have been created, they will not be checked out.  

=back

=head1 Use Cases

The following are example usage scenarios.

=head2 Checkout a file

"ngt checkout $file"

$file in this case may be a relative (to current folder) or absolute path to any file within the nuggit workspace.  

Behavior is equivalent to "git checkout", with nuggit automatically handling any submodule boundaries.  This is done by internally switching to the directory containing $file (if not in the current directory) before executing the relevant git command.

NOTICE: This command does NOT explicitly check if the specified file is within the bounds of the current nuggit workspace, but instead relies on Git's native behavior.  As a side-effect, this command variant can be used for any git repository, regardless of your current working directory.

=head2 Create & checkout a new branch
"ngt checkout -b $branch"

If $branch already exists at the root level, this command will abort with an error.  Specify "--fix" to bypass this safety check.

It will then proceed to checkout this branch in every submodule.  If the branch already exists, attempt a 'safe' checkout of this branch instead.  An error will be reported and no action taken if the branch exists at this level, but does not match the current commit. 


=head2 Checkout an existing branch, following branch name everywhere
"ngt checkout $branch" or "ngt checkout --follow-branch $branch"

This command will attemt to checkout the specified branch in the root repository, or fail if it does not exist.

In this (default) variant, ngt will subsequently attempt to checkout this branch in every submodule.  Committed references are ignored in thos mode.

=head2 Checkout an existing branch, follow references
"ngt checkout --follow-commit $branch" or "ngt checkout --no-follow-branch $branch"

This command will attempt to checkout the specified branch in the root repository, or fail if it does not exist.

In this version, all submodules will be updated to match their committed references.  This may leave some submodules in a detached head state, or on a different branch (via the logic used for a --safe checkout), if the referenced commit does not exist on the desired branch.  

=head2 Checkout the default branch
"ngt checkout --default"

This will attempt to checkout the default branch at all levels.

TODO: Clarify here the definition of default branch


=head2 Resolve detached heads or inconsistent branches without changing repository state

The "--safe" option is designed to aide in this scenario.  It can be used in one of two ways to resolve this condition, depending on the desired result.

=head3 Specify Branch

"ngt checkout --safe $branch"

The above command, will attempt to checkout the specified $branch at all levels, but only if it matches the current commit.  If a submodule is currently in a detached HEAD state that does not match the specified $branch, it will checkout the first branch detected matching the current commit (if any).


=head3 Infer Branch

"ngt checkout --safe"

This will attempt to checkout the best-matching branch at all levels, including the root repository.  Best matching means:
- If default is specified, attempt to checkout the default branch at root level.
  - Otherwise, no action is taken at the root level, except to note the currently checked out branch as the preferred branch name
  - Note: If the root repository is in a detached state, this mode is not applicable and will exit with an error.
- Attempt to checkout a branch in each submodule, provided that said branch matches the current commit. In order it will try
  - If the preferred branch name matches the current commit, that branch will be checked out
  - "master", or the current repositories default branch
  - First branch reported by Git to match the current commit
  - If no matching branch is identified, it will be left at the current state


=cut


my $num_args;
my $branch;
my $cwd = getcwd();
my $create_branch_bool = 0;
my $follow_branch_bool = 1; # Follow branch, or follow commit
my $checkout_default_bool = 0;
my $checkout_file_flag = 0;
my $verbose = 0;
my $do_init_submodules = 1;
my $use_force = 0;
my $safe_mode = 0;
my $fix_mode = 0;

sub ParseArgs();
sub does_branch_exist_throughout($);
sub does_branch_exist_at_root($);
sub does_branch_exist_here($);

my $ngt = Git::Nuggit->new(); # Initialize Nuggit & Logger prior to altering @ARGV
my $default_branch; # Used only if checkout_default_bool defined

ParseArgs();

# Special case: Allow reversion of a single file. This can be done even if merge is in progress
checkout_file($ARGV[0]) if (@ARGV == 1 && !$create_branch_bool && (-f $ARGV[0] || $checkout_file_flag ));


die("Not a nuggit!\n") unless $ngt;
$ngt->start(level => 1, verbose => $verbose); # Open Logger for loggable-command mode
my $root_dir = $ngt->root_dir();

# Checkout not permitted while merge in progress
$ngt->merge_conflict_state("die-on-error");

chdir($root_dir) || die("Can't enter $root_dir");

# Handle Branch checkout/creation at root level (special case)
if ($create_branch_bool) {
    root_create_branch();
}
else # Checkout an existing branch
{
    # TODO: Replace with setup_branch_where_needed().  Do we need to handle root specially?
    ## Root Level
    my $root_branch = $branch;
    if ($checkout_default_bool && !defined($branch)) 
    {
        say "Checking out default branch . . . ";
        if (!defined($branch)) {
            # User did not explicitly specify default branch for root
            $root_branch = get_remote_default();
        }
    }
    else
    {
        say "Switch to existing branch - $branch";
        $root_branch = $branch;
    }

    # If safe-mode specified, verify before proceeding
    my $do_checkout = 1;
    if ($safe_mode) {
        $root_branch = check_safe_branch($root_branch);
        $do_checkout = 0 if !$root_branch; # Skip checkout if operation is not deemed safe.
        $follow_branch_bool = 1; # We evaluate each branch independently to ensure a 'safe' checkout operation.
    }

    if ($do_checkout) {
        my $branch_state = does_branch_exist_at_root($root_branch);
        
        # Check that branch already exists (locally or remotely)
        if ($branch_state == 0) {
            die("Branch ($root_branch) does not exist. If it exists remotely, did you forget to do a \"nuggit fetch\"?  If you intend to create a new branch, Specify \"-b\".");
        }
        $ngt->run("git checkout $root_branch");
        $ngt->run("git branch --set-upstream-to remotes/origin/$root_branch") if $branch_state & 2;
    }
    
    ## Submodules

    # Remaining behavior will be identical for both cases
    $ngt->run("git submodule update --init --recursive") if $do_init_submodules && !$safe_mode; # Checkout any new submodules

    if($follow_branch_bool)
    {
        print "follow branch\n";
        # follow the branch recursively... not the explicit commit 
        # from the parent repo
        chdir $root_dir;
        setup_branch_where_needed($branch);
        
    }
    else # follow commit
    {
        # checkout the branch in the root repo (already done)
        # and update each submodule to specified commit
        $ngt->run("git submodule update --init --recursive") if $do_init_submodules;
        say "Submodules updated to match references (--follow-commit).  WARNING: Submodules may be in detached head state";
    
        ############################################################################################
        # SHOULD NOT NEED TO DO THIS WITH THE DESIRED WORKFLOW, BUT IT COULD PROBABLY HAPPEN
        # TO DO - MAYBE INCLUDE THE OPTION --REMOTE TO 
        # UPDATE EACH SUBMODULE WITH THE LATEST OF EACH OF THEIR TRACKING BRANCHES???
        ############################################################################################
    }
}




sub ParseArgs()
{
    my $arg_count = @ARGV;
    my ($help, $man);
    my $follow_commit_bool = 0;
#  print "Number of arguments $arg_count \n";
  
  ######################################################################################################
  #
  # TO DO - WOULD LIKE TO ALSO CREATE A FLAG --follow-branch
  # which would recursively checkout the branch so that you are on the same branch in all submodules
  # the default checkout should be git submodule update --recursive
  #
  ######################################################################################################
  Getopt::Long::GetOptions(
      "help"             => \$help,
      "man"              => \$man,
      "b"                => \$create_branch_bool,
      "follow-branch!"   => \$follow_branch_bool,
      "follow-commit!"   => \$follow_commit_bool,
      "verbose!"         => \$verbose,
      "default!"         => \$checkout_default_bool,
      "init-submodules!" => \$do_init_submodules,
      "file!" => \$checkout_file_flag,
      "force!" => \$use_force,
      "file!"            => \$checkout_file_flag,
      "safe!"            => \$safe_mode,
      "fix!"            => \$fix_mode,
                          );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    if (@ARGV > 0) {
        $branch=$ARGV[0];
    } elsif (!$checkout_default_bool) {
        die("Branch name is required unless --default was specified. ");
    }

    # follow_commit_bool implies no-follow_branch_bool
    $follow_branch_bool = 0 if $follow_commit_bool;

    die("--default flag is mutually exclusive with --follow-commit") if $follow_commit_bool && $checkout_default_bool;

    if ($verbose) {
        say "Follow branch flag provided" if ($follow_branch_bool);
        say "Follow commit flag provided" if $follow_commit_bool;
    }
    if ($branch eq "master" && !$follow_commit_bool && !$use_force) {
        say "You have requested to checkout 'master' at all levels. This may not be the default branch in all submodules.";
        say "Are you sure this is what you want to do?";
        while(1) {
            say "Enter one of the following:";
            say "\tyes - Proceed to checkout master at all levels. Specify '--force' in the future to bypass this prompt";
            say "\tno  - Abort and exit [default]";
            say "\tcommit - Follow commit references instead of checking out branches. This may result in detached heads and is equivalent to --follow-commit-bool.";
            say "\tdefault - Proceed as if you specified '--default' instead of 'master'";

            my $input = <STDIN>;
            chomp($input);
            last if ($input eq "yes");
            die("Aborted") if $input eq "no";
            if ($input eq "commit") {
                $follow_branch_bool = 0; $follow_commit_bool=1;
                last;
            } elsif ($input eq "default") {
                $branch = undef;
                $checkout_default_bool = 1;
                last;
            }
        }
    }
}



# check all submodules to see if the branch exists
sub does_branch_exist_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  
  # get a list of all of the submodules
  my @submodules = get_submodules();

#  print "Does branch exist throughout?\n";
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;
    
    if(does_branch_exist_here($branch) == 0)
    {
#      print "branch does not exist here: $_\n";
      return 0;
    }
    
    # return to root directory
    chdir $root_dir;
  }

  return 1;
}


# find any submodules where the branch does not exist and create it
# note this will also switch to the existing branch where it already exists
sub setup_branch_where_needed
{
    my $branch = shift;
    my $root_dir = getcwd();

    submodule_foreach(undef, {'breadth_first_fn' => sub {
        my ($parent, $name, $substatus, $hash, $label, $opts) = (@_);

        if ($checkout_default_bool)
        {
            my $remote_branch;
            my $parent_gitmodules = File::Spec->catfile($root_dir,$parent,".gitmodules");
            if (-e $parent_gitmodules) {
                my $cfg = `git config --file $parent_gitmodules --get-regexp branch`;
                if ( $cfg =~  m/submodule\.$name\.branch (.*)$/mg ) {
                  $remote_branch = $1;
                }
            }
            if (!defined($remote_branch)) {
                $remote_branch = get_remote_default($branch);
            }
            my $do_checkout = 1;
            if ($safe_mode) {
                $remote_branch = check_safe_branch($remote_branch);
                $do_checkout = 0 if !$remote_branch; # Skip checkout if operation is not deemed safe.
            }
            if ($do_checkout) {
                $ngt->run("git checkout $remote_branch");
                $ngt->run("git branch --set-upstream-to remotes/origin/$remote_branch");
            }
        }
        else # follow commit
        {
            my $state = does_branch_exist_here($branch);

            if ($state == 0)
            {
                if ($create_branch_bool || $fix_mode) {
                    # create the branch here
                    $ngt->run("git checkout -b $branch");
                } else {
                    say colored("ERROR: $branch does not exist for $name. Re-run with --fix to force creation. If you believe this branch should already exist, verify that you have successfully run a 'ngt fetch' and try again.",'red');
                }

            }
            else
            {
                my $do_checkout = 1;
                my $local_branch = $branch;
                if ($safe_mode) {
                    $local_branch = check_safe_branch($branch);
                    return if !$local_branch; # Done with this submodule if checkout is not safe.
                }
                    
                # Branch exists remotely, check it out
                $ngt->run("git checkout $local_branch");

                # Ensure tracking is setup correctly (if remote branch exists)
                $ngt->run("git branch --set-upstream-to remotes/origin/$local_branch") if $state & 2;
            }
        }

        # Initialize any new recursive submodules
      # TODO: checkout results should give us an indication if a submodule has been updated to make below conditional
      # NOTE: If below does initialize a new submodule, it may not be checked out to the new branch
        $ngt->run("git submodule update --init") if !$safe_mode;
                      }});
}


# check of the branch exists in the current repo (based on the current directory)
# rtv 0 = branch does not exist
# $rtv & 1 == branch exists locally
# $rtv & 2 == branch exists remotely
sub does_branch_exist_here($)
{
  my $branch = $_[0];
  my $branches;
  my @branches;
  my $rtv = 0;
#  print "Does branch exist here?\n";
  
  # execute git branch and grep the output for branch
  $branches = `git branch -a | grep $branch\$`;
  
  # the branch name may be a substring or may be the selected branch
  # the selected branch will have a * at the beginning, remove that 
  $branches =~ s/[\*\s]*//;
  
  # split the string into an array where each branch name that included the desired
  # branch name as a substring is an entry
  @branches = split / /, $branches;
  
  # search for an exact match for the branch in each array entry
  foreach(@branches)
  {
    # check for the exact match
    if($_ =~ m/^$branch$/)
    {
        # found the branch return true
        $rtv += 1;
    }
    elsif($_ =~ m/remotes\/(\w+)\/$branch$/)
    {
        # Branch exists remotely, but not locally
        $rtv += 2;
    }
  }

  # did not find the branch - return false
  return $rtv;
}



# check to see if the specified branch already exists at the root level
sub does_branch_exist_at_root($)
{
  my $branch = $_[0];

#  print "Does branch exist at root?\n";

  return does_branch_exist_here($branch);
}

sub get_remote_default
{
    # FUTURE: Accept branch name as hint if symbolic-ref is ambiguous
    
    my $tmp = $ngt->run('git symbolic-ref refs/remotes/origin/HEAD');
    my ($branch) = $tmp =~ qr{^refs/remotes/origin/(.+)$ }x;
    
    return $branch;
}

sub checkout_file
{
    my $file = shift;

    say "Checkout file $file";

    # Get name of parent dir
    my ($vol, $dir, $fn) = File::Spec->splitpath( $file );

    if ($dir) {
        chdir($dir) || die ("Error: Can't enter file's parent directory: $dir");
    }
    $ngt->run("git checkout $fn");
    exit 1;
}

sub root_create_branch {
    
    say "Creating new branch - $branch";
    my $branch_state = does_branch_exist_at_root($branch);
    my $create_cmd = "git checkout -b $branch";
    
    # Mirror Git behavior if branch exists with -b flag
    if ($branch_state != 0) {
        # Branch either exists locally or remotely; either way disallow duplicate creation
        die("Can't create a branch that already exists. Please try again without -b flag.");
    }

    # Create the branch at root
    $ngt->run($create_cmd);

    # Run git checkout -b at all levels, checking for errors
    # If branch already exists, give a warning, but proceed anyway with the remainder of the tree
    submodule_foreach(sub {
                          $ngt->run($create_cmd); # TODO: Disable die-on-error, get error status, suppress echo output

                          # If success, nothing else to be done
                          # If failure
                          #   If error message is "branch already exists"
                          #      Print warning and continue
                          #   If error is unknown, print original output, an "Unknown error occurred" warning, and continue
                      });

    # Done
}

# Return tgt_branch if it is safe to check out, undef if not. If repository is currently in a detached head and tgt_branch is undefined or unsafe, then the best matching branch will be checked out, if available.
#
# If tgt_branch is not defined, identify the default or best-matching branch for the repository's (getcwd()) current commit
#
# Scenarios for safe checkout branch (if input is a branch)
# - Already on this branch + commit
# - Already on this commit
# - Does not match current commit
# - Branch does not exist locally
# - Branch does not exist
# - Branch exists locally and is not safe, but remote branch is
# For safe checkout sha
# - Already on this commit
# - Does not match current commit
#
# Return values:
# - Empty string if safe, but equal to currently checked out commit & branch
# - $tgt_branch if safe and matching
# - First exact-match branch if tgt is a SHA or branch name would be unsafe and we are currently in a detached head
# - undef if this is not a safe operation
sub check_safe_branch {
    my $tgt_branch = shift;
    my $hint_branch = shift; # If parent repository submodule listing was parsed, it may provide the tracking branch as an argument here
    

    say "Check safe branch: $tgt_branch in ".getcwd() if $verbose;
    
    # Get current workspace state
    #  Expected output from shell:  $sha (HEAD -> branch[, branch2, ..]) $msg
    #  NOTE: Git output is different from a script:  $sha $msg
    my ($err, $info, $stderr) = $ngt->run('git show -s --no-abbrev-commit --no-color --format="format:%H%n%D"');
    my ($current_commit, $branches_raw) = split('\n', $info);    
    # Use chomp to remove any trailing whitespace -- aka \r for Windows users
    chomp($current_commit);
    chomp($branches_raw);

    # Split input at comma and trim whitespace
    my @branches = split('\s*,\s*', $branches_raw);
    my $head = shift @branches;
    my ($cur_branch) = ($head =~ /^HEAD\s\-\>\s([\/\-\.\w]+)$/);

    # TODO: Handle case where $tgt_branch is a SHA. All logic following essentially assumes tgt_branch is a branch
    if ($tgt_branch && $cur_branch && $cur_branch eq $tgt_branch) {
        # We are already on the branch. While it is safe to checkout, we return a falsey value to bypass unnecessary operations
        say "\t Already on $tgt_branch" if $verbose;
        # return "";  # DEBUG, restore this later
    }

    # Tags don't help us here, so filter them out from the branches list
    @branches = grep { $_ !~ /^tag/ } @branches;
    
    # Get recorded commit for $tgt_branch
    #   Not needed; If branch is on same commit, it will be shown in list
    # my $branch_commit = $ngt->run("git rev-parse $tgt_branch");

    # If $tgt_branch or origin/$tgt_branch is in list, return success
    if ($tgt_branch && grep( /^(origin\/)?$tgt_branch$/, @branches )) {
        return $tgt_branch;
    } elsif ($head eq "HEAD" && scalar(@branches) > 0) {
        # We are in a detached head, but other branches exist matching this commit

        # Determine default branch and use if in @branches
        my $default_branch = get_remote_default();
        if ($default_branch) {
            return $default_branch;
        }

        # Check if caller has provided a (backup) hint
        if ($hint_branch && grep( /(origin\/)?$hint_branch$/, @branches)) {
            return $hint_branch;
        }

        # TODO: If we are in a submodule, check if parent has defined a tracking branch or if a hint was passed to this fn

        # If master is in list, use that [default default]
        if (grep( /^(origin\/)?master$/, @branches )) {
            return "master";
        }

        # Otherwise use last (non-tag) match found
        #  Note; Assume Remaining List is ordered remote branches, local branches
        my $rtv = pop(@branches);
         # Remote origin/ prefix if defined (git will automatically checkout locally if we strip the origin prefix, otherwise we'll remain in a detached head)
        $rtv =~ s/^origin\///;
        return $rtv;

        # TODO: Fix origin handling above
        # - origin may be ahead of the local branch
        #   - git checkout foo && git fetch && git checkout origin/foo
        # - In this case we want to in a single-step checkout foo and update to origin/foo if we can do so safely...
        # -   Or we can simply warn user for now if the two do not match
        # - Preliminary safety handling if matching origin/
        #   - Set rtv to origin/$match, but don't return if there is an exact match
        #   - If this is best match, check if $match exists locally
        #     - If so, it's at a different commit and we can't checkout safely.  Warn the user instead with a suggestion of explicitly checking out the branch and attempting to pull.
        #     - If not, return $match and caller can check it out and let git set it automatically
        # In other words, when 'ngt checkout --safe' finishes, it may print warnins that:
        # - Submodule X is in a detached HEAD state. Current commit does not match any known branches. 
        # - Submodule Y is in a detached HEAD state.  It matches remote branch $branch, but not local. Manual resolution recommended.
        # 0 
    }
    # Otherwise return invalid
    return undef;
}
