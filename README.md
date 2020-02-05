# Nuggit

Nuggit is a wrapper for git that makes repositories consisting of submodules (or nested submodules) 
work more like mono-repositories.  This is, in part, achieved by doing work on the same branch across
all submodules and taking the approproate action when submodules are modified, added, pushed, pulled
etc. without requring the user to do extra magic just for submodules.

A wrapper script. "ngt" can be used to invoke all of the capabilities
defined below.  Tab auto-completion is optionally available for this wrapper.

The nuggit.sh or nuggit.csh shell should be sourced to add nuggit to
your path for bash or csh respectively.  These files can be used as an
example if needed to adopt for other shell environments.  

Usage information for most scripts is available with a "--man" or
"--help"  parameter.  For example, "ngt --man" or "ngt status --man".

### Point of Contact
Contact Chris Monaco (chris.monaco@jhuapl.edu) or David Edell (david.edell@jhuapl.edu) for more information


## Installation
Several installation options are documented below for convenience.

Minimum requirements for Nuggit are:
- Command-line Git tools, version 2.13.2 or later.  For best results, 
- Perl version 5.10 or later

### Automated (not yet available)
TODO: A Makefile.PL will be added in the future to enable standard
Perl installation.

### Manual via CPAN
Install Perl module dependencies using CPAN, or CPANM.  CPANM can be installed and run without root
privileges on most systems (see below)

For run-time dependencies, "sudo cpan IPC::Run3" or "cpanm IPC::Run3".
Additional dependencies are required for running the test suite.  See
the test directory for details.

Source the appropriate shell script in your profile to add Nuggit to
your path and enable auto-completion of commands (ie: "ngt status").
Scripts are provided for bash and cshell.

#### Optional: CPANM Setup
The following commands will install cpanm and all required dependencies locally.  This may take a few minutes if none are already installed.  Running cpanm as root will install packages globally.
- curl -L https://cpanmin.us/ -o cpanm && chmod +x cpanm
- ./cpanm JSON Term::ReadKey DateTime Git::Repository HTTP::Request LWP::UserAgent
- ./cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

### Manual
No non-standard modules requiring compialtion are utilized by this
suite permitting an alternative manual installation process if
required.

The following procedure is not recommended unless nominal installation
ethods are unavailable.

- Obtain this repository (ie: git clone ...)
- Download the IPC::Run3 library.
- Copy the IPC-Run/lib/IPC directory into this repository's 'lib'
directory.
- Add the bin folder to your path (ie: source the provided
nuggit.[c]sh script)

    
# Nuggit Commands:

NOTICE: The listing below may not be up to date or may be incomplete.
Details are available for most commands by running "--help"
(abbreviated) or "--man" (full).

Commands can be run with their full names as shown below, or through
the nuggit wrapper as described above.

### nuggit add
- Add the specified files to the staging area
- example
  - `nuggit add ./fsw_core/apps/appx/file.c`
- nuggit add command utilizes the "nuggit_log.txt".  Each file that is "added" to the staging area
using "nuggit add" will result in a nuggit log entry.  See "nuggit log"

### nuggit branch
- View the branches that exist and display if the same branch is checked out across all
submodules or if there is a branch discrepancy
- example
  - `nuggit branch`

### nuggit_branch_delete_merged.pl
- delete a specified branch that has already been merged.   Delete it in the local repository
and delete it in the remote repository
- Command sytax:
  - `nuggit_branch_delete_merged.pl <branch to delete>`
- example
  - `nuggit_branch_delete_merged.pl JIRA-XYZ`
- TO DO - fold this into another nuggut commmand, i.e. `nuggit branch -d <branch name>`



### nuggit clone
- clone a repositoy 
  - i.e. 
    - `nuggit clone ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git`
- unlike with git, nuggit clone will populate all submodules

### nuggit init
- Install the nuggit data structure to a preexisting repository.  If the repo was cloned
using the native git clone you will need to "nuggit  init" in the root folder of the 
git repository
        

### nuggit checkout
- checkout a branch.  There are some variations described here:
  - `nuggit_checkout.pl <branch_name>`
    - checkout a branch that already exists OR
    - checkout a branch that was created remotely and has not previously been locally checked out.
    - this will create this branch locally in all submodules and check that branch out in the
      root repository and all submodules
    - NOTE that if changes were pushed to this branch in a submodule using git directly (not using nuggit)
      AND the parent reposities were not updated to point to the new submodule commits, this checkout command
      will result a repository that reports local changes.
  - nuggit_checkout.pl -b <branch_name>
    - create a brand new branch and check it out in the root repository and all nested submodules
  - `nuggit_checkout.pl <branch> --follow-commit`


