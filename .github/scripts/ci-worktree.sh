#!/bin/bash
# ci-worktree.sh - Run CI checks locally in a worktree
#
# Usage: .github/scripts/ci-worktree.sh [worktree-path]
#   worktree-path: Optional path to worktree (defaults to current directory)
#
# This script runs the same checks as CI/CD pipelines, allowing developers
# to validate their changes before pushing to remote.

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get worktree path
if [ -n "$1" ]; then
    WORKTREE_PATH="$1"
else
    WORKTREE_PATH="$(pwd)"
fi

# Verify we're in a git repository
if ! git -C "$WORKTREE_PATH" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository: $WORKTREE_PATH${NC}"
    exit 1
fi

cd "$WORKTREE_PATH"

# Get branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Running CI checks for worktree: $(basename $WORKTREE_PATH)${NC}"
echo -e "${BLUE}Branch: $BRANCH_NAME${NC}"
echo -e "${BLUE}Path: $WORKTREE_PATH${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local timeout_seconds="${3:-120}"
    
    echo -e "${BLUE}► Running: $test_name${NC}"
    
    # Run with timeout
    if timeout "$timeout_seconds" bash -c "$test_command" > /tmp/ci-test-$$.log 2>&1; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        local exit_code=$?
        echo -e "${RED}✗ $test_name${NC}"
        if [ $exit_code -eq 124 ]; then
            echo -e "${YELLOW}  Timeout after ${timeout_seconds}s${NC}"
        fi
        echo -e "${YELLOW}  See /tmp/ci-test-$$.log for details${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${YELLOW}1. Pre-flight checks${NC}"
echo "─────────────────────────────────────────────────────────────"

# Check for required tools
MISSING_TOOLS=()

if ! command_exists "node"; then
    MISSING_TOOLS+=("node")
fi

if ! command_exists "npm"; then
    MISSING_TOOLS+=("npm")
fi

if ! command_exists "deno"; then
    echo -e "${YELLOW}⚠ Deno not found - skipping function tests${NC}"
fi

if ! command_exists "supabase"; then
    echo -e "${YELLOW}⚠ Supabase CLI not found - skipping database tests${NC}"
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing required tools: ${MISSING_TOOLS[*]}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All required tools installed${NC}"
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠ node_modules not found, running npm install...${NC}"
    npm install --silent
fi

echo -e "${YELLOW}2. TypeScript Type Checking${NC}"
echo "─────────────────────────────────────────────────────────────"

# Check if types/database.ts exists
if [ -f "types/database.ts" ]; then
    # Simple syntax check
    if node -e "require('typescript')" 2>/dev/null; then
        run_test "TypeScript compilation" "npx tsc --noEmit --skipLibCheck types/database.ts"
    else
        echo -e "${YELLOW}⚠ TypeScript not installed - skipping type check${NC}"
    fi
else
    echo -e "${YELLOW}⚠ types/database.ts not found - skipping type check${NC}"
fi
echo ""

echo -e "${YELLOW}3. Database Migration Validation${NC}"
echo "─────────────────────────────────────────────────────────────"

