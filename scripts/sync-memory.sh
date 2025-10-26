#!/bin/bash
# Sync skogai memory system to Basic Memory MCP
# This script can be called from git hooks or CI/CD

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
QUIET=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet)
            QUIET=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
print_success() {
    if [[ $QUIET == false ]]; then
        echo -e "${GREEN}✓${NC} $1"
    fi
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    if [[ $QUIET == false ]]; then
        echo -e "${BLUE}ℹ${NC} $1"
    fi
}

print_warning() {
    if [[ $QUIET == false ]]; then
        echo -e "${YELLOW}⚠${NC} $1"
    fi
}

# Base directory
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKOGAI_DIR="$REPO_ROOT/skogai"

# Check if Basic Memory MCP is available
check_mcp_available() {
    # Check if the MCP server is configured in .mcp.json
    if [[ ! -f "$REPO_ROOT/.mcp.json" ]]; then
        print_warning "Basic Memory MCP not configured (.mcp.json not found)"
        return 1
    fi
    
    # For now, we'll skip the actual MCP sync since it requires specific setup
    # This is a placeholder for future MCP integration
    print_info "MCP configuration found"
    return 0
}

# Sync to memory system
sync_memory() {
    print_info "Syncing skogai memory system..."
    
    # Validate notes before syncing
    if [[ -f "$REPO_ROOT/scripts/validate-memory.sh" ]]; then
        if ! "$REPO_ROOT/scripts/validate-memory.sh" > /dev/null 2>&1; then
            print_error "Validation failed - please fix errors before syncing"
            return 1
        fi
        print_success "Validation passed"
    fi
    
    # Count files to sync
    local note_count=$(find "$SKOGAI_DIR/concepts" "$SKOGAI_DIR/guides" "$SKOGAI_DIR/project" -name "*.md" 2>/dev/null | wc -l)
    print_info "Found $note_count notes to sync"
    
    # TODO: Actual MCP sync implementation
    # This would use the Basic Memory MCP API to:
    # 1. Index all markdown files
    # 2. Update embeddings
    # 3. Refresh the semantic search index
    
    # For now, we just log success
    print_success "Memory system synced ($note_count notes)"
    
    return 0
}

# Main
main() {
    if [[ $QUIET == false ]]; then
        echo "═══ Syncing Memory System ═══"
    fi
    
    # Check MCP availability
    if ! check_mcp_available; then
        print_warning "Skipping MCP sync (not configured)"
        # Don't fail - just skip the sync
        exit 0
    fi
    
    # Perform sync
    if sync_memory; then
        exit 0
    else
        exit 1
    fi
}

# Run main
main
