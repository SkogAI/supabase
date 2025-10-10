# Claude Workflow Script Libraries

This directory contains shared libraries for Claude workflow scripts, implementing a structured I/O architecture for consistent, composable, and testable script operations.

## Overview

The structured I/O architecture provides:

- **Standardized context**: Consistent environment and repository validation
- **Typed results**: JSON-based result objects with proper error handling
- **Multiple formats**: JSON, compact, human-readable, and table outputs
- **Composability**: Scripts can easily pipe data to each other
- **Testability**: Mock structured data instead of complex bash output

## Libraries

### `colors.sh`
Centralized color and formatting constants.

```bash
source "$(dirname "$0")/lib/colors.sh"
echo -e "${GREEN}Success!${NC}"
echo -e "${COLOR_ERROR}${SYMBOL_ERROR} Error occurred${NC}"
```

**Available colors:**
- `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `MAGENTA`, `WHITE`
- `BOLD`, `DIM`, `NC` (no color)

**Semantic colors:**
- `COLOR_SUCCESS`, `COLOR_ERROR`, `COLOR_WARNING`, `COLOR_INFO`, `COLOR_DEBUG`

**Symbols:**
- `SYMBOL_SUCCESS` (✓), `SYMBOL_ERROR` (✗), `SYMBOL_WARNING` (⚠)
- `SYMBOL_INFO` (ℹ), `SYMBOL_PROGRESS` (◉), `SYMBOL_BULLET` (•)

### `context.sh`
Initialize and retrieve script execution context.

```bash
source "$(dirname "$0")/lib/context.sh"

# Get full context (validates environment, checks git/GitHub)
ctx=$(get_context) || exit 1

# Extract specific values
repo_name=$(get_repo_full_name "$ctx")
branch=$(get_current_branch "$ctx")
is_clean=$(get_is_clean "$ctx")
default_branch=$(get_default_branch "$ctx")

