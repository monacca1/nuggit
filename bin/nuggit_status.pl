#!/usr/bin/env perl

=head1 SYNOPSIS

Display submodule-aware status of project.

   nuggit status

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item -uno

Ignore untracked files

=item --ignored

Show ignored files

=item --json

Show raw status structure in JSON format.

=back

=cut

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Pod::Usage;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Data::Dumper; # Debug and --dump option
use Git::Nuggit;
use Git::Nuggit::Status;

# The following flags are currently DEPRECATED, but may be re-added in the future
my $cached_bool = 0; # If set, show only staged changes
my $unstaged_bool = 0; # If set, and cached not set, show only unstaged changes

my $verbose = 0;
my $do_dump = 0; # Output Dumper() of raw status (debug-only)
my $do_json = 0; # Outptu in JSON format
my $flags = {
             "uno" => 0, # If set, ignore untracked objects (git -uno command). This has no effect on cached or unstaged modes (which always ignore untracked files)
             "ignored" => 0, # If set, show ignored files
             "all" => 0, # If set, show all submodules (even if status is clean)
            };
my $color_submodule = 'yellow';

my ($help, $man);
Getopt::Long::GetOptions(
    "help"            => \$help,
    "man"             => \$man,
                           "cached|staged"  => \$cached_bool, # Allow --cached or --staged
                           "unstaged"=> \$unstaged_bool,
                           "verbose!" => \$verbose,
                           "uno!" => \$flags->{uno},
                           "ignored!" => \$flags->{ignored},
                           'dump' => \$do_dump,
                         'json' => \$do_json,
                         'all|a!' => \$flags->{all},
     );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;


my $root_repo_branch;

my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;

print "nuggit root dir is: $root_dir\n" if $verbose;
print "nuggit cwd is ".getcwd()."\n" if $verbose;
print "nuggit relative_path_to_root is ".$relative_path_to_root . "\n" if $verbose;

# Optional: Query status only for specified path
my $argc = @ARGV;
if ($argc == 1) {
    $relative_path_to_root = $ARGV[0];
    say "Changing directory to specified $relative_path_to_root" if $verbose;
    chdir $relative_path_to_root || die "Can't enter directory $relative_path_to_root: $!";
} elsif ($argc == 0) {
    #print "changing directory to root: $root_dir\n" if $verbose;
    chdir $root_dir || die "Can't enter $root_dir";
} else {
    pod2usage( {
                -message => "Error: Only zero or one unnamed arguments supported. You provided $argc",
                -exitval => "1", # Return non-zero to indicate an error
               });
}

# Get Status with specified options
my $status = get_status($flags); # TODO: Flags for untracked? show all?

die("Unable to retrieve Nuggit repository status") unless defined($status);

say Dumper($status) if $do_dump;

if ($do_json) {
    require JSON;
    JSON->import();
    say encode_json($status);
}
else
{
    if (-e "$root_dir/.nuggit/merge_conflict_state") {
        say colored("Nuggit Merge in Progress.  Complete with \"ngt merge --resume\" or \"ngt merge --abort\"",'red');
    }
    pretty_print_status($status, $relative_path_to_root, $verbose);
    #say colored("Warning: Above output may not reflect if submodules are not initialized, on the wrong branch, or out of sync with upstream", $warnColor);
}







