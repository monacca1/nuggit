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

# TODO: This script has not been updated to fully utilize Git::Nuggit*
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;

=head1 SYNOPSIS
 nuggit_relink_submodules.pl - 
    when the commit at the head of a branch within a submodules is NOT
    the commit that the parent repo points to, the situation needs to 
    be "relinked"... which means "add" the submodule to the parent
    index so it will be committed at the next nuggit_commit



 for each submodule that has changes, add it to the
 index to be committed to the particular repo/submodule
 you need to follow this up with a nuggit_commit.pl

=cut

print "nuggit_relink_submodules.pl\n";



my $root_dir;
my $root_repo_branch;
my $submodules;

$root_dir = find_root_dir() || die("Not a nuggit!\n");
my $log = Git::Nuggit::Log->new(root => $root_dir);


my ($help, $man);
Getopt::Long::GetOptions(
    "help"            => \$help,
    "man"             => \$man,
                        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;


$log->start(1);

relink($root_dir);

print "Follow up this command with \"nuggit commit -m <msg>\"\n";


sub relink
{
  my $dir = $_[0];
  
  my $submodule;
  my $submodule_status;
  my $submodule_count;

  chdir $dir;
  $dir = getcwd();


  $submodules = `list_submodules.sh`;
  my @submodules = split /\n/, $submodules;

  $submodule_count = @submodules;
  if($submodule_count == 0)
  {
#    print "No submodules\n";
    return;
  }

#  print "Count of submodules: $submodule_count\n";

#  print "==========================\n";
#  print "Submodules: \n";
  foreach(@submodules)
  {
    $submodule = $_;
    
#    print "submodule: " . $_ . "\n";
    relink($submodule);

    if(-e $dir)
    {
      chdir $dir;    
    }
    else
    {
      print "ERROR: Directory ($dir) does not exist\n";
      print "Check with nuggit tree\n";
    }
    
    $submodule_status = `git status --porcelain $submodule`;

    if($submodule_status ne "")
    {
      print "status: " . $submodule_status ;
      
      print `git add $submodule`;
      
    }

  }

}





#submodule_foreach(\&submodule_foreach_example);

sub submodule_foreach_example
{
    my ($parent, $name, $substatus, $hash, $label) = (@_);
    my $subpath = $parent . '/' . $name .'/';

    print "-----------------------------\n";
    print "parent:           $parent\n";
    print "name:             $name\n";
    print "submoduel status: $substatus\n";
    print "hash:             $hash\n";
    print "label:            $label\n";
    

}
