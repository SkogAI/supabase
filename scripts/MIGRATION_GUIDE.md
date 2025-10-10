# Migration Guide: Structured I/O Architecture

This guide explains how to migrate Claude workflow scripts to the new structured I/O architecture.

## Overview

The structured I/O architecture provides:

1. **Shared libraries** - Eliminate duplicated code across scripts
2. **JSON output** - Machine-readable output for composability
3. **Standardized errors** - Typed error handling with context
4. **Multiple formats** - Support JSON, human, compact, and table output
5. **Type safety** - JSON schemas define all data structures

## Migration Status

### ✅ Migrated Scripts

- **`claude-quick`** - Reference implementation with full structured I/O support

### 🔄 Pending Migration

Priority order (from proposal):

1. `claude-status` - Complex aggregation, high value
2. `claude-watch` - Real-time updates
3. `auto-create-pr` - Programmatic usage
4. `check-mergeable` - Temp file patterns
5. `claude-issue` - Simple create operation
6. `claude-on-issue` - Event handler
7. `claude-pr` - PR creation
8. `claude-on-pr` - PR event handler
9. `claude-sync` - Sync operations
10. `claude-cleanup` - Cleanup operations

## Step-by-Step Migration

### 1. Add Library Imports

Replace individual environment checks with shared library imports:

**Before:**
```bash
#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi
```

**After:**
```bash
#!/usr/bin/env bash
set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared libraries
source "$SCRIPT_DIR/lib/context.sh"
source "$SCRIPT_DIR/lib/result.sh"
source "$SCRIPT_DIR/lib/format.sh"
source "$SCRIPT_DIR/lib/gh-api.sh"
```

### 2. Add Format Flag Support

Add argument parsing for `--format` flag:

```bash
# Parse command-line arguments
FORMAT="auto"
DESCRIPTION=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --format=*)
                FORMAT="${1#*=}"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                DESCRIPTION="$*"
                break
                ;;
        esac
    done
}

# Add to main()
parse_args "$@"
```

### 3. Use Context API

Replace manual context gathering with the context API:

**Before:**
```bash
CURRENT_BRANCH=$(git branch --show-current)
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

**After:**
```bash
# Get context
ctx=$(get_context)
if [ $? -ne 0 ]; then
    result=$(error_result "get_context" "Failed to initialize context" "environment")
    format_output "$result" "$FORMAT"
    exit 1
fi

# Extract fields
CURRENT_BRANCH=$(echo "$ctx" | jq -r '.context.git.currentBranch')
REPO=$(echo "$ctx" | jq -r '.context.repository.fullName')
```

### 4. Use GitHub API Wrappers

Replace raw `gh` commands with structured API wrappers:

**Before:**
```bash
gh issue create --title "$TITLE" --body "$BODY"
echo "✓ Issue created!"
```

**After:**
```bash
# Create issue
issue_data=$(gh_create_issue "$TITLE" "$BODY")

if [ $? -eq 0 ]; then
    result=$(success_result "create_issue" "$issue_data")
    format_output "$result" "$FORMAT"
else
    result=$(error_result "create_issue" "Failed to create issue" "network")
    format_output "$result" "$FORMAT"
    exit 1
fi
```

### 5. Use Result Objects

Wrap all operations in standardized result objects:

**Success:**
```bash
result=$(success_result "operation_name" '{"key": "value"}')
format_output "$result" "$FORMAT"
```

**Error:**
```bash
result=$(error_result "operation_name" "Error message" "error_type")
format_output "$result" "$FORMAT"
exit 1
```

**With Warning:**
```bash
result=$(success_result "operation_name" "$data")
result=$(echo "$result" | add_warning "Warning message")
format_output "$result" "$FORMAT"
```

### 6. Format Output

Use the format API for all output:

**Before:**
```bash
echo -e "${GREEN}✓ Success!${NC}"
echo "URL: $URL"
```

**After:**
```bash
# Structured output (handles JSON/human automatically)
format_output "$result" "$FORMAT"

# Or for simple messages
format_success "Operation completed"
format_error "Something went wrong" "error"
format_info "FYI: This is informational"
```

## Common Patterns

### Pattern 1: Simple Create Operation

```bash
main() {
    parse_args "$@"

    # Get context
    ctx=$(get_context) || {
        result=$(error_result "get_context" "Failed to initialize" "environment")
        format_output "$result" "$FORMAT"
        exit 1
    }

    # Perform operation
    data=$(gh_create_issue "$TITLE" "$BODY")

    if [ $? -eq 0 ]; then
        result=$(success_result "create_issue" "$data")
        format_output "$result" "$FORMAT"
    else
        result=$(error_result "create_issue" "Failed" "network")
        format_output "$result" "$FORMAT"
        exit 1
    fi
}
```

### Pattern 2: List/Status Operation

```bash
main() {
    parse_args "$@"

    ctx=$(get_context) || exit 1

    # Get list data
    issues=$(gh_list_issues "@claude" 10)

    # Format as array result
    result=$(success_result "list_issues" "$issues")
    format_output "$result" "$FORMAT"
}
```

### Pattern 3: Conditional Logic with Warnings

```bash
main() {
    parse_args "$@"

    ctx=$(get_context) || exit 1

    BRANCH=$(echo "$ctx" | jq -r '.context.git.currentBranch')

    if [ "$BRANCH" = "main" ]; then
        # Add warning
        result=$(success_result "operation" "$data")
        result=$(echo "$result" | add_warning "Running on main branch")
        format_output "$result" "$FORMAT"
    else
        result=$(success_result "operation" "$data")
        format_output "$result" "$FORMAT"
    fi
}
```

## Error Types

Use appropriate error types for better error handling:

- **`general`** - Generic error (default)
- **`network`** - Network/API failures
- **`validation`** - Invalid input or state
- **`conflict`** - Merge conflicts, branch conflicts
- **`permission`** - Authorization/permission errors
- **`not_found`** - Resource not found

```bash
result=$(error_result "operation" "Branch not found" "not_found")
```

## Testing Your Migration

After migration, test all output formats:

```bash
# Human output (TTY)
./claude-script "test"

# JSON output
./claude-script --format=json "test"

# Compact JSON
./claude-script --format=compact "test" | jq '.result.success'

# Verify backward compatibility
./claude-script "test" 2>&1 | grep "✓"
```

## Checklist

- [ ] Replace color definitions with `source lib/colors.sh`
- [ ] Replace environment checks with `get_context()`
- [ ] Add `--format` flag parsing
- [ ] Replace `gh` commands with `gh-api.sh` wrappers
- [ ] Wrap operations in `success_result()` / `error_result()`
- [ ] Use `format_output()` for all output
- [ ] Add appropriate error types
- [ ] Test all output formats
- [ ] Verify backward compatibility
- [ ] Update help text with format options

## Need Help?

- See `scripts/claude-quick` for complete reference implementation
- Check `scripts/lib/*.sh` for API documentation
- Review `scripts/schemas/*.json` for data structure definitions
- Open an issue if you have questions

## Benefits After Migration

✅ **Less code** - No duplicated environment checks or formatting
✅ **Better errors** - Typed errors with context
✅ **Composable** - Scripts can pipe data to each other
✅ **Testable** - Mock structured data instead of parsing text
✅ **Extensible** - Easy to add new output formats
✅ **Consistent** - All scripts follow same patterns
