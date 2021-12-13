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

#
# This script will output the state of the currenctly checked out branch
#
# to do - boil this down into a statement that indicates the repo is consistent or not
# maybe make that the default behavior, or make a differt command the "check-tree"
# maybe make the current output be the output for a -v (verbose) option?
#

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

sub list_submodules( );
sub p_indent($);
sub submodule_tree($$$$);


my $ngt = Git::Nuggit->new();


my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;



my $cwd = getcwd();

$root_dir = $ngt->root_dir();

my $submodules;


chdir $root_dir;

print "==========================================================\n";
print "Repository location:\n";
print "    $root_dir \n";

# print $cwd . "\n";

my $active_branch = get_selected_branch_here();

# get branch of root repo

print "On branch: \n";
print "    $active_branch \n";

print "Branch HEAD commit for root repo:\n";
print "    " . `git log -n1 $active_branch | grep commit`;
print "==========================================================\n";


submodule_tree("root repo", $root_dir, "0000", 0);



sub submodule_tree($$$$)
{
  my $repo     = $_[0];
  my $dir      = $_[1];
  my $ref_hash = $_[2];
  my $indent   = $_[3];
  
  my $start_dir;
  my $result_dir;
  my $submodule_count;
  my $submodule;
  my $submodule_status;
  
  my $ls_tree_info;
  my @ls_tree_info_split;
  
  my $git_log_result;
  my @git_log_result_split;
  my $head_commit;
 
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

  $git_log_result       = `git log -n1 HEAD | grep commit`;
  @git_log_result_split = split(" ", $git_log_result);
  $head_commit = $git_log_result_split[1];
  print p_indent($indent) . "Branch HEAD commit: " . $head_commit . "\n";

  if($dir ne $start_dir)
  {  
    if($head_commit ne $ref_hash)
    {
      print p_indent($indent) . "************************************************************\n";
      print p_indent($indent) . "* Submodule $repo inconsistent with parent reference\n";
      print p_indent($indent) . "* Parent points to commit: \n";
      print p_indent($indent) . "*     $ref_hash\n";
      print p_indent($indent) . "* HEAD of branch is commit: \n";
      print p_indent($indent) . "*     $head_commit\n";
      print p_indent($indent) . "************************************************************\n";
    }  
  }
  
#  print list_submodules();
  $submodules = list_submodules();

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

    # check if directory exists;
    if(-e $dir . "/" . $submodule)
    {
    }
    else
    {
       print p_indent($indent) . "************************************************************\n";
       print p_indent($indent) . "* Submodule specified:\n";
       print p_indent($indent) . "*    $submodule\n";
       print p_indent($indent) . "* However, directory does not exist:\n";
       print p_indent($indent) . "*    $dir/$submodule\n";
       print p_indent($indent) . "* Bailing out\n";
       print p_indent($indent) . "************************************************************\n";
       exit();
    }

#    print p_indent($indent) . "Directory: " . getcwd() . "\n";
#    print p_indent($indent) . "Executing command: git ls-tree -r $active_branch $submodule --abbrev=8\n";
    print p_indent($indent) . "Submodule $submodule\n";
    $ls_tree_info = `git ls-tree -r $active_branch $submodule`;
    @ls_tree_info_split = split(" ", $ls_tree_info);
    $ref_hash = $ls_tree_info_split[2];
    print p_indent($indent) . "  SM ref commit hash: " . $ref_hash . "\n";


#    print "Recursing into submodule: " . $_ . "\n";
    submodule_tree($submodule, $dir . "/" . $submodule,  $ref_hash,   $indent+1);
    chdir $dir;
  }

  #nuggit_get_path_relation_to_root.pl

  #print `git log -n1 HEAD | grep commit`;
  #print `git ls-tree -r HEAD | grep commit`;

}



sub p_indent($)
{ 
  my $i;
  my $indent = $_[0];
  
  for($i = 0; $i < $indent; $i = $i + 1)
  {
    print "  ";
  }
}



sub list_submodules( )
{
 
  if (-e '.gitmodules')
  {
    return `grep path .gitmodules | sed 's/path//' | sed 's/\=//' | sed 's/ //g' | sed 's/\t//g' `
  }
  
  return "";
}


