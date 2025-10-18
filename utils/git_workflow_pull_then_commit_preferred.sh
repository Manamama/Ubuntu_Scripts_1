#!/bin/bash

# Philosophy: "Pull First, Then Commit" (Merge-based, True History)
# This workflow ensures local work is always based on the latest remote state.
# It integrates remote changes before local commits are finalized, allowing for early conflict resolution.
# It maintains a complete, auditable history with merge commits.
# Untracked files are generally safe as Git operations primarily affect tracked files.

echo "The git sync (git : pull, add, commit, push) script does not assume <branch> is set, e.g., main or current branch name, because if a wrong branch is gven, then the script fails"
BRANCH="main"


git status
#git pull origin "$BRANCH" # Integrates remote changes via merge
git pull origin
git add .
git status # Sanity check: See what has been staged
git commit -m "Automated commit, probably minor changes"
#git push origin "$BRANCH"
git push origin
git status


#git restore --source=origin/main --staged --worktree docs/pmbok_instructions/workflows/git_and_GitHub_workflow.md  makes the local file overwritten. 
# But then `git pull` again!
