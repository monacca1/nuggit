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

use strict;
use warnings;

use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;
use Getopt::Long;
use Pod::Usage;

my $prune_mode = 0;
my $root_dir = do_upcurse();

my $log = Git::Nuggit::Log->new(root => $root_dir);

=head1 SYNOPSIS

nuggit fetch


Fetch commits, branches, and tags from the remote for all submodules.  The parallel flag is automatically utiliazed (-j8) to speed up results.

NOTE: Fetch is always performed against the default remote ('origin')

Specify "--prune" to enable detection and removal of branches that have been removed on the remote.  Note this only affects remotes/* entries, and will never prune branches that have been checked out locallly.

=cut

my ($help, $man);
Getopt::Long::GetOptions(
                         "help"            => \$help,
                         "man"             => \$man,
                         "prune!"          => \$prune_mode,
                        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
$log->start(1);

# TODO: Detect if fetch fails
my $opts = "";
$opts .= "--prune " if $prune_mode;
my $cmd = "git fetch --all --recurse-submodules -j8 $opts";
print `$cmd`;
$log->cmd($cmd);
#print `git submodule foreach --recursive git fetch --all`;
