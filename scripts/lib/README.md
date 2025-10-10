# Shared Libraries for Claude Workflow Scripts

This directory contains shared libraries used by all Claude workflow scripts to provide consistent behavior, structured output, and composability.

## Library Overview

### `context.sh` - Environment and Repository Context

Provides functions for gathering execution context (git state, repo info, environment).

**Key Functions:**

```bash
# Get complete context (git + repo + environment)
ctx=$(get_context)

# Extract specific context fields
BRANCH=$(echo "$ctx" | jq -r '.context.git.currentBranch')
REPO=$(echo "$ctx" | jq -r '.context.repository.fullName')
IS_CLEAN=$(echo "$ctx" | jq -r '.context.git.isClean')

# Check dependencies
check_dependencies  # Returns 0 if all deps available

# Validate context
validate_context "$ctx"  # Returns 0 if valid
```

**Context Structure:**
```json
{
  "context": {
    "repository": {
      "owner": "owner",
      "name": "repo",
      "fullName": "owner/repo",
      "defaultBranch": "main"
    },
    "git": {
      "currentBranch": "feature-branch",
      "isClean": true,
      "hasUncommitted": false,
      "rootPath": "/path/to/repo"
    },
    "environment": {
      "hasGhCli": true,
      "hasJq": true,
      "ghVersion": "2.x.x"
    }
  }
}
```

### `result.sh` - Standardized Result Objects

Provides functions for creating standardized result objects with success/error states.

**Key Functions:**

```bash
# Create success result
result=$(success_result "operation_name" '{"key": "value"}')

# Create error result
result=$(error_result "operation_name" "Error message" "error_type")

# Add warning to result
result=$(echo "$result" | add_warning "Warning message")

# Add metadata
result=$(echo "$result" | add_metadata "duration" "1.5")

# Check if result is successful
if is_success "$result"; then
    data=$(get_result_data "$result")
fi

# Get error information
error=$(get_result_error "$result")
error_type=$(get_error_type "$result")
```

**Result Structure:**
```json
{
  "result": {
    "success": true,
    "operation": "create_issue",
    "data": { "number": 123, "url": "..." },
    "error": null,
    "warnings": ["warning message"],
    "metadata": {
      "timestamp": "2025-10-10T12:00:00Z"
    }
  }
}
```

**Error Types:**
- `general` - Generic error
- `network` - Network/API failure
- `validation` - Invalid input/state
- `conflict` - Merge/branch conflict
- `permission` - Authorization error
- `not_found` - Resource not found

### `format.sh` - Output Formatting

Provides functions for formatting output in different modes (JSON, human, compact, table).

**Key Functions:**

```bash
# Auto-detect format and output result
format_output "$result" "$FORMAT"

# Check if stdout is TTY
if is_tty; then
    # Interactive terminal
fi

# Format simple messages
format_success "Operation completed"
format_error "Error occurred" "error"
format_info "Information message"

# Detect output format
format=$(detect_format "$explicit_format")
```

**Supported Formats:**
- `auto` - Auto-detect (JSON for non-TTY, human for TTY)
- `json` - Pretty-printed JSON
- `compact` - Single-line JSON
- `human` - Human-readable with colors
- `table` - Tabular format (for arrays)

### `gh-api.sh` - GitHub API Wrappers

Provides structured wrappers around GitHub CLI (`gh`) for consistent API access.

**Key Functions:**

```bash
# Create issue
issue=$(gh_create_issue "Title" "Body")

# Create PR
pr=$(gh_create_pr "Title" "Body" "base_branch")

# Get issue/PR info
issue=$(gh_get_issue "123")
pr=$(gh_get_pr "456")

# List issues/PRs
issues=$(gh_list_issues "@claude" 10)
prs=$(gh_list_prs "label:bug" 5)

# Get PR for branch
pr=$(gh_get_pr_for_branch "feature-branch")

# Check branch existence
if branch_exists_local "branch-name"; then
    # Branch exists locally
fi

if branch_exists_remote "branch-name"; then
    # Branch exists on remote
fi

# Get branch status
status=$(gh_get_branch_status "branch-name")
```

