#!/usr/bin/env perl
# PHASE TWO: Simple Scenarios

use strict;
use warnings;
use v5.10;
use Test::Most;
use Getopt::Long; # For Debug Flags
use FindBin;
use lib $FindBin::Bin; # Add local test lib to path
use lib "$FindBin::Bin/../lib"; # Add local test lib to path
use File::Slurp qw(edit_file_lines);

require "test.pm" ;
require Git::Nuggit; # For direct API testing, or usage of internal functions for validation

our $test_root = "/tmp/testrepo"; # WARNING: This directory may be deleted at the start of each test if pre-existing
our $verbose = 0; # 0 = off, 4=full
our $verbose_setup = 0; # Discrete Verbosity level for setup functions
my $skip_setup = 1;
our $do_cmdlog = 1; # Global Cmd Logger to aide debugging
our $do_fulllog = 1; # Save all stderr + stdout to logfile
my $list_only = 0; 
my $test_idx; # If defined, run only this test (idx from 1).

Getopt::Long::GetOptions
(
 "verbose=i" => \$verbose, # Output Verbosity Level, 0=off ... 4=full
 "setup-verbose=i" => \$verbose_setup, # Output Verbosity for Setup
 "root" => \$test_root, # Root directory to execute tests in (defaults to /tmp/testrepo)
 "skip-setup!" => \$skip_setup,  # Skip Setup if possible; Useful to speed up execution during debugging
 "test=i" => \$test_idx, # If specified, only execute this test
 # TODO: Allow this argument to be specified multiple times with differing values (=i@, and test_idx becomes array
 # TODO: skip-test
 # TODO: do/skip test by regex on name
 "list" => \$list_only, # List available tests only
);

die_on_fail; # Exit if any test fails.  Use SKIP on tests that we expect to fail


# Ensure $test_root is an absolute path
$test_root = File::Spec->rel2abs($test_root);
our $test_work = "$test_root/test";

# Explicitly Run Setup to Ensure a Clean Slate NOTE: This isn't
#  strictly necessary as dir should always be in a suitable state and
#  can typically be skipped to speed up execution (with -s flag)
setup() unless $skip_setup;


my @tests = (
             ["Simple Clone + Write" , \&simple_clone_write_tests], # Test 1
             ["Simple 2 User no-conflict test; User1 Writes, User2 Pulls", \&test_simple_2user],

             # 3
             ["Simple Conflict, Manual Resolution Required", \&test_simple_conflict],
             ["Non-conflicting Parallel Work in Discrete Submodules", \&test_2user_parallel_submodule],
             ["Non-conflicting Parallel Work in Same Submodule", \&test_2user_parallel_files_same_submodule],
             
             # TODO: nuggit_init Test from root level of repo, from no repo, and from submodule (may belong in 02-base.t)

             # Merge test, default branch
             # Merge test, specified branch
             # Merge test, default branch when default isn't always the same

            );

my $test_cnt = 0;

if ($test_idx) {
    die("Specified Test # ($test_idx) is invalid") if ($test_idx <= 0 || $test_idx > scalar(@tests));

    $test_idx--; # Convert to 0-indexed
    plan tests => 1;
    dotest($tests[$test_idx][0],$tests[$test_idx][1]);
    done_testing();
    exit;
} elsif ($list_only) { # TODO: Or filter options to be processed to calculate plan cnt
    foreach my $test (@tests) {
        my $key = @$test[0];
        my $fn = @$test[1];

        # TODO: Filter options?
        
        $test_cnt++;
        
        if ($list_only) {
            say "$test_cnt\t$key";
        }
    }
    if ($list_only) {
        plan tests => 0;
        done_testing();
        exit();
    }
} else {
    $test_cnt = scalar(@tests);
}

# In either case, set tests appropriately
plan tests => scalar $test_cnt;

# If run_specific, then run by name or idx
# Else runall
foreach my $test (@tests) {
    my $key = @$test[0];
    my $fn = @$test[1];

    # TODO: Filter options by name?
    
    dotest($key,$fn);
}


done_testing();

########################################
### Simple Scenario Tests ###
########################################

