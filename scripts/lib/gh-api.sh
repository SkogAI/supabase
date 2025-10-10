#!/usr/bin/env bash
# gh-api.sh - Structured GitHub API wrappers
# Usage: source "$(dirname "$0")/lib/gh-api.sh"

# Create a GitHub issue
# Usage: gh_create_issue "title" "body"
gh_create_issue() {
    local title="$1"
    local body="$2"
    local result

    result=$(gh issue create \
        --title "$title" \
        --body "$body" \
        --json number,url 2>&1)

    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    else
        echo "{}" >&2
        return 1
    fi
}

# Create a GitHub PR
# Usage: gh_create_pr "title" "body" "base_branch"
gh_create_pr() {
    local title="$1"
    local body="$2"
    local base_branch="${3:-}"
    local result

    if [ -n "$base_branch" ]; then
        result=$(gh pr create \
            --title "$title" \
            --body "$body" \
            --base "$base_branch" \
            --json number,url 2>&1)
    else
        result=$(gh pr create \
            --title "$title" \
            --body "$body" \
            --json number,url 2>&1)
    fi

    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    else
        echo "{}" >&2
        return 1
    fi
}

# Get issue information
# Usage: gh_get_issue "issue_number"
gh_get_issue() {
    local issue_number="$1"
    local result

    result=$(gh issue view "$issue_number" \
        --json number,title,state,body,author,url,createdAt,updatedAt 2>&1)

    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    else
        echo "{}" >&2
        return 1
    fi
}

# Get PR information
# Usage: gh_get_pr "pr_number"
gh_get_pr() {
    local pr_number="$1"
    local result

    result=$(gh pr view "$pr_number" \
        --json number,title,state,body,author,url,createdAt,updatedAt,baseRefName,headRefName,mergeable 2>&1)

    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    else
        echo "{}" >&2
        return 1
    fi
}

# List issues with search
# Usage: gh_list_issues "search_query" limit
gh_list_issues() {
    local query="$1"
    local limit="${2:-10}"
    local result

    result=$(gh issue list \
        --search "$query" \
        --json number,title,state,author,url,updatedAt \
        --limit "$limit" 2>&1)

    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    else
        echo "[]" >&2
        return 1
    fi
}

# List PRs with search
# Usage: gh_list_prs "search_query" limit
gh_list_prs() {
    local query="$1"
    local limit="${2:-10}"
    local result

    result=$(gh pr list \
        --search "$query" \
        --json number,title,state,author,url,updatedAt,headRefName \
        --limit "$limit" 2>&1)

    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    else
        echo "[]" >&2
        return 1
    fi
}

# Get PR for a branch
# Usage: gh_get_pr_for_branch "branch_name"
gh_get_pr_for_branch() {
    local branch="$1"
    local result

    result=$(gh pr list \
        --head "$branch" \
        --json number,title,state,url \
        --limit 1 2>&1)

    if [ $? -eq 0 ] && [ "$result" != "[]" ]; then
        echo "$result" | jq '.[0]'
        return 0
    else
        echo "null" >&2
        return 1
    fi
}

# Check if branch exists locally
# Usage: if branch_exists_local "branch_name"; then ...
branch_exists_local() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/$branch"
}

# Check if branch exists remotely
# Usage: if branch_exists_remote "branch_name"; then ...
branch_exists_remote() {
    local branch="$1"
    git show-ref --verify --quiet "refs/remotes/origin/$branch"
}

# Get branch status
# Usage: gh_get_branch_status "branch_name"
gh_get_branch_status() {
    local branch="$1"
    local exists_local exists_remote pr_info

    exists_local="false"
    exists_remote="false"

    if branch_exists_local "$branch"; then
        exists_local="true"
    fi

    if branch_exists_remote "$branch"; then
        exists_remote="true"
    fi

    pr_info=$(gh_get_pr_for_branch "$branch" 2>/dev/null || echo "null")

    jq -n \
        --arg branch "$branch" \
        --argjson local "$exists_local" \
        --argjson remote "$exists_remote" \
        --argjson pr "$pr_info" \
        '{
            branch: {
                name: $branch,
                status: {
                    existsLocally: $local,
                    existsRemotely: $remote
                },
                associatedPR: $pr
            }
        }'
}
