#!/usr/bin/env bash

set -e
# @env WORKTREE_BASE=/home/skogix/dev/supabase/.dev/worktrees
# @env PARSE_TEMPLATE=/home/skogix/dev/supabase/.github/sparse-checkouts/default.txt

# @cmd skogix test
# @arg name!  Name of the new worktree
skogix() {
  # Step 1: Build the worktree path
  local WORKTREE_PATH="${WORKTREE_BASE}/${argc_name}"
  # Step 2: Create worktree and checkout branch
  git worktree add "$WORKTREE_PATH" -b "${argc_name}"
  # Step 3: Change into the worktree
  cd "$WORKTREE_PATH"
  # Step 4: Enable sparse-checkout mode
  git sparse-checkout init --no-cone
  # Step 5: Apply sparse-checkout rules (PARSE_TEMPLATE must be absolute path)
  git sparse-checkout set --no-cone --stdin <"$PARSE_TEMPLATE"
  # Step 6: Re-read the working tree to apply sparse-checkout
  git checkout
}

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
