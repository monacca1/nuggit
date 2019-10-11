use v5.10; # Add support for 'say'

# Common Test Framework
#  NOTE: Functions provided depend on the following global variables set from main:
# - $test_root, $test_work, $verbose_setup
use File::Slurp qw(read_file write_file edit_file append_file);
use IPC::Run3;
use Term::ANSIColor;
use FindBin;
use Cwd;
use File::pushd; # Module to chdir, and automatically pop when function returns
use File::Spec;

# Get Path to Bin Directory
my $bin = $FindBin::Bin.'/../bin';
our $test_root;
our $test_work;
our $verbose;
our $verbose_setup;
our $cmdlog_fh;
our $fulllog_fh;
our $do_cmdlog;
our $do_fulllog;
my $cmd_color = 'green on_grey4';
my $stderr_color = 'red';

sub log_cmd {
    my $msg = shift;
    say colored($msg,$cmd_color) if $verbose;
    say $cmdlog_fh $msg if $cmdlog_fh;
    say $fulllog_fh colored($msg,$cmd_color) if $fulllog_fh;
}

##########################
# Common Test Components #
##########################

# Appends content to specified file, commits, and pushes (at all levels) with appropriate verifications
sub test_write {
    my $msg = shift || "test_write()";
    my $fn = shift || "sub1/sub3/README.md";
    my $opts = shift;
    $num_tests = 8;
    $num_tests += scalar(@{$opts->{check_modified}}) if ($opts && $opts->{check_modified});
    plan tests => $num_tests;

    # Update a file in nested sub3
    lives_ok {append_file($fn, ($msg."\n"))} "Write to file $fn";
    log_cmd("# Write \"$msg\" to $fn");

    # Verify Status
    my $status = nuggit("status");
    ok(  $status =~ /^\s*M.+$fn$/m, "Check file $fn Modified");

    if ($opts && $opts->{check_modified}) {
        # Assume a list of parent submodules given that should be modified at this point
        foreach my $dir (@{$opts->{check_modified}}) {
            ok(  $status =~ /^\s*M.+$dir$/m, "Check dir $dir Modified");
        }
    }
    
    # Stage sub3 Change
    ok(nuggit("add",$fn), "Stage submodule reference");
    ok(  nuggit("status", "--cached") =~ /^\s*S.+$fn$/m, "Verify $fn is staged");

    # Commit
    ok(nuggit("commit", "-m \"Update $fn file\""), "Commit $fn change");       

    # Verify Status
    my $status;
    lives_ok{$status = nuggit_status("status")} "Get Status";
    ok( ($status->{'status'} eq "clean"), "Status is clean after commit");

    # Push Changes
    if ($opts && $opts->{push_fail}) {
        dies_ok{nuggit("push")} "Push all changes, expect conflict";
    } else {
        ok(nuggit("push"), "Push all changes");
    }
   

    print ">>> test_write($msg,$fn) Complete\n" if $verbose;

    return 1;
}



############################
# TEST UTILITY FUNCTIONS ###
############################

# Create new Nuggit 'User' work area by cloning default root repo, unless alternate is specified.
#   Only minimal sanity checks ar eperformed during setup
sub nuggit_setup_user {
    plan tests => 13;
    
    my $path = shift; # path == user
    tchdir($test_work);

    if ($path) {
        lives_ok{nuggit("clone", "$test_work/root.git", $path)};
    } else {
        lives_ok{nuggit("clone", "$test_work/root.git")};
    }
    
    $path = "root" unless $path;
    ok(-d $path);
    tchdir($path);
    ok(-e ".nuggit", "Verify .nuggit exists after clone") or skip "Aborting test1, nuggit failed";
    ok(-d ".git");
    ok(-d "sub1");
    ok(-d "sub2");
    ok(-e "sub1/README.md", "sub1 README.md exists");
    ok(-d "sub1/sub3", "sub3 nested submodule");
    ok(-e "sub1/sub3/README.md");
    
    # Verify State is Clean
    ok( nuggit("checkout_default"), "Checkout of default branches"); # TODO: Consider folding this into clone

    my $status = nuggit("status");
    ok( ($status =~ /^\s*$/), "Status is clean after clone");

    return 1;
}

