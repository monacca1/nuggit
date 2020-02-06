#!/usr/bin/env perl
our $VERSION = 0.01;
# TIP: To format documentation in the command line, run "perldoc nuggit.pm"

use v5.10;
use strict;
use warnings;
use Cwd qw(getcwd);
use Term::ANSIColor;

# TODO: This should become an Object where:
# - constructor finds root dir and relative path
# - constructor dies if not a nuggit (not called for clone or init)
# - allow configuration of defaults/settings.  Persistent settings, if used, can be read from .nuggit directory


=head1 Nuggit Library

This library provides common utility functions for interacting with repositories using Nuggit.

=head1 Methods

=cut

=head2 get_submodules()

Return an array of all submodules from current (or specified) directory and below listed depth-first.

NOTE: Direct usage of submodule_foreach() is preferred when possible.

=cut

sub get_submodules {
    my $dir = shift;
    my $old_dir = getcwd();
    chdir($dir) if defined($dir);
    my @modules;
    submodule_foreach(sub {
                          push(@modules, shift .'/'. shift );
                      });
    chdir($old_dir) if defined($dir);

    return \@modules;
}


=head2 submodule_foreach(fn)

Recurse into each submodule and execute the given command. This is roughly equivalent to "git submodule foreach"

Parameters:

=over

=item fn

Callback function to be called foreach submodule found.  CWD will be at root of current submodule.

Callback will always be called starting from the deepest submodule.

Function will be called with

-parent Relative path from root to parent
-name   Name of submodule.  $name/$parent is full path from root
-status If modified, '+' or '-' as reported by Git
-hash   Commit SHA1
-label  Matching Branch/Tag as reported by Git (?)


=over 20

=item parent Relative path from root to parent

=item name   Name of submodule.  $name/$parent is full path from root

=item status If modified, '+' or '-' as reported by Git

=item hash   Commit SHA1

=item label  Matching Branch/Tag as reported by Git (?)

=back


=item opts

Hash containing list of user options.  Currently supported options are:

=over

=item recursive If false, do not recurse into nested submodules

=item FUTURE: Option may include a check if .gitmodules matches list reported by git submodule

=back

=item parent

Path of Parent Directory. In each recursion, the submodule name will be appended.

=back

=cut

sub submodule_foreach {
  my $fn = shift;
  my $opts = shift;
  my $parent = shift || ".";
  my $cwd = getcwd();

  if (!-e '.gitmodules')
  {
      return; # early if there are no submodules (for faster execution)
  }
  my $list = `git submodule`;

  # TODO: Consider switching to IPC::Run3 to check for stderr for better error handling
  if (!$list || $list eq "") {
    return;
  }

  my @modules = split(/\n/, $list);
  while(my $submodule = shift(@modules))
  {
      my $status = substr($submodule, 0,1);
      $status = 0 if ($status eq ' ');
      
      my @words = split(/\s+/, substr($submodule, 1));
      
      my $hash   = $words[0];
      my $name = $words[1];
      my $label;
      $label = substr($words[2], 1, -1) if defined($words[2]); # Label may not always exist

      # Enter submodule
      chdir($name) || die "submodule_foreach can't enter $name";

      # Pre-traversal callback (breadth-first)
      if (defined($opts) && defined($opts->{breadth_first_fn}) ) {
          $opts->{breadth_first_fn}->($parent, $name, $status, $hash, $label, $opts);
      }


      # Recurse
      if (!$opts || !defined($opts->{recursive}) || (defined($opts->{recursive}) && $opts->{recursive})) {
          submodule_foreach($fn, $opts, $name);
      }

      # Callback (depth-first)
      $fn->($parent, $name, $status, $hash, $label, $opts) if $fn;

      # Reset Dir
      chdir($cwd);
    
  }
  
}

=head2 find_root_dir

Returns the root directory of the nuggit, or undef if not found
Also navigate to the nuggit root directory

=cut

