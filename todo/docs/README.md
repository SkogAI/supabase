# argc Documentation Collection

**For AI Agents**: Multi-level documentation system for understanding and using argc.

## What is This?

This documentation is specifically designed for AI agents to consume at different depths depending on their current task. Each level builds on the previous one.

## Documentation Levels

### Level 1: Quick Usage
**File**: `LEVEL1_QUICK_USAGE.md`
**Use When**: You just need to USE argc right now
**Time**: 2-minute read
**Contains**:
- One-line summary
- Basic usage pattern
- Common patterns cheat sheet
- The magic eval line

### Level 2: Core Concepts
**File**: `LEVEL2_CORE_CONCEPTS.md`
**Use When**: You need to understand WHAT argc is and WHY to use it
**Time**: 10-minute read
**Contains**:
- What argc is
- argc vs traditional bash comparison
- When to use argc (and when not to)
- Key concepts (declarative syntax, variable injection, two-tier architecture)
- Design patterns
- Real-world examples from your codebase

### Level 3: Parameters & Syntax
**File**: `LEVEL3_PARAMETERS_SYNTAX.md`
**Use When**: You're creating argc commands and need complete syntax reference
**Time**: 20-minute read
**Contains**:
- Complete command definition syntax
- All argument types (required, optional, variadic)
- All option types (boolean flags, value flags)
- Variable access patterns
- Advanced patterns
- Complete syntax reference table
- Validation examples
- Error handling

### Level 4: Architecture & Design
**File**: `LEVEL4_ARCHITECTURE.md`
**Use When**: You're designing complex CLIs or discussing architecture
**Time**: 30-minute read
**Contains**:
- Architectural patterns (two-tier, command groups, smart wrappers)
- Design principles
- Complex architectures
- Integration with external tools
- Error handling strategies
- Testing strategies
- Performance considerations
- Migration strategies
- Best practices summary
- Production example analysis

## Example Scripts

Located in `../examples/`:

| File | Description | Complexity |
|------|-------------|------------|
| `01_hello_world.sh` | Simplest possible argc script | ⭐ |
| `02_optional_args.sh` | Optional arguments with defaults | ⭐ |
| `03_flags.sh` | Boolean flags and options | ⭐⭐ |
| `04_multi_command.sh` | Multiple subcommands | ⭐⭐ |
| `05_delegation.sh` | Delegation pattern (argc → bash) | ⭐⭐⭐ |
| `06_validation.sh` | Input validation patterns | ⭐⭐⭐ |
| `07_real_world.sh` | Complete production-grade CLI | ⭐⭐⭐⭐ |

## Quick Navigation

**I need to...**

- **Use argc right now** → `LEVEL1_QUICK_USAGE.md`
- **Understand when to use argc** → `LEVEL2_CORE_CONCEPTS.md`
- **Look up syntax** → `LEVEL3_PARAMETERS_SYNTAX.md`
- **Design a complex CLI** → `LEVEL4_ARCHITECTURE.md`
- **See working examples** → `../examples/`

## Reading Path

### For Quick Tasks
1. Read `LEVEL1_QUICK_USAGE.md`
2. Copy pattern from examples
3. Done

### For Understanding
1. Read `LEVEL1_QUICK_USAGE.md` (basics)
2. Read `LEVEL2_CORE_CONCEPTS.md` (understanding)
3. Reference `LEVEL3_PARAMETERS_SYNTAX.md` as needed

### For Building Production CLIs
1. Read all levels in order (1 → 2 → 3 → 4)
2. Study `07_real_world.sh` example
3. Review your `Argcfile.sh` for patterns
4. Design your architecture

### For Architecture Discussions
1. Start with `LEVEL4_ARCHITECTURE.md`
2. Reference `LEVEL2_CORE_CONCEPTS.md` for fundamentals
3. Use `LEVEL3_PARAMETERS_SYNTAX.md` for technical details

## Key Takeaways

### The argc Pattern
```bash
#!/usr/bin/env bash
set -e

# @cmd Description
# @arg name!  Required argument
# @option --flag  Boolean flag
command() {
    echo "$argc_name"
    [ -n "${argc_flag:-}" ] && echo "Flag set"
}

eval "$(argc --argc-eval "$0" "$@")"
```

### The Two-Tier Architecture
```
argc (Argcfile.sh)
    ↓ delegates to
bash scripts (scripts/*.sh)
```

- **argc layer**: Interface, parsing, validation
- **bash layer**: Logic, error handling, integration

### When to Use argc

✅ **Use argc for**:
- User-facing CLIs
- Multi-command tools
- Wrapper scripts
- Complex argument parsing

⚠️ **Use traditional bash for**:
- Production automation
- Complex business logic
- Legacy environments
- Very simple scripts

## Integration with Your Codebase

Your `Argcfile.sh` demonstrates excellent argc patterns:

```bash
# Clean interface
# @cmd Smart wrapper: creates issue OR PR based on git state
# @arg description!  Task description
quick() {
    scripts/claude-quick "$argc_description"
}

# Complex options
# @cmd Monitor workflow runs with real-time updates
# @option --logs      Follow job logs
# @option --compact   Use compact output
# @arg run_id         Specific run ID
watch() {
    local args=()
    [ -n "${argc_logs:-}" ] && args+=("--logs")
    [ -n "${argc_compact:-}" ] && args+=("--compact")
    [ -n "${argc_run_id:-}" ] && args+=("$argc_run_id")
    scripts/claude-watch "${args[@]}"
}
```

This is the pattern to follow: argc provides the UX, bash scripts do the work.

## Documentation Philosophy

This documentation follows your existing project's pattern of **progressive disclosure**:

- **Level 1**: Quick reference (like CLAUDE.md command lists)
- **Level 2**: Understanding (like WORKFLOWS.md)
- **Level 3**: Complete reference (like feature docs)
- **Level 4**: Architecture (like MCP_SERVER_ARCHITECTURE.md)

Each level is self-contained but builds on previous levels.

## For AI Agents

**Token-efficient reading strategy:**

1. **Quick task?** → Read Level 1 only (500 tokens)
2. **Need context?** → Read Level 1 + Level 2 (2000 tokens)
3. **Building something?** → Read Level 1-3 (5000 tokens)
4. **Architecture discussion?** → Read all levels (8000 tokens)

**Search strategy:**

- Need syntax? → Grep Level 3 for pattern
- Need example? → Check examples directory
- Need concept? → Search Level 2
- Need design pattern? → Search Level 4

## Quick Reference Card

```bash
# Command
# @cmd Description
command() { ... }

# Required argument
# @arg name!  Description
# Access: $argc_name

# Optional argument
# @arg name  Description
# Access: ${argc_name:-default}

# Boolean flag
# @option --flag  Description
# Access: ${argc_flag:-}
# Check: [ -n "${argc_flag:-}" ]

# Magic line (always at end)
eval "$(argc --argc-eval "$0" "$@")"
```

---

**Next Steps**: Choose your level and start reading!
