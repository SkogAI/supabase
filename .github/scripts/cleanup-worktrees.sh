#!/bin/bash
# cleanup-worktrees.sh - Automated cleanup of merged worktrees
#
# Usage: ./cleanup-worktrees.sh [OPTIONS]
#
# Options:
#   --status      Show status of all worktrees (merged/unmerged)
#   --dry-run     Show what would be cleaned without actually cleaning
#   --auto        Auto-cleanup merged worktrees with confirmation
#   --force       Skip confirmation prompts (use with --auto)
#   --help        Show this help message

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKTREE_DIR=".dev/worktree"
DEFAULT_BASE_BRANCH="develop"
MASTER_BRANCH="master"
LOG_FILE=".dev/worktree-cleanup.log"

# Parse command line arguments
MODE="interactive"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --status)
            MODE="status"
            shift
            ;;
        --dry-run)
            MODE="dry-run"
            shift
            ;;
        --auto)
            MODE="auto"
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Automated cleanup of merged worktrees"
            echo ""
            echo "Options:"
            echo "  --status      Show status of all worktrees (merged/unmerged)"
            echo "  --dry-run     Show what would be cleaned without actually cleaning"
            echo "  --auto        Auto-cleanup merged worktrees with confirmation"
            echo "  --force       Skip confirmation prompts (use with --auto)"
            echo "  --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --status                 # List all worktrees with merge status"
            echo "  $0 --dry-run                # Preview what would be cleaned"
            echo "  $0                          # Interactive cleanup"
            echo "  $0 --auto                   # Auto-cleanup with confirmation"
            echo "  $0 --auto --force           # Auto-cleanup without confirmation"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Log function
log_action() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Print colored message
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Check if worktree directory exists
if [ ! -d "$WORKTREE_DIR" ]; then
    print_color "$YELLOW" "No worktree directory found at $WORKTREE_DIR"
    exit 0
fi

# Fetch latest from remote
print_color "$BLUE" "Fetching latest changes from remote..."
git fetch origin --prune 2>/dev/null || true
git fetch origin "$DEFAULT_BASE_BRANCH" "$MASTER_BRANCH" 2>/dev/null || true

# Check if base branches exist, fallback to main/master if needed
if ! git rev-parse --verify "origin/$DEFAULT_BASE_BRANCH" &>/dev/null; then
    if git rev-parse --verify "origin/main" &>/dev/null; then
        DEFAULT_BASE_BRANCH="main"
    elif git rev-parse --verify "origin/master" &>/dev/null; then
        DEFAULT_BASE_BRANCH="master"
    fi
fi

if ! git rev-parse --verify "origin/$MASTER_BRANCH" &>/dev/null; then
    if git rev-parse --verify "origin/main" &>/dev/null; then
        MASTER_BRANCH="main"
    fi
fi

# Get list of all worktrees (excluding main)
mapfile -t WORKTREES < <(git worktree list --porcelain | grep -E "^worktree " | cut -d' ' -f2 | grep "$WORKTREE_DIR" || true)

