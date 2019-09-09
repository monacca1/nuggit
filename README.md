# nuggit
(incomplete prototype status):

Nuggit is a wrapper for git that makes repositories consisting of submodules (or nested submodules) 
work more like mono-repositories.  This is, in part, achieved by doing work on the same branc across
all submodules and taking the approproate action when submodules are modified, added, pushed, pulled
etc. without requring the user to do extra magic just for submodules.

The following describes the nuggut prototype user scripts.  The goal would be to eventually have a single 
driver script "nuggit" that would identify the command and then call the approprate script.
        i.e. nuggit checkout would call nuggit_checkout.pl
Again, this is a prototype, the implementation of any of the individual scripts could probably be 
significantly improved from the perspecives of: design, error handling, git commands, documentation, etc

### TO DO

*** Handling of merging, in particular when merging to master 
  * In a mono-repo, when merging your working branch to master that operation is consistent
    throughout the mono-repository. Merging to master and pushing is also conceptually the same as 
    merging to the "remote tracking branch".  When working with submodules, the remote "tracking branch"
    for may not be the same across all submodules and the root repository.  It may not be appropriate to 
    merge to master across all submodules.
  * Maybe we need to abstract merging to master to be "merge with tracking branch" and the tool will
    automagically identify the tracking branch.
    
*** Addressing submodule inconsistences
  * If any submodules get inconsistent... meaning the parent repo is on branch X and is pointing to 
    a certain commit in a submodule that is also on branch X, but the submodule has additional commits on
    branch X, this is an inconsistency in the nuggit workflow.  Consider a "nuggit_check.pl" that will
    check for this occurance and maybe a "nuggit_fix.pl" (???) that will repoint the submodule references
    to the latest commit in each of the submodules for that working branch.

*** Add more logging.  
  * I've already added some logging by the nuggit_add.pl and nuggit_commit.pl which creates log entries
    into a file in the .nuggit/ directory called nuggit_log.txt
  * So far the nuggit_log.txt includes all the "git add" and "git commit" activities
  * consider adding logging to nuggit_push.pl, nuggit_pull.pl, nuggit_fetch.pl, nuggit_checkout.pl
  

    
#########################################################################################################

# nuggit prototype scripts:

### nuggit_env.sh 
- the nuggit scripts path needs to be added to your path.  You can either add the instance
of nuggit to your path using your .cshrc or you can use this nuggit_env.sh script.  To use
the nuggit_env.sh, you must navigate to the nuggit/bin directory, (be in the bash shell) and
"source nuggit_env.sh"

### nuggit_clone.pl
- clone a repositoy 
  - i.e. 
    - nuggit_clone.pl ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git

### nuggit_init
- Install the nuggit data structure to a preexisting repository.  If the repo was cloned
using the native git clone you will need to "nuggit_init" in the root folder of the 
git repository
        
### nuggit_branch.pl
- view the branches that exist and display if the same branch is checked out across all
submodules or if there is a branch discrepancy

### nuggit_checkout_default.pl
- this will recursively checkout the default branch, starting in the root repo and recursing
down into each submodule.  Note that the default branch of a submodule may be different from
the default branch of the root repo.  The default branch in one submodule may be different 
from the default branch in another submodule.

### nuggit_checkout.pl
- checkout a branch.  There are some variations described here:
  - nuggit_checkout.pl <branch_name>
    - checkout a branch that already exists OR
    - checkout a branch that was created remotely and has not previously been locally checked out.
    - this will create this branch locally in all submodules and check that branch out in the
      root repository and all submodules
    - NOTE that if changes were pushed to this branch in a submodule using git directly (not using nuggit)
      AND the parent reposities were not updated to point to the new submodule commits, this checkout command
      will result a repository that reports local changes.
  - nuggit_checkout.pl -b <branch_name>
    - create a brand new branch and check it out in the root repository and all nested submodules
  - nuggit_checkout <branch> --follow-commit



<a/>
### nuggit_diff.pl
- do a git diff in the root repository and do a git diff in each submodule 
- any arguments passed in to nuggit_diff.pl will be forwarded to the git diff commands that execute.
  - i.e. 
    - nuggit_diff.pl --name-only
        
        
nuggit_rev_list.pl
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
        
nuggit_fetch.pl
        -fetches everything in the root and submodules recursively.
        - "git fetch": downloads commits, files, and refs from a remote repository to your local repository. 
        - Fetching is what yu do when you want to see what everyone else has been working on.
        
nuggit_pull.pl
        - pull the checked out branch from origin for the root repository.  Then foreach
        submodule pull from origin.
        - Any local, uncommitted changes will trigger a warning and will prevent git from completing
        the pull
        
nuggit_status.pl
        - two variations: 
        - nuggit_status.pl
                - for each submodule show the status 
        - nuggit_status.pl --cached
                - show the changes that were added to the staging area that will be committed on the next nuggit commit
        - the output will show the relative path of each file that has a status.  The 
        relative path is relative to the nuggit root repository.  This is so the file path and name
        can be copied and pasted into the command line of the nuggit_add.pl command
        
nuggit_add.pl
        - add the specified files to the staging area
        - example
                nuggit_add.pl ./fsw_core/apps/appx/file.c
        - nuggit_add.pl utilizes the "nuggit_log.txt".  Each file that is "added" to the staging area
          using nuggit_add.pl will result in a nuggit log entry.  See "nuggit_log"
                
nuggit_commit.pl
        - commit all the files that have been added to the staging area across all of the
        repositores (root and nested submodules) into the checked out branch
        - example
                nuggit_commit.pl -m "required commit message goes here"
        - nuggit_commit.pl utilizes the "nuggit_log.txt".  Each nuggit_commit issued by the user
          and each underying commit performed by nuggit_commit.pl will result in a nuggit log entry
        
nuggit_push.pl
        - identifies the checked out branch at the root repository and pushes the local
        branch from the local repository to the origin for each nested submodule recursively
             
nuggit_merge.pl
        - merge the specified branch into the currently checked out branch in the root repository
        and all nested submodules
        - TO DO - NOT FINISHED.
        - example
                - nuggit_merge.pl <branch_name> -m "commit message"
                - TO DO - RIGHT NOW THE COMMIT MESSAGE IS NOT HONORED.
        
nuggit_merge_default.pl
        - merge the default branch into the working branch recursively
        - no arguments provided.
        - this script will identify the default branch for the root repo and the
          submodules individually
        - this is intended to be done before pushing changes prior to merging the
          working branch back into the default branch.

nuggit_relink_submodules.pl
        - This is to be used to correct when the submodule linkages get updated outside
          of nuggit or to address other potentially inconsistencies.
        
nuggit_log.pl
        - usage:
                - Show the entire nuggit log (located at the root of the repository in .nuggit/nuggit_log.txt)
                   nuggit_log.pl
                   or
                   nuggit_log.pl --show-all
                - show N lines of the nuggit log
                   nuggit_log.pl --show <n>
                - clear the nuggit log in your repository (sandbox)
                   nuggit_log.pl -c
                
                        
