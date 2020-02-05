#!/usr/bin/env perl

=head1 SYNOPSIS

Recursively push changes in root repository and all submodules.

No arguments are supported for this command at present beyond --help and --man to show this dialog.

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
my ($help, $man);
GetOptions(
    "help"            => \$help,
    "man"             => \$man,
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

print "nuggit_push_default.pl\n";

print `git submodule foreach --recursive git push`;
print `git push`;

exit $?;


