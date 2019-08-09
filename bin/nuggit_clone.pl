#!/usr/bin/perl -w


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_clone.pl ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git
#



# (1) quit unless we have the correct number of command-line args
$num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "\nUsage: nuggit_clone.pl url/repo.git\n";
    exit;
}

$url=$ARGV[0];


print "repo url is: $url\n";


#isolate the text between the slash and the .git
#i.e.
#nuggit_clone ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git

$repo = $url;
$repo =~ m/\/([a-z\-\_A-Z0-9]*)\.git/;
$repo = $1;

# now remove beginning / and ending .git

print "repo name is: $repo\n";


# clone the repository
system ("git clone $ARGV[0] --recursive");

# initialize the nuggit meta data directory structure
system ("cd $repo; nuggit_init");
