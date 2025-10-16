# argc - Level 1: Quick Usage

**For AI Agents**: Use this when you just need to USE argc quickly.

## One-Line Summary
argc is a bash CLI framework using special comments to auto-generate argument parsing and help text.

## Basic Usage

```bash
#!/usr/bin/env bash
set -e

# @cmd Say hello to someone
# @arg name!  Person's name (required)
hello() {
    echo "Hello, $argc_name!"
}

eval "$(argc --argc-eval "$0" "$@")"
```

**Run it:**
```bash
./script.sh hello "World"
# Output: Hello, World!
```

## Common Patterns

### Required Argument
```bash
# @arg name!  Description
# Access: $argc_name
```

### Optional Argument
```bash
# @arg name  Description
# Access: ${argc_name:-default}
```

### Boolean Flag
```bash
# @option --verbose  Enable verbose mode
# Access: ${argc_verbose:-}  # Empty if not set
```

### Call External Script
```bash
# @cmd Deploy application
# @arg environment!  Target environment
deploy() {
    ./scripts/deploy.sh "$argc_environment"
}
```

## The Magic Line
```bash
eval "$(argc --argc-eval "$0" "$@")"
```
**Always put this at the end.** It activates argc.

## Cheat Sheet

| Pattern | Code | Access |
|---------|------|--------|
| Required arg | `# @arg name!` | `$argc_name` |
| Optional arg | `# @arg name` | `${argc_name:-}` |
| Boolean flag | `# @option --flag` | `${argc_flag:-}` |
| Command | `# @cmd Description` | Function below comment |

**Next Level**: See `LEVEL2_CORE_CONCEPTS.md` for understanding WHY and WHEN to use argc.