# note a side effect is that this will change to the nuggit root directory
# consider returning to the cwd and making the caller chdir to the root
# dir if desired.
sub find_root_dir
{
    my $cwd = getcwd();
    my $nuggit_root;
    my $path = "";

    my $max_depth = 10;
    my $i = 0;

    for($i = 0; $i < $max_depth; $i = $i+1)
    {
        # .nuggit must exist inside a git repo
        if(-e ".nuggit" && -e ".git") 
        {
            $nuggit_root = getcwd();
            #     print "starting path was $cwd\n";
            #     print ".nuggit exists at $nuggit_root\n";
            $path = "./" unless $path;
            chdir($cwd);
            return ($nuggit_root, $path);
        }
        chdir "../";
        $path = "../".$path;
  
        #  $cwd = getcwd();
        #  print "$i, $max_depth - cwd = " . $cwd . "\n";
  
    }
    chdir($cwd);
    return undef;
}

=head1 nuggit_init

Initialize Nuggit Repository by creating a .nuggit file at current location.

=cut

sub nuggit_init
{
    die("nuggit_init() must be run from the top level of a git repository") unless -e ".git";
    mkdir(".nuggit");

    # Git .git dir (this handles non-standard directories, including bare repos and submodules)
    my $git_dir = `git rev-parse --git-dir`;
    chomp($git_dir);

    system("echo \".nuggit\" >> $git_dir/info/exclude");

}

=head2 get_remote_tracking_branch

Get the name of the default branch used for pushes/pulls for this repository.

NOTE: This function may serve as the basis for an improved get_selected_branch() function that retrieves additional information.

=cut

sub get_remote_tracking_branch
{
    my $data = `git branch -vv`;
    my @lines = split(/\n/,$data);
    foreach my $line (@lines) {
        if ($line =~ /^\*\s/) {
            # This line is the current branch
            if ($line =~ /\'([\w\-\_\/]+)\'$/) {
                return $1;
            } else {
                say "No branch matched from $line";
                return undef; # No remote tracking branch defined
            }
        }
    }
    die "Internal ERROR: get_remote_tracking_branch() couldn't identify current branch"; # shouldn't happen
}

=head2 get_selected_branch_here

?

=cut

sub get_selected_branch_here()
{
  my $branches;
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  # execute git branch
  $branches = `git branch`;

  $selected_branch = get_selected_branch($branches);
}




=head2 get_selected_branch

 get the checked out branch from the list of branches
 The input is the output of git branch (list of branches)

=cut

sub get_selected_branch($)
{
  my $root_repo_branches = $_[0];
  my $selected_branch;

  $selected_branch = $root_repo_branches;
  $selected_branch =~ m/\*.*/;
  $selected_branch = $&;
  $selected_branch =~ s/\* //;  
  
  return $selected_branch;
}

=head2 do_upcurse

Find the top-level of this project and chdir into it.  If not a nuggit project, 'die'

Returns root_dir since this is often needed by callers. (FUTURE: This should be an OOP method, in which case this return value would be deprecated in favor of class variable)

=cut

sub do_upcurse
{
    my $verbose = shift;
    
    my ($root_dir, $relative_path_to_root) = find_root_dir();
    die("Not a nuggit!\n") unless $root_dir;

    print "nuggit root dir is: $root_dir\n" if $verbose;
    print "nuggit cwd is ".getcwd()."\n" if $verbose;
    print "nuggit relative_path_to_root is ".$relative_path_to_root . "\n" if $verbose;
    
    #print "changing directory to root: $root_dir\n";
    chdir $root_dir;
    return $root_dir;
}

=head2 git_submodule_status

DEPRECATED: Use Git::Nuggit::Status instead.  This function may be removed at any time.

Get status of Nuggit repository and return as a string.

NOTE: This API may be refactored in future to return a data structure to seperate display and backend logic.

Returns a status object (ref) containing:
- status - clean || modified   (Future updates may add untracked, refs-only, or other status words/flags)
- name   - Name of repository
- path   - Full path to root of this repository
- branch - Current branch
- raw     - Output from underlying git command(s) with minimal parsing to clarify paths
- children - An array of submodules, each of which is a status object of this type.

=cut

