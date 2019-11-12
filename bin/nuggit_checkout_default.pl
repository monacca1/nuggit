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

sub checkout_default();



check_merge_conflict_state(); # Do not proceed if merge in process; require user to commit via ngt merge --continue

# print "nuggit root dir is: $root_dir\n";
#print "nuggit cwd is $cwd\n";

#print "changing directory to root: $root_dir\n";
chdir($root_dir) || die("Can't enter $root_dir");


print "Current working directory is: " . getcwd() . "\n";


my $tmp;
my $default_branch;

$tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
$tmp =~ m/remotes\/origin\/(.*)$/;
$default_branch = $1;

print "Tracking branch is: $default_branch\n";
print `git checkout $default_branch`;
print `git pull`;

checkout_default();



sub checkout_default()
{
  my $parent_dir = getcwd();
  my $tmp2;
  my $default_branch;
  my $git_config_branch = "";
  
  # get a list of all of the submodules
  my $submodules = `list_submodules.sh`;
  
  # put each submodule entry into its own array entry
  my @submodules = split /\n/, $submodules;

#  print "Does branch exist throughout?\n";
    
  foreach (@submodules)
  {
    $tmp2 = `git config --file .gitmodules --get-regexp branch`;

    if( $tmp2 =~ m/submodule\.$_\.branch (.*)\n/  )
    {
       $git_config_branch = $1;
       print "Found submodule $_ config for default branch is $git_config_branch\n";

       print "Entering submodule $_ \n";
       chdir $_;
       
       print `git checkout $git_config_branch`;
       print `git pull`;
       
    }
    else
    {
       print "Entering submodule $_ \n";
       chdir $_;

       $tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
       $tmp =~ m/remotes\/origin\/(.*)$/;
       $default_branch = $1;

       print "Tracking branch for this submodule ($_) is: $default_branch\n";
       print `git checkout $default_branch`;
       print `git pull`;
       
    }
     
    checkout_default();
    
    # return to parent directory
    chdir $parent_dir;
  }
}












#submodule_foreach(\&checkout_default_branch);

# check all submodules to see if the branch exists
sub checkout_default_branch
{
  my    $tmp;
  my    $foo;
  my    $default_branch;
  my ($parent, $name, $status, $hash, $label) = (@_);
  my $current_dir = $parent . '/' . $name; # Full Path to Repo Relative to Root
  
  die "DEBUG: Internal Error, Unexpected Args length of ".scalar(@_) unless scalar(@_)>=5;
  $tmp = `git symbolic-ref refs/remotes/origin/HEAD`;
  $tmp =~ m/remotes\/origin\/(.*)$/;
  
#  $foo = `git config --file .gitmodules --get-regexp branch`;
#  print "Attempt to get the tracking branch for this submodule using .gitmodules returned " . $foo . "\n";

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

