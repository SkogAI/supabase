#!/bin/bash
# list-worktrees.sh - List all active worktrees

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_shared_utils.sh"

echo ""
print_header "Active worktrees"
git worktree list
echo ""
print_info "To remove a worktree: .github/scripts/remove-worktree.sh <worktree-name>"
print_info "To clean up merged worktrees: .github/scripts/cleanup-worktrees.sh --auto"
