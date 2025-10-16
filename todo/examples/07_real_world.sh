#!/usr/bin/env bash
# Example 7: Real-World Complete CLI

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_prerequisites() {
    command -v docker >/dev/null || {
        print_error "docker not found"
        exit 1
    }
}

# @cmd Initialize new project
# @arg name!         Project name
# @option --template Template to use (default: basic)
init() {
    local template="${argc_template:-basic}"

    print_info "Initializing project: $argc_name"
    print_info "Template: $template"

    # Create directory structure
    mkdir -p "$argc_name"/{src,tests,docs}

    # Create files
    echo "# $argc_name" > "$argc_name/README.md"
    echo "console.log('Hello, $argc_name!');" > "$argc_name/src/index.js"

    print_success "Project initialized: $argc_name"
}

# @cmd Start development server
# @option --port <number>  Port to use (default: 3000)
# @option --watch          Watch for file changes
dev() {
    check_prerequisites

    local port="${argc_port:-3000}"

    print_info "Starting development server on port $port"

    if [ -n "${argc_watch:-}" ]; then
        print_info "Watch mode enabled"
    fi

    print_success "Server started at http://localhost:$port"
}

# @cmd Build project
# @arg environment     Build environment (default: production)
# @option --minify     Minify output
# @option --sourcemap  Generate source maps
build() {
    local env="${argc_environment:-production}"

    print_info "Building for $env..."

    local flags=()
    [ -n "${argc_minify:-}" ] && flags+=("minify")
    [ -n "${argc_sourcemap:-}" ] && flags+=("sourcemap")

    if [ ${#flags[@]} -gt 0 ]; then
        print_info "Flags: ${flags[*]}"
    fi

    print_success "Build complete"
}

# @cmd Run tests
# @arg pattern        Test file pattern
# @option --coverage  Generate coverage report
# @option --watch     Watch mode
test() {
    print_info "Running tests..."

    if [ -n "${argc_pattern:-}" ]; then
        print_info "Pattern: $argc_pattern"
    fi

    [ -n "${argc_coverage:-}" ] && print_info "Coverage enabled"
    [ -n "${argc_watch:-}" ] && print_info "Watch mode enabled"

    print_success "All tests passed"
}

# @cmd Deploy application
# @arg environment!       Target environment (dev, staging, prod)
# @arg version           Version to deploy (default: latest)
# @option -f --force     Skip confirmation
# @option -v --verbose   Enable verbose output
# @option --dry-run      Preview without deploying
deploy() {
    check_prerequisites

    local env="$argc_environment"
    local version="${argc_version:-latest}"

    # Validate environment
    case "$env" in
        dev|staging|prod) ;;
        *)
            print_error "Invalid environment: $env"
            echo "Valid: dev, staging, prod"
            exit 1
            ;;
    esac

    # Verbose mode
    if [ -n "${argc_verbose:-}" ]; then
        print_info "Environment: $env"
        print_info "Version: $version"
    fi

    # Dry run
    if [ -n "${argc_dry_run:-}" ]; then
        print_info "DRY RUN: Would deploy $version to $env"
        return 0
    fi

    # Confirmation unless forced
    if [ -z "${argc_force:-}" ]; then
        echo -n "Deploy $version to $env? (y/N) "
        read -r
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    print_info "Deploying $version to $env..."
    print_success "Deployment complete"
}

# @cmd Show project status
status() {
    echo "📊 Project Status"
    echo "  Environment: development"
    echo "  Version: 1.0.0"
    echo "  Status: Running"
}

# @cmd Clean build artifacts
# @option --all  Clean all including dependencies
clean() {
    print_info "Cleaning build artifacts..."

    if [ -n "${argc_all:-}" ]; then
        print_info "Removing dependencies too..."
    fi

    print_success "Clean complete"
}

eval "$(argc --argc-eval "$0" "$@")"

# Complete CLI with:
# - Multiple commands (init, dev, build, test, deploy, status, clean)
# - Required and optional arguments
# - Boolean flags and value flags
# - Short and long form flags (-f, --force)
# - Defaults for optional arguments
# - Input validation
# - Prerequisite checking
# - Colored output
# - Confirmation prompts
# - Dry run mode
# - Verbose mode
#
# Usage:
# ./07_real_world.sh init myproject
# ./07_real_world.sh dev --port 8080 --watch
# ./07_real_world.sh build production --minify
# ./07_real_world.sh test --coverage
# ./07_real_world.sh deploy prod v1.2.3 -f -v
# ./07_real_world.sh deploy staging --dry-run
# ./07_real_world.sh status
# ./07_real_world.sh clean --all
# ./07_real_world.sh --help
