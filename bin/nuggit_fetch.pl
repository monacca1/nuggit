#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;
use Getopt::Long;
use Pod::Usage;

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
