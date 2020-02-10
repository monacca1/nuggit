#!/usr/bin/env perl

=head1 SYNOPSIS

Nuggit file rename wrapper.  This invokes "git mv" appropriately for the given file", which in turn renames said file and stages it in a single step.

WARNING: This command can only be used to move a file WITHIN a given submodule.  It is not possible to move a file between submodules while preserving history.

=cut

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use Git::Nuggit;
use File::Spec;

my $ngt = Git::Nuggit->new(); # Initialize Nuggit & Logger prior to altering @ARGV
my $verbose = 0;
my ($help, $man);
Getopt::Long::GetOptions(
    "help"             => \$help,
    "man"              => \$man,
    "verbose"          => \$verbose,
    );
pod2usage(-exitval => 0, -verbose => 2) if $man;
pod2usage(1) if $help || !defined($ARGV[0]);

die("Not a nuggit!\n") unless $ngt;
$ngt->start(level => 1, verbose => $verbose); # Open Logger for loggable-command mode


my $file = $ARGV[0];
my $newfile = File::Spec->rel2abs($ARGV[1]);
say "Renaming $file to $newfile";

# Get name of parent dir
my ($vol, $dir, $fn) = File::Spec->splitpath( $file );

if ($dir) {
    chdir($dir) || die ("Error: Can't enter file's parent directory: $dir");
}
$ngt->run("git mv $fn $newfile");
