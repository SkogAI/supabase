#!/usr/bin/env bash

# Configuration
WORKTREE_BASE="${WORKTREE_BASE:-/home/skogix/dev/supabase/.dev/worktree}"
PARSE_TEMPLATE="${PARSE_TEMPLATE:-/home/skogix/dev/supabase/.github/sparse-checkouts/default.txt}"

# Ensure worktree base exists
mkdir -p "$WORKTREE_BASE"

# Check sparse template exists
[ ! -f "$PARSE_TEMPLATE" ] && echo "Error: Template not found" && exit 1

# Fetch all branches
git fetch --all --quiet

# Process branches
git branch -r | sed 's/^[[:space:]]*origin\///' | \
rg '(issue|pr|pull|bug|feature|fix|hotfix|patch|update|release|docs|test|refactor|style|perf|chore|build|ci|revert|claude|copilot).*[0-9]+' | \
while IFS= read -r branch; do
    [ "$branch" = "HEAD" ] || [[ "$branch" == *"HEAD"* ]] && continue

    worktree_path="${WORKTREE_BASE}/${branch}"
    [ -d "$worktree_path" ] && continue

    echo "Creating: $branch"
    git worktree add "$worktree_path" -b "$branch" "origin/${branch}" 2>/dev/null || \
    git worktree add "$worktree_path" "$branch" 2>/dev/null || continue

    (cd "$worktree_path" && \
     git sparse-checkout init --no-cone && \
     git sparse-checkout set --no-cone --stdin <"$PARSE_TEMPLATE" && \
     git checkout) || echo "Failed: $branch"
done

echo "Done. Worktrees in: $WORKTREE_BASE"
git worktree list