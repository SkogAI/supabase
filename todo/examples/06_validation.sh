#!/usr/bin/env bash
# Example 6: Input Validation

set -e

# @cmd Set log level
# @arg level!  Log level (debug, info, warn, error)
set-level() {
    # Validate argument
    case "$argc_level" in
        debug|info|warn|error)
            echo "✓ Log level set to: $argc_level"
            ;;
        *)
            echo "❌ Error: Invalid level '$argc_level'"
            echo "Valid options: debug, info, warn, error"
            exit 1
            ;;
    esac
}

# @cmd Deploy to environment
# @arg environment!  Environment name
deploy() {
    # Validate environment
    case "$argc_environment" in
        dev|development)
            echo "Deploying to development..."
            ;;
        staging|stage)
            echo "Deploying to staging..."
            ;;
        prod|production)
            echo "⚠️  WARNING: Deploying to PRODUCTION"
            read -p "Are you sure? (yes/no) " -r
            [ "$REPLY" = "yes" ] || exit 1
            echo "Deploying to production..."
            ;;
        *)
            echo "❌ Error: Unknown environment '$argc_environment'"
            echo "Valid: dev, staging, prod"
            exit 1
            ;;
    esac
}

# @cmd Process file
# @arg file!  File path
process() {
    # Check file exists
    if [ ! -f "$argc_file" ]; then
        echo "❌ Error: File not found: $argc_file"
        exit 1
    fi

    # Check file is readable
    if [ ! -r "$argc_file" ]; then
        echo "❌ Error: File not readable: $argc_file"
        exit 1
    fi

    echo "✓ Processing file: $argc_file"
    echo "  Size: $(wc -c < "$argc_file") bytes"
    echo "  Lines: $(wc -l < "$argc_file")"
}

eval "$(argc --argc-eval "$0" "$@")"

# Usage:
# ./06_validation.sh set-level debug           # ✓ Valid
# ./06_validation.sh set-level invalid         # ❌ Error
# ./06_validation.sh deploy dev                # ✓ Valid
# ./06_validation.sh deploy unknown            # ❌ Error
# ./06_validation.sh process /etc/hosts        # ✓ Valid if file exists
# ./06_validation.sh process /nonexistent      # ❌ Error
