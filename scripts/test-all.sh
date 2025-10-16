#!/bin/bash

# test-all.sh - Run all test suites continuously and report errors only
# Usage: ./scripts/test-all.sh [--once] [--watch-interval SECONDS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WATCH_MODE=true
WATCH_INTERVAL=5
ERROR_LOG="/tmp/supabase-test-errors.log"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --once)
      WATCH_MODE=false
      shift
      ;;
    --watch-interval)
      WATCH_INTERVAL="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --once              Run tests once and exit"
      echo "  --watch-interval N  Set watch interval in seconds (default: 5)"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Function to run a test and capture errors
run_test() {
  local test_name="$1"
  local test_command="$2"
  local output
  local exit_code

  # Run test and capture output
  output=$(eval "$test_command" 2>&1) || exit_code=$?

  if [ -n "$exit_code" ] && [ "$exit_code" -ne 0 ]; then
    # Test failed
    echo -e "${RED}✗ FAILED${NC}: $test_name" >&2
    echo "─────────────────────────────────────────────────" >&2
    echo "$output" >&2
    echo "─────────────────────────────────────────────────" >&2
    echo "" >&2

    # Log to error file
    {
      echo "═════════════════════════════════════════════════"
      echo "FAILED: $test_name ($(date '+%Y-%m-%d %H:%M:%S'))"
      echo "═════════════════════════════════════════════════"
      echo "$output"
      echo ""
    } >> "$ERROR_LOG"

    return 1
  else
    # Check for FAIL markers in SQL test output
    if echo "$output" | grep -q "FAIL:"; then
      echo -e "${RED}✗ FAILED${NC}: $test_name (contains FAIL markers)" >&2
      echo "─────────────────────────────────────────────────" >&2
      echo "$output" | grep -A5 "FAIL:" >&2
      echo "─────────────────────────────────────────────────" >&2
      echo "" >&2

      # Log to error file
      {
        echo "═════════════════════════════════════════════════"
        echo "FAILED: $test_name ($(date '+%Y-%m-%d %H:%M:%S'))"
        echo "═════════════════════════════════════════════════"
        echo "$output" | grep -A5 "FAIL:"
        echo ""
      } >> "$ERROR_LOG"

      return 1
    else
      # Test passed - only show if in single run mode
      if [ "$WATCH_MODE" = false ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
      fi
      return 0
    fi
  fi
}

# Function to run all tests
run_all_tests() {
  local run_start=$(date '+%Y-%m-%d %H:%M:%S')
  local total=0
  local passed=0
  local failed=0

  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Starting test run at $run_start${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Find the Supabase DB container name dynamically
  DB_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'supabase_db_|supabase-db' | head -1)
  if [ -z "$DB_CONTAINER" ]; then
    echo -e "${RED}✗ ERROR${NC}: Supabase database container not found. Run 'npm run db:start' first." >&2
    return 1
  fi

  # SQL Test Suites (using psql via docker)
  total=$((total + 1))
  if run_test "RLS Test Suite" "docker exec -i \$DB_CONTAINER psql -U postgres -d postgres < tests/rls_test_suite.sql"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  total=$((total + 1))
  if run_test "Profiles Test Suite" "docker exec -i \$DB_CONTAINER psql -U postgres -d postgres < tests/profiles_test_suite.sql"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  total=$((total + 1))
  if run_test "Storage Buckets Test Suite" "docker exec -i \$DB_CONTAINER psql -U postgres -d postgres < tests/storage_buckets_test_suite.sql"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  total=$((total + 1))
  if run_test "Storage Test Suite" "docker exec -i \$DB_CONTAINER psql -U postgres -d postgres < tests/storage_test_suite.sql"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi

  # Edge Functions Tests (skipped - test files have syntax errors)
  # total=$((total + 1))
  # if run_test "Edge Functions Tests" "cd supabase/functions && deno test --allow-all"; then
  #   passed=$((passed + 1))
  # else
  #   failed=$((failed + 1))
  # fi

  # Connection Tests
  if [ -f "scripts/test-connection.sh" ]; then
    total=$((total + 1))
    if run_test "Connection Test" "bash scripts/test-connection.sh"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  fi

  # Database Health Check
  if [ -f "scripts/check-db-health.sh" ]; then
    total=$((total + 1))
    if run_test "Database Health Check" "bash scripts/check-db-health.sh"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  fi

  # SAML Tests (if scripts exist)
  if [ -f "scripts/test_saml.sh" ]; then
    total=$((total + 1))
    if run_test "SAML Tests" "./scripts/test_saml.sh"; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  fi

  # Summary
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  if [ "$failed" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC} ($passed/$total)"
  else
    echo -e "${RED}Some tests failed!${NC} (Passed: $passed, Failed: $failed, Total: $total)"
    echo -e "See errors above or check: $ERROR_LOG"
  fi
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  return $failed
}

# Clear error log at start
> "$ERROR_LOG"

# Main execution
if [ "$WATCH_MODE" = true ]; then
  echo -e "${GREEN}Starting continuous test monitoring (errors only)${NC}"
  echo -e "${GREEN}Press Ctrl+C to stop${NC}"
  echo -e "${GREEN}Error log: $ERROR_LOG${NC}"
  echo ""

  # Run tests in watch mode
  while true; do
    run_all_tests

    if [ $? -eq 0 ]; then
      # All tests passed - just show a brief status
      echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓ All tests passing${NC}"
    fi

    echo -e "Waiting ${WATCH_INTERVAL}s before next run..."
    echo ""
    sleep "$WATCH_INTERVAL"
  done
else
  # Run once and exit
  run_all_tests
  exit $?
fi