# Base Nuggit Clone Test
sub simple_clone_write_tests {
    plan tests => 4;

    # Perform a Simple Nuggit Clone, default target
    subtest("nuggit_clone", \&nuggit_setup_user);
 
    # Perform a Simple Nuggit Clone, specify dir name
    subtest("nuggit_clone user1", \&nuggit_setup_user, "user1");

    # Simple Write in nested submodule
    tchdir("$test_work/user1"); # Reuse user1 from prior test
    subtest('Simple Write Test in nested submodule',
            \&test_write, 
            ("First test_write()", "sub1/sub3/README.md", {check_modified => [qw(sub1 sub1/sub3)]})
           );

    return 1;
}

# Simple Test.  User 1 makes a change, User 2 pulls it.
sub test_simple_2user
{
    plan tests => 4;

    # Setup users
    subtest("Setup user1", \&nuggit_setup_user, "user1");
    subtest("Setup user2", \&nuggit_setup_user, "user2");

    my $msg = "TEST User1 Append";
    my $fn = "sub1/sub3/README.md";
    my @lines;
    
    subtest 'User 1 Appends to sub1/sub3/README.md' => sub {
        plan tests => 3;
        tchdir("$test_work/user1");
        subtest ("Simple Write",
                 \&test_write,
                 ($msg, "sub1/sub3/README.md", {check_modified => [qw(sub1 sub1/sub3)] } )
                  );
        ok( (@lines = read_file($fn, chomp => 1))[-1] eq $msg, "sub3/README ends with expected line");
    };
    subtest 'User 2 Can Pull Change' => sub {
        plan tests => 4;
        tchdir("$test_work/user2");
        ok( (@lines = read_file($fn, chomp => 1))[-1] ne $msg, "sub3/README does NOT yet end with expected line");
        ok( nuggit("pull"), "Pull Changes");
        ok( (@lines = read_file($fn, chomp => 1))[-1] eq $msg, "sub3/README ends with expected line");
    };
    
    return 1;
}

sub test_simple_conflict
{
    plan tests => 5;

    # Setup users
    subtest("Setup user1", \&nuggit_setup_user, "user1");
    subtest("Setup user2", \&nuggit_setup_user, "user2");
    my $msg = "TEST User1 Append";
    my $msg2 = "Independent User2 Append in discrete submodule";
    my $fn = "sub1/sub3/README.md";
    my @lines;
    
    subtest 'User 1 Appends to $fn' => sub {
        plan tests => 3;
        tchdir("$test_work/user1");
        subtest ("Simple Write",
                 \&test_write,
                 ($msg, $fn, {check_modified => [qw(sub1 sub1/sub3)] } )
                  );
        ok( (@lines = read_file($fn, chomp => 1))[-1] eq $msg, "$fn ends with expected lineA");
    };
    subtest 'User 2 Appends to $fn to create conflict' => sub {
        plan tests => 4;
        tchdir("$test_work/user2");
        ok( (@lines = read_file($fn, chomp => 1))[-1] ne $msg, "$fn does NOT yet end with expected lineA");

        subtest ("Write in second submodule, expect nuggit push failure",
                 \&test_write,
                 ($msg2, $fn, {check_modified => [qw(sub1 sub1/sub3)], push_fail => 1 } )
                  );
        
        dies_ok{ nuggit("pull") } "Pull Changes, expect conflicts requiring manual resolution";

    };
    subtest 'Manual Conflict resolution' => sub {
        plan tests => 5;

        # Edit file (remove any line starting with << == or >> for easy simulated resolution)
        edit_file_lines { $_ = '' if /^[=<>]+/ } $fn;

        # Add file to mark as resolved
        ok(nuggit("add",$fn), "Mark conflict as [manually] resolved");

        # Attempt to commit; this should fail as an invalid workflow
        dies_ok{
            nuggit("commit", "-m \"Commit with open conflict, nuggit should disallow this\"")
        } "Commit with open conflict should fail";

        # Complete merge (specify no-edit for test convenience)
        ok(nuggit("merge", "--continue --no-edit"));
               
        # Verify nuggit_status is clean
        my $status;
        lives_ok{$status = nuggit_status("status")};
        ok($status->{'status'} eq "clean", "Status is clean after commit");
    };
    
    return 1;


}

