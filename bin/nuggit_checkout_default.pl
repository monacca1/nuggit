#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;

=head1 SYNOPSIS

Checkout the default branch at all levels.

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=back

=cut

my $num_args;
my $branch;
my $cwd = getcwd();


my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;
my $log = Git::Nuggit::Log->new(root => $root_dir)->start(1);

my ($help, $man);
Getopt::Long::GetOptions(
    "help"            => \$help,
    "man"             => \$man,
                        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;


check_merge_conflict_state(); # Do not proceed if merge in process; require user to commit via ngt merge --continue

# print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir($root_dir) || die("Can't enter $root_dir");

submodule_foreach(\&checkout_default_branch);

# check all submodules to see if the branch exists
sub checkout_default_branch
{
  my    $tmp;
  my    $default_branch;
  my ($parent, $name, $status, $hash, $label) = (@_);
  my $current_dir = $parent . '/' . $name; # Full Path to Repo Relative to Root
  
  die "DEBUG: Internal Error, Unexpected Args length of ".scalar(@_) unless scalar(@_)>=5;
  $tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
  $tmp =~ m/remotes\/origin\/(.*)$/;

  # TODO: Handle ambiguous HEAD case.  If multiple branches are returned from above, prompt user to select (default to master, if it exists).  Or better yet, pasre .gitmodules to find tracking branch
  
  $default_branch = $1;  

  print "default HEAD branch is $default_branch\n";

#  $tmp = `git remote show origin | grep HEAD`;   
#  $tmp =~ m/HEAD branch\: (.*)$/;
#  $default_branch = $1;
  
  print "Tracking branch is: $default_branch\n";
  print "\t Current Ref Status is $status at $hash of $label\n"; # VERIFY Accuracy/meaning of label
  
  print `git checkout $default_branch`;
  print `git pull`;
  
}

