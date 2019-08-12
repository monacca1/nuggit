#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);


# usage: 
#
# to view all branches just use:
# nuggit_branch.pl
#     This will also check to see if all submodules are on the same branch and warn you if there are any that are not.
#
# to create a branch
# nuggit_branch.pl <branch_name>
#
# to delete a branch across all submodules
# nuggit_branch.pl -d <branch_name> 
#

sub ParseArgs();
sub get_selected_branch($);
sub is_branch_selected_here($);
sub is_branch_selected_throughout($);
sub delete_branch($);
sub create_new_branch($);

my $root_dir;
my $cwd = getcwd();
my $root_repo_branches;
my $selected_branch;
my $display_branches = 0;
my $create_branch    = 0;
my $delete_branch    = undef;

# print "nuggit_branch.pl\n";

ParseArgs();

$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

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
    $create_branch = 1;
  }
  elsif($argc == 0)
  {
    $display_branches = 1;
  }
}


if($display_branches)
{
  $root_repo_branches = `git branch`;
  $selected_branch    = get_selected_branch($root_repo_branches);

  print "Root repo is on branch: \n";
  print "* ".  $selected_branch . "\n";
  print "\n";
  print "Full list of root repo branches is: \n";
  print $root_repo_branches . "\n";

  # --------------------------------------------------------------------------------------
  # now check each submodule to see if it is on the selected branch
  # for any submodules that are not on the selected branch, display them
  # show the command to set each submodule to the same branch as root repo
  # --------------------------------------------------------------------------------------

  is_branch_selected_throughout($selected_branch);
}

if($create_branch)
{
  create_new_branch($ARGV[0]);
}


sub ParseArgs()
{
  Getopt::Long::GetOptions(
     "d=s"  => \$delete_branch
     );
}

sub create_new_branch($)
{
  my $new_branch = $_[0];
 
  # create a new branch everywhere but do not switch to it.
  
  print "TO DO - CREATE NEW BRANCH: $_[0]\n";
}

sub get_selected_branch($)
{
  my $root_repo_branches = $_[0];
  my $selected_branch;

  $selected_branch = $root_repo_branches;
  $selected_branch =~ m/\*.*/;
  $selected_branch = $&;
  $selected_branch =~ s/\* //;  
  
  return $selected_branch;
}


# check all submodules to see if the branch exists
sub is_branch_selected_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;

#  print "Is branch selected throughout?\n";
    
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;
    
    if(is_branch_selected_here($branch) == 0)
    {
      print "**** branch $branch is not selected in submodule: $_\n";
      print "**** Please run:\n";
      print "****       nuggit checkout [branch]\n";
      print "\n";
      
      return 0;
    }
    
    # return to root directory
    chdir $root_dir;
  }

  print "All submodules are are the same branch\n";

  return 1;
}


# check of the branch exists in the current repo (based on the current directory)
sub is_branch_selected_here($)
{
  my $branch = $_[0];
  my $branches;
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  # execute git branch
  $branches = `git branch`;

  $selected_branch = get_selected_branch($branches);
  
  if($selected_branch eq $branch)
  {
#    print "branch $branch was selected\n";
    return 1;
  }
  else
  {
    print "**** Branch discrepancy, please correct.\n";
    print "**** checked out branch is $selected_branch, expected branch $branch to be checked out\n";  
    return 0;
  }
  
}


sub delete_branch($)
{
  print "TO DO - DELETE BRANCH $_[0]\n";
}
