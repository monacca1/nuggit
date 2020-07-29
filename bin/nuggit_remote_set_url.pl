#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Pod::Usage;
use Cwd qw(getcwd);
use File::Spec;
use Git::Nuggit;

=head1 SYNOPSIS

nuggit_remote_set_url.pl <remote name> <new url>

Nuggit command to change the URL for the given remote in the root nuggit
repository and its submodules.  Based on git set-url.
If the remote is not given, origin is changed by default.

=cut

# quit if the incorrect number of arguments is given
my $numArgs = $#ARGV + 1;
if ($numArgs != 1 && $numArgs != 2) {
	pod2usage(1);
	exit 1;
}

my $name;
my $newurl;

# remote is origin unless two arguments are given
if ($numArgs == 2) {
	$name = $ARGV[0];
	$newurl = $ARGV[1];
} else {
	$name = 'origin';
	$newurl = $ARGV[0];
}


# go to nuggit root
my ($root_dir, $relative_path_to_root) = find_root_dir();
if (!$root_dir) {
	die 'Nuggit root directory not found';
}
chdir $relative_path_to_root || die "Cannot enter directory $relative_path_to_root: $!";

# remove repo name from newurl, url is invalid if it does not match the pattern
die 'Url invalid' if $newurl !~ m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
$newurl =~ s/$1$2//;

# get root repo name
my $rootUrl = `git remote get-url $name`;
$rootUrl =~ m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
my $rootName = $2 ? "$1$2" : "$1";

# change root url
print `git remote set-url $name $newurl$rootName`;

# change submodule urls
submodule_foreach(sub {
        my $submodUrl = `git remote get-url $name`;
	$submodUrl =~  m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
	my $submodName = $2 ? "$1$2" : "$1";
	print `git remote set-url $name $newurl$submodName`;
      }
);
