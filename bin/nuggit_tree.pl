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
Getopt::Long::Configure ("bundling"); # ie: to allow "status -ad"
use Pod::Usage;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Data::Dumper; # Debug and --dump option
use Git::Nuggit;


sub submodule_tree($);


my $ngt = Git::Nuggit->new();

my $cwd = getcwd();
my $root_dir = $ngt->root_dir();
my $submodules;


chdir $root_dir;

# print $root_dir . "\n";

# print $cwd . "\n";

my $active_branch = get_selected_branch_here();

# get branch of root repo

print "On branch: " . $active_branch . "\n";

print "head commit of root repo:\n";
print `git log -n1 $active_branch | grep commit`;



print `git ls-tree -r $active_branch | grep commit`;
# OR replace grep commit with the submodule name:
# git ls-tree -r <branch> <submodule_name>



submodule_tree($root_dir);



sub submodule_tree($)
{
  my $dir = $_[0];
  my $start_dir;
  my $result_dir;
  my $submodule_count;
  my $submodule;
  my $submodule_status;
 
  $start_dir = getcwd(); 
#  print "starting dir: " . $start_dir . "\n";
   
  chdir $dir;
  
  $result_dir = getcwd(); 
#  print "result dir: " . $dir . "\n";

  if( $dir ne $start_dir )
  {
    if($result_dir eq $start_dir)
    {
      print "Error recursing into:  $dir\n";
      print " from directory: $start_dir\n";
      print "Directory for submodule does not exist\n";
      exit();
    }
  }
  
#  print `list_submodules.sh`;
  $submodules = `list_submodules.sh`;

  #print `list_all_submodule.sh`;

  my @submodules = split /\n/, $submodules;

  $submodule_count = @submodules;
  if($submodule_count == 0)
  {
#    print "No submodules\n";
    return;
  }

  foreach(@submodules)
  {
    $submodule = $_;
    
#    print "Recursing into submodule: " . $_ . "\n";
    submodule_tree($dir . "/" . $submodule);
    chdir $start_dir;
    
    $submodule_status = `git status --porcelain $submodule`;

    if($submodule_status ne "")
    {
      print "status: " . $submodule_status ;
      
      print `git add $submodule`;
      
    }

  }

  #nuggit_get_path_relation_to_root.pl


  #submodule_tree($active_branch);


  #print `git log -n1 HEAD | grep commit`;
  #print `git ls-tree -r HEAD | grep commit`;

}


# check all submodules to see if the branch exists
sub submodule_tree_old($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  my $branch_consistent_throughout = 1;
  my $cnt = 0;

  submodule_foreach(sub {
      my $subname = File::Spec->catdir(shift, shift);
      
      my $active_branch = get_selected_branch_here();
      
      
      print "Submodule name " . $subname . "\n";
      
         
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
