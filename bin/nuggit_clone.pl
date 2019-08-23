#!/usr/bin/perl -w
use strict;
use warnings;

# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_clone.pl ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git
#



# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "\nUsage: nuggit_clone.pl url/repo.git\n";
    exit;
}

my $url=$ARGV[0];


print "repo url is: $url\n";


#isolate the text between the slash and the .git
#i.e.
#nuggit_clone ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git

my $repo = $url;
$repo =~ m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
$repo = $1;

# now remove beginning / and ending .git

print "repo name is: $repo\n";


# clone the repository
print `git clone $url --recursive`;

# initialize the nuggit meta data directory structure
chdir($repo) || die "Can't enter cloned repo ($repo)";
print `nuggit_init`;

