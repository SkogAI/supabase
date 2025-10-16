# argc - Level 2: Core Concepts

**For AI Agents**: Use this to understand WHAT argc is and WHY to use it.

## What is argc?

argc is a **declarative CLI framework** for bash that:
- Eliminates manual argument parsing boilerplate
- Auto-generates help text from comments
- Provides type-safe variable access
- Enables clean command organization

## argc vs Traditional Bash

### Traditional Bash (Manual Parsing)
```bash
#!/bin/bash

show_help() {
    echo "Usage: $0 deploy [OPTIONS]"
    echo "  -e, --environment  Target environment"
    echo "  -v, --verbose      Verbose output"
}

ENVIRONMENT=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$ENVIRONMENT" ]; then
    echo "Error: environment required"
    exit 1
fi

# Do work
echo "Deploying to $ENVIRONMENT"
```

### argc (Declarative)
```bash
#!/usr/bin/env bash
set -e

# @cmd Deploy application
# @arg environment!  Target environment
# @option --verbose  Verbose output
deploy() {
    echo "Deploying to $argc_environment"
    [ -n "${argc_verbose:-}" ] && echo "Verbose mode enabled"
}

eval "$(argc --argc-eval "$0" "$@")"
```

**Benefits:**
- 15 lines vs 35+ lines
- Help text auto-generated
- Validation handled automatically
- Cleaner, more maintainable code

## When to Use argc

### ✅ Use argc for:
- **User-facing CLIs** - Clean interface with auto-generated help
- **Multi-command tools** - Subcommands (like git: `git commit`, `git push`)
- **Wrapper scripts** - Delegating to other scripts with validated params
- **Complex argument parsing** - Multiple optional flags and arguments

### ⚠️ Use traditional bash for:
- **Production automation** - Scripts that need maximum reliability
- **Complex business logic** - Multi-step processes with extensive error handling
- **Legacy environments** - Where argc may not be installed
- **Very simple scripts** - Single-purpose with 1-2 arguments

## Key Concepts

### 1. Declarative Syntax
Comments define the interface:
```bash
# @cmd <description>     - Define a command
# @arg <name>[!]         - Define argument (! = required)
# @option --<flag>       - Define boolean flag
```

### 2. Variable Injection
argc converts annotations to bash variables:
```bash
# @arg username!   → $argc_username
# @arg count       → ${argc_count:-}
# @option --force  → ${argc_force:-}
```

### 3. Two-Tier Architecture
```
argc (Argcfile.sh)
    └─> User Interface Layer
        └─> Auto-generated help
        └─> Argument validation
        └─> Variable injection
            ↓
bash scripts (implementation)
    └─> Business Logic Layer
        └─> Error handling
        └─> Complex operations
        └─> Integration with tools
```

### 4. Automatic Help Generation
```bash
./script.sh --help
# Automatically shows:
# - All commands
# - Required/optional args
# - Descriptions from comments
# - Usage examples
```

## Design Pattern: argc as Gateway

**Pattern from your codebase (Argcfile.sh):**

```bash
# argc provides clean UX
# @cmd Create GitHub issue with @claude mention
# @arg description!  Issue title/description
issue() {
    # Delegate to bash script for implementation
    scripts/claude-issue "$argc_description"
}
```

**Why this works:**
- argc handles **interface** (parsing, validation, help)
- bash script handles **implementation** (logic, error handling)
- Clean separation of concerns
- Easy to test each layer independently

## Real-World Example: Your Argcfile.sh

```bash
# @cmd Monitor workflow runs with real-time updates
# @option --logs         Follow job logs after completion
# @option --compact      Use compact output mode
# @arg run_id            Specific workflow run ID to watch
watch() {
    local args=()
    [ -n "${argc_logs:-}" ] && args+=("--logs")
    [ -n "${argc_compact:-}" ] && args+=("--compact")
    [ -n "${argc_run_id:-}" ] && args+=("$argc_run_id")

    scripts/claude-watch "${args[@]}"
}
```

**What this demonstrates:**
1. Multiple optional flags (`--logs`, `--compact`)
2. Optional positional argument (`run_id`)
3. Conditional array building
4. Delegation to bash script with translated args

## Mental Model

Think of argc as:
- **Input**: Comments describing what you want
- **Process**: argc generates parsing code
- **Output**: Clean variables you can use

```
Comments (@cmd, @arg, @option)
         ↓
    argc magic
         ↓
Variables ($argc_name, ${argc_flag:-})
```

**Next Level**: See `LEVEL3_PARAMETERS_SYNTAX.md` for complete syntax reference.
