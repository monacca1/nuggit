#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Getopt::Long;
use Pod::Usage;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;

=head1 SYNOPSIS

nuggit clone [-b BRANCH_NAME] CLONE_URL_TO_ROOT_REPO

=cut

my ($branch, $help, $man);
Getopt::Long::GetOptions(
                         "help"            => \$help,
                         "man"             => \$man,
                         "branch|b=s"      => \$branch,
                        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;



# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
if ($num_args != 1 && $num_args != 2) {
    po2usage(1);
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

my $opts = "";
$opts .= "-b $branch " if defined($branch);


# clone the repository
print `git clone $opts $url --recursive -j8 $repo`;

# initialize the nuggit meta data directory structure
chdir($repo) || die "Can't enter cloned repo ($repo)";
nuggit_init();
my $log = Git::Nuggit::Log->new(root => '.')->start(1);

