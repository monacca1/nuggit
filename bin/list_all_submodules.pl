#!/usr/local/bin/perl

# this script will recurse into submodules to build a full list of all submodules


use strict; # Must declare all variables
use warnings;
use Getopt::Long;

my $arg;
my $i = 0;


sub main();
sub foreach_submodule();


main();



sub main()
{
   
  foreach_submodule();

} # end main()


#
# recurse into each submodule
#
sub foreach_submodule()
{
  my $submodule;
  my $submodule_list;
  my @submodule_array;
  my $dir;
  my $submodule_dir;

  # check if there are any submodules in this repo or if this is a leaf repo
  if(-e ".gitmodules")
  {
    $submodule_list = `list_submodules.sh`;    

    @submodule_array = split /\n/, $submodule_list;

    $dir = `pwd`;
    chomp($dir);

    while($submodule=shift(@submodule_array))
    {
#      print "===============================\n";
#      print "Root: " . $dir . "\n";

      chomp($submodule);
      
      $submodule_dir = $dir . "/" . $submodule;
  
      print $submodule . "\n";
  
      chdir($submodule_dir);
    
#      print "At level $i - recursing\n";
#      $i = $i + 1;
      foreach_submodule();
#      $i = $i - 1;
#      print "POP back to level $i\n";

      chdir($dir);
    
    } # end while
    
  } # end if(-e ".gitmodules")
  else
  {
#    print "There are NO submodules!!!\n";
    $submodule_list = "";
  }

} # end foreach_submodule()


