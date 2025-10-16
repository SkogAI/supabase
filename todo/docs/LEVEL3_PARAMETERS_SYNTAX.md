# argc - Level 3: Parameters & Syntax

**For AI Agents**: Complete reference for creating argc parameters and understanding syntax.

## Command Definition

### Basic Command
```bash
# @cmd <description>
command_name() {
    # Implementation
}
```

### Multiple Commands (Subcommands)
```bash
# @cmd Start the application
start() {
    echo "Starting..."
}

# @cmd Stop the application
stop() {
    echo "Stopping..."
}
```

**Usage:**
```bash
./script.sh start
./script.sh stop
./script.sh --help  # Shows all commands
```

## Arguments

### Required Argument
```bash
# @arg name!  Description of argument
```
- `!` suffix = required
- Validation fails if not provided
- Access: `$argc_name`

### Optional Argument
```bash
# @arg name  Description of argument
```
- No `!` = optional
- Can be missing
- Access: `${argc_name:-}` or `${argc_name:-default}`

### Multiple Arguments
```bash
# @cmd Copy files
# @arg source!     Source file
# @arg destination! Destination file
copy() {
    cp "$argc_source" "$argc_destination"
}
```

### Variadic Arguments (Multiple Values)
```bash
# @arg files*  One or more files to process
```
- `*` suffix = array of values
- Access: `"${argc_files[@]}"`

## Options (Flags)

### Boolean Flag
```bash
# @option --verbose  Enable verbose output
```
- Present or absent
- Access: `${argc_verbose:-}`
- Check: `[ -n "${argc_verbose:-}" ]`

### Flag with Value
```bash
# @option --config <file>  Configuration file path
```
- Requires a value
- Access: `${argc_config:-}`

### Short and Long Form
```bash
# @option -v --verbose  Enable verbose output
```
- Both `-v` and `--verbose` work
- Access: same variable `${argc_verbose:-}`

## Variable Access Patterns

### Required Argument
```bash
# @arg name!
# Direct access (always exists)
echo "$argc_name"
```

### Optional Argument with Default
```bash
# @arg port
# Provide default if not set
PORT="${argc_port:-8080}"
```

### Optional Flag Check
```bash
# @option --dry-run
if [ -n "${argc_dry_run:-}" ]; then
    echo "Dry run mode"
fi
```

### Array Argument
```bash
# @arg files*
for file in "${argc_files[@]}"; do
    echo "Processing: $file"
done
```

## Complete Syntax Reference

### Comment Annotations

| Annotation | Syntax | Purpose |
|------------|--------|---------|
| Command | `# @cmd <description>` | Define command/subcommand |
| Required arg | `# @arg <name>! <description>` | Required positional argument |
| Optional arg | `# @arg <name> <description>` | Optional positional argument |
| Variadic arg | `# @arg <name>* <description>` | Multiple values (array) |
| Boolean flag | `# @option --<flag> <description>` | On/off switch |
| Flag with value | `# @option --<flag> <placeholder> <desc>` | Flag requiring value |
| Short form | `# @option -<c> --<flag> <description>` | Short and long form |

### Variable Naming

argc converts parameter names to variables:
- `@arg user-name` → `$argc_user_name` (dashes become underscores)
- `@option --dry-run` → `${argc_dry_run:-}`
- `@arg files*` → `"${argc_files[@]}"`

## Advanced Patterns

### Conditional Logic with Flags
```bash
# @cmd Deploy application
# @arg environment!  Target environment
# @option --force    Skip confirmation
# @option --verbose  Verbose output
deploy() {
    local env="$argc_environment"

    # Check if force flag is set
    if [ -z "${argc_force:-}" ]; then
        read -p "Deploy to $env? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    # Verbose output
    [ -n "${argc_verbose:-}" ] && set -x

    ./scripts/deploy.sh "$env"
}
```

### Building Argument Arrays
```bash
# @cmd Run tests
# @option --coverage  Enable coverage
# @option --watch     Watch mode
# @arg pattern        Test pattern filter
test() {
    local args=()

    [ -n "${argc_coverage:-}" ] && args+=("--coverage")
    [ -n "${argc_watch:-}" ] && args+=("--watch")
    [ -n "${argc_pattern:-}" ] && args+=("$argc_pattern")

    npm test "${args[@]}"
}
```

### Delegation Pattern
```bash
# @cmd Create GitHub issue
# @arg description!  Issue description
# @option --urgent   Mark as urgent
issue() {
    local cmd="scripts/create-issue"

    if [ -n "${argc_urgent:-}" ]; then
        "$cmd" "$argc_description" --priority high
    else
        "$cmd" "$argc_description"
    fi
}
```

## Validation Examples

### Validate Argument Values
```bash
# @cmd Set log level
# @arg level!  Log level (debug, info, warn, error)
set_level() {
    case "$argc_level" in
        debug|info|warn|error)
            echo "LOG_LEVEL=$argc_level" > .env
            ;;
        *)
            echo "Error: Invalid level '$argc_level'"
            echo "Valid: debug, info, warn, error"
            exit 1
            ;;
    esac
}
```

### Check Required Files
```bash
# @cmd Process file
# @arg input_file!  Input file path
process() {
    if [ ! -f "$argc_input_file" ]; then
        echo "Error: File not found: $argc_input_file"
        exit 1
    fi

    cat "$argc_input_file" | ./process.sh
}
```

## The Eval Line Explained

```bash
eval "$(argc --argc-eval "$0" "$@")"
```

**What it does:**
1. `argc --argc-eval "$0" "$@"` - argc reads your script, processes annotations
2. Generates bash code for parsing arguments
3. `eval` executes the generated code
4. Variables like `$argc_name` become available
5. Your function gets called with parsed arguments

**Must be at end of file** - After all function definitions.

## Error Handling

argc handles these automatically:
- Missing required arguments → Error message + usage
- Unknown options → Error message + valid options
- Wrong number of arguments → Error message + expected format
- `--help` flag → Auto-generated help text

## Complete Example

```bash
#!/usr/bin/env bash
set -e

# @cmd Deploy application to environment
# @arg environment!           Target environment (dev, staging, prod)
# @arg version               Version to deploy (default: latest)
# @option -f --force         Skip confirmation prompts
# @option -v --verbose       Enable verbose output
# @option --dry-run          Show what would happen without doing it
# @option --rollback <id>    Rollback to specific deployment ID
deploy() {
    local env="$argc_environment"
    local version="${argc_version:-latest}"

    # Verbose mode
    [ -n "${argc_verbose:-}" ] && set -x

    # Dry run mode
    if [ -n "${argc_dry_run:-}" ]; then
        echo "DRY RUN: Would deploy $version to $env"
        exit 0
    fi

    # Rollback mode
    if [ -n "${argc_rollback:-}" ]; then
        ./scripts/rollback.sh "$env" "$argc_rollback"
        exit 0
    fi

    # Confirmation unless forced
    if [ -z "${argc_force:-}" ]; then
        read -p "Deploy $version to $env? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    # Actual deployment
    ./scripts/deploy.sh "$env" "$version"
}

eval "$(argc --argc-eval "$0" "$@")"
```

**Usage:**
```bash
./deploy.sh deploy prod              # Interactive, latest version
./deploy.sh deploy prod v1.2.3 -f    # Force deploy v1.2.3
./deploy.sh deploy dev --dry-run     # See what would happen
./deploy.sh deploy staging --rollback abc123  # Rollback
./deploy.sh --help                   # See all options
```

**Next Level**: See `LEVEL4_ARCHITECTURE.md` for designing complex CLIs.
