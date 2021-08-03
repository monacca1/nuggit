#!/usr/bin/env perl

#*******************************************************************************
##                           COPYRIGHT NOTICE
##      (c) 2019 The Johns Hopkins University Applied Physics Laboratory
##                         All rights reserved.
##
##  Permission is hereby granted, free of charge, to any person obtaining a 
##  copy of this software and associated documentation files (the "Software"), 
##  to deal in the Software without restriction, including without limitation 
##  the rights to use, copy, modify, merge, publish, distribute, sublicense, 
##  and/or sell copies of the Software, and to permit persons to whom the 
##  Software is furnished to do so, subject to the following conditions:
## 
##     The above copyright notice and this permission notice shall be included 
##     in all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
##  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
##  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
##  DEALINGS IN THE SOFTWARE.
##
#*******************************************************************************/

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Pod::Usage;
use Cwd qw(getcwd);
use Term::ANSIColor;
use File::Spec;
use Git::Nuggit;
use JSON;
use Data::Dumper;

=head1 SYNOPSIS

List or create branches.

To create a branch, "ngt branch BRANCH_NAME"

To list branches, "ngt branch".  Note the output of "ngt status" with optional "-a" and "-d" flags will also display the currently checked out branches along with additional details.

To list all branches, "ngt branch -a"

To delete a branch, "ngt branch -d BRANCH_NAME".  See below for additional options.

NOTE: The "-r" syntax for deleting remote repositories in Nuggit differs from native git. In git this command requires specifying a branch in the form 'origin/branch' and only removes them locally.  Nuggit does not require the prefix, and removes them locally and remotely.

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item -d | --delete

Delete specified branch from the root repository, and all submodules, providing that said branch has been merged. 

Equivalent to "git branch -d", deleting the specified branch name only if it has been merged into HEAD.  This version will apply said change to all submodules.

=item -D | --delete-force

This flag forces deletion of the branch regardless of merged state. Usage is otherwise the same as -d above and mirrors "git branch -D"

=item -r | remote

Apply operation to the remote (server) branch.  

This flag currently applies only branch deletion operations, and is explicitly documented below as '-rd' and '-rD'.

Typical usage is: "ngt branch -rd branch" or "ngt branch -rD branch".

Note: Unlike the native git branch command, no 'origin' prefix is required here.

=item -rd

This will delete the specified branch from the remote origin for the root repository, and all submodules, providing that said branch has been merged into HEAD [as known to local system].  Precede this commmand with a "ngt fetch" to ensure local knowledge is up to date with the current state of the origin to improve accuracy of this check.

This check is meant to supplement server-side hooks/settings to help minimize user errors, but does not replace the utility of additional server-side checks.

=item -rD

Delete specified branch from the remote origin for the root repository, and all submodules, unconditionally.

=item --all | -a

List all known branches, not just those that exist locally.  Remote branches are typically prefixed with "remotes/origin/".  This is equivalent to the same option to "git branch".

=item --merged | --no-merged

Filter branch listing by merged or not merged state.  If neither option is specified, then all matching branches will be displayed.  This may be combined with the "-a" option, and is equivalent to the same option in "git branch".

NOTE: If the '--no-merged' option is specified, checks for submodule branches matching root will be skipped.

=item --orphans

List all orphaned branches.  An orphaned branch is one that exists in a submodule but not in the root repository. 

=item --orphan

This argument must specify a branch name and an additional flag.  If no other flags are provided indicating specific information about the orphan, this will show full details about the orphan branch.  Full details include, the count of repos where the specified branch exists, count of repos where specified branch is missing, gives a list of repos where specified branch is missing, gives a list of repos where specified branch exists.  When this flag is provided, the following specifics can be requested --missing-from or --exists-in, where information about which repos do not have this branch, or which repos do have this branch respectively.

=item --exists-in-all

The --exists-in-all flag may be provided an optional branch name.  If a branch name is provided, this will check if the specified branch exists in all submodules.  If no branch name is provided, this will output a list of branches that do exist in all submodules that are visibile from the currently checked out workspace/branch.

=back

=cut


