#!/bin/bash
# Generate coverage report for skogai memory system
# Shows what's documented and what might be missing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base directory
SKOGAI_DIR="$(cd "$(dirname "$0")/../skogai" && pwd)"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
}

print_stat() {
    echo -e "${BLUE}$1:${NC} $2"
}

# Count observations by tag type
count_observations() {
    grep -h "^- \[" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | \
        sed 's/- \[\([^]]*\)\].*/\1/' | \
        sort | uniq -c | sort -rn
}

# Count notes by directory
count_notes_by_type() {
    echo "Concepts:  $(find "$SKOGAI_DIR/concepts" -name "*.md" 2>/dev/null | wc -l)"
    echo "Guides:    $(find "$SKOGAI_DIR/guides" -name "*.md" 2>/dev/null | wc -l)"
    echo "Project:   $(find "$SKOGAI_DIR/project" -name "*.md" 2>/dev/null | wc -l)"
}

# Count total observations
count_total_observations() {
    grep -h "^- \[" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l
}

# Count WikiLinks
count_wikilinks() {
    grep -oh '\[\[[^]]*\]\]' "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | \
        sed 's/\[\[\(.*\)\]\]/\1/' | \
        sort -u | wc -l
}

# Count total words in all notes
count_total_words() {
    find "$SKOGAI_DIR/concepts" "$SKOGAI_DIR/guides" "$SKOGAI_DIR/project" -name "*.md" -exec wc -w {} + 2>/dev/null | \
        tail -1 | awk '{print $1}'
}

# List top tags
list_top_tags() {
    count_observations | head -15
}

# Check what scripts are documented
check_script_coverage() {
    local total_scripts=$(find "$REPO_ROOT/scripts" -name "*.sh" -type f 2>/dev/null | wc -l)
    local documented_scripts=0
    
    # Check if scripts are mentioned in notes
    while IFS= read -r script; do
        local script_name=$(basename "$script")
        if grep -rq "$script_name" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null; then
            ((documented_scripts++))
        fi
    done < <(find "$REPO_ROOT/scripts" -name "*.sh" -type f 2>/dev/null)
    
    echo "$documented_scripts/$total_scripts"
}

# Check what migrations are documented
check_migration_coverage() {
    local total_migrations=$(find "$REPO_ROOT/supabase/migrations" -name "*.sql" 2>/dev/null | wc -l)
    local documented_migrations=$(grep -r "migration" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)
    
    if [[ $documented_migrations -gt 0 ]]; then
        echo "Referenced: $documented_migrations mentions"
    else
        echo "0 mentions"
    fi
}

# Check what tests are documented
check_test_coverage() {
    local total_tests=$(find "$REPO_ROOT/tests" -name "*.sql" 2>/dev/null | wc -l)
    local documented_tests=0
    
    while IFS= read -r test; do
        local test_name=$(basename "$test")
        if grep -rq "$test_name" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null; then
            ((documented_tests++))
        fi
    done < <(find "$REPO_ROOT/tests" -name "*.sql" 2>/dev/null)
    
    echo "$documented_tests/$total_tests"
}

# Main report
main() {
    print_section "skogai Memory System Coverage Report"
    date
    
    print_section "Overall Statistics"
    echo ""
    print_stat "Total Notes" "$(find "$SKOGAI_DIR/concepts" "$SKOGAI_DIR/guides" "$SKOGAI_DIR/project" -name "*.md" 2>/dev/null | wc -l)"
    print_stat "Total Observations" "$(count_total_observations)"
    print_stat "Unique WikiLinks" "$(count_wikilinks)"
    print_stat "Total Words" "$(count_total_words)"
    echo ""
    
    print_section "Notes by Type"
    echo ""
    count_notes_by_type
    echo ""
    
    print_section "Top 15 Observation Tags"
    echo ""
    list_top_tags
    echo ""
    
    print_section "Repository Coverage"
    echo ""
    print_stat "Scripts Documented" "$(check_script_coverage)"
    print_stat "Migrations Mentioned" "$(check_migration_coverage)"
    print_stat "Tests Documented" "$(check_test_coverage)"
    echo ""
    
    print_section "Tag Categories"
    echo ""
    echo "Technical Implementation:"
    print_stat "  best-practice" "$(grep -h "^- \[best-practice\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    print_stat "  security" "$(grep -h "^- \[security\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    print_stat "  pattern" "$(grep -h "^- \[pattern\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    print_stat "  testing" "$(grep -h "^- \[testing\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    echo ""
    echo "Features & Capabilities:"
    print_stat "  feature" "$(grep -h "^- \[feature\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    print_stat "  config" "$(grep -h "^- \[config\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    print_stat "  component" "$(grep -h "^- \[component\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    echo ""
    echo "Problem Solving:"
    print_stat "  issue" "$(grep -h "^- \[issue\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    print_stat "  solution" "$(grep -h "^- \[solution\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    print_stat "  workflow" "$(grep -h "^- \[workflow\]" "$SKOGAI_DIR"/concepts/*.md "$SKOGAI_DIR"/guides/*/*.md "$SKOGAI_DIR"/project/*.md 2>/dev/null | wc -l)"
    echo ""
    
    print_section "Quick Reference"
    echo ""
    echo "Add new note:        scripts/memory-add-concept.sh <name>"
    echo "Add observation:     Edit note and add: - [tag] Your observation"
    echo "Validate notes:      scripts/validate-memory.sh"
    echo "Update coverage:     scripts/generate-coverage-report.sh"
    echo ""
    
    print_success "Coverage report complete!"
}

# Run main
main
