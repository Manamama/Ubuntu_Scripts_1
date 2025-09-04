#!/bin/bash
set -e

# Check if inside a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a git repository." >&2
    exit 1
fi

# Use the first argument as the commit message, or a default.
COMMIT_MSG="${1:-Automated commit}"

git pull
echo "Rebase if in doubt"
git status
git add .
git status
git commit -m "$COMMIT_MSG"
git push