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
Perl 
installation.

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
- Add the specified files to the staging area.  This can be done without regard to which submodule the files are located in.  nuggit
will figure it out based on the location of the file.  In other words, you do not need to switch directory into the submodule containing
the file in order to "add" it to the staging area for that submodule.  
- The output of the nuggit status command will shw the relative path of the files that you have changed.  The paths displayed are relative 
to the current working directory of the shell.  The paths to the files being added using nuggit add should be relative to the current 
working directory as well.  You can copy and paste the file/paths from the nuggit status command and use them in the nuggit add command.
- example
  - `nuggit add ./fsw_core/apps/appx/file.c`
- nuggit add command utilizes the "nuggit_log.txt".  Each file that is "added" to the staging area
using "nuggit add" will result in a nuggit log entry.  See "nuggit log"



### nuggit branch
- View the branches that exist and display if the same branch is checked out across all submodules (recursively) or if there is a 
branch discrepancy.  The nuggit workflow requires that the root repository and all nested submodules are on the same branch for 
development.  The default tracking branch is not required to be the same across all submodules but with the nuggit workflow, you 
do not perform development on the default tracking branch directly (i.e master).  Instead you develop on a branch and then merge 
to master on a remote collaboration server (i.e. bit bucket).
- You can be anywhere in the nuggit (git) repo to execute this command.
- example
  - `nuggit branch`



### nuggit_branch_delete_merged.pl
-This command will delete a specified branch that has already been merged. It will delete it in the local repository AND in the 
remote repository
- Since nuggit creates branches across all submodules to allow the relevant work to be performed in whichever submodule may need 
the work, it will result in the creation of the branch in submodules for which the work is not performed. After a branch is merged 
into the default tracking branch, this command can be used to delete the merged branches. This includes the repos where work was 
performed on that branch and it includes repos were no work was performed on that branch.
- You can be anywhere in the nuggit (git) repo to execute this command.
- Command sytax:
  - `nuggit_branch_delete_merged.pl <branch to delete>`
- example
  - `nuggit_branch_delete_merged.pl JIRA-XYZ`
- TO DO - fold this into another nuggut commmand, i.e. `nuggit branch -d <branch name>`
- TO DO - add verification to make sure that the branch has been merged in across all submodules.  In other words, make sure that there
are not commits that are not in common with master (?)  Do a pull of default and the branch in order to be sure that this is true 
on the remote too


### nuggit checkout
- nuggit checkout is analagous to git checkout, however, when checking out a branch, it will attempt to checkout the branch, 
not only in the base/root repository, but also recursively in the nested submodules.  Like the git command, you can use this 
create a new branch.  Nuggit checkout should be used to create or checkout development branches rather than using git directly.

- nuggit checkout can be used to checkout an existing branch, create a new branch, (to do) 
checkout a file or (to do) checkout a specific commit of the repository.
- checkout an existing branch
  - this could be a branch that exists locally or created up stream and does not yet exist locally
  - this will checkout the existing branch in all submodules and in the root repository.  It is assumed
that this branch was created using nuggit and thus exists in all submodules.
  - example
    - `nuggit checkout JIRA-XYZ`
  - NOTE that when checking out master, or whatever the default tracking branch is.  You should use `nuggit checkout --default` rather
  than trying to checkout master explicitly.  This is because each submodule may have its own "default tracking" branch that and it
  may not be called master.  The `--default` option is used to checkout the default tracking branch everywhere.  With this workflow 
  model you do not work on master, however, for your workflow it maybe appropriate to merge into master (default tracking branch) and 
  then push.
- create and checkout a new branch
  - this will create the branch in the root repository and in all submodules.
  - example:
    - `nuggit checkout -b JIRA-XYZ`
- checkout an explicit file
  - TO DO
  - This will revert local modifications so that the file matches the committed
  - a work around for this, while it has not yet been implemented is to use the `git checkout <file>` command in the same directory 
  as the file you would like to checkout / revert
- checkout a hash
   - TO DO
     - TO DO - this may need to use some of the logic implemented in: `nuggit_checkout.pl <branch> --follow-commit`

- NOTE that if changes were pushed to this branch in a submodule using git directly (not using nuggit)
AND the parent reposities were not updated to point to the new submodule commits, this checkout command
will result a repository that reports local changes.



#### Checkout Default
- Usually "master" is the default tracking branch, but not always.  And since each submodule can have its own default tracking branch, if
we want to checkout the default tracking branch we cannot specify a single explicit branch name to check out.
-"Checkout Default" is a concept which means to checkout the conceptual master branch rather than the explicit master branch.  In other 
words, this is to check out the default tracking branch for your project.  Checkout out of the default tracking branch is acheieved with 
the nuggit checkout command with the `--default` option. 
- `nuggit checkout --default` will identify the tracking branch of the root/base repository and check it out.  It will then do 
the same for each nested submodule recursively.  The result of this operation will be a repository where the root/base repository and 
each submodule is checked out the latest of the tracking branch.
- This operation should be done instead of checking out master.
- You can be anywhere in the nuggit (git) repo to execute this command.
- See the command `nuggit checkout` with the `--default` option



### nuggit clone
- Clone a repositoy 
- Cloning a repository containing one or more nested submodules with git requires additional steps or arguments to populate the submodules.
- Cloning a repository containing one or more nested submodules with nuggit is intended to be as simple as cloing a mono-repository with git.  
- nuggit will perform the additional steps required to fully populate each nested submodule.  
- nuggit clone will also initialize this git repository so that it can be used with the rest of the nuggit commands.  Specifically it adds a 
.nuggit in the repo root directory to hold nuggit information and data structures.
  - i.e. 
    - `nuggit clone ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git`
