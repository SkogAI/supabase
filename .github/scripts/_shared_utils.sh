#!/bin/bash
# Shared utilities for worktree scripts
# This file provides consistent color output and helper functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo ""
}

# Auto-detect the default branch (main or master)
get_default_branch() {
    local branch
    # Try to get default branch from remote HEAD
    branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    
    if [ -z "$branch" ]; then
        # Fallback: check which exists
        if git rev-parse --verify "origin/main" &>/dev/null; then
            branch="main"
        elif git rev-parse --verify "origin/master" &>/dev/null; then
            branch="master"
        elif git rev-parse --verify "origin/develop" &>/dev/null; then
            branch="develop"
        else
            # Last resort
            branch="master"
        fi
    fi
    
    echo "$branch"
}

# Validate that a branch exists on remote
branch_exists_on_remote() {
    local branch="$1"
    git rev-parse --verify "origin/$branch" &>/dev/null
}

# Check if local branch exists
branch_exists_locally() {
    local branch="$1"
    git rev-parse --verify "refs/heads/$branch" &>/dev/null
}

# Truncate and slugify text
slugify() {
    local text="$1"
    local max_length="${2:-50}"
    
    # Convert to lowercase, replace non-alphanumeric with hyphens
    local slug=$(echo "$text" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//g' | sed 's/-$//g')
    
    # Truncate to max length
    if [ ${#slug} -gt $max_length ]; then
        slug="${slug:0:$max_length}"
        # Remove trailing hyphen after truncation
        slug=$(echo "$slug" | sed 's/-$//g')
    fi
    
    # Ensure not empty
    if [ -z "$slug" ]; then
        slug="worktree"
    fi
    
    echo "$slug"
}
