#!/usr/bin/env perl
# TIP: To format documentation in the command line, run "perldoc nuggit.pm"

use strict;
use warnings;
use Cwd qw(getcwd);

=head1 Nuggit Library

This library provides common utility functions for interacting with repositories using Nuggit.

This module is standalone and does not require any non-standard modules

=head1 Methods

=cut



=head2 submodule_foreach(fn)

Recurse into each submodule and execute the given command. This is roughly equivalent to "git submodule foreach"

Parameters:

=over

=item fn

Callback function to be called foreach submodule found.  CWD will be at root of current submodule.

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
  # TODO: Consider switchign to IPC::Run3 to check for stderr for better error handling
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
      #print "DEBUG: $hash, $name, $label, $status\n";
      # Enter submodule
      chdir($name);
      
      # Callback
      $fn->($parent, $name, $status, $hash, $label);
      
      if (!$opts || (exists($opts->{recursive}) && $opts->{recursive})) {
          submodule_foreach($fn, $opts, $name);
      }
      
      # Reset Dir
      chdir($cwd);
    
  }
  
}

=head2 find_root_dir

Returns the root directory of the nuggit, or undef if not found

=cut

sub find_root_dir
{
    my $cwd = getcwd();
    my $nuggit_root;

    my $max_depth = 10;
    my $i = 0;

    for($i = 0; $i < $max_depth; $i = $i+1)
    {
        if(-e ".nuggit") 
        {
            $nuggit_root = getcwd();
            #     print "starting path was $cwd\n";
            #     print ".nuggit exists at $nuggit_root\n";
            return $nuggit_root;
        }
        chdir "../";
  
        #  $cwd = getcwd();
        #  print "$i, $max_depth - cwd = " . $cwd . "\n";
  
    }

    return undef;
}

1;
