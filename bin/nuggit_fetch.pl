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

Fetch commits, branches, and tags from the remote for all submodules.  

nuggit fetch

NOTE: Fetch is always performed against the default remote ('origin')

=cut

my ($help, $man);
Getopt::Long::GetOptions(
    "help"            => \$help,
    "man"             => \$man,
                        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
$log->start(1);

# TODO: Detect if fetch fails
my $cmd = "git fetch --all --recurse-submodules";
print `$cmd`;
$log->cmd($cmd);
#print `git submodule foreach --recursive git fetch --all`;
