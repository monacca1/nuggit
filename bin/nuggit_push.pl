#!/usr/bin/perl -w


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_push.pl 
#

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path

require "nuggit.pm";

sub get_selected_branch($);
sub get_selected_branch_here();

my $verbose = 0;
my $cwd = getcwd();
my $root_dir = do_upcurse($verbose);

print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;


my $branch = get_selected_branch_here();

print "nuggit_push.pl\n";

print "TO DO - NEED TO MAKE SURE THE REPO IS ON THE SAME BRANCH THROUGHOUT ALL SUBMODULES\n";

print `git submodule foreach --recursive git push --set-upstream origin $branch`;

die "Failed to push one or more submodules" unless $? == 0;

print `git push --set-upstream origin $branch`;




