#!/usr/bin/env bash

# Remove set -e as it can cause issues with arithmetic operations

# Configuration
WORKTREE_BASE="${WORKTREE_BASE:-/home/skogix/dev/supabase/.dev/worktree}"
PARSE_TEMPLATE="${PARSE_TEMPLATE:-/home/skogix/dev/supabase/.github/sparse-checkouts/default.txt}"
REPO_OWNER_AND_NAME=$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track statistics
CREATED=0
SKIPPED=0
FAILED=0
FAILED_ITEMS=()

# Function to create sparse worktree
create_sparse_worktree() {
    local branch_name="$1"
    local worktree_path="$2"

    echo -e "${BLUE}Creating worktree for: ${branch_name}${NC}"

    # Check if worktree already exists
    if [ -d "$worktree_path" ]; then
        echo -e "${YELLOW}  → Skipping: Worktree already exists${NC}"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    # Check if branch exists (local or remote)
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        # Local branch exists
        git worktree add "$worktree_path" "$branch_name" || {
            echo -e "${RED}  → Failed to create worktree${NC}"
            FAILED=$((FAILED + 1))
            FAILED_ITEMS+=("$branch_name")
            return 1
        }
    elif git show-ref --verify --quiet "refs/remotes/origin/${branch_name}"; then
        # Remote branch exists
        git worktree add "$worktree_path" -b "$branch_name" "origin/${branch_name}" || {
            echo -e "${RED}  → Failed to create worktree${NC}"
            FAILED=$((FAILED + 1))
            FAILED_ITEMS+=("$branch_name")
            return 1
        }
    else
        # Create new branch
        git worktree add "$worktree_path" -b "$branch_name" || {
            echo -e "${RED}  → Failed to create worktree${NC}"
            FAILED=$((FAILED + 1))
            FAILED_ITEMS+=("$branch_name")
            return 1
        }
    fi

    # Configure sparse checkout
    (
        cd "$worktree_path"
        git sparse-checkout init --no-cone
        git sparse-checkout set --no-cone --stdin <"$PARSE_TEMPLATE"
        git checkout
    ) || {
        echo -e "${RED}  → Failed to configure sparse checkout${NC}"
        FAILED=$((FAILED + 1))
        FAILED_ITEMS+=("$branch_name")
        return 1
    }

    echo -e "${GREEN}  ✓ Successfully created sparse worktree${NC}"
    CREATED=$((CREATED + 1))
    return 0
}

# Function to process GitHub issues
process_issues() {
    echo -e "${BLUE}📋 Processing GitHub Issues...${NC}"

    # Try to get issues using gh CLI
    if command -v gh &> /dev/null; then
        if gh auth status &>/dev/null; then
            while IFS=$'\t' read -r issue_number issue_title; do
                local branch_name="issue-${issue_number}"
                local worktree_path="${WORKTREE_BASE}/${branch_name}"
                create_sparse_worktree "$branch_name" "$worktree_path"
            done < <(gh issue list --state open --limit 100 --json number,title --jq '.[] | [.number, .title] | @tsv')
        else
            echo -e "${YELLOW}  ⚠ GitHub CLI not authenticated. Skipping issues.${NC}"
            echo -e "${YELLOW}    Run: gh auth login${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ GitHub CLI not installed. Skipping issues.${NC}"
    fi
}

# Function to process GitHub PRs
process_prs() {
    echo -e "${BLUE}🔀 Processing GitHub Pull Requests...${NC}"

    # Try to get PRs using gh CLI
    if command -v gh &> /dev/null; then
        if gh auth status &>/dev/null; then
            while IFS=$'\t' read -r pr_number pr_title head_branch; do
                local branch_name="pr-${pr_number}"
                local worktree_path="${WORKTREE_BASE}/${branch_name}"

                # For PRs, we might want to use the actual head branch name
                # Uncomment the next line if you prefer using the PR's actual branch name
                # branch_name="$head_branch"

                create_sparse_worktree "$branch_name" "$worktree_path"
            done < <(gh pr list --state open --limit 100 --json number,title,headRefName --jq '.[] | [.number, .title, .headRefName] | @tsv')
        else
            echo -e "${YELLOW}  ⚠ GitHub CLI not authenticated. Skipping PRs.${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ GitHub CLI not installed. Skipping PRs.${NC}"
    fi
}

# Function to process existing remote branches
process_remote_branches() {
    echo -e "${BLUE}🌿 Processing existing issue/PR branches...${NC}"

    # Find branches that look like issue or PR branches
    git fetch --all --quiet

    # Use while read to properly handle branch names
    while IFS= read -r branch; do
        # Skip HEAD reference
        if [[ "$branch" == "HEAD" ]] || [[ "$branch" == *"HEAD"* ]]; then
            continue
        fi

        # Clean branch name (remove origin/ if present)
        branch="${branch#origin/}"

        local worktree_path="${WORKTREE_BASE}/${branch}"
        create_sparse_worktree "$branch" "$worktree_path"
    done < <(git branch -r | sed 's/^[[:space:]]*origin\///' | rg '(issue|pr|pull|bug|feature|fix|hotfix|patch|update|release|docs|test|refactor|style|perf|chore|build|ci|revert|claude|copilot).*[0-9]+' | head -50)
}

# Main execution
main() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}Sparse Worktree Creation Tool${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
    echo -e "📁 Worktree Base: ${WORKTREE_BASE}"
    echo -e "📝 Sparse Template: ${PARSE_TEMPLATE}"
    echo ""

    # Ensure worktree base directory exists
    mkdir -p "$WORKTREE_BASE"

    # Check if sparse template exists
    if [ ! -f "$PARSE_TEMPLATE" ]; then
        echo -e "${RED}Error: Sparse checkout template not found at ${PARSE_TEMPLATE}${NC}"
        exit 1
    fi

    # Process different sources
    if [ "${1:-}" == "--issues-only" ]; then
        process_issues
    elif [ "${1:-}" == "--prs-only" ]; then
        process_prs
    elif [ "${1:-}" == "--branches-only" ]; then
        process_remote_branches
    else
        process_issues
        echo ""
        process_prs
        echo ""
        process_remote_branches
    fi

    # Print summary
    echo ""
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}Summary${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${GREEN}✓ Created: ${CREATED}${NC}"
    echo -e "${YELLOW}⊝ Skipped: ${SKIPPED}${NC}"
    echo -e "${RED}✗ Failed: ${FAILED}${NC}"

    if [ ${#FAILED_ITEMS[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed items:${NC}"
        for item in "${FAILED_ITEMS[@]}"; do
            echo -e "${RED}  - ${item}${NC}"
        done
    fi

    echo ""
    echo -e "${BLUE}Worktrees location: ${WORKTREE_BASE}${NC}"
    echo ""

    # List created worktrees
    if command -v git &> /dev/null; then
        echo -e "${BLUE}Current worktrees:${NC}"
        git worktree list
    fi
}

# Run main function with all arguments
main "$@"