# Access nested values directly
owner=$(echo "$ctx" | jq -r '.context.repository.owner')
```

**Context structure** (see `schemas/command-context.schema.json`):
```json
{
  "context": {
    "repository": {
      "owner": "SkogAI",
      "name": "supabase",
      "fullName": "SkogAI/supabase",
      "defaultBranch": "master"
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

### `result.sh`
Standardized result objects for script operations.

```bash
source "$(dirname "$0")/lib/result.sh"

# Create success result
data='{"issueNumber": 123, "url": "https://github.com/..."}'
result=$(success_result "create_issue" "$data")

# Create error result
result=$(error_result "network_error" \
    "Failed to connect to GitHub" \
    '{}' \
    '["Check your internet connection", "Verify gh CLI authentication"]')

# Add warnings
result=$(add_warning "$result" "This operation may take a while")

# Check result status
if [ "$(is_success "$result")" = "true" ]; then
    echo "Success!"
fi

# Extract data
data=$(get_result_data "$result")
error_msg=$(get_error_message "$result")
```

**Result structure** (see `schemas/operation-result.schema.json`):
```json
{
  "result": {
    "success": true,
    "operation": "create_issue",
    "data": { "issueNumber": 123, "url": "..." },
    "error": null,
    "warnings": [],
    "metadata": {
      "timestamp": "2025-10-10T12:00:00Z",
      "duration": 1.23
    }
  }
}
```

### `format.sh`
Output formatting for structured results.

```bash
source "$(dirname "$0")/lib/format.sh"

# Parse --format flag
parse_format_args "$@"

# Auto-detect format (TTY=human, pipe=json)
format=$(detect_format)

# Format and output result
format_output "$result" "$format"

# Or let format_output auto-detect
format_output "$result"
```

**Supported formats:**
- `json` - Pretty-printed JSON
- `compact` - Single-line JSON
- `human` - Colored, human-readable output
- `table` - Tabular format (for list results)

**Auto-detection:**
- stdout is TTY → `human` format
- stdout is pipe/redirect → `json` format

### `gh-api.sh`
Structured GitHub API wrappers.

```bash
source "$(dirname "$0")/lib/gh-api.sh"

# Get issue
issue=$(gh_get_issue 123)

# Create issue
issue=$(gh_create_issue "Bug report" "Description with @claude")

# Get PR
pr=$(gh_get_pr 45)

# Create PR
pr=$(gh_create_pr "Feature title" "PR body" "main")

# List issues
issues=$(gh_list_issues "@claude" 10)

# List PRs
prs=$(gh_list_prs "@claude" 10)

# Get branch status
status=$(gh_get_branch_status "claude/issue-123-20251010-1200")
```

All functions return JSON structures matching the schemas in `scripts/schemas/`.

## Usage Pattern

### Basic Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/context.sh"
source "$SCRIPT_DIR/lib/result.sh"
source "$SCRIPT_DIR/lib/format.sh"

# Parse format flag
parse_format_args "$@"

# Get context
ctx=$(get_context) || exit 1

# Do work
data='{"foo": "bar"}'
result=$(success_result "my_operation" "$data")

# Output result
format_output "$result"
```

### Error Handling

```bash
# Validate input
if [ -z "$INPUT" ]; then
    result=$(error_result "invalid_argument" \
        "Input is required" \
        '{}' \
        '["Provide input as first argument", "Run with --help for usage"]')
    format_output "$result"
    exit 1
fi

# Handle operation failure
if ! some_operation; then
    result=$(error_result "operation_failed" \
        "Failed to perform operation" \
        '{"attempted": "some_operation"}')
    format_output "$result"
    exit 1
fi
```

### Composability

```bash
# Script A outputs JSON
./script-a --format=json > result.json

# Script B consumes JSON
issue_number=$(cat result.json | jq -r '.result.data.number')
./script-b "$issue_number" --format=human

# Pipeline
./script-a --format=json | jq '.result.data.number' | xargs ./script-b --format=human
```

## Migration Guide

### Converting Existing Scripts

1. **Add library sources** at the top:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/lib/context.sh"
   source "$SCRIPT_DIR/lib/result.sh"
   source "$SCRIPT_DIR/lib/format.sh"
   ```

2. **Replace environment checks** with `get_context()`:
   ```bash
   # Old
   if ! command -v gh &> /dev/null; then
       echo "Error: gh not installed"
       exit 1
   fi

   # New
   ctx=$(get_context) || exit 1
   ```

3. **Replace direct output** with structured results:
   ```bash
   # Old
   echo "✓ Issue #$NUMBER created"

   # New
   result=$(success_result "create_issue" "$issue_json")
   format_output "$result"
   ```

4. **Add format flag support**:
   ```bash
   parse_format_args "$@"
   ```

5. **Test both formats**:
   ```bash
   # Human output (TTY)
   ./my-script "test"

   # JSON output (pipe)
   ./my-script "test" --format=json

   # Verify JSON structure
   ./my-script "test" --format=json | jq .
   ```

### Backward Compatibility

For existing scripts, create wrapper scripts:
```bash
# claude-quick (old interface)
#!/usr/bin/env bash
# Wrapper that always uses human format
exec "$(dirname "$0")/claude-quick-v2" --format=human "$@"
```

## Testing

### Test Context Retrieval
```bash
source scripts/lib/context.sh
ctx=$(get_context)
echo "$ctx" | jq .
```

### Test Result Creation
```bash
source scripts/lib/result.sh
result=$(success_result "test" '{"foo": "bar"}')
echo "$result" | jq .
```

### Test Formatting
```bash
source scripts/lib/format.sh
result='{"result": {"success": true, "data": {"number": 123}}}'
format_output "$result" "human"
format_output "$result" "json"
```

## Schema Validation

All JSON structures follow schemas in `scripts/schemas/`:

- `command-context.schema.json` - Context structure
- `operation-result.schema.json` - Result structure
- `branch-status.schema.json` - Branch status
- `issue-pr.schema.json` - Issue/PR data

Validate output against schemas:
```bash
./my-script --format=json | jq . > output.json
# Use ajv or similar tool to validate against schema
```

## Best Practices

1. **Always use `set -euo pipefail`** at the top of scripts
2. **Source libraries with full path** using `SCRIPT_DIR`
3. **Validate input early** and return structured errors
4. **Use typed error codes** from `operation-result.schema.json`
5. **Add helpful suggestions** to error results
6. **Support `--format` flag** for all scripts
7. **Document output structure** in script comments
8. **Test both human and JSON output** formats

## Examples

See `claude-quick-v2` for a complete reference implementation demonstrating:
- Context retrieval
- Conditional logic based on git state
- GitHub API integration
- Structured result output
- Multiple format support
- Proper error handling