# usage: 
#
# to view all branches just use:
# nuggit_branch.pl
#     This will also check to see if all submodules are on the same branch and warn you if there are any that are not.
#
# to create a branch
# nuggit_branch.pl <branch_name>
#
# to delete fully merged branch across all submodules
# nuggit_branch.pl -d <branch_name> 
#     TO DO - DO YOU NEED TO CHECK THAT ALL BRANCHES ARE MERGED ACROSS ALL SUBMODULES BEFORE DELETING ANY OF THE BRANCHES IN ANY SUBMODULES???????
#

sub ParseArgs();
sub is_branch_selected_throughout($);
sub create_new_branch($);
sub get_selected_branch_here();

sub get_branch_info();
sub list_orphans();
sub list_nuggit_branches();
sub orphan_branch_details();
sub orphan_branch_missing_from();
sub orphan_branch_exists_in();
sub orphan_branch_full_details();

my $ngt = Git::Nuggit->new() || die("Not a nuggit!");

my $cwd = getcwd();
my $root_repo_branches;
my $show_all_flag             = 0; # IF set, show all branches
my $create_branch             = 0;
my $delete_branch_flag        = 0;
my $delete_merged_flag        = 0;
my $delete_remote_flag        = 0;
my $delete_merged_remote_flag = 0;
my $show_merged_bool          = undef; # undef = default, true=merged-only, false=unmerged-only
my $orphans_flag              = 0;
my $exists_in_all_flag        = 0;
my $orphan_branch             = "";
my $exists_in_flag            = 0;
my $missing_from_flag         = 0;
my $verbose = 0;
my $show_json = 0;
my $selected_branch = undef;

# print "nuggit_branch.pl\n";

ParseArgs();
my $root_dir = $ngt->root_dir();

chdir $root_dir;

if($delete_branch_flag)
{
  $ngt->start(level=> 1, verbose => $verbose);
  say "Deleting merged branch across all submodules: " . $selected_branch;
  delete_branch($selected_branch);
} 
elsif ($delete_merged_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting branch across all submodules: " . $selected_branch;
    delete_merged_branch($selected_branch);
}
elsif ($delete_remote_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting branch from origin across all submodules: " . $selected_branch;
    delete_remote_branch($selected_branch);
}
elsif ($delete_merged_remote_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting merged branch from origin across all submodules: " . $selected_branch;
    delete_merged_remote_branch($selected_branch);
}
elsif($orphans_flag)
{
  list_orphans();
}
elsif($exists_in_all_flag)
{
   list_nuggit_branches();
}
elsif($orphan_branch ne "")
{
  if($exists_in_flag)
  {
    orphan_branch_exists_in();
  }
  elsif($missing_from_flag)
  {
    orphan_branch_missing_from();
  }
  else
  {
    orphan_branch_full_details();
  }
}
elsif (defined($selected_branch)) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    create_new_branch($selected_branch);
}
else
{
    $ngt->start(level=> 0, verbose => $verbose);
    if ($show_json) {
        verbose_display_branches();
    } else {
        display_branches();
    }
}

sub verbose_display_branches
{
    # TODO: This may will eventually replace display_branches below, with a new text-output added here
    # TODO: If user requests to check all submodules, call get_branches on all submodules
    #        and verify branch is consistent throughout (similar to below, but saving output for more display options)
    # Output would then be either:
    # - Text listing similar to current, but extend by noting branches for any submodule that differs
    # - JSON output
    #   - is_consistent: bool
    #   - branches: Root branches object
    #   - submodules: Object where key is submodule path and value is branch listing

    my $branches = get_branches({
        all => $show_all_flag,
        merged => $show_merged_bool,
       });
    say encode_json($branches);
}

