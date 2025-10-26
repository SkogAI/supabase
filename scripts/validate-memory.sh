#!/bin/bash
# Validate skogai memory system
# Checks YAML frontmatter, required fields, and observation format

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0
WARNINGS=0
ERRORS=0

# Base directory
SKOGAI_DIR="$(cd "$(dirname "$0")/../skogai" && pwd)"

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══${NC} $1"
}

# Validate YAML frontmatter
validate_yaml() {
    local file="$1"
    local first_line=$(head -1 "$file")
    
    if [[ "$first_line" != "---" ]]; then
        print_error "$(basename "$file"): Missing YAML frontmatter (must start with ---)"
        return 1
    fi
    
    # Check if there's a closing ---
    if ! tail -n +2 "$file" | head -20 | grep -q "^---$"; then
        print_error "$(basename "$file"): Unclosed YAML frontmatter (missing closing ---)"
        return 1
    fi
    
    return 0
}

# Validate required fields
validate_required_fields() {
    local file="$1"
    local errors=0
    
    # Extract frontmatter (first 30 lines, between --- markers)
    local frontmatter=$(head -30 "$file" | awk '/^---$/{if(++count==2) exit}count==1')
    
    # Check for required fields
    if ! echo "$frontmatter" | grep -q "^title:"; then
        print_error "$(basename "$file"): Missing required field 'title'"
        ((errors++))
    fi
    
    if ! echo "$frontmatter" | grep -q "^permalink:"; then
        print_error "$(basename "$file"): Missing required field 'permalink'"
        ((errors++))
    fi
    
    if ! echo "$frontmatter" | grep -q "^tags:"; then
        print_error "$(basename "$file"): Missing required field 'tags'"
        ((errors++))
    fi
    
    # Check type field (optional but recommended)
    if ! echo "$frontmatter" | grep -q "^type:"; then
        print_warning "$(basename "$file"): Missing optional field 'type' (recommended)"
    fi
    
    return $errors
}

# Validate a single file
validate_file() {
    local file="$1"
    local file_errors=0
    
    ((TOTAL_FILES++))
    
    # Run validations
    validate_yaml "$file" || ((file_errors++))
    validate_required_fields "$file" || ((file_errors++))
    
    if [[ $file_errors -eq 0 ]]; then
        ((PASSED_FILES++))
        print_success "$(basename "$file")"
        return 0
    else
        ((FAILED_FILES++))
        return 1
    fi
}

# Main validation
main() {
    print_section "Validating skogai Memory System"
    
    print_info "Scanning $SKOGAI_DIR for semantic notes..."
    echo ""
    
    # Find and validate all markdown files
    while IFS= read -r file; do
        validate_file "$file"
    done < <(find "$SKOGAI_DIR/concepts" "$SKOGAI_DIR/guides" "$SKOGAI_DIR/project" -name "*.md" 2>/dev/null | sort)
    
    if [[ $TOTAL_FILES -eq 0 ]]; then
        print_error "No semantic notes found in $SKOGAI_DIR"
        exit 1
    fi
    
    # Print summary
    print_section "Validation Summary"
    echo ""
    echo "Total files:    $TOTAL_FILES"
    echo -e "Passed:         ${GREEN}$PASSED_FILES${NC}"
    if [[ $FAILED_FILES -gt 0 ]]; then
        echo -e "Failed:         ${RED}$FAILED_FILES${NC}"
    else
        echo "Failed:         $FAILED_FILES"
    fi
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "Warnings:       ${YELLOW}$WARNINGS${NC}"
    else
        echo "Warnings:       $WARNINGS"
    fi
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "Errors:         ${RED}$ERRORS${NC}"
    else
        echo "Errors:         $ERRORS"
    fi
    echo ""
    
    # Exit with appropriate code
    if [[ $FAILED_FILES -gt 0 || $ERRORS -gt 0 ]]; then
        print_error "Validation failed"
        exit 1
    else
        print_success "All files passed validation!"
        exit 0
    fi
}

# Run main
main
