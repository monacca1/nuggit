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

use Cwd qw(getcwd);

sub git_rev_list_recurse();


# shows how many commits are on each side since the common ancestor?
#bash-4.2$ git rev-list --left-right --count origin/master...master
#0       2

sub get_working_branch();

my $root_dir;
$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}

print "nuggit root directory is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;
git_rev_list_recurse();



sub git_rev_list_recurse()
{
  my $dir;
  my $submodule = "";
  my $submodule_list;
  my $working_branch;
  my @submodule_array;  
  my $submodule_dir;
  
  $working_branch = get_working_branch();
  
  $dir = getcwd();
  chomp($dir);
    
  print "Dir: $dir\n";
  print "diff between remote and local for branch: $working_branch\n";
  print "origin  local\n";
  print `git rev-list --left-right --count origin/$working_branch...$working_branch`;
  
  # check if there are any submodules in this repo or if this is a leaf repo
  if(-e ".gitmodules")
  {
    $submodule_list = `list_submodules.sh`;    

    @submodule_array = split /\n/, $submodule_list;

    while($submodule=shift(@submodule_array))
    {

      chomp($submodule);
      
      $submodule_dir = $dir . "/" . $submodule;
  
      chdir($submodule_dir);

      git_rev_list_recurse();
      
      chdir($dir);
    
    } # end while
    
  } # end if(-e ".gitmodules")

}



# get the checked out branch from the list of branches
# The input is the output of git branch (list of branches)
sub get_working_branch()
{
  my $branches;
  my $selected_branch;

  $branches = `git branch`;
  
  $selected_branch = $branches;
  $selected_branch =~ m/\*.*/;
  $selected_branch = $&;
  $selected_branch =~ s/\* //;  
  
  return $selected_branch;
}

