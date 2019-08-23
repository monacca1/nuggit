#!/usr/bin/env perl

# this script will recurse into submodules to build a full list of all submodules


use strict; # Must declare all variables
use warnings;
use Getopt::Long;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Cwd;

require "nuggit.pm";

my $arg;
my $i = 0;


sub main();
sub foreach_submodule($);


main();



sub main()
{
  submodule_foreach(sub {
                       print shift . '/' . shift . "\n";
                     }
                    );

} # end main()

