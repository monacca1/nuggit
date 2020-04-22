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

=head1 SYNOPSIS

Recursively push changes in root repository and all submodules.

Use "--help" or "--man" to display this help dialog.

Specify "--all" to push all branches, not just the currently checked out one.

=cut

# TODO: Support for explicitly specifying remote and/or branch


use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Pod::Usage;
use Getopt::Long;
use Git::Nuggit;
use Git::Nuggit::Log;

my $root_dir = do_upcurse();
my $log = Git::Nuggit::Log->new(root => $root_dir);
my ($help, $man, $all_flag);
GetOptions(
           "help"            => \$help,
           "man"             => \$man,
           "all!"            => \$all_flag,
          );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
die("Not a nuggit!") unless $root_dir;
$log->start(1);

sub get_selected_branch($);
sub get_selected_branch_here();

my $verbose = 0;
my $cwd = getcwd();

chdir $root_dir;


my $branch = get_selected_branch_here();
my $opts = "";
$opts .= "--all " if $all_flag;

print "nuggit_push.pl\n";

print `git submodule foreach --recursive git push $opts --set-upstream origin $branch`;

die "Failed to push one or more submodules" unless $? == 0;

print `git push $opts --set-upstream origin $branch`;

exit $?;