if [ ${#WORKTREES[@]} -eq 0 ]; then
    print_color "$YELLOW" "No worktrees found in $WORKTREE_DIR"
    exit 0
fi

# Arrays to store worktree info
declare -a MERGED_WORKTREES
declare -a MERGED_BRANCHES
declare -a UNMERGED_WORKTREES
declare -a UNMERGED_BRANCHES
declare -a DIRTY_WORKTREES
declare -a ORPHANED_WORKTREES

# Analyze each worktree
print_color "$BLUE" "Analyzing worktrees..."
echo ""

for worktree_path in "${WORKTREES[@]}"; do
    if [ ! -d "$worktree_path" ]; then
        # Worktree directory doesn't exist
        ORPHANED_WORKTREES+=("$worktree_path")
        continue
    fi
    
    # Get branch name for this worktree
    branch_name=$(cd "$worktree_path" && git branch --show-current 2>/dev/null || echo "")
    
    if [ -z "$branch_name" ]; then
        # Detached HEAD or other issue
        ORPHANED_WORKTREES+=("$worktree_path")
        continue
    fi
    
    # Check if worktree has uncommitted changes
    if git -C "$worktree_path" rev-parse --verify HEAD >/dev/null 2>&1; then
        if ! git -C "$worktree_path" diff-index --quiet HEAD -- 2>/dev/null; then
            DIRTY_WORKTREES+=("$worktree_path:$branch_name")
        fi
    fi
    
    # Determine base branch based on branch type
    if [[ "$branch_name" =~ ^hotfix/ ]]; then
        base_branch="$MASTER_BRANCH"
    else
        base_branch="$DEFAULT_BASE_BRANCH"
    fi
    
    # Check if branch is merged into its base
    if git branch --merged "origin/$base_branch" 2>/dev/null | grep -q "^[* ]*$branch_name$"; then
        MERGED_WORKTREES+=("$worktree_path")
        MERGED_BRANCHES+=("$branch_name")
    else
        UNMERGED_WORKTREES+=("$worktree_path")
        UNMERGED_BRANCHES+=("$branch_name")
    fi
done

# Display status
display_status() {
    echo ""
    print_color "$BLUE" "═══════════════════════════════════════════════════════════"
    print_color "$BLUE" "                  WORKTREE STATUS REPORT"
    print_color "$BLUE" "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Summary
    print_color "$GREEN" "Total worktrees: $((${#MERGED_WORKTREES[@]} + ${#UNMERGED_WORKTREES[@]} + ${#ORPHANED_WORKTREES[@]}))"
    print_color "$GREEN" "Merged (ready for cleanup): ${#MERGED_WORKTREES[@]}"
    print_color "$YELLOW" "Unmerged (active): ${#UNMERGED_WORKTREES[@]}"
    print_color "$RED" "Orphaned or invalid: ${#ORPHANED_WORKTREES[@]}"
    echo ""
    
    # Merged worktrees
    if [ ${#MERGED_WORKTREES[@]} -gt 0 ]; then
        print_color "$GREEN" "✓ MERGED WORKTREES (safe to remove):"
        for i in "${!MERGED_WORKTREES[@]}"; do
            worktree_path="${MERGED_WORKTREES[$i]}"
            branch_name="${MERGED_BRANCHES[$i]}"
            worktree_name=$(basename "$worktree_path")
            
            # Check if dirty
            if [[ " ${DIRTY_WORKTREES[@]} " =~ " ${worktree_path}:${branch_name} " ]]; then
                print_color "$YELLOW" "  ⚠ $worktree_name ($branch_name) [HAS UNCOMMITTED CHANGES]"
            else
                echo "  • $worktree_name ($branch_name)"
            fi
        done
        echo ""
    fi
    
    # Unmerged worktrees
    if [ ${#UNMERGED_WORKTREES[@]} -gt 0 ]; then
        print_color "$YELLOW" "○ UNMERGED WORKTREES (active development):"
        for i in "${!UNMERGED_WORKTREES[@]}"; do
            worktree_path="${UNMERGED_WORKTREES[$i]}"
            branch_name="${UNMERGED_BRANCHES[$i]}"
            worktree_name=$(basename "$worktree_path")
            
            # Check if dirty
            if [[ " ${DIRTY_WORKTREES[@]} " =~ " ${worktree_path}:${branch_name} " ]]; then
                echo "  • $worktree_name ($branch_name) [has uncommitted changes]"
            else
                echo "  • $worktree_name ($branch_name)"
            fi
        done
        echo ""
    fi
    
    # Orphaned worktrees
    if [ ${#ORPHANED_WORKTREES[@]} -gt 0 ]; then
        print_color "$RED" "✗ ORPHANED/INVALID WORKTREES:"
        for worktree_path in "${ORPHANED_WORKTREES[@]}"; do
            worktree_name=$(basename "$worktree_path")
            echo "  • $worktree_name"
        done
        echo ""
    fi
    
    print_color "$BLUE" "═══════════════════════════════════════════════════════════"
}

# Cleanup a worktree
cleanup_worktree() {
    local worktree_path="$1"
    local branch_name="$2"
    local worktree_name=$(basename "$worktree_path")
    
    print_color "$BLUE" "Cleaning up: $worktree_name ($branch_name)"
    
    # Remove worktree
    if git worktree remove "$worktree_path" 2>/dev/null; then
        print_color "$GREEN" "  ✓ Worktree removed"
        log_action "Removed worktree: $worktree_name"
    else
        # Try force remove if normal remove fails
        if git worktree remove --force "$worktree_path" 2>/dev/null; then
            print_color "$GREEN" "  ✓ Worktree force removed"
            log_action "Force removed worktree: $worktree_name"
        else
            print_color "$RED" "  ✗ Failed to remove worktree"
            return 1
        fi
    fi
    
    # Delete local branch
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        if git branch -D "$branch_name" 2>/dev/null; then
            print_color "$GREEN" "  ✓ Local branch deleted"
            log_action "Deleted local branch: $branch_name"
        else
            print_color "$YELLOW" "  ⚠ Failed to delete local branch"
        fi
    fi
    
    # Check if remote branch exists and offer to delete
    if git ls-remote --heads origin "$branch_name" 2>/dev/null | grep -q "$branch_name"; then
        print_color "$YELLOW" "  ℹ Remote branch still exists: $branch_name"
        print_color "$YELLOW" "    To delete: git push origin --delete $branch_name"
    fi
    
    echo ""
}

# Prune orphaned worktrees
prune_orphaned() {
    if [ ${#ORPHANED_WORKTREES[@]} -gt 0 ]; then
        print_color "$BLUE" "Pruning orphaned worktree references..."
        git worktree prune
        log_action "Pruned orphaned worktree references"
        print_color "$GREEN" "✓ Orphaned references pruned"
        echo ""
    fi
}

# Execute based on mode
case $MODE in
    status)
        display_status
        ;;
        
    dry-run)
        display_status
        echo ""
        print_color "$BLUE" "DRY RUN - No changes will be made"
        echo ""
        
        if [ ${#MERGED_WORKTREES[@]} -gt 0 ]; then
            print_color "$YELLOW" "Would clean up ${#MERGED_WORKTREES[@]} merged worktree(s):"
            for i in "${!MERGED_WORKTREES[@]}"; do
                worktree_path="${MERGED_WORKTREES[$i]}"
                branch_name="${MERGED_BRANCHES[$i]}"
                worktree_name=$(basename "$worktree_path")
                
                if [[ " ${DIRTY_WORKTREES[@]} " =~ " ${worktree_path}:${branch_name} " ]]; then
                    print_color "$RED" "  ✗ SKIP: $worktree_name ($branch_name) - has uncommitted changes"
                else
                    print_color "$GREEN" "  ✓ $worktree_name ($branch_name)"
                fi
            done
        else
            print_color "$GREEN" "No merged worktrees to clean up"
        fi
        
        if [ ${#ORPHANED_WORKTREES[@]} -gt 0 ]; then
            echo ""
            print_color "$YELLOW" "Would prune ${#ORPHANED_WORKTREES[@]} orphaned worktree reference(s)"
        fi
        ;;
        
    auto)
        display_status
        echo ""
        
        if [ ${#MERGED_WORKTREES[@]} -eq 0 ] && [ ${#ORPHANED_WORKTREES[@]} -eq 0 ]; then
            print_color "$GREEN" "✓ No worktrees need cleanup"
            exit 0
        fi
        
        # Count worktrees that can be safely cleaned
        safe_cleanup_count=0
        for i in "${!MERGED_WORKTREES[@]}"; do
            worktree_path="${MERGED_WORKTREES[$i]}"
            branch_name="${MERGED_BRANCHES[$i]}"
            if [[ ! " ${DIRTY_WORKTREES[@]} " =~ " ${worktree_path}:${branch_name} " ]]; then
                ((safe_cleanup_count++))
            fi
        done
        
        if [ $safe_cleanup_count -eq 0 ] && [ ${#ORPHANED_WORKTREES[@]} -eq 0 ]; then
            print_color "$YELLOW" "⚠ All merged worktrees have uncommitted changes. Skipping cleanup."
            exit 0
        fi
        
        # Confirmation prompt
        if [ "$FORCE" = false ]; then
            print_color "$YELLOW" "About to clean up $safe_cleanup_count merged worktree(s)"
            if [ ${#ORPHANED_WORKTREES[@]} -gt 0 ]; then
                print_color "$YELLOW" "and prune ${#ORPHANED_WORKTREES[@]} orphaned reference(s)"
            fi
            echo ""
            read -p "Continue? [y/N] " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_color "$YELLOW" "Cleanup cancelled"
                exit 0
            fi
        fi
        
        echo ""
        print_color "$GREEN" "Starting cleanup..."
        echo ""
        
        # Clean up merged worktrees
        for i in "${!MERGED_WORKTREES[@]}"; do
            worktree_path="${MERGED_WORKTREES[$i]}"
            branch_name="${MERGED_BRANCHES[$i]}"
            
            # Skip if has uncommitted changes
            if [[ " ${DIRTY_WORKTREES[@]} " =~ " ${worktree_path}:${branch_name} " ]]; then
                worktree_name=$(basename "$worktree_path")
                print_color "$YELLOW" "⚠ Skipping $worktree_name - has uncommitted changes"
                echo ""
                continue
            fi
            
            cleanup_worktree "$worktree_path" "$branch_name"
        done
        
        # Prune orphaned
        prune_orphaned
        
        print_color "$GREEN" "✓ Cleanup complete!"
        log_action "Auto cleanup completed"
        ;;
        
    interactive)
        display_status
        echo ""
        
        if [ ${#MERGED_WORKTREES[@]} -eq 0 ]; then
            if [ ${#ORPHANED_WORKTREES[@]} -gt 0 ]; then
                print_color "$YELLOW" "No merged worktrees, but found orphaned references."
                read -p "Prune orphaned references? [y/N] " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    prune_orphaned
                fi
            else
                print_color "$GREEN" "✓ No worktrees need cleanup"
            fi
            exit 0
        fi
        
        print_color "$BLUE" "Interactive cleanup mode"
        echo ""
        
        # Ask for each merged worktree
        for i in "${!MERGED_WORKTREES[@]}"; do
            worktree_path="${MERGED_WORKTREES[$i]}"
            branch_name="${MERGED_BRANCHES[$i]}"
            worktree_name=$(basename "$worktree_path")
            
            # Check if has uncommitted changes
            if [[ " ${DIRTY_WORKTREES[@]} " =~ " ${worktree_path}:${branch_name} " ]]; then
                print_color "$RED" "⚠ $worktree_name has uncommitted changes"
                read -p "Clean up anyway? [y/N] " -n 1 -r
            else
                print_color "$GREEN" "Clean up $worktree_name ($branch_name)?"
                read -p "[y/N] " -n 1 -r
            fi
            
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cleanup_worktree "$worktree_path" "$branch_name"
            else
                print_color "$YELLOW" "Skipped $worktree_name"
                echo ""
            fi
        done
        
        # Ask about orphaned
        if [ ${#ORPHANED_WORKTREES[@]} -gt 0 ]; then
            read -p "Prune ${#ORPHANED_WORKTREES[@]} orphaned reference(s)? [y/N] " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                prune_orphaned
            fi
        fi
        
        print_color "$GREEN" "✓ Interactive cleanup complete!"
        log_action "Interactive cleanup completed"
        ;;
esac

echo ""
print_color "$BLUE" "Tip: Use '.github/scripts/list-worktrees.sh' to see remaining worktrees"
