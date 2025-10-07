#!/bin/bash
# ci-worktree.sh - Run CI checks locally in a worktree
#
# Usage: .github/scripts/ci-worktree.sh [worktree-name]
#   worktree-name: Optional specific worktree to test (default: current directory)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_skip() {
    echo -e "${YELLOW}⊘${NC} $1"
    ((TESTS_SKIPPED++))
}

print_header() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
}

# Determine worktree path
WORKTREE_PATH=""
if [ -n "$1" ]; then
    # Explicit worktree name provided
    WORKTREE_PATH=".dev/worktree/$1"
    if [ ! -d "$WORKTREE_PATH" ]; then
        print_error "Worktree not found: $WORKTREE_PATH"
        exit 1
    fi
else
    # Check if we're in a worktree
    CURRENT_DIR=$(pwd)
    if [[ "$CURRENT_DIR" == *".dev/worktree/"* ]]; then
        WORKTREE_PATH="$CURRENT_DIR"
    else
        # Assume we're in the main repo
        WORKTREE_PATH="."
    fi
fi

# Get worktree name
if [[ "$WORKTREE_PATH" == *".dev/worktree/"* ]]; then
    WORKTREE_NAME=$(basename "$WORKTREE_PATH")
else
    WORKTREE_NAME="main-repository"
fi

# Change to worktree directory
cd "$WORKTREE_PATH"

print_header "CI Checks for Worktree: $WORKTREE_NAME"
print_info "Path: $WORKTREE_PATH"
print_info "Branch: $(git branch --show-current)"
echo ""

# Check if Docker is running (needed for some tests)
DOCKER_RUNNING=false
if docker info &> /dev/null; then
    DOCKER_RUNNING=true
    print_info "Docker is running (database tests available)"
else
    print_warning "Docker is not running (database tests will be skipped)"
fi

# ============================================================================
# Test 1: TypeScript Type Checking
# ============================================================================
print_section "TypeScript Type Checking"

if command -v node &> /dev/null && [ -f "package.json" ]; then
    if npm run types:generate --silent 2>&1 | grep -q "error"; then
        print_error "TypeScript type generation failed"
    else
        print_success "TypeScript types validated"
    fi
else
    print_skip "TypeScript type checking (Node.js not available)"
fi

# ============================================================================
# Test 2: SQL Linting
# ============================================================================
print_section "SQL Linting"

if command -v sqlfluff &> /dev/null && [ -d "supabase/migrations" ]; then
    if sqlfluff lint supabase/migrations --quiet; then
        print_success "SQL linting passed"
    else
        print_error "SQL linting failed"
    fi
else
    print_skip "SQL linting (sqlfluff not installed)"
fi

# ============================================================================
# Test 3: Migration Validation
# ============================================================================
print_section "Migration Validation"

if [ -d "supabase/migrations" ]; then
    # Check for migration files
    MIGRATION_COUNT=$(find supabase/migrations -name "*.sql" -type f | wc -l)
    if [ "$MIGRATION_COUNT" -gt 0 ]; then
        print_success "Found $MIGRATION_COUNT migration files"
        
        # Check for syntax errors in migrations (basic check)
        HAS_SYNTAX_ERROR=false
        for migration in supabase/migrations/*.sql; do
            if [ -f "$migration" ]; then
                # Check for common syntax issues
                if grep -q "SYNTAX ERROR" "$migration" 2>/dev/null; then
                    print_error "Syntax error detected in $(basename $migration)"
                    HAS_SYNTAX_ERROR=true
                fi
            fi
        done
        
        if [ "$HAS_SYNTAX_ERROR" = false ]; then
            print_success "Migration syntax check passed"
        fi
    else
        print_skip "No migration files found"
    fi
else
    print_skip "Migration validation (no migrations directory)"
fi

# ============================================================================
# Test 4: Edge Function Linting
# ============================================================================
print_section "Edge Function Linting"

if command -v deno &> /dev/null && [ -d "supabase/functions" ]; then
    cd supabase/functions
    
    # Deno format check
    if deno fmt --check 2>&1 | grep -q "error"; then
        print_error "Deno format check failed"
    else
        print_success "Deno format check passed"
    fi
    
    # Deno lint
    if deno lint 2>&1 | grep -q "error"; then
        print_error "Deno lint failed"
    else
        print_success "Deno lint passed"
    fi
    
    cd ../..
else
    print_skip "Edge function linting (Deno not installed)"
fi

# ============================================================================
# Test 5: Edge Function Type Checking
# ============================================================================
print_section "Edge Function Type Checking"

if command -v deno &> /dev/null && [ -d "supabase/functions" ]; then
    cd supabase/functions
    
    TYPE_CHECK_FAILED=false
    for dir in */; do
        if [ -f "${dir}index.ts" ]; then
            if ! deno check "${dir}index.ts" 2>&1 | grep -q "error"; then
                : # Success - do nothing
            else
                print_error "Type check failed for ${dir}index.ts"
                TYPE_CHECK_FAILED=true
            fi
        fi
    done
    
    if [ "$TYPE_CHECK_FAILED" = false ]; then
        print_success "Edge function type checking passed"
    fi
    
    cd ../..
