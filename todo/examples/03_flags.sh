#!/usr/bin/env bash
# Example 3: Boolean Flags

set -e

# @cmd Process a file with options
# @arg filename!       File to process
# @option --verbose    Enable verbose output
# @option --dry-run    Show what would happen without doing it
# @option --force      Skip confirmation prompts
process() {
    echo "Processing: $argc_filename"

    # Check verbose flag
    if [ -n "${argc_verbose:-}" ]; then
        echo "Verbose mode enabled"
        echo "File: $argc_filename"
        echo "Size: $(wc -c < "$argc_filename" 2>/dev/null || echo "unknown")"
    fi

    # Dry run mode
    if [ -n "${argc_dry_run:-}" ]; then
        echo "DRY RUN: Would process file"
        exit 0
    fi

    # Confirmation unless forced
    if [ -z "${argc_force:-}" ]; then
        read -p "Process $argc_filename? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    echo "✓ File processed successfully"
}

eval "$(argc --argc-eval "$0" "$@")"

# Usage:
# ./03_flags.sh process myfile.txt
# ./03_flags.sh process myfile.txt --verbose
# ./03_flags.sh process myfile.txt --dry-run
# ./03_flags.sh process myfile.txt --force --verbose