sub display_branches
{
    my $flag = ($show_all_flag ? "-a" : "");
    if (defined($show_merged_bool)) 
    {
        if ($show_merged_bool) 
        {
            $flag .= " --merged";
        }
        else
        {
            $flag .= " --no-merged";
        }
    }

    $root_repo_branches = `git branch $flag`;
    $selected_branch    = get_selected_branch($root_repo_branches);
    
    # Note: If showing merged/no-merged, selected branch may be unknown
    say "Root repo is on branch: ".colored($selected_branch, 'bold') if $selected_branch;
    if ($root_repo_branches) 
    {
        print color('bold');
        print "All " if $show_all_flag;
        if (defined($show_merged_bool))
	{
            if ($show_merged_bool) 
	    {
                print "Merged ";
            }
	    else
	    {
                print "Unmerged ";
            }
        }
        say "Branches:";
        print color('reset');
        say $root_repo_branches;
    }

  # --------------------------------------------------------------------------------------
  # now check each submodule to see if it is on the selected branch
  # for any submodules that are not on the selected branch, display them
  # show the command to set each submodule to the same branch as root repo
  # --------------------------------------------------------------------------------------
  is_branch_selected_throughout($selected_branch) if $selected_branch;

}


sub ParseArgs()
{
    my ($help, $man, $remote_flag);
    Getopt::Long::Configure("no_ignore_case", "bundling");
    Getopt::Long::GetOptions(
        "delete|d!"         => \$delete_merged_flag,
        "delete-force|D!"   => \$delete_branch_flag,
        "remote|r"          => \$remote_flag,
        "merged!"           => \$show_merged_bool,
        "all|a!"            => \$show_all_flag,
        "verbose|v!"        => \$verbose,
        "json!"             => \$show_json, # For branch listing command only
        "help"              => \$help,
	"orphans"           => \$orphans_flag,        # list orphan branches
	"exists-in-all"     => \$exists_in_all_flag,  # get list of branches that exist in all submodules (that we have access to from the currently checked out branch)
	"orphan=s"          => \$orphan_branch,       # specifies the specific orphan branch name. 
	                                              # If this is provided, then additional flags may be provided
        "exists-in"         => \$exists_in_flag,      # when this and the orphan branch are passed in, this will list all the submodule repos where the branch exists
	"missing-from"      => \$missing_from_flag,   # when this and the orphan branch are passed in, this will list all the submodule repos where the branch does not exist.
        "man"               => \$man,
      ) || pod2usage(1);
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    if ($remote_flag) {
        if ($delete_branch_flag) { $delete_branch_flag = 0; $delete_remote_flag = 1; }
        if ($delete_merged_flag) { $delete_merged_flag = 0; $delete_merged_remote_flag = 1; }
    }
    die "Error: Please specify only one of '-d' or '-D' flags." if ($delete_branch_flag+$delete_remote_flag+$delete_merged_flag+$delete_merged_remote_flag) > 1;

    if ( ($delete_branch_flag + $delete_merged_flag + $delete_remote_flag + $delete_merged_remote_flag) > 1) {
        die "ERROR: Please specify only one version of delete flags (-d -D -rd -rD) at a time.";
    }

    # If a single argument is specified, then it is a branch name. Otherwise user is requesting a listing.
    if (@ARGV == 1) {
        $selected_branch = $ARGV[0];
    }
}

sub create_new_branch($)
{
    my $new_branch = shift;
    $ngt->run_die_on_error(0);
 
  # create a new branch everywhere but do not switch to it.
  say "Creating new branch $new_branch";
  $ngt->run("git branch $new_branch");
  submodule_foreach(sub {
      $ngt->run("git branch $new_branch");
                    });
}



# check all submodules to see if the branch exists
sub is_branch_selected_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  my $branch_consistent_throughout = 1;
  my $cnt = 0;
  print "Checking submodule status . . . ";

  submodule_foreach(sub {
      my $subname = File::Spec->catdir(shift, shift);
      
      my $active_branch = get_selected_branch_here();
         
      if ($active_branch ne $branch) {
          say colored("$subname is not on selected branch", 'bold red');
          say "\t Currently on branch $active_branch";
          $cnt++;
                    
          $branch_consistent_throughout = 0;
      }
                    });

  if($branch_consistent_throughout == 1)
  {
      say "All submodules are are the same branch";
  } else {
      say "$cnt submodules are not on the same branch.";
      say "If this is not desired, and no commits have been made to erroneous branches, please resolve with 'ngt checkout $branch'.";
      say "If changes have been erroneously made to the wrong branch, manual resolution may be required in the indicated submodules to merge branches to preserve the desired state.";
  }
  
  return $branch_consistent_throughout;
}

