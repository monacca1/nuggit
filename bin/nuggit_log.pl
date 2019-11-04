#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
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

my $verbose = 0;
my $write_msg;
my $clear_nuggit_log  = 0;
my $show_raw_bool     = 0;
my $show_summary_bool = 1;

my $filter_first_timestamp;
my $filter_last_timestamp;

my $show_n_entries    = 0;

# Color scheme
my $timeColor = 'green';
my $cwdColor = 'cyan';
use Time::Local;
my $cwd;
my $root_repo_branch;
my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!") unless $root_dir;

ParseArgs();

my $log_file = "$root_dir/.nuggit/nuggit_log.txt";

if($clear_nuggit_log == 1)
{
    _nuggit_log_clear();
    nuggit_log_init($root_dir, "ngt log --clear");
}
elsif($show_raw_bool == 1)
{
  print `cat $log_file`;
}
elsif($write_msg)
{
    # Include comment flag to avoid issues if we attempt to replay commands in future
    nuggit_log_init($root_dir, "# $write_msg");
}
else
{
    die("Log file does not exist") unless -e $log_file;
    open(my $fh, '<', $log_file) || die("Error: Unable to open log file");
    my $last_timestamp;
    my $filter_active = 0;

    while(my $line = <$fh>) {
        if ($line =~ /^([^,]+),(.+)$/) {
            my $timestamp = $1;
            my $cmd = $2;

            # Parse timestamp for filtering purposes
            my ($mon,$mday,$year,$hour,$min,$sec) = $timestamp =~ /(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)/;
            $last_timestamp = timelocal($sec, $min, $hour, $mday, $mon-1, $year);

            last if $filter_last_timestamp && $last_timestamp > $filter_last_timestamp;
            if ($filter_first_timestamp && $last_timestamp < $filter_first_timestamp) {
                $filter_active = 1;
                next;
            } else {
                $filter_active = 0;
            }
            
            # Display it
            print colored($timestamp,$timeColor);
            print ": ";
            say $cmd;
        } elsif (!$show_summary_bool && !$filter_active) {
            if ($line =~ /^,,\t(.+)$/) {
                # Message line
                say $1;
            } elsif ($line =~ /^,,CWD,(.+),CMD,(.+)$/) {
                # Logged command
                print "$2";
                print colored("\t($1)", $cwdColor) unless $1 eq ".";
                say "";
            } elsif ($line =~ /^,,(.+)$/) {
                # TODO: Other log types may be added in future, just dump them for now.
                say $1;
            } else {
                say $line; # If all else fails, show it as-is
            }
        }        
    }
    close($fh);
}




sub ParseArgs()
{
    my ($filter_today, $filter_last_days, $filter_last_hours);
    Getopt::Long::GetOptions(
        "clean|c"         => \$clear_nuggit_log,
        "raw!"            => \$show_raw_bool,
        "message|m=s"     => \$write_msg,
        "summary|s!"      => \$show_summary_bool,
        "verbose|v!"      => \$verbose,
        "show=s"   => \$show_n_entries,

        # Filtering Options (incomplete)
        "today!"  => \$filter_today,
        "days|d=i" => \$filter_last_days,
        "hours|h=i" => \$filter_last_hours,
        );
    
    $show_summary_bool = 0 if $verbose;

    if ($filter_today) {
        $filter_first_timestamp = time;
        $filter_first_timestamp -= 60*60*24; # Show entries from last 24 hours only
    } elsif ($filter_last_days || $filter_last_hours) {
        $filter_first_timestamp = time;
        $filter_first_timestamp -= 60*60*24*$filter_last_days if $filter_last_days;
        $filter_first_timestamp -= 60*60*$filter_last_hours if $filter_last_hours;
    }

    if ($filter_first_timestamp && $filter_last_timestamp) {
        die("Error: Illegal date ranges specified") if $filter_first_timestamp > $filter_last_timestamp;
    }
  
}

=head1 SYNOPSIS

View and manage the nuggit log file.  If run without arguments, this script will display the log file in summary view.

=over

=item --message | -m

Write the specified message to the log file

=item --summary | --no-summary

If set (default), only the primary entries of nuggit commands executed will be shown.  Otherwise, any additional records, for example of git commands logged by nuggit actions, will also be shown.

=back

=head1 TODO

- Support for clearing log by date or number of (prime) entries.
- Support for filtering log by date or limiting number of entries
- Less-like functionality?
- Support for disabling colorization (ie: --no-color => $ENV{ANSI_COLORS_DISABLED}=1 ?
- file option to allow parsing of specified log file. Bypasses is-a-nuggit check, not compatible with clear flag
- Option to export filtered log selection to a file (filtered by date only) for easy sharing
- Replay option?

=cut
