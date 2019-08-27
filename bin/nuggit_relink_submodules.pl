#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";


# nuggit_relink_submodules.pl - 
#    when the commit at the head of a branch within a submodules is NOT
#    the commit that the parent repo points to, the situation needs to 
#    be "relinked"... which means "add" the submodule to the parent
#    index so it will be committed at the next nuggit_commit


#
# for each submodule that has changes, add it to the
# index to be committed to the particular repo/submodule
#
# you need to follow this up with a nuggit_commit.pl
#
#


print "nuggit_relink_submodules.pl\n";



my $root_dir;
my $root_repo_branch;
my $submodules;

$root_dir = find_root_dir() || die("Not a nuggit!\n");


relink($root_dir);


sub relink($)
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
    chdir $dir;
    
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
