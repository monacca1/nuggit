#!/usr/local/bin/perl

# this script will recurse into submodules to build a full list of all submodules


use strict; # Must declare all variables
use warnings;
use Getopt::Long;

my $arg;
my $i = 0;


sub main();
sub foreach_submodule($);


main();



sub main()
{
   
  foreach_submodule( "" );

} # end main()


#
# recurse into each submodule
#
sub foreach_submodule( $ )
{
  my $submodule;
  my $submodule_list;
  my @submodule_array;
  my $dir;
  my $submodule_dir;
  my $location = $_[0];
  my $tmp;
  
  # use the "location" the build up the relative path of the submodule... relative to the root repo.
  if($location ne "")
  {
    #print "LOCATION: " . $location . "\n";
    
    # The trailing slash needs to be there for the recursive buildup 
    # of the path, but remove it for the printing
    $tmp = $location;
    $tmp =~ s/\/$//;
    print $tmp . "\n"
  }

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
  
#      print "SUBMODULE: " . $submodule . " SUBMODULE DIR: " . $submodule_dir . "\n";
  
      chdir($submodule_dir);
    
#      print "At level $i - recursing\n";
#      $i = $i + 1;
       foreach_submodule( $location . $submodule . "/" );
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


