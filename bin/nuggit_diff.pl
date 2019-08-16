#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);

# to do

# Notes
# git branch -a
# git diff  origin/master master --name-status
# git diff origin/master master --stat
# git diff --submodule
# git diff --cached --submodule


# shows how many commits are on each side since the common ancestor?
#bash-4.2$ git rev-list --left-right --count origin/master...master
#0       2

# git fetch
# git status


my $branch;

#$branch = "jira-111";
$branch = "master";

print "TO DO - NEED TO FIX THIS API... IT SHOULD BE MORE SIMILAR TO THE GIT DIFF COMMAND\n";
print "TO DO - DO THIS AT THE ROOT REPO AND RECURSIVELY AND PUT INTO NICE FORMAT\n\n";

print "diff between remote and local for branch $branch\n";
print "remote  local\n";
print "commits commits\n";
print "|       |\n";
print `git rev-list --left-right --count origin/$branch...$branch`;