### nuggit_diff.pl
- get the differences between the working directory and the repository (of the entire nuggit repository)
- get the differences between the working copy of a file and the file in the repository
- get the differences between the working copy of a directory (or submodule) and the same in the repository
- (to do) get the differences between two branches
- usage:
  - one argument: file with relative path from current directory (as displayed by nuggit status)
    - i.e.
      - `nuggit_diff.pl ../../../path/to/file.c`
  - one argument: a directory (or submodules directory) with relative path (as displayed by nuggit status)
    - i.e.
      - `nuggit_diff.pl ../../../path/to/dir`
  - two arguments: two branches (not yet supported)
    - i.e.
      - `nuggit_diff.pl origin/branch branch`
        
        
### nuggit_rev_list.pl
- show the differences in between the origin branch and the local branch.  If there are non-zero
numbers in both columns, the repository needs to be merged.
- i.e.

                bash-4.2$ nuggit_rev_list.pl 
                Root
                diff between remote and local for branch jira-401
                origin  local
                commits commits
                |       |
                0       1
                Entering 'fsw_core'
                0       3
                Entering 'fsw_core/apps/appx'
                1       4
                Entering 'fsw_core/apps/appy'
                0       0
        
### nuggit_fetch.pl
-fetches everything in the root and submodules recursively.
- "git fetch": downloads commits, files, and refs from a remote repository to your local repository. 
- Fetching is what you do when you want to see what everyone else has been working on.
        
### nuggit_pull.pl
- pull the checked out branch from origin for the root repository.  Then foreach
submodule pull from origin.
- Any local, uncommitted changes will trigger a warning and will prevent git from completing
the pull
        
### nuggit_status.pl
- two variations: 
- `nuggit_status.pl`
  - for each submodule show the status 
- `nuggit_status.pl --cached`
  - show the changes that were added to the staging area that will be committed on the next nuggit commit
- the output will show the relative path of each file that has a status.  The 
relative path is relative to the nuggit root repository.  This is so the file path and name
can be copied and pasted into the command line of the nuggit_add.pl command
        
### nuggit_commit.pl
- commit all the files that have been added to the staging area across all of the
repositores (root and nested submodules) into the checked out branch
- example
  - `nuggit_commit.pl -m "required commit message goes here"`
- nuggit_commit.pl utilizes the "nuggit_log.txt".  Each nuggit_commit issued by the user
and each underying commit performed by nuggit_commit.pl will result in a nuggit log entry
        
### nuggit_push.pl
- identifies the checked out branch at the root repository and pushes the local
branch from the local repository to the origin for each nested submodule recursively
             
### nuggit_merge.pl
- merge the specified branch into the currently checked out branch in the root repository
and all nested submodules
- TO DO - NOT FINISHED.
- example
  - `nuggit_merge.pl <branch_name> -m "commit message"`
  - TO DO - RIGHT NOW THE COMMIT MESSAGE IS NOT HONORED.
        
### nuggit_merge_default.pl
- merge the default branch into the working branch recursively
- no arguments provided.
- this script will identify the default branch for the root repo and the
submodules individually
- this is intended to be done before pushing changes prior to merging the
working branch back into the default branch.

### nuggit_relink_submodules.pl
- This is to be used to correct when the submodule linkages get updated outside
of nuggit or to address other potentially inconsistencies.
        
### nuggit_log.pl
- usage:
  - Show the entire nuggit log (located at the root of the repository in .nuggit/nuggit_log.txt)
    - `nuggit_log.pl`
    - or
    - `nuggit_log.pl --show-all`
  - show N lines of the nuggit log
    - `nuggit_log.pl --show <n>`
  - clear the nuggit log in your repository (sandbox)
    - `nuggit_log.pl -c`


       
# Internal

### nuggit_checkout_default.pl
- this will recursively checkout the default branch, starting in the root repo and recursing
down into each submodule.  Note that the default branch of a submodule may be different from
the default branch of the root repo.  The default branch in one submodule may be different 
from the default branch in another submodule.                  
