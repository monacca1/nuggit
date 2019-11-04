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

To list branches, "ngt branch"

To list all branches, "ngt branch -a"

To delete a branch, "ngt branch -d BRANCH_NAME"

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
sub get_selected_branch($);
sub is_branch_selected_here($);
sub is_branch_selected_throughout($);
sub delete_branch($);
sub create_new_branch($);
sub get_selected_branch_here();

my $cwd = getcwd();
my $root_repo_branches;
my $selected_branch;
my $show_all_flag    = 0; # IF set, show all branches
my $create_branch    = 0;
my $delete_branch    = undef;
my $verbose = 0;

# print "nuggit_branch.pl\n";

ParseArgs();

my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;

print "nuggit root directory is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;


if($delete_branch)
{
  print "Deleting branch across all submodules: " . $delete_branch . "\n";
  delete_branch($delete_branch);
}
else
{
  my $argc = @ARGV;  # get the number of arguments.
                     # if there is only one argument 
                     #   - assume this is a branch name for 
                     #     a branch to create
                     # if there are zero arguments
                     #   - the caller just wants to check
                     #     which branches exist and if
                     #     the entire repo is on the same
                     #     branch
  
  if($argc == 1)
  {
      create_new_branch($ARGV[0]);
  }
  elsif($argc == 0)
  {
      display_branches();
  }
}

sub display_branches
{
    my $flag = ($show_all_flag ? "-a" : "");
  $root_repo_branches = `git branch $flag`;
  $selected_branch    = get_selected_branch($root_repo_branches);

  say "Root repo is on branch:";
  say "* ".  $selected_branch;
  say "";
  say "Full list of root repo branches is:";
  say $root_repo_branches;

  # --------------------------------------------------------------------------------------
  # now check each submodule to see if it is on the selected branch
  # for any submodules that are not on the selected branch, display them
  # show the command to set each submodule to the same branch as root repo
  # --------------------------------------------------------------------------------------

    is_branch_selected_throughout($selected_branch);

}


sub ParseArgs()
{
    my ($help, $man);
    Getopt::Long::GetOptions(
      "d=s"  => \$delete_branch,
      "all|a!" => \$show_all_flag,
      "verbose!" => \$verbose,
      "help"            => \$help,
      "man"             => \$man,
      );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

}

sub create_new_branch($)
{
  my $new_branch = $_[0];
 
  # create a new branch everywhere but do not switch to it.
  
  print "TO DO - CREATE NEW BRANCH: $_[0]\n";
}



# check all submodules to see if the branch exists
sub is_branch_selected_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  my $branch_consistent_throughout = 1;

  submodule_foreach(sub {
      my $subname = File::Spec->catdir(shift, shift);
                        
    if(is_branch_selected_here($branch) == 0)
    {
      say "**** Branch discrepancy";
      say "****  Branch $branch is not selected in submodule: $subname";
      say "****     Selected branch in submodule is: " . get_selected_branch_here();
      say "****  Please run:";
      say "****       nuggit checkout $branch";
      say "";
      
      $branch_consistent_throughout = 0;
    }
  });

  if($branch_consistent_throughout == 1)
  {
    print "All submodules are are the same branch\n";
  }
  
  return $branch_consistent_throughout;
}


# check of the branch exists in the current repo (based on the current directory)
sub is_branch_selected_here($)
{
  my $branch = $_[0];
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  $selected_branch = get_selected_branch_here();
  
  if($selected_branch eq $branch)
  {
#    print "branch $branch was selected\n";
    return 1;
  }
  else
  {
#    print "**** Branch discrepancy\n";
#    print "**** checked out branch is $selected_branch, root repo is on branch $branch\n";
    return 0;
  }
  
}


sub delete_branch($)
{
  my $branch;
  $branch = $_[0];
  
#  print "TO DO - DELETE BRANCH $_[0]\n";

  print `git submodule foreach --recursive git branch -d $branch`;
  print `git branch -d $branch`;
}