# Delete a branch only if it is merged at all levels
sub delete_merged_branch
{
    my $branch = shift;
    if (check_branch_merged_all($branch)) {
        delete_branch($branch, "-D");
    } else {
        die "This branch is not known, or has not been merged into HEAD.  Use '-D' to force deletion anyway.";
    }
}

# Base function to (unconditionally) delete a local branch, failing on first error
sub delete_branch
{
  my $branch = shift;
  my $flag = shift || "-d";

  my $cmd = "git branch $flag $branch";

  # Don't use native git submodule foreach, as it's error handling (aborting) is inconsistent
  $ngt->run_foreach($cmd);
}

# Delete a remote branch (unconditionally)
sub delete_remote_branch
{
    my $branch = shift;
    $ngt->run_foreach("git push origin --delete $branch");
}

# Delete Remote branch, only if it is merged at all levels
sub delete_merged_remote_branch
{
    my $branch = shift;

    if (check_branch_merged_all($branch, "origin")) {
        delete_remote_branch($branch); 
    } else {
        say "This branch is not known locally, or has not been merged into HEAD.  Use '-rD' to force deletion any<way.  It may not be possible to recover branches that have been deleted remotely.";
    }
}

# TODO: Make this an option to call directly, ie: ngt branch -a --merged ? Or ngt branch --check-merged $branch
# TODO: TEST
sub check_branch_merged_all
{
    my $branch = shift;
    my $remote = shift;
    my $status = 1; # Consider it successful, unless we find a branch that is not merged

    # TODO: Replace remotes with origin for local detection?
    my $check_cmd = "git branch -a --merged | grep $branch";
    
    $ngt->foreach( {'depth_first' => sub {
                           my $state = `$check_cmd`;
                           if (!$state) {
                               $status = 0;
                               say "Branch not merged/found at ".getcwd() if $verbose;
                           } else {
                               my @lines = split('\n', $state);
                               my $linefound = 0;
                               foreach my $line (@lines) {
                                   my ($lremote, $lbranch) = $line =~ /[\s\*]*(remotes\/(\w+)\/)?([\w\-\_\/]+)/;
                                   if ($lbranch && $lremote && $branch eq $lbranch && $remote eq $lremote) {
                                       # Match found
                                       #  Note: If $remote is undef, then we only match when corresponding match is as well.
                                       $linefound = 1;
                                   }
                               }
                               if (!$linefound) {
                                   $status = 0;
                                   say "Branch not merged/found at ".getcwd() if $verbose;
                               }
                           }
                       },
                    'run_root' => 1
                   }
                  );
    return $status;
}


# build and return a data structure
#   array [ 
#            { name = string
#              branch array = { 
#                    branch, 
#                    branch, 
#                    branch },
# 	     },
#            ...
#        ]
	  
sub get_branch_info()
{

  print "GETTING BRANCH INFO\n\n\n";
  my @nuggit_branch_info;

  $ngt->foreach({'run_root' => 1, 'breadth_first' => sub {
                   my %branch_info;
                   my $info = shift;
                   my $parent = $info->{'parent'};
                   my $name = $info->{'name'};
		   if($name eq "")
		   {
		     $name = "Nuggit Root";
		   }
                   my $branches_string = `git branch`;
		   
		   $branch_info{'name'} = $name;
	   
		   # convert the branches string into a branches array
		   my @branch_array = split("\n", $branches_string,);
		   
		   # remove the "*" for the selected branch
		   foreach(@branch_array)
		   {
		     $_ =~ s/\*//;
		     $_ =~ s/^\s+//; 
		   }
		   
		   $branch_info{'branches_array'} = \@branch_array;
		   
		   push(@nuggit_branch_info, \%branch_info);

                }});
		   
#  print Dumper(\@nuggit_branch_info);

  return @nuggit_branch_info;

}


