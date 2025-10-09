#!/bin/bash
# remove-worktree.sh - Remove a worktree and optionally its branch
#
# Usage: ./remove-worktree.sh <worktree-name> [--delete-branch]

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_shared_utils.sh"

WORKTREE_NAME="$1"
DELETE_BRANCH="$2"

if [ -z "$WORKTREE_NAME" ]; then
    print_error "Missing required argument: worktree-name"
    echo ""
    echo "Usage: $0 <worktree-name> [--delete-branch]"
    echo ""
    echo "Available worktrees:"
    git worktree list
    exit 1
fi

WORKTREE_PATH=".dev/worktree/${WORKTREE_NAME}"

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
    print_error "Worktree not found at $WORKTREE_PATH"
    exit 1
fi

# Get absolute paths for comparison
WORKTREE_ABS=$(cd "$WORKTREE_PATH" && pwd)
CURRENT_DIR=$(pwd)

# Check if user is currently in the worktree being removed
if [ "$CURRENT_DIR" = "$WORKTREE_ABS" ] || [[ "$CURRENT_DIR" == "$WORKTREE_ABS"/* ]]; then
    print_error "Cannot remove worktree: you are currently inside it"
    echo ""
    echo "Please change to a different directory first:"
    echo "  cd /home/runner/work/supabase/supabase"
    exit 1
fi

# Get the branch name
BRANCH_NAME=$(cd "$WORKTREE_PATH" && git branch --show-current)

echo ""
print_header "Removing worktree"
echo "  Path: $WORKTREE_PATH"
echo "  Branch: $BRANCH_NAME"
echo ""

# Check for uncommitted changes
if git -C "$WORKTREE_PATH" diff-index --quiet HEAD -- 2>/dev/null; then
    : # No changes
else
    print_warning "Worktree has uncommitted changes!"
    echo ""
    read -p "Continue with removal? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removal cancelled"
        exit 0
    fi
fi

# Remove the worktree
if git worktree remove "$WORKTREE_PATH"; then
    print_success "Worktree removed"
else
    print_error "Failed to remove worktree"
    exit 1
fi

# Optionally delete the branch
if [ "$DELETE_BRANCH" = "--delete-branch" ]; then
    echo ""
    print_warning "About to delete branch: $BRANCH_NAME"
    echo ""
    read -p "Are you sure? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if git branch -D "$BRANCH_NAME"; then
            print_success "Branch deleted locally"
            echo ""
            print_info "To delete remote branch:"
            echo "  git push origin --delete $BRANCH_NAME"
        else
            print_error "Failed to delete branch"
        fi
    else
        print_info "Branch deletion cancelled"
    fi
fi
