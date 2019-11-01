#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);

use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;

# show or clear the contents of the nuggit log

# usage: 
#
# clear the nuggit log
#    nuggit_log.pl -c
# show the entire nuggit log
#    nuggit_log.pl --show-all
#   or with no arguments:
#    nuggit_log.pl
# show the last n lines 
#    nuggit_log.pl --show <n>
#
sub ParseArgs();

my $clear_nuggit_log = 0;
my $show_all_bool    = 0;
my $show_n_entries   = 0;

my $date = `date`;
chomp($date);
my $cwd;
my $root_repo_branch;
my ($root_dir, $relative_path_to_root) = find_root_dir();

ParseArgs();



$cwd = getcwd();
#print $cwd . "\n";
#print $clear_nuggit_log  . "\n";
#print $show_all_bool     . "\n";
#print $show_n_entries    . "\n";


if($clear_nuggit_log == 1)
{
  print "Clear the nuggit_log.txt\n";
  
  system("echo nuggit log cleared: $date > .nuggit/nuggit_log.txt");

}
elsif($show_all_bool == 1)
{
  print `cat .nuggit/nuggit_log.txt`;
}
elsif($show_n_entries > 0)
{
  print `tail $show_n_entries .nuggit/nuggit_log.txt`;
}
else
{
  print `cat .nuggit/nuggit_log.txt`;
}




sub ParseArgs()
{
  Getopt::Long::GetOptions(
     "-c"         => \$clear_nuggit_log,
     "--show-all" => \$show_all_bool,
     "--show=s"   => \$show_n_entries
     );
}