sub test_2user_parallel_submodule
{
    plan tests => 4;

    # Setup users
    subtest("Setup user1", \&nuggit_setup_user, "user1");
    subtest("Setup user2", \&nuggit_setup_user, "user2");

    my $msg = "TEST User1 Append (2user_parallel_submodule)";
    my $msg2 = "Independent User2 Append in discrete submodule (2user_parallel_submodule)";
    my $fn = "sub1/sub3/README.md";
    my $fn2 = "sub2/README.md";
    my @lines;
    
    subtest 'User 1 Appends to $fn' => sub {
        plan tests => 3;
        tchdir("$test_work/user1");
        subtest ("Simple Write",
                 \&test_write,
                 ($msg, $fn, {check_modified => [qw(sub1 sub1/sub3)] } )
                  );
        ok( (@lines = read_file($fn, chomp => 1))[-1] eq $msg, "$fn ends with expected lineA");
    };
    subtest 'User 2 Appends to $fn2' => sub {
        plan tests => 7;
        tchdir("$test_work/user2");
        ok( (@lines = read_file($fn, chomp => 1))[-1] ne $msg, "$fn does NOT yet end with expected lineA");

        subtest ("Write in second submodule, expect nuggit push failure",
                 \&test_write,
                 ($msg2, $fn2, {check_modified => [qw(sub2)], push_fail => 1 } )
                  );
        
        ok( nuggit("pull"), "Pull Changes, expect conflicts to be automatically resolved");

        # Verify file contents
        ok( (@lines = read_file($fn, chomp => 1))[-1] eq $msg, "sub1/sub3/README ends with expected line");
        ok( (@lines = read_file($fn2, chomp => 1))[-1] eq $msg2, "sub2/README ends with expected line");

        # Verify nuggit_status is clean
        ok(nuggit("status") !~ /&\s*$/, "Status is clean after commit");
    };
    
    return 1;
}

sub test_2user_parallel_files_same_submodule
{
    plan tests => 4;

    # Setup users
    subtest("Setup user1", \&nuggit_setup_user, "user1");
    subtest("Setup user2", \&nuggit_setup_user, "user2");

    my $msg = "TEST User1 Append to README";
    my $msg2 = "User2 Write new TEST file";
    my $fn = "sub1/sub3/README.md";
    my $fn2 = "sub1/sub3/TEST.md";
    my @lines;
    
    subtest "User 1 Appends to $fn" => sub {
        plan tests => 3;
        tchdir("$test_work/user1");
        subtest ("Simple Write",
                 \&test_write,
                 ($msg, $fn, {check_modified => [qw(sub1 sub1/sub3)] } )
                  );
        ok( (@lines = read_file($fn, chomp => 1))[-1] eq $msg, "$fn ends with expected lineA");
    };
    subtest "User 2 Appends to $fn2" => sub {
        plan tests => 12;
        tchdir("$test_work/user2");
        ok( (@lines = read_file($fn, chomp => 1))[-1] ne $msg, "$fn does NOT yet end with expected lineA");

        lives_ok {append_file($fn2, ($msg2."\n"))} "Write to new file $fn2";
        log_cmd("# Write \"$msg\" to $fn");
        ok(nuggit("add",$fn2), "Stage file");

        my $status = get_status();
        my $obj = file_status($status, $fn2);
        ok( $obj && $obj->{staged_status} == STATE('MODIFIED'), "Verify $fn2 is staged"); # || return;
        ok(nuggit("commit", "-m \"Update $fn2 file\""), "Commit $fn2"); # || return;

        dies_ok{ nuggit("push") } "Push should fail due to conflicts";

        ok( nuggit("pull", "--no-edit"), "Pull Changes, expect conflicts to be automatically resolved");

        # Verify file contents
        ok( (@lines = read_file($fn, chomp => 1))[-1] eq $msg, "sub1/sub3/README ends with expected line");
        ok( (@lines = read_file($fn2, chomp => 1))[-1] eq $msg2, "sub2/README ends with expected line");

        # Verify nuggit_status is clean
        my $status;
        lives_ok{$status = nuggit_status("status")};
        ok($status->{'status'} eq "clean", "Status is clean after commit");
    };
    
    return 1;
}

