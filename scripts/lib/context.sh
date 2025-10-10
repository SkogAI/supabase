#!/usr/bin/env bash
# context.sh - Initialize and provide script execution context
# Usage: source "$(dirname "$0")/lib/context.sh"

# Load dependencies
SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "$SCRIPT_LIB_DIR/colors.sh"

# Check environment dependencies
check_dependencies() {
    local missing_deps=()

    # Check for gh CLI
    if ! command -v gh &> /dev/null; then
        missing_deps+=("gh (GitHub CLI)")
    fi

    # Check for jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq (JSON processor)")
    fi

    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}" >&2
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep" >&2
        done
        return 1
    fi

    return 0
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo -e "${RED}Error: Not in a git repository.${NC}" >&2
        return 1
    fi
    return 0
}

# Get git context information
get_git_context() {
    local git_root git_branch git_status is_clean has_uncommitted

    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    git_branch=$(git branch --show-current 2>/dev/null)
    git_status=$(git status --porcelain 2>/dev/null)

    if [ -z "$git_status" ]; then
        is_clean="true"
        has_uncommitted="false"
    else
        is_clean="false"
        has_uncommitted="true"
    fi

    jq -n \
        --arg root "$git_root" \
        --arg branch "$git_branch" \
        --argjson clean "$is_clean" \
        --argjson uncommitted "$has_uncommitted" \
        '{
            currentBranch: $branch,
            isClean: $clean,
            hasUncommitted: $uncommitted,
            rootPath: $root
        }'
}

# Get repository context from GitHub
get_repo_context() {
    local repo_json owner name full_name default_branch

    repo_json=$(gh repo view --json nameWithOwner,owner,name,defaultBranchRef 2>/dev/null)

    if [ -z "$repo_json" ] || [ "$repo_json" = "null" ]; then
        echo "{}"
        return 1
    fi

    echo "$repo_json" | jq '{
        owner: .owner.login,
        name: .name,
        fullName: .nameWithOwner,
        defaultBranch: .defaultBranchRef.name
    }'
}

# Get environment context
get_env_context() {
    local has_gh has_jq gh_version

    has_gh="false"
    has_jq="false"
    gh_version=""

    if command -v gh &> /dev/null; then
        has_gh="true"
        gh_version=$(gh --version 2>/dev/null | head -n1 | awk '{print $3}')
    fi

    if command -v jq &> /dev/null; then
        has_jq="true"
    fi

    jq -n \
        --argjson has_gh "$has_gh" \
        --argjson has_jq "$has_jq" \
        --arg gh_version "$gh_version" \
        '{
            hasGhCli: $has_gh,
            hasJq: $has_jq,
            ghVersion: $gh_version
        }'
}

# Get complete context (combines all context types)
get_context() {
    # Check dependencies first
    if ! check_dependencies; then
        return 1
    fi

    # Check git repo
    if ! check_git_repo; then
        return 1
    fi

    local git_ctx repo_ctx env_ctx

    git_ctx=$(get_git_context)
    repo_ctx=$(get_repo_context)
    env_ctx=$(get_env_context)

    jq -n \
        --argjson git "$git_ctx" \
        --argjson repo "$repo_ctx" \
        --argjson env "$env_ctx" \
        '{
            context: {
                repository: $repo,
                git: $git,
                environment: $env
            }
        }'
}

# Validate context (ensure required fields are present)
validate_context() {
    local ctx="$1"

    # Check if context has required fields
    if ! echo "$ctx" | jq -e '.context.git.currentBranch' > /dev/null 2>&1; then
        echo -e "${RED}Error: Invalid context - missing git information${NC}" >&2
        return 1
    fi

    if ! echo "$ctx" | jq -e '.context.repository.fullName' > /dev/null 2>&1; then
        echo -e "${RED}Error: Invalid context - missing repository information${NC}" >&2
        return 1
    fi

    return 0
}
