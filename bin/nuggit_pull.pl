#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);

sub get_selected_branch($);
sub get_selected_branch_here();



# usage: 
#
# nuggit_pull.pl
#

print "nuggit_pull.pl\n";

print "TO DO - NEED TO MAKE SURE THERE ARE NO UNCOMMITTED LOCAL CHANGES\n";


my $root_dir;
my $relative_path_to_root;
my $selected_branch = "";


$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}

# the relative path to root is used in the output.
# it is used before each file in each submodule with a status change.
# this is done so the user can copy the entire path and call
# nuggit_add.pl or nuggit_diff.pl on that path and it is valid
$relative_path_to_root = `nuggit_get_path_relation_to_root.pl`;
chomp $relative_path_to_root;

#print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";
#print $relative_path_to_root . "\n";

#print "changing directory to root: $root_dir\n";
chdir $root_dir;


#print "I think you may need to do the following when pulling a new-to-you branch\n";
#print "  git pull origin <branch>\n";
#print "  and then\n";
#print "  git submodule foreach --recursive git pull origin <branch>\n";


$selected_branch = get_selected_branch_here();

print `git pull origin $selected_branch`;
print `git submodule foreach --recursive git pull origin $selected_branch`;





sub get_selected_branch_here()
{
  my $branches;
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  # execute git branch
  $branches = `git branch`;

  $selected_branch = get_selected_branch($branches);  
}


sub get_selected_branch($)
{
  my $root_repo_branches = $_[0];
  my $selected_branch;

  $selected_branch = $root_repo_branches;
  $selected_branch =~ m/\*.*/;
  $selected_branch = $&;
  $selected_branch =~ s/\* //;  
  
  return $selected_branch;
}
