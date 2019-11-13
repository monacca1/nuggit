#!/usr/bin/env perl

# TODO: Support for amend? May be better to skip this one.
# TODO: Option to prompt user before commit if unstaged changes exist?
# TODO: Option to launch default editor to define message

use strict;
use warnings;
use v5.10;
use Pod::Usage;
use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Status;
use Git::Nuggit::Log;
use IPC::Run3; # Utility to execute application and capture both stdout and stderr

# usage: 
#
# nuggit_commit.pl -m "commit message"
#

sub ParseArgs();
sub recursive_commit( $ );
sub staged_changes_exist_here();
sub nuggit_commit($);

my $verbose;

my $commit_message_string;
my $need_to_commit_at_root = 0;
my $branch_check = 1; # Check that all modified submodules are on the correct branch
my $root_repo_branch;
my $commit_all_files = 0; # Results in "git commit -a"

my ($root_dir, $relative_path_to_root) = find_root_dir();
my $log = Git::Nuggit::Log->new(root => $root_dir);

ParseArgs();

die("Not a nuggit!\n") unless $root_dir;
$log->start(verbose => $verbose, level => 1);

say "nuggit root dir is: $root_dir" if $verbose;
say "nuggit cwd is ".getcwd() if $verbose;
say $relative_path_to_root if $verbose;

say "changing directory to root: $root_dir" if $verbose;
chdir $root_dir;

check_merge_conflict_state(); # Do not proceed if merge in process; require user to commit via ngt merge --continue

my $status = get_status({uno => 1}); # Get status, ignoring untracked files

die "No changes to commit." if status_check($status);

if ($status->{'branch.head'}) {
    $root_repo_branch = $status->{'branch.head'};
    if ($root_repo_branch eq "(detached)" ) {
        die "ERROR: Root repository is in a detached head state";
    }
} else {
    die "ERROR: Unable to detect branch name.";
}

if ($branch_check) {
    if ($status->{'branch_status_flag'}) {
        pretty_print_status($status);
        die "One or more submodules are not on branch $root_repo_branch.  Please resolve, or (with caution) rerun with --no-branch-check to ignore.";
    }
}

my $total_commits = 0; # Number of commits made (root+submodules)
my $autostaged_refs = 0; # Number of submodule references automagically staged
my $prestaged_objs = 0; # Number of objects user has previously staged
my $untracked_objs = 0; # Reference count of untracked files not committed
my $unstaged_objs = 0; # Reference count of modified objects not staged/committed.
recursive_commit($status);

say "$autostaged_refs submodule references automatically committed" if $autostaged_refs > 0;
say "$untracked_objs untracked files exist in your work tree." if $untracked_objs > 0;

if (!$commit_all_files) {
    say "$prestaged_objs previously staged changes committed" if $prestaged_objs > 0;
    say "$unstaged_objs unstaged changes remaining in your work tree." if $unstaged_objs > 0;
}

sub recursive_commit( $ )
{
    my $status = shift;
    my $need_to_commit_here = 0;
    my $dir = getcwd();

    foreach my $child (keys %{$status->{objects}}) {
        my $sub = $status->{objects}->{$child};
        
        if ($sub->{is_submodule}) {
            chdir($sub->{path}) || die "Error: Unable to enter submodule $child";
            if (recursive_commit($sub)) {
                chdir($dir);
                # A commit was triggered in this submodule, so it will be auto-staged
                my ($errmsg, $stdout);
                my $cmd = "git add $child";
                run3($cmd, undef, \$stdout, \$errmsg);
                die "Error ($?): Unable to autostage $child in $dir:\n\n $stdout \n $errmsg" if $?;
                $log->cmd($cmd);
                
                $need_to_commit_here = 1;
                $autostaged_refs++;
            } else {
                # else user must stage manually, for example if a commit was made outside of nuggit
                chdir($dir); # pop dir for next iteration
            }

            # Handle manually staged submodule references
            if ($sub->{staged_status} > STATE('UNTRACKED')) {
                $need_to_commit_here = 1;
            }
        } elsif ($sub->{staged_status} > STATE('UNTRACKED')) {
            $need_to_commit_here = 1;
            $prestaged_objs++;
        } elsif ($sub->{status} == STATE('UNTRACKED')) {
            $untracked_objs++;
        } elsif ($sub->{status} > STATE('UNTRACKED')) {
            $unstaged_objs++;
            $need_to_commit_here = 1 if $commit_all_files;
        }
    }
    # If commit is required, make it
    if ($need_to_commit_here) {
        nuggit_commit($status->{path});
        $total_commits++;
        return 1;
    } else {
        return 0;
    }
}


sub ParseArgs()
{
    my ($help, $man);
    Getopt::Long::Configure("bundling"); # ie: enables -am
    Getopt::Long::GetOptions(
                           "message|m=s"  => \$commit_message_string,
                           "all|a!"           => \$commit_all_files,
                           "verbose!" => \$verbose,
                           "branch-check!" => \$branch_check,
                           "help"            => \$help,
                           "man"             => \$man,
                          );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    if (!defined($commit_message_string) ) {
        my $editor = `git config --get core.editor`;
        chomp($editor);
        my $file = "$root_dir/.nuggit/TMP_COMMIT_MSG";
        my $cmd = "$editor $file";
        system($cmd);

        die("Commit message is required") unless -e $file;

        open(my $fh, "<", $file) or die "Commit message is required";
        read $fh, $commit_message_string, -s $fh;
        close($fh);
        unlink($file); # And delete temporary file
    }

    my $size = length $commit_message_string;
    my $min_len = 4; # TODO: Make this configurable?
    if ($size < $min_len) {
        die("A useful commit message of at least $min_len characters is required: You specified \"$commit_message_string\"");
    }
}


sub nuggit_commit($)
{
   my $commit_status;
   my $repo = $_[0];

   my $args = "";
   $args .= "-a " if $commit_all_files;
   my ($stdout, $errmsg); # Git commit typically does not output to stderr
   my $cmd = "git commit $args -m \"N:$root_repo_branch; $commit_message_string\"";
   run3($cmd, undef, \$stdout, \$errmsg);
   $log->cmd($cmd);
   my $err = $?;

   say colored("Commit status in repo $repo:", 'green');
   say $stdout if $stdout;
   say $errmsg if $errmsg;
   
   if ($err) {
       die("Error detected ($err), aborting nuggit commit");
   }
}

sub run_cmd
{
    my $cmd = shift;
    my ($stdout, $stderr);
    run3($cmd, undef, \$stdout, \$stderr);
}


=head1 Nuggit commit

Commit files to the repository, using nuggit to automatically handle submodule boundaries and references.

=head1 SYNOPSIS

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item --message|m

Commit message.  Nuggit will automatically prepend the branch name.

=item --all|a

If set, commit all modified files.  

=item --no-branch-check

Bypass verification that all submodules are on the same branch.

=back

=cut

