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

# See POD documentation at end of file

use strict;
use warnings;
use v5.10;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Pod::Usage;
use Git::Nuggit;
warn "nuggit_pull.pl is DEPRECATED in favor of 'nuggit_ops.pl pull --strategy=branch', or 'nuggit_ops.pl pull' for recommended ref-first";
my $skip_status_check = 1;
my $commit_message;
my $edit_flag = 1; # Mirrors Git's edit/no-edit flag
my $verbose = 0;
my $ref_mode_flag = 0;
my ($help, $man);

# NOTE: Nuggit log entry will be made by nuggit_fetch, which will automatically show nuggit_pull as its context

GetOptions(
    "help"            => \$help,
    "man"             => \$man,
           'verbose!' => \$verbose,

           # TODO: Support for pulling from other branch, remote, or repo (for advanced users)

           # The following options if defined are passed-through to nuggit_merge
           'message=s'  => \$commit_message, # Specify message to use for any commits upon merge (optional; primarily for purposes of automated testing). If omitted, user will be prompted for commit message.  An automated message will be used if a conflict has been automatically resolved.
           'edit!' => \$edit_flag,
           'skip-status-check!' => \$skip_status_check,
           'ref!' => \$ref_mode_flag, # Merge by reference & trust in git
           );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

my $root_dir = do_upcurse();

if (!$skip_status_check) {
    my $status = get_status();
    if (!status_check($status))
    {
        say colored("Local changes detected.  Please commit or stash all changes before running pull.", 'red');
        say colored(" If you wish to attempt the pull anyway, re-run this command with '--skip-status-check' flag.", 'yellow');
        say "\nCurrent repository status is: ";
        pretty_print_status();
        die "Pull aborted due to dirty working directory.  Please commit, or re-run with --skip-status-check";
    }
}


# Execute a Fetch
# TODO: Make this a lib fn and add checks to confirm fetch succeeded
require("$FindBin::Bin/nuggit_fetch.pl");

# Execute Nuggit Merge of remotes/origin/$selected_branch
#  TODO: support for alternate remotes
push(@ARGV, '--log-as-pull');
push(@ARGV, "--message", $commit_message) if defined($commit_message);
push(@ARGV, "--no-edit") if !$edit_flag; # Default is edit
push(@ARGV, "--verbose") if $verbose;
push(@ARGV, '--ref') if $ref_mode_flag;

exec("$FindBin::Bin/nuggit_merge.pl", @ARGV);


# Done (exec never returns)

=head1 Pull

Nuggit pull recursively pulls at all levels.  It is implemented by calling nuggit fetch followed by merge, similarly to how the native git pull function behaves.

If a conflict arises during the pull operation, it must be resolved and completed with nuggit merge --continue|abort

Refer to merge and fetch help pages for additional details.

=head1 SYNOPSIS

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item --verbose

Display additional details.

=item --message

Specify message to use for any commits upon merge

=item --no-edit

If specified, this flag will be passed on to git such that the default merge message will be used for any commits.


=back

=cut
