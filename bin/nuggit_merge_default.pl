#!/usr/bin/perl -w

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

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;

die("This script is deprecated.  Use \"nuggit merge --default\" instead");

# TO DO 
# - this script will 
#       - recurse into each submodule,
#               - identify the default branch
#               - merge that branch into the working branch
#               - add and commit?
#       - as it moves back up the tree, add & commit
#       - or the submodule references will be corrected with the new script
#              - nuggit_relink.pl
#
# 


sub merge_default($);

print "nuggit_merge_default.pl\n";




my $root_dir;
my $root_repo_branch;
my $submodules;


$root_dir = find_root_dir() || die("Not a nuggit!\n");


merge_default($root_dir);


sub merge_default($)
{
  my $dir = $_[0];
  
  my $tmp;
  my $submodule;
  my $submodule_status;
  my $submodule_count;
  
  my $default_branch;

  chdir $dir;
  $dir = getcwd();

  $tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
  $tmp =~ m/remotes\/origin\/(.*)$/;
  $default_branch = $1;  

#  print "Default branch: $default_branch\n";

  $submodules = `list_submodules.sh`;
  my @submodules = split /\n/, $submodules;

  $submodule_count = @submodules;
  if($submodule_count == 0)
  {
    print "No submodules\n";
   
#    return;
  }

  print "Count of submodules: $submodule_count\n";

  print "==========================\n";
  print "Submodules: \n";
  foreach(@submodules)
  {
    $submodule = $_;
    
    print "submodule: " . $_ . "\n";
    merge_default($submodule);
    chdir $dir;

  }
 
  print "TO DO - EXPECT THAT THERE WILL BE PROBLEMS MERGING DEFAULT INTO\n";
  print "WORKING BRANCH AFTER HAVING JUST DONE THE SAME IN A SUBMODULE\n";
  print `git merge $default_branch`;


}
