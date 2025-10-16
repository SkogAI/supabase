# argc - Level 4: Architecture & Design

**For AI Agents**: Advanced patterns for building production-grade CLIs with argc.

## Architectural Patterns

### Pattern 1: Two-Tier Architecture

**Best Practice:** argc for interface, bash scripts for implementation

```
┌─────────────────────────────────────┐
│   Argcfile.sh (argc layer)          │
│   - User interface                  │
│   - Argument parsing                │
│   - Validation                      │
│   - Help generation                 │
└────────────┬────────────────────────┘
             │ delegates to
             ↓
┌─────────────────────────────────────┐
│   scripts/*.sh (bash layer)         │
│   - Business logic                  │
│   - Error handling                  │
│   - External integrations           │
│   - Complex operations              │
└─────────────────────────────────────┘
```

**Example from your codebase:**

```bash
# Argcfile.sh - Interface layer
# @cmd Create GitHub issue with @claude mention
# @arg description!  Issue title/description
issue() {
    scripts/claude-issue "$argc_description"
}

# @cmd Monitor workflow runs with real-time updates
# @option --logs      Follow job logs after completion
# @option --compact   Use compact output mode
# @arg run_id         Specific workflow run ID to watch
watch() {
    local args=()
    [ -n "${argc_logs:-}" ] && args+=("--logs")
    [ -n "${argc_compact:-}" ] && args+=("--compact")
    [ -n "${argc_run_id:-}" ] && args+=("$argc_run_id")

    scripts/claude-watch "${args[@]}"
}
```

**Why this works:**
- **Separation of concerns**: Interface vs. implementation
- **Testability**: Can test bash scripts independently
- **Maintainability**: argc interface stays clean
- **Reusability**: Bash scripts can be called from anywhere

### Pattern 2: Command Groups

Organize related commands into logical groups:

```bash
#!/usr/bin/env bash

# Database commands
# @cmd Start database
db-start() { scripts/db-start.sh; }

# @cmd Stop database
db-stop() { scripts/db-stop.sh; }

# @cmd Reset database
# @option --force  Skip confirmation
db-reset() {
    local args=()
    [ -n "${argc_force:-}" ] && args+=("--force")
    scripts/db-reset.sh "${args[@]}"
}

# Deployment commands
# @cmd Deploy to environment
# @arg environment!  Target environment
deploy() { scripts/deploy.sh "$argc_environment"; }

# @cmd Rollback deployment
# @arg deployment_id!  Deployment to rollback
rollback() { scripts/rollback.sh "$argc_deployment_id"; }

eval "$(argc --argc-eval "$0" "$@")"
```

**Usage:**
```bash
./cli db-start
./cli db-reset --force
./cli deploy prod
./cli --help  # Shows all commands grouped logically
```

### Pattern 3: Smart Wrappers

Use argc to add intelligence to existing tools:

```bash
# @cmd Smart git wrapper - creates issue OR PR based on state
# @arg description!  Task description
quick() {
    # Check git state
    if [ -n "$(git status --porcelain)" ]; then
        # Uncommitted changes → create issue
        scripts/claude-issue "$argc_description"
    else
        # Clean branch → create PR
        scripts/claude-pr "$argc_description"
    fi
}
```

## Design Principles

### 1. Command Naming

**Good:**
```bash
# @cmd Start development server
dev-start() { ... }

# @cmd Run database migrations
db-migrate() { ... }

# @cmd Deploy to production
deploy-prod() { ... }
```

**Bad:**
```bash
# @cmd Do stuff
do() { ... }  # Too vague

# @cmd Start
s() { ... }  # Too cryptic

# @cmd PerformDatabaseMigration
PerformDatabaseMigration() { ... }  # Too verbose
```

**Guidelines:**
- Use verb-noun pattern: `action-target`
- Group with prefixes: `db-*`, `deploy-*`
- Keep under 20 characters
- Use kebab-case

### 2. Argument Design

**Principle of Least Surprise:**

```bash
# Good: Obvious what it does
# @arg source!      Source file
# @arg destination! Destination file
copy() { ... }

# Bad: Unclear order
# @arg file1!
# @arg file2!
copy() { ... }  # Which is source?
```

**Required vs Optional:**
```bash
# Required: Cannot work without it
# @arg environment!  # deploy NEEDS this

# Optional: Has sensible default
# @arg port          # Can default to 8080
```

### 3. Flag Design

