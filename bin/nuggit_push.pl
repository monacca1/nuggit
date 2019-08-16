#!/usr/bin/perl -w


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_push.pl 
#

sub get_selected_branch($);
sub get_selected_branch_here();



my $branch = get_selected_branch_here();


print "nuggit_push.pl --- to do\n";
print "to do - to do - to do\n";

print `git submodule foreach --recursive git push --set-upstream origin $branch`;
print `git push --set-upstream origin $branch`;




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
