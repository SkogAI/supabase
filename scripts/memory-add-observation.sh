#!/bin/bash
# Quick helper to add an observation to an existing note

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
    echo "Usage: $0"
    echo ""
    echo "Interactive tool to add observations to existing notes."
    echo ""
    echo "This script will:"
    echo "  1. List all available notes"
    echo "  2. Let you select one"
    echo "  3. Show common observation tag types"
    echo "  4. Add your observation to the file"
    echo ""
    echo "For observation tag reference, see: skogai/OBSERVATION_TEMPLATES.md"
    exit 1
}

# List all notes
list_notes() {
    local notes=()
    local i=1
    
    echo ""
    echo "Available notes:"
    echo ""
    
    # Concepts
    echo -e "${BLUE}Concepts:${NC}"
    while IFS= read -r file; do
        local title=$(grep "^title:" "$file" | sed 's/title: *//')
        echo "  $i. $title"
        notes+=("$file")
        ((i++))
    done < <(find "$SKOGAI_DIR/concepts" -name "*.md" | sort)
    
    # Guides
    echo ""
    echo -e "${BLUE}Guides:${NC}"
    while IFS= read -r file; do
        local title=$(grep "^title:" "$file" | sed 's/title: *//')
        local category=$(dirname "$file" | xargs basename)
        echo "  $i. [$category] $title"
        notes+=("$file")
        ((i++))
    done < <(find "$SKOGAI_DIR/guides" -name "*.md" | sort)
    
    # Project
    echo ""
    echo -e "${BLUE}Project:${NC}"
    while IFS= read -r file; do
        local title=$(grep "^title:" "$file" | sed 's/title: *//')
        echo "  $i. $title"
        notes+=("$file")
        ((i++))
    done < <(find "$SKOGAI_DIR/project" -name "*.md" | sort)
    
    echo ""
    
    # Return the notes array (store in a temp file)
    for note in "${notes[@]}"; do
        echo "$note"
    done > /tmp/skogai_notes_list.tmp
}

# Show common tags
show_common_tags() {
    echo ""
    echo -e "${BLUE}Common observation tags:${NC}"
    echo ""
    echo "  Technical: [best-practice] [security] [pattern] [testing] [optimization]"
    echo "  Features:  [feature] [config] [component] [integration]"
    echo "  Problems:  [issue] [solution] [workflow] [troubleshooting]"
    echo "  Design:    [concept] [use-case] [design] [principle]"
    echo "  Operations: [monitoring] [metric] [automation] [maintenance]"
    echo ""
    echo "For full reference, see: skogai/OBSERVATION_TEMPLATES.md"
    echo ""
}

# Main interactive flow
main() {
    print_info "Interactive Observation Helper"
    
    # List notes
    list_notes
    
    # Get user selection
    read -p "Select note number (or 'q' to quit): " selection
    
    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Load notes list
    local notes=()
    while IFS= read -r note; do
        notes+=("$note")
    done < /tmp/skogai_notes_list.tmp
    
    # Validate selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ $selection -lt 1 || $selection -gt ${#notes[@]} ]]; then
        print_error "Invalid selection: $selection"
        exit 1
    fi
    
    # Get selected file
    local selected_file="${notes[$((selection-1))]}"
    local title=$(grep "^title:" "$selected_file" | sed 's/title: *//')
    
    print_success "Selected: $title"
    print_info "File: $(basename "$selected_file")"
    
    # Show common tags
    show_common_tags
    
    # Get observation tag
    read -p "Observation tag (e.g., best-practice): " tag
    
    if [[ -z "$tag" ]]; then
        print_error "Tag cannot be empty"
        exit 1
    fi
    
    # Get observation text
    echo ""
    print_info "Enter observation text (press Enter when done):"
    read -p "> " observation_text
    
    if [[ -z "$observation_text" ]]; then
        print_error "Observation text cannot be empty"
        exit 1
    fi
    
    # Format the observation
    local formatted_obs="- [$tag] $observation_text"
    
    # Preview
    echo ""
    print_info "Preview:"
    echo "  $formatted_obs"
    echo ""
    read -p "Add this observation? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Add to file (append before the Relations section if it exists, otherwise at the end)
    if grep -q "^## Relations" "$selected_file"; then
        # Insert before Relations section
        sed -i "/^## Relations/i $formatted_obs\n" "$selected_file"
    else
        # Append to end of file
        echo "" >> "$selected_file"
        echo "$formatted_obs" >> "$selected_file"
    fi
    
    print_success "Added observation to $title"
    print_info "Run 'scripts/validate-memory.sh' to validate"
    
    # Cleanup
    rm -f /tmp/skogai_notes_list.tmp
}

# Run main
main
