#!/usr/bin/env bash
# Example 5: Delegation Pattern (argc → bash script)

set -e

# @cmd Deploy application
# @arg environment!  Target environment (dev, staging, prod)
# @option --force    Skip confirmation
# @option --verbose  Enable verbose output
deploy() {
    local args=("$argc_environment")

    [ -n "${argc_force:-}" ] && args+=("--force")
    [ -n "${argc_verbose:-}" ] && args+=("--verbose")

    # Delegate to bash script
    # In real project: ./scripts/deploy.sh "${args[@]}"
    echo "Would execute: ./scripts/deploy.sh ${args[*]}"
}

# @cmd Run database migrations
# @option --dry-run  Show pending migrations without applying
migrate() {
    local args=()

    [ -n "${argc_dry_run:-}" ] && args+=("--dry-run")

    # Delegate to bash script
    # In real project: ./scripts/migrate.sh "${args[@]}"
    echo "Would execute: ./scripts/migrate.sh ${args[*]}"
}

# @cmd Rollback deployment
# @arg deployment_id!  Deployment ID to rollback to
rollback() {
    # Delegate to bash script
    # In real project: ./scripts/rollback.sh "$argc_deployment_id"
    echo "Would execute: ./scripts/rollback.sh $argc_deployment_id"
}

eval "$(argc --argc-eval "$0" "$@")"

# Usage:
# ./05_delegation.sh deploy prod
# ./05_delegation.sh deploy dev --force --verbose
# ./05_delegation.sh migrate --dry-run
# ./05_delegation.sh rollback abc123
