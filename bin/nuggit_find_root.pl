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

# NOTICE: THIS FILE IS DEPRECATED IN FAVOR OF lib/nuggit.pm's find_root_dir()

use strict;
use warnings;

use Cwd qw(getcwd);

# prints the root directory of the nuggit or 0

# usage: 
#
# nuggit_find_root.pl
#

# find the .nuggit. This script will only search
# in the current directory and 10 directories up and then give up



my $cwd = getcwd();
my $nuggit_root;

my $max_depth = 10;
my $i = 0;

for($i = 0; $i < $max_depth; $i = $i+1)
{
  if(-e ".nuggit") 
  {
     $nuggit_root = getcwd();
#     print "starting path was $cwd\n";
#     print ".nuggit exists at $nuggit_root\n";

     print $nuggit_root . "\n";
     exit();
  }
  chdir "../";
  
#  $cwd = getcwd();
#  print "$i, $max_depth - cwd = " . $cwd . "\n";
  
}

print "-1";