- you can also specify a folder name to contain the cloned repository
  - i.e.
    - `nuggit clone ssh://url-to.repo:7999/project/repo.git folder_name`



### nuggit commit
- Commit all of the files that have previously be added to the staging area.  See `nuggit add`.  The commit will occur in any 
submodule that has changes that have been added to the staging area.  The commit to the submodules will cause a commit to be 
needed in the parent directory of that submodule which nuggit will automatically perform.  In other words, for each submodule 
that has changes to be committed, the new/updated submodule will also be added and committed in the parent repository that 
directly contains that submodule.  This will be recursively performed up the directory structure up to the root/base repository.  
The nuggit commit may result in multiple commits if any submodule contained changes being committed.  In this case, each commit 
will have the same commit message as that provided by the user in the nuggit commit command.
- You can be anywhere in the nuggit (git) repo to execute this command.
- Command:
  - `nuggit commit`
- Example:
  - `nuggit commit -m "made changes to submodule X, Y and Z to fix bug for JIRA FSWSYS-1234"`



### nuggit diff
- Show the differences between the working directory and the repository (of the entire nuggit repository)
- Show the differences between the working copy of a file and the file in the repository
- Show the differences between the working copy of a directory (or submodule) and the same in the repository
- Show the differences between two branches (not yet supported)
- usage:
  - one argument: file with relative path from current directory (as displayed by nuggit status)
    - i.e.
      - `nuggit_diff ../../../path/to/file.c`
  - one argument: a directory (or submodules directory) with relative path (as displayed by nuggit status)
    - i.e.
      - `nuggit_diff ../../../path/to/dir`
  - two arguments: two branches (not yet supported)
    - i.e.
      - `nuggit_diff origin/branch branch`
     

        
### nuggit fetch
- fetches everything in the root and submodules recursively.
- "git fetch": downloads commits, files, and refs from a remote repository to your local repository. 
- Fetching is what you do when you want to see what everyone else has been working on.
- Note: nuggit pull is the same as nuggit fetch followed by nuggit merge

- Command:
  - `nuggit fetch`
- Example:
  - `nuggit fetch`



### nuggit init
- nuggit init will take an existing git repository and iniitialize it to be used with nuggit.  This action
occurrs automatically when cloning a repository using nuggit.  This is conceptually similar to git init where you 
are acting on a pre-existing directtory and initializing it as a git repository.  This should be done at the root 
level of the repository.  This will also install the .nuggit in the current directory (the root of the repo).  If the repo was cloned
using the native git clone you will need to `nuggit init` in the root folder of the git repository in order to use nuggit with
this repository. 
- Note the .nuggit is part of the gitignore so it will not be managed by git.
- Command:
  - `nuggit init`
-Example:
  - `nuggit init`
        

        
### nuggit log
- nuggit log keeps track of the significant events performed on this nuggit repository.  This is to help recall what was done and if necessary assist
in the git-fu that may be required to get out of a sticky situation.  
- For eample, the nuggit log will show the current branch, date/time, directory of files being added to the staging area using nuggit add.
It will show the branch, date/time, directory, commit message and which submodule references were also added and committed upoon a nuggit commit.
-Command:
  - `nuggit log`
- Example:
  - Show the entire nuggit log: `nuggit log`
  - Show he nuggit commands AND the git commands that were executed: `nuggit log -a`
  - Clear the nuggit log: `nuggit -c` or `nuggit -clear`
  
  
  
### nuggit merge
- Merge the specified branch into the currently checked out branch in the root repository and all nested submodules.  
- To merge one working branch into another working branch, or to merge the working branch into the default tracking branch (i.e. master), 
first check out the destination branch, then execute `nuggit merge <source branch name>`
- To merge a branch into the default tracking branch (i.e. master), check out the default tracking branch (`nuggit checkout --default`), 
then `nuggit merge <branch>`
- To merge master or default tracking branch into a working branch, first ensure that the intended destination branch is checked out (meaning
that it is the working branch).  Instead of explicitly merging master into the checked out branch we merge the default tracking branch
into the working branch.  The command to do this is `nuggit merge --default`.   It is a good idea to do this before trying to merge your working
branch into master (or default tracking branch). 
#### Handling merge conflicts
- if there is a merge conflict the output will indicate:
                `>nuggit merge --default
                No branch specified for merge, assuming default remote
                Source branch is: 
                Destination branch is the current branch: JIRA-BARNEY-1
                CONFLICT (content): Merge conflict in sm2.txt
                Merge aborted with conflicts.  Please resolve (stash or edit & stage) then run "nuggit_merge.pl --continue" to continue. at /project/sie/users/monacca1/nuggit_sandbox/bin/nuggit_merge.pl line 358.`





pull

push

rebase

relink

reset

stash

status

tag




       
### nuggit pull
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
        
    
### nuggit_push.pl
- identifies the checked out branch at the root repository and pushes the local
branch from the local repository to the origin for each nested submodule recursively
             




### nuggit_relink_submodules.pl
- This is to be used to correct when the submodule linkages get updated outside
of nuggit or to address other potentially inconsistencies.

       
# Internal

### nuggit_checkout_default.pl
- this will recursively checkout the default branch, starting in the root repo and recursing
down into each submodule.  Note that the default branch of a submodule may be different from
the default branch of the root repo.  The default branch in one submodule may be different 
from the default branch in another submodule.                  

   
        
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