**Boolean flags** for features that can be on/off:
```bash
# @option --verbose   # Enable extra output
# @option --force     # Skip confirmations
# @option --dry-run   # Preview without action
```

**Value flags** when you need a parameter:
```bash
# @option --config <file>    # Config file path
# @option --timeout <secs>   # Timeout duration
# @option --format <type>    # Output format
```

## Complex Architectures

### Multi-Command CLI with Shared Logic

```bash
#!/usr/bin/env bash
set -e

# Shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Shared functions
check_prerequisites() {
    command -v docker >/dev/null || {
        echo "Error: docker not found"
        exit 1
    }
}

# @cmd Initialize new project
# @arg name!  Project name
init() {
    check_prerequisites
    scripts/init.sh "$argc_name"
}

# @cmd Build project
# @option --watch  Watch mode
build() {
    check_prerequisites
    local args=()
    [ -n "${argc_watch:-}" ] && args+=("--watch")
    scripts/build.sh "${args[@]}"
}

# @cmd Test project
# @arg pattern    Test pattern to match
# @option --coverage  Generate coverage report
test() {
    check_prerequisites
    local args=()
    [ -n "${argc_coverage:-}" ] && args+=("--coverage")
    [ -n "${argc_pattern:-}" ] && args+=("$argc_pattern")
    scripts/test.sh "${args[@]}"
}

# @cmd Deploy project
# @arg environment!  Target environment (dev, staging, prod)
# @option --force    Skip confirmation
deploy() {
    check_prerequisites

    # Validate environment
    case "$argc_environment" in
        dev|staging|prod) ;;
        *)
            echo "Error: Invalid environment: $argc_environment"
            echo "Valid: dev, staging, prod"
            exit 1
            ;;
    esac

    local args=("$argc_environment")
    [ -n "${argc_force:-}" ] && args+=("--force")

    scripts/deploy.sh "${args[@]}"
}

eval "$(argc --argc-eval "$0" "$@")"
```

### Integration with External Tools

**Pattern: argc + GitHub CLI**

```bash
# @cmd Create pull request with automated checks
# @arg title!        PR title
# @option --draft    Create as draft
# @option --ready    Mark as ready after checks pass
pr-create() {
    local gh_args=("--title" "$argc_title")
    [ -n "${argc_draft:-}" ] && gh_args+=("--draft")

    # Create PR
    PR_URL=$(gh pr create "${gh_args[@]}" --json url -q .url)
    echo "Created: $PR_URL"

    # Wait for checks if --ready flag set
    if [ -n "${argc_ready:-}" ]; then
        echo "Waiting for checks..."
        gh pr checks "$PR_URL" --watch
        gh pr ready "$PR_URL"
        echo "Marked as ready"
    fi
}
```

**Pattern: argc + Docker**

```bash
# @cmd Run command in Docker container
# @arg service!  Service name
# @arg command*  Command to run
run() {
    local service="$argc_service"
    local cmd=("${argc_command[@]}")

    if ! docker ps | grep -q "$service"; then
        echo "Starting $service..."
        docker-compose up -d "$service"
    fi

    docker-compose exec "$service" "${cmd[@]}"
}
```

## Error Handling Strategies

### Strategy 1: Fail Fast in argc Layer

```bash
# @cmd Deploy application
# @arg environment!  Environment
deploy() {
    # Validate immediately
    case "$argc_environment" in
        dev|staging|prod) ;;
        *)
            echo "❌ Invalid environment: $argc_environment"
            exit 1
            ;;
    esac

    # Check prerequisites
    command -v docker >/dev/null || {
        echo "❌ docker not found"
        exit 1
    }

    # Delegate to script
    scripts/deploy.sh "$argc_environment"
}
```

### Strategy 2: Pass Validation to Script

```bash
# @cmd Deploy application
# @arg environment!  Environment
deploy() {
    # Let the script handle all validation
    # argc just ensures the argument exists
    scripts/deploy.sh "$argc_environment"
}

# scripts/deploy.sh handles:
# - Environment validation
# - Prerequisite checks
# - Complex business rules
```

**When to use each:**
- **argc validation**: Simple checks (required fields, basic format)
- **Script validation**: Complex rules (business logic, external dependencies)

## Testing argc CLIs

### Manual Testing

```bash
# Test help
./cli --help
./cli command --help

# Test required args
./cli command           # Should fail with error
./cli command value     # Should succeed

# Test optional flags
./cli command value --flag
./cli command value --flag=value

# Test edge cases
./cli command ""        # Empty string
./cli command "with spaces"
./cli command --unknown-flag  # Should error
```

