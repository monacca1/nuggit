#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Getopt::Long;
use Pod::Usage;

=head1 SYNOPSIS

Initialize the current working directory as a Nuggit project.  To undo, delete the ".nuggit" folder.

nuggit init

=cut

my ($help, $man);
Getopt::Long::GetOptions(
    "help"            => \$help,
    "man"             => \$man,
                        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;


nuggit_init();


