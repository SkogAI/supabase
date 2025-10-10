#!/usr/bin/env bash
# gh-api.sh - Structured GitHub API wrappers
#
# Provides consistent interfaces to GitHub API via gh CLI.
# Returns structured JSON matching defined schemas.
#
# Usage:
#   source "$(dirname "$0")/lib/gh-api.sh"
#   issue=$(gh_get_issue 123)
#   pr=$(gh_create_pr "title" "body" "base-branch")

# Get the directory containing this library
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$LIB_DIR/result.sh"

# Get issue details
# Args:
#   $1 - issue number
# Returns: JSON object with issue data
gh_get_issue() {
    local issue_number="$1"

    if [ -z "$issue_number" ]; then
        error_result "invalid_argument" "Issue number is required" '{}'
        return 1
    fi

    local issue_json
    issue_json=$(gh issue view "$issue_number" \
        --json number,title,body,state,author,url,createdAt,updatedAt \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$issue_json" ]; then
        error_result "issue_not_found" "Issue #$issue_number not found" \
            "$(jq -n --arg num "$issue_number" '{issueNumber: $num}')"
        return 1
    fi

    echo "$issue_json"
}

# Create issue
# Args:
#   $1 - title
#   $2 - body
# Returns: JSON object with created issue data
gh_create_issue() {
    local title="$1"
    local body="$2"

    if [ -z "$title" ]; then
        error_result "invalid_argument" "Issue title is required" '{}'
        return 1
    fi

    local issue_json
    issue_json=$(gh issue create \
        --title "$title" \
        --body "$body" \
        --json number,url,title \
        2>/dev/null)

    if [ $? -ne 0 ]; then
        error_result "issue_create_failed" "Failed to create issue" '{}'
        return 1
    fi

    echo "$issue_json"
}

# Get PR details
# Args:
#   $1 - PR number
# Returns: JSON object with PR data
gh_get_pr() {
    local pr_number="$1"

    if [ -z "$pr_number" ]; then
        error_result "invalid_argument" "PR number is required" '{}'
        return 1
    fi

    local pr_json
    pr_json=$(gh pr view "$pr_number" \
        --json number,title,body,state,author,url,headRefName,baseRefName,createdAt,updatedAt,mergeable \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$pr_json" ]; then
        error_result "pr_not_found" "PR #$pr_number not found" \
            "$(jq -n --arg num "$pr_number" '{prNumber: $num}')"
        return 1
    fi

    echo "$pr_json"
}

# Create PR
# Args:
#   $1 - title
#   $2 - body
#   $3 - base branch (optional, defaults to repo default)
# Returns: JSON object with created PR data
gh_create_pr() {
    local title="$1"
    local body="$2"
    local base_branch="${3:-}"

    if [ -z "$title" ]; then
        error_result "invalid_argument" "PR title is required" '{}'
        return 1
    fi

    local pr_json cmd_args
    cmd_args=(gh pr create --title "$title" --body "$body" --json number,url,title)

    if [ -n "$base_branch" ]; then
        cmd_args+=(--base "$base_branch")
    fi

    pr_json=$("${cmd_args[@]}" 2>/dev/null)

    if [ $? -ne 0 ]; then
        error_result "pr_create_failed" "Failed to create PR" '{}'
        return 1
    fi

    echo "$pr_json"
}

# List issues with filters
# Args:
#   $1 - search query (optional)
#   $2 - limit (optional, default 10)
# Returns: JSON array of issues
gh_list_issues() {
    local search="${1:-}"
    local limit="${2:-10}"

    local issues_json cmd_args
    cmd_args=(gh issue list --json number,title,state,author,updatedAt --limit "$limit")

    if [ -n "$search" ]; then
        cmd_args+=(--search "$search")
    fi

    issues_json=$("${cmd_args[@]}" 2>/dev/null)

    if [ $? -ne 0 ]; then
        error_result "issue_list_failed" "Failed to list issues" '{}'
        return 1
    fi

    echo "$issues_json"
}

# List PRs with filters
# Args:
#   $1 - search query (optional)
#   $2 - limit (optional, default 10)
# Returns: JSON array of PRs
gh_list_prs() {
    local search="${1:-}"
    local limit="${2:-10}"

    local prs_json cmd_args
    cmd_args=(gh pr list --json number,title,state,author,updatedAt,headRefName --limit "$limit")

    if [ -n "$search" ]; then
        cmd_args+=(--search "$search")
    fi

    prs_json=$("${cmd_args[@]}" 2>/dev/null)

    if [ $? -ne 0 ]; then
        error_result "pr_list_failed" "Failed to list PRs" '{}'
        return 1
    fi

    echo "$prs_json"
}

# Get branch status
# Args:
#   $1 - branch name
# Returns: JSON object with branch status (matches branch-status.schema.json)
gh_get_branch_status() {
    local branch_name="$1"

    if [ -z "$branch_name" ]; then
        error_result "invalid_argument" "Branch name is required" '{}'
        return 1
    fi

    # Check if branch exists locally
    local exists_locally exists_remotely
    exists_locally=$(git show-ref --verify --quiet "refs/heads/$branch_name" && echo true || echo false)
    exists_remotely=$(git show-ref --verify --quiet "refs/remotes/origin/$branch_name" && echo true || echo false)

    # Parse branch type (claude/issue-123-20251010-1200 format)
    local branch_type issue_number timestamp
    if [[ "$branch_name" =~ ^claude/issue-([0-9]+)-([0-9]{8})-([0-9]{4})$ ]]; then
        branch_type="claude"
        issue_number="${BASH_REMATCH[1]}"
        timestamp="20${BASH_REMATCH[2]:2:2}-${BASH_REMATCH[2]:4:2}-${BASH_REMATCH[2]:6:2}T${BASH_REMATCH[3]:0:2}:${BASH_REMATCH[3]:2:2}:00Z"
    else
        branch_type="unknown"
        issue_number=""
        timestamp=""
    fi

    # Check if branch is merged
    local is_merged
    is_merged=$(git branch --merged 2>/dev/null | grep -q "^\*\? *$branch_name$" && echo true || echo false)

    # Get associated PR
    local pr_json pr_number pr_state pr_url
    pr_json=$(gh pr list --head "$branch_name" --json number,state,url --limit 1 2>/dev/null || echo "[]")
    pr_number=$(echo "$pr_json" | jq -r '.[0].number // empty')
    pr_state=$(echo "$pr_json" | jq -r '.[0].state // empty')
    pr_url=$(echo "$pr_json" | jq -r '.[0].url // empty')

    # Build result
    jq -n \
        --arg name "$branch_name" \
        --arg type "$branch_type" \
        --arg issue "$issue_number" \
        --arg ts "$timestamp" \
        --argjson local "$exists_locally" \
        --argjson remote "$exists_remotely" \
        --argjson merged "$is_merged" \
        --arg pr_num "$pr_number" \
        --arg pr_state "$pr_state" \
        --arg pr_url "$pr_url" \
        '{
            branch: {
                name: $name,
                type: $type,
                issueNumber: (if $issue != "" then $issue else null end),
                timestamp: (if $ts != "" then $ts else null end),
                status: {
                    existsLocally: $local,
                    existsRemotely: $remote,
                    isMerged: $merged,
                    hasConflicts: false
                },
                associatedPR: (if $pr_num != "" then {
                    number: ($pr_num | tonumber),
                    state: $pr_state,
                    url: $pr_url
                } else null end)
            }
        }'
}
