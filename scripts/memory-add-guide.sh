#!/bin/bash
# Add a new guide note to skogai memory system

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory
SKOGAI_DIR="$(cd "$(dirname "$0")/../skogai" && pwd)"

# Helper functions
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

# Usage
usage() {
    echo "Usage: $0 <category> <guide-name>"
    echo ""
    echo "Creates a new guide note in skogai/guides/<category>/"
    echo ""
    echo "Existing categories:"
    ls -1 "$SKOGAI_DIR/guides" 2>/dev/null | sed 's/^/  - /'
    echo ""
    echo "Examples:"
    echo "  $0 mcp \"Setup Guide\"        # Creates: guides/mcp/Setup Guide.md"
    echo "  $0 saml saml-config          # Creates: guides/saml/saml-config.md"
    echo "  $0 new-cat \"My Guide\"       # Creates: guides/new-cat/My Guide.md"
    echo ""
    exit 1
}

# Check arguments
if [[ $# -lt 2 ]]; then
    usage
fi

CATEGORY="$1"
GUIDE_NAME="$2"
CATEGORY_DIR="$SKOGAI_DIR/guides/$CATEGORY"
FILENAME="$CATEGORY_DIR/${GUIDE_NAME}.md"

# Create category directory if it doesn't exist
if [[ ! -d "$CATEGORY_DIR" ]]; then
    print_warning "Category '$CATEGORY' doesn't exist, creating..."
    mkdir -p "$CATEGORY_DIR"
fi

# Check if file already exists
if [[ -f "$FILENAME" ]]; then
    print_error "File already exists: $FILENAME"
    exit 1
fi

# Generate permalink (lowercase, replace spaces with hyphens)
GUIDE_SLUG=$(echo "$GUIDE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
PERMALINK="guides/$CATEGORY/$GUIDE_SLUG"

# Get current date
CURRENT_DATE=$(date +%Y-%m-%d)

# Create the file
cat > "$FILENAME" << EOF
---
title: $GUIDE_NAME
type: guide
permalink: $PERMALINK
tags:
  - guide
  - $CATEGORY
  - TODO-add-tags
---

# $GUIDE_NAME

## Overview

Brief description of what this guide covers.

## Prerequisites

- [prereq] Requirement 1
- [prereq] Requirement 2

## Step-by-Step Instructions

### Step 1: Setup

- [step] First action to take
- [step] Configuration needed

### Step 2: Implementation

- [step] Main implementation steps
- [pattern] Code pattern to follow

### Step 3: Testing

- [testing] How to test this works
- [testing] Expected results

## Common Issues

- [issue] Problem that might occur
- [solution] How to resolve it

## Best Practices

- [best-practice] Recommended approach
- [best-practice] Important guideline

## Example

\`\`\`bash
# Example command or code
echo "Hello, World!"
\`\`\`

## Relations

- part_of [[Project Architecture]]
- implements [[Concept Name]]
- uses [[Tool or Service]]
EOF

print_success "Created guide: $FILENAME"
print_info "Category: $CATEGORY"
print_info "Permalink: $PERMALINK"
echo ""
print_info "Next steps:"
echo "  1. Edit the file and add step-by-step instructions"
echo "  2. Update the tags in the frontmatter"
echo "  3. Add code examples and screenshots if relevant"
echo "  4. Run: scripts/validate-memory.sh to check formatting"
echo ""

# Open in editor if EDITOR is set
if [[ -n "$EDITOR" ]]; then
    print_info "Opening in \$EDITOR..."
    "$EDITOR" "$FILENAME"
elif command -v code &> /dev/null; then
    print_info "Opening in VS Code..."
    code "$FILENAME"
elif command -v vim &> /dev/null; then
    print_info "Opening in vim..."
    vim "$FILENAME"
else
    print_info "Edit the file: $FILENAME"
fi