**Return Format:**

All functions return JSON data that can be used directly in result objects:

```bash
issue_data=$(gh_create_issue "Fix bug" "@claude\n\nFix the bug")
result=$(success_result "create_issue" "$issue_data")
```

### `colors.sh` - Color and Formatting Constants

Provides centralized color codes and symbols for consistent visual output.

**Available Colors:**
```bash
RED, GREEN, YELLOW, BLUE, CYAN, MAGENTA, WHITE
BOLD, DIM, UNDERLINE
NC  # No Color (reset)
```

**Available Symbols:**
```bash
SYMBOL_SUCCESS="✓"
SYMBOL_ERROR="✗"
SYMBOL_WARNING="⚠"
SYMBOL_INFO="ℹ"
SYMBOL_PROGRESS="◉"
SYMBOL_BRANCH="📌"
SYMBOL_ISSUE="💬"
SYMBOL_PR="🔀"
SYMBOL_EDIT="📝"
SYMBOL_CLEAN="✨"
```

**Usage:**
```bash
source "$SCRIPT_DIR/lib/colors.sh"

echo -e "${GREEN}${SYMBOL_SUCCESS}${NC} Operation succeeded"
echo -e "${RED}${SYMBOL_ERROR}${NC} Operation failed"
```

## Usage Example

Complete example showing all libraries working together:

```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load libraries
source "$SCRIPT_DIR/lib/context.sh"
source "$SCRIPT_DIR/lib/result.sh"
source "$SCRIPT_DIR/lib/format.sh"
source "$SCRIPT_DIR/lib/gh-api.sh"

FORMAT="auto"
TITLE=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format) FORMAT="$2"; shift 2 ;;
            --format=*) FORMAT="${1#*=}"; shift ;;
            *) TITLE="$*"; break ;;
        esac
    done
}

main() {
    parse_args "$@"

    # Get context
    ctx=$(get_context)
    if [ $? -ne 0 ]; then
        result=$(error_result "get_context" "Failed to initialize" "environment")
        format_output "$result" "$FORMAT"
        exit 1
    fi

    # Validate input
    if [ -z "$TITLE" ]; then
        result=$(error_result "validate_input" "Title required" "validation")
        format_output "$result" "$FORMAT"
        exit 1
    fi

    # Create issue
    issue=$(gh_create_issue "$TITLE" "@claude\n\n$TITLE")

    if [ $? -eq 0 ]; then
        result=$(success_result "create_issue" "$issue")
        format_output "$result" "$FORMAT"
    else
        result=$(error_result "create_issue" "Failed to create issue" "network")
        format_output "$result" "$FORMAT"
        exit 1
    fi
}

main "$@"
```

## Design Principles

1. **Single Responsibility** - Each library handles one concern
2. **Pure Functions** - Functions return data, don't modify global state
3. **JSON First** - All data structures use JSON for consistency
4. **Composability** - Functions can be chained and composed
5. **Error Handling** - Explicit error returns, no silent failures
6. **Backward Compatibility** - Auto-detect TTY for legacy behavior

## Migration Guide

See `scripts/MIGRATION_GUIDE.md` for step-by-step instructions on migrating existing scripts to use these libraries.

## Testing

Test library functions:

```bash
# Source library
source scripts/lib/context.sh

# Test context
ctx=$(get_context)
echo "$ctx" | jq '.'

# Verify structure
echo "$ctx" | jq '.context.git.currentBranch'
```

## Contributing

When adding new library functions:

1. Keep functions focused and pure
2. Return JSON for structured data
3. Document function parameters and return values
4. Add examples to this README
5. Update relevant JSON schemas
6. Test with both TTY and non-TTY output