### Automated Testing

```bash
#!/bin/bash
# test-cli.sh

test_help() {
    ./cli --help | grep -q "Usage:" || {
        echo "FAIL: Help not working"
        return 1
    }
    echo "PASS: Help works"
}

test_required_arg() {
    ./cli deploy 2>&1 | grep -q "required" || {
        echo "FAIL: Missing arg not caught"
        return 1
    }
    echo "PASS: Required arg validated"
}

test_valid_command() {
    ./cli status &>/dev/null || {
        echo "FAIL: Valid command failed"
        return 1
    }
    echo "PASS: Command executed"
}

# Run tests
test_help
test_required_arg
test_valid_command
```

## Performance Considerations

### Startup Time

argc adds minimal overhead (~10-50ms):
```bash
# Fast: Direct delegation
# @cmd Status
status() {
    scripts/status.sh
}

# Slow: Heavy processing in argc
# @cmd Status
status() {
    # Avoid doing heavy work here
    for i in {1..1000}; do
        echo "Processing $i"
    done
}
```

**Best Practice:** Keep argc functions thin, delegate heavy work to scripts.

### Large CLIs

For 50+ commands, consider splitting:

```bash
# cli (main entry point)
├── Argcfile.sh          # Core commands
├── Argcfile.db.sh       # Database commands
├── Argcfile.deploy.sh   # Deployment commands
└── Argcfile.test.sh     # Testing commands
```

Load dynamically:
```bash
# Main Argcfile.sh
source "$(dirname "$0")/Argcfile.db.sh"
source "$(dirname "$0")/Argcfile.deploy.sh"
source "$(dirname "$0")/Argcfile.test.sh"

eval "$(argc --argc-eval "$0" "$@")"
```

## Migration Strategy

### From Traditional Bash to argc

**Step 1:** Start with one command
```bash
# Old: ./deploy.sh prod
# New: ./cli deploy prod

# @cmd Deploy
# @arg environment!
deploy() {
    ./deploy.sh "$argc_environment"
}
```

**Step 2:** Add more commands gradually
```bash
# @cmd Deploy
deploy() { ./deploy.sh "$argc_environment"; }

# @cmd Status
status() { ./status.sh; }

# Keep old scripts working during transition
```

**Step 3:** Migrate complex arguments
```bash
# Old: ./deploy.sh prod --force --verbose
# New: ./cli deploy prod --force --verbose

# @cmd Deploy
# @arg environment!
# @option --force
# @option --verbose
deploy() {
    local args=("$argc_environment")
    [ -n "${argc_force:-}" ] && args+=("--force")
    [ -n "${argc_verbose:-}" ] && args+=("--verbose")
    ./deploy.sh "${args[@]}"
}
```

**Step 4:** Deprecate old scripts (optional)
```bash
# deploy.sh
echo "⚠️  Warning: deploy.sh is deprecated"
echo "Use: ./cli deploy $*"
echo ""
# Still works, but warns users
```

## Best Practices Summary

1. **Separation**: argc for interface, bash for logic
2. **Naming**: Clear, consistent command names (verb-noun)
3. **Validation**: Simple checks in argc, complex in scripts
4. **Documentation**: Let argc generate help (write good descriptions)
5. **Testing**: Test both argc layer and bash scripts
6. **Migration**: Gradual, maintain backwards compatibility
7. **Performance**: Keep argc functions thin
8. **Organization**: Group related commands

## Real-World Production Example

Your `Argcfile.sh` demonstrates these principles:

```bash
# Clean interface layer
# @cmd Smart wrapper: creates issue OR PR based on git state
# @arg description!  Task description
quick() {
    scripts/claude-quick "$argc_description"
}

# @cmd Monitor workflow runs with real-time updates
# @option --logs      Follow job logs after completion
# @option --compact   Use compact output mode
# @arg run_id         Specific workflow run ID to watch
watch() {
    local args=()
    [ -n "${argc_logs:-}" ] && args+=("--logs")
    [ -n "${argc_compact:-}" ] && args+=("--compact")
    [ -n "${argc_run_id:-}" ] && args+=("$argc_run_id")
    scripts/claude-watch "${args[@]}"
}
```

**What makes this good:**
- ✅ Clear command names (`quick`, `watch`)
- ✅ Well-documented arguments
- ✅ Clean delegation to bash scripts
- ✅ Proper optional argument handling
- ✅ Args array building for complex flags

This is production-grade argc architecture.
