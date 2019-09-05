#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";


# usage: 
#
# nuggit_commit.pl -m "commit message"
#

print "nuggit_commit.pl\n";

# to get a list of files that have been staged to commit (by the user) use:
#   git diff --name-only --cached
# use this inside each submodule to see if we need to commit in that submodule.


# for each submodule drill down into that directory:
#    see if there is anything stated to commit
#    if there is something staged to commit, commit the staged files with the commit message provided
#    this will need to be nested or recursive or linear across all submodules... need to design how this will work
#       but will need to traverse all the way back up the tree committing at each level.  Use the commit message 
#       provided by the caller, but for committing submodules that have changed as a result, consider constructing
#       a commit message that is based on the callers commit message... consider adding the branch and submodule name
#       to the commit?
#    

sub ParseArgs();
sub recursive_commit( $ );
sub staged_changes_exist_here();
sub nuggit_commit($);

my $verbose;
my $git_diff_cmd   = "git diff --name-only --cached";
my $cached_bool;
my $commit_message_string;
my $inhibit_commit_bool = 1;
my $need_to_commit_at_root = 0;
my $branches;
my $root_repo_branch;

ParseArgs();

my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;

print "nuggit root dir is: $root_dir\n" if $verbose;
print "nuggit cwd is ".getcwd()."\n" if $verbose;
print $relative_path_to_root . "\n" if $verbose;

print "changing directory to root: $root_dir\n" if $verbose;
chdir $root_dir;

$branches = `git branch`;
$root_repo_branch = get_selected_branch($branches);


my $date = `date`;
chomp($date);
system("echo ===========================================         >> $root_dir/.nuggit/nuggit_log.txt");
system("echo nuggit_commit.pl, branch = $root_repo_branch, $date >> $root_dir/.nuggit/nuggit_log.txt");
system("echo commit message: $commit_message_string              >> $root_dir/.nuggit/nuggit_log.txt");
recursive_commit("");


sub ParseArgs()
{
  Getopt::Long::GetOptions(
                           "m=s"  => \$commit_message_string,
                           "verbose!" => \$verbose
                          );
  die("Commit message is required. Specify with: -m \"Useful description\"") unless $commit_message_string;
}



sub recursive_commit( $ )
{
  my $status;
  my $submodule = "";
  my @submodule_array;
  my $dir;
  my $submodule_dir;
  my $location = $_[0];
  my $tmp;
  my $need_to_commit_here = 0;

  # use the "location" the build up the relative path of the submodule... relative to the root repo.
  if($location ne "")
  {
    #print "LOCATION: " . $location . "\n";
    
    # The trailing slash needs to be there for the recursive buildup 
    # of the path, but remove it for the printing
    $tmp = $location;
    $tmp =~ s/\/$//;
#    print $tmp . "\n"
  }
  
  # check if there are any submodules in this repo or if this is a leaf repo
  if(-e ".gitmodules")
  {
    # Assemble non-recursive list of submodules
      submodule_foreach(
                        sub { push @submodule_array,  shift.'/'.shift; },
                        {recursive => 0}
                       );

    $dir = getcwd();
    chomp($dir);

    while($submodule=shift(@submodule_array))
    {
#      print "===============================\n";
#      print "Root: " . $dir . "\n";

      chomp($submodule);
      
      $submodule_dir = $dir . "/" . $submodule;
  
#      print "SUBMODULE: " . $submodule . " SUBMODULE DIR: " . $submodule_dir . "\n";
  
      chdir($submodule_dir) || die "Can't enter $submodule_dir";
    
#      print "At level $i - recursing\n";
#      $i = $i + 1;
       $need_to_commit_here += recursive_commit( $location . $submodule . "/" );
#      $i = $i - 1;
#      print "POP back to level $i\n";

      chdir($dir) || die "Can't enter $dir";

      # ==========================================================================================
      # at this point we are back in the parent directory.
      # if the submodule we just recursed into caused a commit
      # we need to "git add" this submodule here.  When this function returns
      # it will get committed
      # ==========================================================================================
      if($need_to_commit_here >= 1)
      {
        print "Need to commit here: $need_to_commit_here at $submodule_dir\n";
        print "The submodule caused a commit, we need to 'git add $submodule' here:\n";
        print "in directory: " . getcwd() . "\n";
        print "about to execute: git add $submodule\n";
        print `git add $submodule`;
        
        system("echo git add $submodule >> $root_dir/.nuggit/nuggit_log.txt");
      }
      else
      {
        print "Submodule $submodule did not cause a commit\n";
      }
      # ==========================================================================================
    
    } # end while
    
  } # end if(-e ".gitmodules")
  
  
  if(staged_changes_exist_here())
  {
    $need_to_commit_here = 1;

    if(defined $submodule)
    {
      print "Staged changes exist here in submodule: $submodule, location $location\n";
    }
    else
    {
      print "Staged changes exist here at root\n";
    }



    nuggit_commit($location);
  }

  return $need_to_commit_here;

}



sub staged_changes_exist_here()
{
  my $status;
  my $dir;
  my $need_to_commit_here;

  $status = `$git_diff_cmd`;
  
  if($status ne "")
  {
    $dir = getcwd();
    print "Files staged to commit here at ($dir)\n";
    $need_to_commit_here = 1;
  }
}


sub nuggit_commit($)
{
   my $commit_status;
   my $repo = $_[0];
   my $dir;

   $dir = getcwd();    
   system("echo in dir $dir, committing in repo $repo >> $root_dir/.nuggit/nuggit_log.txt");
   
   $commit_status = `git commit -m "N: Branch $root_repo_branch, $commit_message_string"`;
   print "Commit status in repo $repo: \n";
   print $commit_status . "\n";
}