sub nuggit_status
{
  my $status;
  my $root_dir = getcwd(); # Caller should chdir() first if an alternate starting dir desired
  my $submodule_branch;
  my $status_cmd;
  my $status_cmd_mode = shift;
  my $untracked_mode = shift; # If true, ignore untracked files
  my $relative_path_to_root = shift; # TODO: This will be removed (handled in print fn instead) once status output is pre-parsed.

  # identify the checked out branch of root repo
  # execute git branch
  my $branches = `git branch`;
  my $root_repo_branch = get_selected_branch($branches);

  # Replace mode with Git::Repository::Status, and apply to output filtering only
  if ($status_cmd_mode eq "cached") 
  {
      $status_cmd = "git diff --name-only --cached";
  }
  elsif ($status_cmd_mode eq "unstaged")
  {
      $status_cmd = "git diff --name-only";
  }
  else 
  {
      $status_cmd = "git status --porcelain";
      $status_cmd .= " -uno" if $untracked_mode;
  }

  my $submodules = get_submodules();
  my $opts = {'status_cmd' => $status_cmd, 'status_cmd_mode' => $status_cmd_mode,
              'output' => {}, 'out_children' => {}};

  # Pass along relative path to root (this is a placeholder pending full parsing of status)
  $opts->{'relative_path_to_root'} = $relative_path_to_root if (defined($relative_path_to_root));

  $status = _nuggit_status($opts); # Get root status

  # Recurse into submodules
  submodule_foreach(\&_nuggit_status, $opts);

  # And cleanup parent<->child relations (since we parse status depth-first
  my $list = $opts->{'out_children'};
  foreach my $child (keys %$list) {
      my $parent = $opts->{output}{$child};
      if (defined($parent)) {
          $parent->{children} = $opts->{'out_children'}{$child};
      } else {
          die "Internal Error: $child is orphaned" unless $child eq '.';
      }
  }

  return $status;
} # end nuggit_status()

# Internal status function called by git_submodule_status().  See above for details.
sub _nuggit_status
{
    my $rtv;
    my ($parent, $name, $substatus, $hash, $label, $opts) = (@_);

    if (scalar(@_) > 4) {
        #my $subpath = $parent . '/' . $name .'/';
        my $subname = ($parent eq '.') ? "$name" : "$parent/$name";

        die("Internal Error: Duplicate repo at $subname") if defined($opts->{output}{$subname});
        $rtv = {
                'path' => $subname.'/',
                'name' => $name,
                'substatus' => $substatus, # Status of parent reference
                'sha1' => $hash, # VERIFY
                'label' => $label,
               };

        # Save reference to self 
        $opts->{output}{$subname} = $rtv;

        # And save as a child of $parent (to be added to children object later)
        $opts->{out_children}{$parent} = [] if !defined($opts->{out_children}{$parent});
        push(@{$opts->{out_children}{$parent}}, $rtv);

    } else {
        $opts = shift; # opts is sole-argument when called in this mode. Other args unneeded.
        $rtv = {
                'path' => './',
                'name' => $name,
               };
        $opts->{output}{'.'} = $rtv;
    }

    my $status;
    my $branches;
    my $submodule_branch;

    my $status_cmd = $opts->{'status_cmd'} || die("Internal Error: missing status_cmd");
    my $status_cmd_mode = $opts->{'status_cmd_mode'} || die("Internal Error: missing status_cmd_mode");

    $branches = `git branch`;
    $submodule_branch = get_selected_branch($branches);
    $rtv->{'branch'} = $submodule_branch;

    $status = `$status_cmd`;

    if($status ne "")
    {
        # Decode raw status
        $rtv->{'files'} = {};
        my @lines = split("\n", $status);

        foreach my $line (@lines) {
            if ($status_cmd_mode eq "status") {
                if ($line =~ /^\s+(\w+)\s+([\.\w\-\/]+)/) {
                    my $status = $1;
                    my $file = $2;
                    $rtv->{'files'}{$file} = $status;
                }
            } else {
                $line =~ s/^\s+|\s+$//g; # Trim any whitespace
                $rtv->{'files'}{$line} = ($status_cmd_mode eq "cached") ? 'S' : 'M';
            }
        }
        
        # add the repo path to the output from git that just shows the file
        # TODO: Replace original path conversion with parsing of status
        if (defined($opts->{'relative_path_to_root'})) {
            my $relative_path_to_root = $opts->{'relative_path_to_root'};
            my $subpath = $rtv->{'path'};
            $subpath = "" if $subpath eq "./"; # Hide useless ./

            if ($status_cmd_mode eq "status")
            {
                $status =~ s/^(...)/$1$relative_path_to_root$subpath/mg;
            } 
            else # cached or unstaged.  FIXME: S=staged, unstaged should be M or ?
            {
                $status =~ s/^(.)/S   $relative_path_to_root$subpath$1/mg;
            }
        }
        $rtv->{'raw'} = $status;
        $rtv->{'status'} = "modified"; # TODO: We can do better . . .

    }
    else
    {
        $rtv->{'status'} = 'clean';
    }

    # =============================================================================
    # to do - detect if there are any remote changes
    # with this workflow you should be keeping the remote branch up to date and 
    # fully consitent across all submodules
    # - show any commits on the remote that are not here.
    # =============================================================================
#    print "TO DO - SHOW ANY COMMITS ON THE REMOTE THAT ARE NOT HERE ??? or make this a seperate command?\n";
    return $rtv;
}

