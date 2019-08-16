#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(getcwd);


#
#
# in the submodule directory
#   git fetch
#   git merge
#
#   if you didnt make any changes, and you are on master, I think that is the same as
#   git pull
#
# git submodule update --remote
#  goes into the directory, fetch and update
#
#


# if there are changes upstream and local we can either merge or rebase?
#
# git submodule update --remote --merge
#    merge the changes into my branch???
#
#
# the rebase option:
# git submodule update --remote --rebase
#
#


# ------------------------------------------------------------------------------------------------------------------
# the following assumes you want to merge the branch into master at the command line
# and then push to master... this is not allowed in some workflows.  In those workflows
# you have to push to a remote branch and then use a pull request on the server to 
# perform the merge
#
# git checkout master
# git merge <branch>
#    I tried this on a clean merge and it resulted in a fast forward merge... no commit
#    you can either try to force a commit.  There is an argument to pass to git merge --no-ff 
#    you can pass in a -m to git merge and
#    you will have to do this recursively in each repo, and then add and commit as you go up the tree.
# ------------------------------------------------------------------------------------------------------------------


my $root_dir;

$root_dir = `nuggit_find_root.pl`;
chomp $root_dir;

if($root_dir eq "-1")
{
  print "Not a nuggit!\n";
  exit();
}

print "nuggit_merge.pl - TO DO\n";


