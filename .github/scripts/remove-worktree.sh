#!/bin/bash
# remove-worktree.sh - Remove a worktree and optionally its branch
#
# Usage: ./remove-worktree.sh <worktree-name> [--delete-branch]

set -e

WORKTREE_NAME="$1"
DELETE_BRANCH="$2"

if [ -z "$WORKTREE_NAME" ]; then
    echo "Usage: $0 <worktree-name> [--delete-branch]"
    echo ""
    echo "Available worktrees:"
    git worktree list
    exit 1
fi

WORKTREE_PATH=".dev/worktree/${WORKTREE_NAME}"

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
    echo "Error: Worktree not found at $WORKTREE_PATH"
    exit 1
fi

# Get the branch name
BRANCH_NAME=$(cd "$WORKTREE_PATH" && git branch --show-current)

echo "Removing worktree: $WORKTREE_PATH"
echo "Branch: $BRANCH_NAME"

# Remove the worktree
git worktree remove "$WORKTREE_PATH"

echo "✓ Worktree removed"

# Optionally delete the branch
if [ "$DELETE_BRANCH" = "--delete-branch" ]; then
    echo "Deleting branch: $BRANCH_NAME"
    git branch -D "$BRANCH_NAME"
    echo "✓ Branch deleted locally"
    echo ""
    echo "To delete remote branch:"
    echo "  git push origin --delete $BRANCH_NAME"
fi
