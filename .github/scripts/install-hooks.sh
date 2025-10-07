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
