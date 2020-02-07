#!/usr/bin/env perl

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


