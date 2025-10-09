#!/bin/bash
# create-worktree.sh - Create worktrees for GitHub issues following Git Flow
#
# Usage: ./create-worktree.sh <issue-number> [type] [--preview]
#   type: feature (default), bugfix, hotfix
#   --preview: Create preview environment (requires Supabase CLI and credentials)

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_shared_utils.sh"

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
    print_error "Missing required argument: issue-number"
    echo ""
    echo "Usage: $0 <issue-number> [type] [--preview]"
    echo "  type: feature (default), bugfix, hotfix"
    echo "  --preview: Create preview environment"
    exit 1
fi

# Validate type
if [[ ! "$TYPE" =~ ^(feature|bugfix|hotfix)$ ]]; then
    print_error "Invalid type: $TYPE"
    echo "Valid types: feature, bugfix, hotfix"
    exit 1
fi

print_info "Fetching latest from origin..."
git fetch origin

# Get issue title from GitHub CLI if available
if command -v gh &> /dev/null; then
    ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --json title -q .title 2>/dev/null || echo "")
    if [ -n "$ISSUE_TITLE" ]; then
        # Convert title to slug format with 50 char limit
        SLUG=$(slugify "$ISSUE_TITLE" 50)
        WORKTREE_NAME="${TYPE}-${SLUG}-${ISSUE_NUMBER}"
        BRANCH_NAME="${TYPE}/${SLUG}-${ISSUE_NUMBER}"
    else
        print_warning "Could not fetch issue title from GitHub (using generic name)"
        WORKTREE_NAME="${TYPE}-issue-${ISSUE_NUMBER}"
        BRANCH_NAME="${TYPE}/issue-${ISSUE_NUMBER}"
    fi
else
    print_warning "GitHub CLI not found (using generic name)"
    WORKTREE_NAME="${TYPE}-issue-${ISSUE_NUMBER}"
    BRANCH_NAME="${TYPE}/issue-${ISSUE_NUMBER}"
fi

# Determine base branch
if [ "$TYPE" = "hotfix" ]; then
    # Auto-detect main/master for hotfixes
    if branch_exists_on_remote "master"; then
        BASE_BRANCH="master"
    elif branch_exists_on_remote "main"; then
        BASE_BRANCH="main"
    else
        print_error "Neither 'master' nor 'main' branch found on remote"
        exit 1
    fi
else
    # For features and bugfixes, use develop or fallback to main/master
    if branch_exists_on_remote "develop"; then
        BASE_BRANCH="develop"
    else
        BASE_BRANCH=$(get_default_branch)
        print_warning "No 'develop' branch found, using '$BASE_BRANCH' as base"
    fi
fi

# Validate base branch exists
if ! branch_exists_on_remote "$BASE_BRANCH"; then
    print_error "Base branch 'origin/$BASE_BRANCH' does not exist"
    exit 1
fi

WORKTREE_PATH=".dev/worktree/${WORKTREE_NAME}"

# Check if branch already exists locally
if branch_exists_locally "$BRANCH_NAME"; then
    print_error "Branch '$BRANCH_NAME' already exists locally"
    echo ""
    echo "Options:"
    echo "  1. Delete the existing branch: git branch -D $BRANCH_NAME"
    echo "  2. Use a different issue number or type"
    echo "  3. Checkout existing worktree if it exists"
    exit 1
fi

# Check if worktree directory already exists
if [ -d "$WORKTREE_PATH" ]; then
    print_error "Worktree directory already exists: $WORKTREE_PATH"
    echo ""
    echo "Options:"
    echo "  1. Remove existing worktree: .github/scripts/remove-worktree.sh $(basename "$WORKTREE_PATH")"
    echo "  2. Use a different issue number or type"
    exit 1
fi

echo ""
print_header "Creating worktree"
echo "  Path: $WORKTREE_PATH"
echo "  Branch: $BRANCH_NAME"
echo "  Base: origin/$BASE_BRANCH"
echo ""

# Create worktree directory if needed
mkdir -p .dev/worktree

# Create the worktree
if git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "origin/$BASE_BRANCH"; then
    print_success "Worktree created successfully!"
else
    print_error "Failed to create worktree"
    exit 1
fi

# Install Git hooks in the worktree
echo ""
print_info "Installing Git hooks..."
cd "$WORKTREE_PATH"
if [ -f ".github/scripts/install-hooks.sh" ]; then
    if .github/scripts/install-hooks.sh > /dev/null 2>&1; then
        print_success "Git hooks installed (pre-push validation enabled)"
    else
        print_warning "Could not install Git hooks (continuing anyway)"
    fi
else
    print_warning "Hook installation script not found (skipping)"
fi
cd - > /dev/null

# Preview environment setup
if [ "$CREATE_PREVIEW" = true ]; then
    echo ""
    print_info "Setting up preview environment..."
    if command -v supabase &> /dev/null; then
        print_warning "Preview environment creation requires Supabase project credentials"
        print_warning "This feature is planned but not yet implemented"
        print_warning "See docs/CI_WORKTREE_INTEGRATION.md for details"
    else
        print_warning "Supabase CLI not found - skipping preview environment"
        print_info "Install: https://supabase.com/docs/guides/cli"
    fi
fi

echo ""

# Run template setup script if it exists
TEMPLATE_SETUP=".dev/worktree-templates/${TYPE}/setup.sh"
if [ -f "$TEMPLATE_SETUP" ]; then
    print_info "Running $TYPE template setup..."
    echo ""
    (cd "$WORKTREE_PATH" && bash "../../worktree-templates/${TYPE}/setup.sh")
fi

echo ""
print_header "Next steps:"
echo "  cd $WORKTREE_PATH"
echo "  # Make your changes"
echo "  git add ."
echo "  git commit -m \"Description of changes\""
echo "  # Run CI checks before pushing (optional):"
echo "  .github/scripts/ci-worktree.sh"
echo "  # Push (pre-push hook will run CI checks automatically)"
echo "  git push -u origin $BRANCH_NAME"
echo "  gh pr create --base $BASE_BRANCH"
echo ""
print_info "Docker ports are shared across all worktrees (same Supabase instance)"
print_info "Worktrees share .git directory but have separate working trees"
