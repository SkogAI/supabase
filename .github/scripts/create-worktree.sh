#!/bin/bash
# create-worktree.sh - Create worktrees for GitHub issues following Git Flow
#
# Usage: ./create-worktree.sh <issue-number> [type] [--preview]
#   type: feature (default), bugfix, hotfix
#   --preview: Create preview environment (requires Supabase CLI and credentials)

set -e

ISSUE_NUMBER="$1"
TYPE="${2:-feature}"
BASE_BRANCH="develop"
CREATE_PREVIEW=false

# Parse arguments
for arg in "$@"; do
    if [ "$arg" = "--preview" ]; then
        CREATE_PREVIEW=true
    fi
done

if [ -z "$ISSUE_NUMBER" ]; then
    echo "Usage: $0 <issue-number> [type] [--preview]"
    echo "  type: feature (default), bugfix, hotfix"
    echo "  --preview: Create preview environment"
    exit 1
fi

# Fetch latest from origin
git fetch origin

# Get issue title from GitHub CLI if available
if command -v gh &> /dev/null; then
    ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --json title -q .title 2>/dev/null || echo "")
    if [ -n "$ISSUE_TITLE" ]; then
        # Convert title to slug format (lowercase, hyphens)
        SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//g' | sed 's/-$//g')
        WORKTREE_NAME="${TYPE}-${SLUG}-${ISSUE_NUMBER}"
        BRANCH_NAME="${TYPE}/${SLUG}-${ISSUE_NUMBER}"
    else
        WORKTREE_NAME="${TYPE}-issue-${ISSUE_NUMBER}"
        BRANCH_NAME="${TYPE}/issue-${ISSUE_NUMBER}"
    fi
else
    WORKTREE_NAME="${TYPE}-issue-${ISSUE_NUMBER}"
    BRANCH_NAME="${TYPE}/issue-${ISSUE_NUMBER}"
fi

# Hotfixes branch from master/main
if [ "$TYPE" = "hotfix" ]; then
    BASE_BRANCH="master"
fi

WORKTREE_PATH=".dev/worktree/${WORKTREE_NAME}"

echo "Creating worktree:"
echo "  Path: $WORKTREE_PATH"
echo "  Branch: $BRANCH_NAME"
echo "  Base: $BASE_BRANCH"

# Create worktree directory if needed
mkdir -p .dev/worktree

# Create the worktree
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "origin/$BASE_BRANCH"

echo ""
echo "✓ Worktree created successfully!"
echo ""

# Preview environment setup
if [ "$CREATE_PREVIEW" = true ]; then
    echo "Setting up preview environment..."
    if command -v supabase &> /dev/null; then
        echo "⚠ Preview environment creation requires Supabase project credentials"
        echo "⚠ This feature is planned but not yet implemented"
        echo "⚠ See docs/CI_WORKTREE_INTEGRATION.md for details"
    else
        echo "⚠ Supabase CLI not found - skipping preview environment"
        echo "⚠ Install: https://supabase.com/docs/guides/cli"
    fi
    echo ""
fi

echo "Next steps:"
echo "  cd $WORKTREE_PATH"
echo "  # Make your changes"
echo "  git add ."
echo "  git commit -m \"Description of changes\""
echo "  git push -u origin $BRANCH_NAME"
echo "  gh pr create --base $BASE_BRANCH"
echo ""
echo "Optional: Run CI checks before pushing:"
echo "  .github/scripts/ci-worktree.sh"