=head1 check_merge_conflict_state()

Checks if a merge operation is in progress, and dies if it is.

This function should be called with the path to the nuggit root repository or with that as the current working directory.

=cut

sub check_merge_conflict_state
{
    my $root_dir = shift || '.';
    if( -e "$root_dir/.nuggit/merge_conflict_state") {
        die "A merge is in progress.  Please complete with 'ngt merge --continue' or abort with 'ngt merge --abort' before proceeding.";
    }
}

# The following is an initial cut at an OOP interface.  The OOP interface is incomplete at this stage
#  and serves as a convenience wrapper for other commands, and Nuggit::Log
package Git::Nuggit;
use Git::Nuggit::Log;
use Cwd qw(getcwd);
use IPC::Run3;

sub new
{
    my ($class, %args) = @_;
    # This is a Singleton library, handled transparently for the user
    # Future: If a non-singleton use case arises, we can add a flag to bypass it below
    state $instance;
    if (defined($instance)) {
        # If previously initialized, do not re-initialize
        return $instance;
    }

    my ($root_dir, $relative_path_to_root) = main::find_root_dir(); # TODO: Move all functions into namespace & export
    $args{root} = $root_dir; # For Logger initialiation

    return undef unless $root_dir; # Caller is responsible for aborting if Nuggit is required
   
    # Create our object
    $instance = bless {
        logger => Git::Nuggit::Log->new(%args),
        root => $root_dir,
        relative_path_to_root => $relative_path_to_root,
        verbose => $args{verbose},
        # Command execution defaults (TODO: setters)
        run_die_on_error => 1,
        run_echo_always => defined($args{echo_always}) ? $args{echo_always} : 1,
        # level =>  (defined($args{level}) ? $args{level} : 0),
    }, $class;

    # Wrapper to conveniently allow root/file to be specified in constructor or start method
    #  Return self if successful, fail if parsing fails.
    return $instance;
}

sub root_dir
{
    my $self = shift;
    return $self->{root};
}

sub start
{
    my $self = shift;
    return $self->{logger}->start(@_);
}

sub logger {
    my $self = shift;
    return $self->{logger};
}

# Usage: my ($status, $stdout, $stderr) = run($cmd [,@args]);  # TODO: @args to be added later, for now single string expected
sub run {
    my $self = shift;
    # TODO: Support optional log level.  If set, the first argument will be numeric.
    my $cmd = shift;

    my ($stdout, $stderr);
    
    $self->{logger}->cmd($cmd);

    # Run it (wrap in an eval, since we don't want script to die automatically)
    # We use IPC::Run3 so we can reliably capture stdout + stderr (backticks only captures stdout)
    run3($cmd, undef, \$stdout, \$stderr);

    if ($self->{run_die_on_error} && $?) {
        say $stderr if $stderr;
        my ($package, $filename, $line) = caller;
        my $cwd = getcwd(); # TODO: Convert to relative path
        die("$cmd failed with $? at $package $filename:$line in $cwd");
    }

    if ($self->{run_echo_always}) {
        say $stdout if $stdout;
        say $stderr if $stderr;
    }

    
    return ($?, $stdout, $stderr);
}


1;
