#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);

# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_checkout.pl <branch_name>
#
#
# nuggit_checkout.pl <branch_name>
# nuggit_checkout.pl -b <branch_name>
#

my $num_args;
my $branch;
my $root_dir;
my $cwd = getcwd();
my $existing_branch_name = "";
my $create_branch_name = "";
my $follow_branch_bool = 0;
my $follow_commit_bool = 0;


sub ParseArgs();
sub does_branch_exist_throughout($);
sub create_branch_where_needed($);
sub does_branch_exist_at_root($);
sub does_branch_exist_here($);

ParseArgs();

if( ($follow_branch_bool == 0) && ($follow_commit_bool == 0))
{
  print "default behavior is to follow the branch\n";
  $follow_branch_bool = 1;
  $follow_commit_bool = 0;
}


$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;


if($create_branch_name eq "")
{
  # Not creating a new branch (attempt to use an 
  # existing branch) but will need to create it in 
  # submodules if it does not exist everywhere
  
#  print `git checkout $branch`;

  if(does_branch_exist_at_root($branch))
  {

    # checkout the branch at the root
    print `git checkout $branch`;

    
    if($follow_branch_bool)
    {
      print "follow branch\n";
      # follow the branch recursively... not the explicity commit 
      # from the parent repo
      if(does_branch_exist_throughout($branch))
      {
  #      print "branch exists throughout\n";
      }
      else
      {
  #      print "branch did not exist throughout\n";
        chdir $root_dir;
        create_branch_where_needed($branch);
      }

      print `git submodule update --recursive`;   
      print `git submodule foreach --recursive git checkout $branch`;

    }
    elsif($follow_commit_bool)
    {
      print "follow commit\n";
      # checkout the branch in the root repo (already done)
      # and update each submodule 
      print `git submodule update --recursive`;
      
      ############################################################################################
      # SHOULD NOT NEED TO DO THIS WITH THE DESIRED WORKFLOW, BUT IT COULD PROBABLY HAPPEN
      # TO DO - MAYBE INCLUDE THE OPTION --REMOTE TO 
      # UPDATE EACH SUBMODULE WITH THE LATEST OF EACH OF THEIR TRACKING BRANCHES???
      ############################################################################################
      
    }
    
  }
  else
  {
    print "Branch \"$branch\" does not exist in root repo\n";
  }
}
else
{
  # Creating a branch. Create it recursively in all submodules
  print `git checkout -b $branch`;
  print `git submodule foreach --recursive git checkout -b $branch`;
}



sub ParseArgs()
{
  my $arg_count = @ARGV;

#  print "Number of arguments $arg_count \n";
  
  ######################################################################################################
  #
  # TO DO - WOULD LIKE TO ALSO CREATE A FLAG --follow-branch
  # which would recursively checkout the branch so that you are on the same branch in all submodules
  # the default checkout should be git submodule update --recursive
  #
  ######################################################################################################
  Getopt::Long::GetOptions(
     "b=s"            => \$create_branch_name,
     "follow-branch"  => \$follow_branch_bool,
     "follow-commit"  => \$follow_commit_bool
     );

  if($follow_branch_bool == 1)
  {
    print "Follow branch flag provided\n";
  }

  # the -b argument means to create the branch just like in git
  if($create_branch_name ne "")
  { 
    $branch=$create_branch_name;

    print "Creating new branch -  $branch\n";  
  }
  else
  { 
    # Use existing branch
    $branch=$ARGV[0];
    print "Switch to existing branch - $branch\n";
  }

  #print "branch = $branch\n";

}



# check all submodules to see if the branch exists
sub does_branch_exist_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;

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
sub create_branch_where_needed($)
{
  my $branch = $_[0];
  my $root_dir = getcwd();
#  print "Create branch where needed. called from $root_dir\n";
  
  # get a list of all of the submodules
  my $submodules = `list_all_submodules.pl`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;
   
  foreach (@submodules)
  {
    # switch directory into the sumbodule
    chdir $_;
    
#    print "Current working directory is: " . getcwd() . "\n";
    
    if(does_branch_exist_here($branch) == 0)
    {
      # to do - create the branch here
      system("git checkout -b $branch");
    }
    else
    {
      system("git checkout $branch");
    }
    
    # return to root directory
    chdir $root_dir;
  }  
}


# check of the branch exists in the current repo (based on the current directory)
sub does_branch_exist_here($)
{
  my $branch = $_[0];
  my $branches;
  my @branches;
  
#  print "Does branch exist here?\n";
  
  # execute git branch and grep the output for branch
  $branches = `git branch | grep $branch\$`;
  
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
      return 1;
    }
  }

  # did not find the branch - return false
  return 0;
}



# check to see if the specified branch already exists at the root level
sub does_branch_exist_at_root($)
{
  my $branch = $_[0];

#  print "Does branch exist at root?\n";

  return does_branch_exist_here($branch);
}
