#!/usr/bin/env bash
# context.sh - Initialize and retrieve script execution context
#
# Provides standardized context about the repository, git state, and environment.
# This eliminates duplicated validation code across scripts.
#
# Usage:
#   source "$(dirname "$0")/lib/context.sh"
#   ctx=$(get_context) || exit 1
#   repo_name=$(echo "$ctx" | jq -r '.context.repository.name')

# Get the directory containing this library
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/result.sh"

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Validate environment has required tools
validate_environment() {
    local missing_tools=()

    if ! command_exists gh; then
        missing_tools+=("gh (GitHub CLI)")
    fi

    if ! command_exists jq; then
        missing_tools+=("jq (JSON processor)")
    fi

    if ! command_exists git; then
        missing_tools+=("git")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        error_result "missing_dependencies" \
            "Missing required tools: ${missing_tools[*]}" \
            '{"tools": '"$(printf '%s\n' "${missing_tools[@]}" | jq -R . | jq -s .)"'}'
        return 1
    fi

    return 0
}

# Get git repository information
get_git_context() {
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "null"
        return 1
    fi

    local current_branch root_path is_clean has_uncommitted
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    root_path=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    # Check if working tree is clean
    if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
        is_clean=true
        has_uncommitted=false
    else
        is_clean=false
        has_uncommitted=true
    fi

    jq -n \
        --arg branch "$current_branch" \
        --arg root "$root_path" \
        --argjson clean "$is_clean" \
        --argjson uncommitted "$has_uncommitted" \
        '{
            currentBranch: $branch,
            isClean: $clean,
            hasUncommitted: $uncommitted,
            rootPath: $root
        }'
}

# Get GitHub repository information
get_repository_context() {
    local repo_json
    repo_json=$(gh repo view --json nameWithOwner,name,owner,defaultBranchRef 2>/dev/null || echo "null")

    if [ "$repo_json" = "null" ]; then
        echo "null"
        return 1
    fi

    echo "$repo_json" | jq '{
        owner: .owner.login,
        name: .name,
        fullName: .nameWithOwner,
        defaultBranch: .defaultBranchRef.name
    }'
}

# Get environment information
get_environment_context() {
    local gh_version
    gh_version=$(gh --version 2>/dev/null | head -n1 | awk '{print $3}' || echo "unknown")

    jq -n \
        --argjson has_gh "$(command_exists gh && echo true || echo false)" \
        --argjson has_jq "$(command_exists jq && echo true || echo false)" \
        --arg gh_ver "$gh_version" \
        '{
            hasGhCli: $has_gh,
            hasJq: $has_jq,
            ghVersion: $gh_ver
        }'
}

# Get complete context (repository, git, environment)
# Returns JSON structure matching command-context.schema.json
get_context() {
    # Validate environment first
    validate_environment || return 1

    local repo_ctx git_ctx env_ctx

    repo_ctx=$(get_repository_context)
    if [ "$repo_ctx" = "null" ]; then
        error_result "invalid_repository" \
            "Not in a valid GitHub repository or gh CLI not authenticated" \
            '{}'
        return 1
    fi

    git_ctx=$(get_git_context)
    if [ "$git_ctx" = "null" ]; then
        error_result "invalid_git_repo" \
            "Not in a git repository" \
            '{}'
        return 1
    fi

    env_ctx=$(get_environment_context)

    jq -n \
        --argjson repo "$repo_ctx" \
        --argjson git "$git_ctx" \
        --argjson env "$env_ctx" \
        '{
            context: {
                repository: $repo,
                git: $git,
                environment: $env
            }
        }'
}

# Convenience functions to extract specific values from context
get_repo_full_name() {
    echo "$1" | jq -r '.context.repository.fullName'
}

get_current_branch() {
    echo "$1" | jq -r '.context.git.currentBranch'
}

get_is_clean() {
    echo "$1" | jq -r '.context.git.isClean'
}

get_default_branch() {
    echo "$1" | jq -r '.context.repository.defaultBranch'
}
