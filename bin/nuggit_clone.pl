#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;


# usage: 
#
#/homes/monacca1/git-stuff/nuggit/bin/nuggit_clone.pl ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git
#



# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
if ($num_args != 1 && $num_args != 2) {
    print "\nUsage: nuggit_clone.pl url/repo.git [target_dir]\n";
    exit 1;
}

my $url=$ARGV[0];  # URL or Path to Clone From
my $repo=$ARGV[1]; # Name of Target Directory (implied from URL/Path otherwise)

print "repo url is: $url\n";


#isolate the text between the slash and the .git
#i.e.
#nuggit_clone ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git

if (!$repo) {
    $repo = $url;
    
    # now remove beginning / and ending .git
    $repo =~ m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
    
    $repo = $1;
}


print "repo name is: $repo\n";


# clone the repository
print `git clone $url --recursive -j8 $repo`;

# initialize the nuggit meta data directory structure
chdir($repo) || die "Can't enter cloned repo ($repo)";
nuggit_init();
nuggit_log_init();
