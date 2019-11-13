#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;

=head1 SYNOPSIS

nuggit checkout <branch_name>

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

=back

=cut


my $num_args;
my $branch;
my $cwd = getcwd();
my $create_branch_bool = 0;
my $follow_branch_bool = 1; # Follow branch, or follow commit
my $checkout_default_bool = 0;
my $verbose = 0;

sub ParseArgs();
sub does_branch_exist_throughout($);
sub does_branch_exist_at_root($);
sub does_branch_exist_here($);

my $ngt = Git::Nuggit->new(); # Initialize Nuggit & Logger prior to altering @ARGV
my $default_branch; # Used only if checkout_default_bool defined

ParseArgs();
die("Not a nuggit!\n") unless $ngt;
$ngt->start(level => 1, verbose => $verbose); # Open Logger for loggable-command mode
my $root_dir = $ngt->root_dir();

check_merge_conflict_state(); # Checkout not permitted while merge in progress

chdir($root_dir) || die("Can't enter $root_dir");

if ($create_branch_bool) {
    my $branch_state = does_branch_exist_at_root($branch);
    
    # Mirror Git behavior if branch exists with -b flag
    if ($branch_state != 0) {
        # Branch either exists locally or remotely; either way disallow duplicate creation
        die("Can't create a branch that already exists. Please try again without -b flag.");
    }

    $ngt->run("git checkout -b $branch");
    
}
else
{
    if ($checkout_default_bool && !defined($branch)) 
    {
        if (defined($branch)) {
            # User explicitly specified default branch for root
            $default_branch = $branch;
        } else {
            $default_branch = get_remote_default();
        }
        $ngt->run("git checkout $default_branch");
        my $branch_state = does_branch_exist_at_root($default_branch);

        # We can only set tracking if it already exists remotely
        $ngt->run("git branch --set-upstream-to remotes/origin/$default_branch") if $branch_state & 2;

    }
    else
    {
        my $branch_state = does_branch_exist_at_root($branch);
        
        # Check that branch already exists (locally or remotely)
        if ($branch_state == 0) {
            die("Branch ($branch) does not exist. If it exists remotely, did you forget to do a \"nuggit fetch\"?  If you intend to create a new branch, Specify \"-b\".");
        }
        
        $ngt->run("git checkout $branch");
        $ngt->run("git branch --set-upstream-to remotes/origin/$branch") if $branch_state & 2;
    }
}

# Remaining behavior will be identical for both cases
$ngt->run("git submodule init"); # Checkout any new submodules

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
    $ngt->run("git submodule update --init --recursive");
    say "Submodules updated to match references (--follow-commit).  WARNING: Submodules may be in detached head state";
    
    ############################################################################################
    # SHOULD NOT NEED TO DO THIS WITH THE DESIRED WORKFLOW, BUT IT COULD PROBABLY HAPPEN
    # TO DO - MAYBE INCLUDE THE OPTION --REMOTE TO 
    # UPDATE EACH SUBMODULE WITH THE LATEST OF EACH OF THEIR TRACKING BRANCHES???
    ############################################################################################
    
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
     "b"               => \$create_branch_bool,
     "follow-branch!"  => \$follow_branch_bool,
      "follow-commit!" => \$follow_commit_bool,
      "verbose!"       => \$verbose,
      "default!"       => \$checkout_default_bool,
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

    if($follow_branch_bool == 1)
    {
        say "Follow branch flag provided";
    }

    # the -b argument means to create the branch just like in git
    if($create_branch_bool)
    { 
        print "Creating new branch -  $branch\n";  
    }
    elsif($checkout_default_bool)
    {
        say "Checking out default branch";
    }
    else
    { 
        # Use existing branch
        print "Switch to existing branch - $branch\n";
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

    submodule_foreach(sub {
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
            $ngt->run("git checkout $remote_branch");
            $ngt->run("git branch --set-upstream-to remotes/origin/$remote_branch");
        }
        else
        {
            my $state = does_branch_exist_here($branch);

            if ($state == 0)
            {
                # create the branch here
                $ngt->run("git checkout -b $branch");

            }
            else
            {
                # Branch exists remotely, check it out
                $ngt->run("git checkout $branch");

                # Ensure tracking is setup correctly (if remote branch exists)
                $ngt->run("git branch --set-upstream-to remotes/origin/$branch") if $state & 2;
            }
        }

        # Initialize any new recursive submodules
      # TODO: checkout results should give us an indication if a submodule has been updated to make below conditional
      # NOTE: If below does initialize a new submodule, it may not be checked out to the new branch
        $ngt->run("git submodule init");
        
                      });
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
    
    my $tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
    $tmp =~ m/remotes\/origin\/(.*)$/;
    
    my $branch = $1;

    return $branch;
}
