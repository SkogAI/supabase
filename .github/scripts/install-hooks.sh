#!/bin/bash
# install-hooks.sh - Install git hooks for worktree validation
#
# Usage: .github/scripts/install-hooks.sh

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Installing Git Hooks${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Get the root directory of the repository
REPO_ROOT=$(git rev-parse --show-toplevel)

# Check if we're in a git repository
if [ ! -d "$REPO_ROOT/.git" ]; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$REPO_ROOT/.git/hooks"

# Install pre-push hook
if [ -f "$REPO_ROOT/.github/hooks/pre-push" ]; then
    echo -e "${BLUE}Installing pre-push hook...${NC}"
    
    # Check if hook already exists
    if [ -f "$REPO_ROOT/.git/hooks/pre-push" ]; then
        echo -e "${YELLOW}⚠ Pre-push hook already exists${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Skipping pre-push hook${NC}"
        else
            cp "$REPO_ROOT/.github/hooks/pre-push" "$REPO_ROOT/.git/hooks/pre-push"
            chmod +x "$REPO_ROOT/.git/hooks/pre-push"
            echo -e "${GREEN}✓ Pre-push hook installed${NC}"
        fi
    else
        cp "$REPO_ROOT/.github/hooks/pre-push" "$REPO_ROOT/.git/hooks/pre-push"
        chmod +x "$REPO_ROOT/.git/hooks/pre-push"
        echo -e "${GREEN}✓ Pre-push hook installed${NC}"
    fi
else
    echo -e "${RED}Error: Pre-push hook template not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "${BLUE}What's next?${NC}"
echo "  • The pre-push hook will run automatically before every push"
echo "  • It validates your changes using CI checks"
echo "  • To bypass (not recommended): git push --no-verify"
echo ""
echo -e "${BLUE}Test the hook:${NC}"
echo "  .github/scripts/ci-worktree.sh"
echo ""
echo -e "${BLUE}Uninstall:${NC}"
echo "  rm .git/hooks/pre-push"
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# Find git root
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

print_header "Installing Git Hooks"

# Check if hooks directory exists
HOOKS_SOURCE=".github/hooks"
HOOKS_DEST=".git/hooks"

if [ ! -d "$HOOKS_SOURCE" ]; then
    print_error "Hooks source directory not found: $HOOKS_SOURCE"
    exit 1
fi

if [ ! -d "$HOOKS_DEST" ]; then
    print_error "Git hooks directory not found: $HOOKS_DEST"
    print_info "Are you in a git repository?"
    exit 1
fi

# Install each hook
HOOKS_INSTALLED=0
HOOKS_SKIPPED=0

for hook_file in "$HOOKS_SOURCE"/*; do
    if [ -f "$hook_file" ]; then
        hook_name=$(basename "$hook_file")
        dest_file="$HOOKS_DEST/$hook_name"
        
        # Check if hook already exists
        if [ -f "$dest_file" ]; then
            # Check if it's the same file
            if cmp -s "$hook_file" "$dest_file"; then
                print_info "$hook_name already installed (up to date)"
                ((HOOKS_SKIPPED++))
                continue
            else
                # Backup existing hook
                backup_file="${dest_file}.backup-$(date +%Y%m%d-%H%M%S)"
                cp "$dest_file" "$backup_file"
                print_warning "$hook_name exists - backed up to $(basename $backup_file)"
            fi
        fi
        
        # Copy and make executable
        cp "$hook_file" "$dest_file"
        chmod +x "$dest_file"
        print_success "Installed $hook_name"
        ((HOOKS_INSTALLED++))
    fi
done

echo ""
echo "Hooks Installed: $HOOKS_INSTALLED"
echo "Hooks Skipped:   $HOOKS_SKIPPED"
echo ""

if [ $HOOKS_INSTALLED -gt 0 ]; then
    print_success "Git hooks installed successfully!"
    echo ""
    print_info "The following hooks are now active:"
    for hook_file in "$HOOKS_DEST"/*; do
        if [ -f "$hook_file" ] && [ -x "$hook_file" ]; then
            hook_name=$(basename "$hook_file")
            # Skip sample hooks
            if [[ ! "$hook_name" =~ \.sample$ ]]; then
                echo "  - $hook_name"
            fi
        fi
    done
    echo ""
    print_info "To bypass hooks during commit/push, use --no-verify flag"
else
    print_info "No new hooks to install"
fi

echo ""