sub list_orphans()
{
  # this should list all branches in any repo where the particular branch does not also exist in the root repo.

  # get the list of root repo branches
  
  # for each submodule, get the list of all branches and only display the branches that do not exist in the parent. 

  my @nuggit_branch_info = get_branch_info();

  print Dumper(\@nuggit_branch_info);

  # algorithm... find the root repo
  # for each repo that is not the root repo
  #    for each branch listed in the submodule... check if the branch is in the root repo
  #        if the branch is not in the root repo, it is an orphan branch

  # alternative algorithm..
  #  for each repo
  #     for each branch
  #        check if the branch is in every other repo.  if not it is an orphan branch

  foreach my $info (@nuggit_branch_info) 
  {
     print "Repo Name " . $info->{'name'}  . " \n";
     print "branches array: " . $info->{'branches_array'} . "\n";
     
     my $tmp = $info->{'branches_array'};

     print "printing tmp via dumper: \n";
     print Dumper($tmp);
     
     # test printing one individual element
     print "printing directly: $tmp->[0]\n";  
     
     
     # construct temporary array so we can walk through the items with the foreach loop
     my @foo = @{ $tmp };
     foreach(@foo)
     {
       print "branch:  " . $_ ."\n";
     }
     
     
#     print "printing array len: ", scalar @tmp, "\n";
     
#     print "\@tmp: ". $tmp[0]  . "\n";
     
#     foreach my $branch (@tmp)
#     {
#       print "branch:    " . $branch . "\n";
#     }
  }

  if($show_json)
  {
     # output for machine
     print "to do - get orphan info\n";
   
     print "show json?: $show_json \n";
  }
  else # output for human
  {
    print "to do - get a list of branches that exist in all submodules\n";
  }
  
}

sub list_nuggit_branches()
{
  # this will display a list of branches that are in good standing and exist in all submodule repositories
  # Note, the existence of a submodule may depend on what branch you have checked out.  So it will not 
  # be possible to check the status of a branch in submodules that do not exist in the currently checked out
  # branch
  if(defined($selected_branch))
  {
     print "Check if specified branch is in good standing\n";
     print "branch to check = " . $selected_branch . "\n";
  }  
  else
  {
    print "List all branches that exist in all repos\n";
    
    if($show_json)
    {
      # output for machine
      print "to do - output json info showing a list of branches that are in good standing and exist everywhere\n"
    }
    else # output for human
    {
      print "to do - get a list of branches that exist in all submodules\n";
    }    
    
  }
  


}

sub orphan_branch_full_details()
{
  # show full details
    
  if($show_json)
  {
     # output for machine
     print "to do - get branch full details\n";
   
     print "show json?: $show_json \n";
  }
  else # output for human
  {
    print "to do - show full orphan details about the specified branch ($orphan_branch)\n";
    print "show json?: $show_json \n";
  }

}

sub orphan_branch_missing_from()
{
  # show the information about the specified branch that includes which submodules do
  # not have this branch
    
  if($show_json)
  {
     # output for machine
     print "to do - get orphan 'missing-from' details in json form for branch $orphan_branch\n";
   
     print "show json?: $show_json \n";
  }
  else # output for human
  {
    print "to do - show orphan branch 'missing-from' details: ($orphan_branch)\n";
    print "show json?: $show_json \n";
  }
  
}

sub orphan_branch_exists_in()
{
  # show the information about the specified branch that includes which submodules 
  # have this branch

  if($show_json)
  {
     # output for machine
     print "to do - get orphan 'exists-in' details in json form for branch $orphan_branch\n";
   
     print "show json?: $show_json \n";
     
     print $orphan_branch ."-----\n";
     if(defined($orphan_branch))    ###### TO DO... this doesnt work... need to fix how we get this from GetOptions()
     {
       print "Checking for branch $orphan_branch\n";
     }
     
  }
  else # output for human
  {
    print "to do - show orphan branch 'exists-in' details: ($orphan_branch)\n";
    print "show json?: $show_json \n";

     if(defined($selected_branch))    ###### TO DO... this doesnt work... need to fix how we get this from GetOptions()
     {
       print "Checking for branch $selected_branch\n";
     }

  }

}