sub begin {
    if (!-d $test_root) {
        setup(); # Run First-Time Setup
    }
    chdir($test_root);

    if (!$cmdlog_fh && $do_cmdlog) {
        open( $cmdlog_fh, ">", "$FindBin::Script.cmd.log");
    }
    if (!$fulllog_fh && $do_fulllog) {
        open( $fulllog_fh, ">", "$FindBin::Script.full.log");
    }

    # If existing, delete it
    if (-d $test_work) {
        system("rm -rf $test_work");
    }

    # Restore it
    mkdir("test");
    run("cp -r *.git test/");
    chdir("test");
}
# Wrapper to subtest that calls a setup function before executing tests
#  Parameters are passed directly to subtest()
sub dotest {
    log_cmd("### dotest $_[0] ###");
    begin();
    subtest(@_);
    #end(); # Not needed at present
}

# Create Test Repo.  End Result is:
# $test_root/root.git, sub1.git, sub2.git, sub3.git
# sub1 + sub2 are submodules of root
# sub3 is a submodule of sub2, but sub1 is not pointing at head of sub2 that defines it.
sub setup {
    my $test_root = shift || $test_root;
    my $tmp_verbose = $verbose; $verbose = $verbose_setup;

    if (-d $test_root) {
        # Delete to start with a fresh directory
        log_cmd("# setup() removing old test directory $test_root");
        system("rm", "-rf", $test_root);
    }

    # Create Root Test Directory
    mkdir($test_root);

    # Create several test repos
    create_repo($test_root,"root");
    create_repo($test_root,"sub1");
    create_repo($test_root,"sub2");
    create_repo($test_root,"sub3");

    # Add Demo Submodules
    add_submodule($test_root,"root","sub1");
    add_submodule($test_root,"root","sub2");
    add_submodule($test_root,"root/sub1","sub3"); # only commits in sub1

    # Nested submodule requires an extra commit
    chdir("$test_root/root");
    run('git commit -am "Added Nested Submodule"');
    run("git push");
    $verbose = $tmp_verbose;
    log_cmd("# setup() restored $test_root to known state");
}

sub run { # Run a given command, or die if it fails
    my $cmd = shift;
    my $dir = shift;
    my $rtv;
    my $err;
    my $temp = pushd($dir) if $dir;

    log_cmd($cmd);
    say "\tcwd=".getcwd() if $verbose > 1;

    # NOTE: This only works if underlying command returns error code to bash -- Git does not always do so
    # Git will also output nominal status to stderr
    eval { run3($cmd, undef, \$rtv, \$err); };
    if ($fulllog_fh) {
        say $fulllog_fh $rtv;
        say $fulllog_fh colored($err,$stderr_color);
    }
    if    ( $@        ) { die "Error: $@";                       } # Internal Error
    elsif ( $? & 0x7F ) { die "Killed by signal ".( $? & 0x7F ); }
    elsif ( $? >> 8   ) { die "$cmd Exited with error ".( $? >> 8 )."\n $rtv \n $err";  }

    # Backtick Method: Does not capture stderr
    #my $rtv = `$cmd`;
    #die "$cmd Failed with Error $?\n" if $?;

    say $rtv if $verbose > 3;
    say colored($err,'red') if $verbose > 3; # Note: Git routinely writes to stderr

    return $rtv;
}

# Create a new repository at given path with some sample content
sub create_repo {
    my $root_path = shift;
    my $repo_name = shift;
    my $path = $root_path."/".$repo_name;

    mkdir($path) unless (-d $path);
    chdir($path);

    run("git init");
    write_file("README.md", "This is an initial test file.\nOriginal Repo at $path\n");
    run("git add README.md");
    run("git commit -am 'README.md'");

    # Create a 'bare' clone to serve as reference
    chdir($root_path);
    run("git clone --bare $path");

    # Set Remote (which will be created next)
    chdir($path);
    run("git remote add origin $path.git");
    run("git fetch");
    run("git branch -u origin/master master");
    
}

# Add a Submodule Reference to Sample Repo
sub add_submodule {
    my $root_path = shift;
    my $repo_name = shift;
    my $sub_name = shift;
    my $path = $root_path."/".$repo_name;
    my $sub_path = $root_path."/".$sub_name.".git";

    chdir($path);
    run("git submodule add $sub_path");
    edit_file { s/$root_path/\.\./g } "$path/.gitmodules";
    run("git commit -am 'Added submodule $sub_name'");
    run("git push"); 
}

# Wrapper to Run specified nuggit command and return output.
# Usage:  nuggit("status")  or nuggit("clone", "$url")
sub nuggit {
    my $cmd = shift;
    return run("$bin/nuggit_$cmd.pl ".join(" ", @_));
}

# Wrapper for chdir() in ok(), and with optional logging based on global verbose flag
sub tchdir {
    my $dir = shift;
    ok(chdir($dir));
    log_cmd("chdir($dir)");
}


1;