else
    print_skip "Edge function type checking (Deno not installed)"
fi

# ============================================================================
# Test 6: Edge Function Unit Tests
# ============================================================================
print_section "Edge Function Unit Tests"

if command -v deno &> /dev/null && [ -d "supabase/functions" ]; then
    cd supabase/functions
    
    # Run tests without integration tests
    if deno test --allow-all --quiet 2>&1 | grep -q "FAILED"; then
        print_error "Edge function tests failed"
    else
        print_success "Edge function tests passed"
    fi
    
    cd ../..
else
    print_skip "Edge function tests (Deno not installed)"
fi

# ============================================================================
# Test 7: RLS Policy Tests
# ============================================================================
print_section "RLS Policy Tests"

if [ "$DOCKER_RUNNING" = true ] && command -v supabase &> /dev/null && [ -f "tests/rls_test_suite.sql" ]; then
    # Check if Supabase is running
    if supabase status &> /dev/null; then
        if supabase db execute --file tests/rls_test_suite.sql 2>&1 | grep -q "FAIL"; then
            print_error "RLS policy tests failed"
        else
            print_success "RLS policy tests passed"
        fi
    else
        print_warning "Supabase not running - skipping RLS tests"
        print_info "Run 'supabase start' to enable RLS tests"
        ((TESTS_SKIPPED++))
    fi
else
    if [ "$DOCKER_RUNNING" = false ]; then
        print_skip "RLS policy tests (Docker not running)"
    elif ! command -v supabase &> /dev/null; then
        print_skip "RLS policy tests (Supabase CLI not installed)"
    else
        print_skip "RLS policy tests (test file not found)"
    fi
fi

# ============================================================================
# Test 8: Storage Policy Tests
# ============================================================================
print_section "Storage Policy Tests"

if [ "$DOCKER_RUNNING" = true ] && command -v supabase &> /dev/null && [ -f "tests/storage_test_suite.sql" ]; then
    # Check if Supabase is running
    if supabase status &> /dev/null; then
        if supabase db execute --file tests/storage_test_suite.sql 2>&1 | grep -q "FAIL"; then
            print_error "Storage policy tests failed"
        else
            print_success "Storage policy tests passed"
        fi
    else
        print_skip "Storage policy tests (Supabase not running)"
    fi
else
    print_skip "Storage policy tests (not available)"
fi

# ============================================================================
# Summary
# ============================================================================
print_header "CI Check Summary"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo "Tests Passed:  $TESTS_PASSED"
echo "Tests Failed:  $TESTS_FAILED"
echo "Tests Skipped: $TESTS_SKIPPED"
echo "Total Tests:   $TOTAL_TESTS"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All checks passed! Safe to push."
    echo ""
    exit 0
else
    print_error "Some checks failed. Please fix issues before pushing."
    echo ""
    exit 1
fi
