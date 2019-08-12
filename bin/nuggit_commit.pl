#!/usr/bin/perl -w


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_commit.pl 
#

print "nuggit_commit.pl --- to do\n";



# to get a list of files that have been staged to commit (by the user) use:
#   git diff --name-only --cached
# use this inside each submodule to see if we need to commit in that submodule.


# for each submodule drill down into that directory:
#    see if there is anything stated to commit
#    if there is something staged to commit, commit the staged files with the commit message provided
#    this will need to be nested or recursive or linear across all submodules... need to design how this will work
#       but will need to traverse all the way back up the tree committing at each level.  Use the commit message 
#       provided by the caller, but for committing submodules that have changed as a result, consider constructing
#       a commit message that is based on the callers commit message... consider adding the branch and submodule name
#       to the commit?
#    