if [ -d "supabase/migrations" ]; then
    # Check migration file naming
    INVALID_MIGRATIONS=0
    for migration in supabase/migrations/*.sql; do
        if [ -f "$migration" ]; then
            filename=$(basename "$migration")
            # Check if filename matches pattern: YYYYMMDDHHMMSS_description.sql
            if ! echo "$filename" | grep -qE '^[0-9]{14}_[a-z0-9_]+\.sql$'; then
                echo -e "${RED}✗ Invalid migration filename: $filename${NC}"
                echo -e "${YELLOW}  Expected format: YYYYMMDDHHMMSS_description.sql${NC}"
                ((INVALID_MIGRATIONS++))
            fi
        fi
    done
    
    if [ $INVALID_MIGRATIONS -eq 0 ]; then
        echo -e "${GREEN}✓ Migration naming convention${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Migration naming convention${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Migration naming convention")
    fi
    
    # Simple SQL syntax check
    SYNTAX_ERRORS=0
    for migration in supabase/migrations/*.sql; do
        if [ -f "$migration" ]; then
            # Basic syntax check - look for unterminated strings or unbalanced quotes
            if grep -q "[^\\]'[^']*$" "$migration" 2>/dev/null; then
                ((SYNTAX_ERRORS++))
            fi
        fi
    done
    
    if [ $SYNTAX_ERRORS -eq 0 ]; then
        echo -e "${GREEN}✓ Basic SQL syntax check${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠ Possible SQL syntax issues detected${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No migrations directory found${NC}"
fi
echo ""

echo -e "${YELLOW}4. Edge Functions Testing${NC}"
echo "─────────────────────────────────────────────────────────────"

if [ -d "supabase/functions" ] && command_exists "deno"; then
    cd supabase/functions
    
    # Deno formatting check
    run_test "Deno format check" "deno fmt --check"
    
    # Deno linting
    run_test "Deno lint" "deno lint"
    
    # Type checking for all functions
    TYPECHECK_FAILED=0
    for dir in */; do
        if [ -f "${dir}index.ts" ]; then
            echo -e "${BLUE}  Type checking ${dir}index.ts${NC}"
            if ! deno check "${dir}index.ts" 2>/dev/null; then
                ((TYPECHECK_FAILED++))
            fi
        fi
    done
    
    if [ $TYPECHECK_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ Function type checking${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ Function type checking ($TYPECHECK_FAILED failed)${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("Function type checking")
    fi
    
    # Run function tests
    if ls */test.ts 1> /dev/null 2>&1; then
        run_test "Function unit tests" "deno test --allow-all"
    else
        echo -e "${YELLOW}⚠ No function tests found${NC}"
    fi
    
    cd ../..
else
    if [ ! -d "supabase/functions" ]; then
        echo -e "${YELLOW}⚠ No functions directory found${NC}"
    else
        echo -e "${YELLOW}⚠ Deno not installed - skipping function tests${NC}"
    fi
fi
echo ""

echo -e "${YELLOW}5. Database Tests${NC}"
echo "─────────────────────────────────────────────────────────────"

if command_exists "supabase"; then
    # Check if Supabase is running
    if supabase status 2>/dev/null | grep -q "API URL"; then
        # RLS tests
        if [ -f "tests/rls_test_suite.sql" ]; then
            run_test "RLS policy tests" "npm run test:rls"
        else
            echo -e "${YELLOW}⚠ RLS test suite not found${NC}"
        fi
        
        # Storage tests
        if [ -f "tests/storage_test_suite.sql" ]; then
            run_test "Storage policy tests" "supabase db execute --file tests/storage_test_suite.sql"
        else
            echo -e "${YELLOW}⚠ Storage test suite not found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Supabase not running - skipping database tests${NC}"
        echo -e "${YELLOW}  Run 'npm run db:start' to start Supabase${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Supabase CLI not installed - skipping database tests${NC}"
fi
echo ""

echo -e "${YELLOW}6. SQL Linting${NC}"
echo "─────────────────────────────────────────────────────────────"

if command_exists "sqlfluff" && [ -d "supabase/migrations" ]; then
    run_test "SQL linting" "npm run lint:sql"
else
    if ! command_exists "sqlfluff"; then
        echo -e "${YELLOW}⚠ sqlfluff not installed - skipping SQL linting${NC}"
        echo -e "${YELLOW}  Install: pip install sqlfluff${NC}"
    else
        echo -e "${YELLOW}⚠ No migrations to lint${NC}"
    fi
fi
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo ""
    echo -e "${RED}CI checks failed! Please fix the issues before pushing.${NC}"
    exit 1
else
    echo -e "${GREEN}All checks passed! Safe to push.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  git add ."
    echo -e "  git commit -m 'Your commit message'"
    echo -e "  git push -u origin $BRANCH_NAME"
    exit 0
fi
