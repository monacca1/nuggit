#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
require "nuggit.pm";

sub get_selected_branch_here();



# usage: 
#
# nuggit_pull.pl
#

print "nuggit_pull.pl\n";

my $selected_branch = "";
my $nuggit_status = "";

my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;

#print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";
#print $relative_path_to_root . "\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;



print "Checking for local changes\n";
$nuggit_status = `nuggit_status.pl`;
if(defined $nuggit_status)
{
  if($nuggit_status eq "")
  {
#    print "nuggit_status.pl returned empty string\n";
  }
  else
  {
    print "Local changes exists!!! The pull may not have occurred or completed!!!\n";
    print "nuggit_status.pl returned the following:\n";
    print "$nuggit_status\n";
  }
}
else
{
  print "nuggit_status.pl returned nothing\n";
}



#print "I think you may need to do the following when pulling a new-to-you branch\n";
#print "  git pull origin <branch>\n";
#print "  and then\n";
#print "  git submodule foreach --recursive git pull origin <branch>\n";


$selected_branch = get_selected_branch_here();

print `git pull origin $selected_branch`;
print `git submodule foreach --recursive git pull origin $selected_branch`;

# TODO: Any new submodules need to be init and explicitly updated.
#print `git submodule init`;
#print `git submodule foreach --recursive git submodule init`;


