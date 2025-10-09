#!/usr/bin/env bash

set -e

# @cmd Create GitHub issue with @claude mention
# @arg description!  Issue title/description
issue() {
    scripts/claude-issue "$argc_description"
}

# @cmd Add @claude comment to existing issue
# @arg issue_number!  Issue number
# @arg task!          Task description
on-issue() {
    scripts/claude-on-issue "$argc_issue_number" "$argc_task"
}

# @cmd Create PR from current branch with @claude mention
# @arg description!  Task description for Claude
pr() {
    scripts/claude-pr "$argc_description"
}

# @cmd Add @claude comment to existing PR
# @arg pr_number!  PR number
# @arg task!       Task description
on-pr() {
    scripts/claude-on-pr "$argc_pr_number" "$argc_task"
}

# @cmd View Claude activity status
status() {
    scripts/claude-status
}

# @cmd Smart wrapper: creates issue OR PR based on git state
# @arg description!  Task description
quick() {
    scripts/claude-quick "$argc_description"
}

# @cmd Auto-create PR for current Claude branch
auto-pr() {
    scripts/auto-create-pr
}

# @cmd Sync all claude/* branches with main/master
sync() {
    scripts/claude-sync
}

# @cmd Delete merged claude/* branches locally and remotely
cleanup() {
    scripts/claude-cleanup
}

# @cmd Monitor workflow runs with real-time updates
# @option --logs  Follow job logs after completion
# @option --compact  Use compact output mode
# @arg run_id  Specific workflow run ID to watch
watch() {
    local args=()
    if [ -n "${argc_logs:-}" ]; then
        args+=("--logs")
    fi
    if [ -n "${argc_compact:-}" ]; then
        args+=("--compact")
    fi
    if [ -n "${argc_run_id:-}" ]; then
        args+=("$argc_run_id")
    fi
    scripts/claude-watch "${args[@]}"
}

# @cmd Run linting and testing checks
lint-and-test() {
    scripts/lint-and-test
}

# @cmd Check PR mergeability and call @claude to resolve
check-mergeable() {
    scripts/check-mergeable
}

eval "$(argc --argc-eval "$0" "$@")"
