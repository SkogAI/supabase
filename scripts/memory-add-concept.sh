#!/bin/bash
# Add a new concept note to skogai memory system

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

# Usage
usage() {
    echo "Usage: $0 <concept-name>"
    echo ""
    echo "Creates a new concept note in skogai/concepts/"
    echo ""
    echo "Examples:"
    echo "  $0 \"My Concept\"          # Creates: My Concept.md"
    echo "  $0 my-concept             # Creates: my-concept.md"
    echo ""
    echo "The script will:"
    echo "  1. Create a new note with YAML frontmatter"
    echo "  2. Generate a permalink from the name"
    echo "  3. Open the file in your default editor (if \$EDITOR is set)"
    exit 1
}

# Check arguments
if [[ $# -lt 1 ]]; then
    usage
fi

CONCEPT_NAME="$1"
FILENAME="$SKOGAI_DIR/concepts/${CONCEPT_NAME}.md"

# Check if file already exists
if [[ -f "$FILENAME" ]]; then
    print_error "File already exists: $FILENAME"
    exit 1
fi

# Generate permalink (lowercase, replace spaces with hyphens)
PERMALINK=$(echo "$CONCEPT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Get current date
CURRENT_DATE=$(date +%Y-%m-%d)

# Create the file
cat > "$FILENAME" << EOF
---
title: $CONCEPT_NAME
type: note
permalink: concepts/$PERMALINK
tags:
  - concept
  - TODO-add-tags
---

# $CONCEPT_NAME

## Overview

Brief description of this concept.

## Core Concepts

- [concept] Key concept or principle
- [concept] Another important aspect

## Use Cases

- [use-case] When to use this
- [use-case] Common scenarios

## Best Practices

- [best-practice] Recommended approach
- [best-practice] Important guideline

## Relations

- part_of [[Project Architecture]]
- relates_to [[Other Concept]]
- documented_in [[Guide Name]]
EOF

print_success "Created concept note: $FILENAME"
print_info "Permalink: concepts/$PERMALINK"
echo ""
print_info "Next steps:"
echo "  1. Edit the file and add relevant observations"
echo "  2. Update the tags in the frontmatter"
echo "  3. Add WikiLinks to related concepts"
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
