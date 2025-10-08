#!/bin/bash
# Verification script for all npm run commands
# Tests and verifies that all npm scripts defined in package.json are functioning correctly

# Don't exit on error - we want to capture all results
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
SKIPPED=0
WARNINGS=0

# Results array
declare -a RESULTS

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
    RESULTS+=("✅ $1")
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
    RESULTS+=("❌ $1")
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
    RESULTS+=("⚠️ $1")
}

print_skip() {
    echo -e "${BLUE}⊘${NC} $1"
    ((SKIPPED++))
    RESULTS+=("⊘ $1 (skipped)")
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local has_all=true
    
    # Check Docker
    if command_exists docker; then
        if docker info &> /dev/null; then
            print_success "Docker is installed and running"
        else
            print_warning "Docker is installed but not running"
            has_all=false
        fi
    else
        print_warning "Docker is not installed (required for db:* scripts)"
        has_all=false
    fi
    
    # Check Supabase CLI
    if command_exists supabase; then
        local version=$(supabase --version 2>&1 | head -n1)
        print_success "Supabase CLI is installed: $version"
    else
        print_warning "Supabase CLI is not installed (required for db:*, migration:*, functions:*, types:*, test:rls)"
        has_all=false
    fi
    
    # Check Deno
    if command_exists deno; then
        if deno --version &> /dev/null; then
            local version=$(deno --version 2>&1 | head -n1)
            print_success "Deno is installed: $version"
        else
            print_warning "Deno is installed but not functioning correctly (required for functions:*, lint:functions, format:functions, test:functions*)"
            has_all=false
        fi
    else
        print_warning "Deno is not installed (required for functions:*, lint:functions, format:functions, test:functions*)"
        has_all=false
    fi
    
    # Check Node.js/npm
    if command_exists npm; then
        local version=$(npm --version)
        print_success "npm is installed: v$version"
    else
        print_error "npm is not installed (required)"
        has_all=false
    fi
    
    # Check sqlfluff
    if command_exists sqlfluff; then
        local version=$(sqlfluff --version)
        print_success "sqlfluff is installed: $version"
    else
        print_warning "sqlfluff is not installed (required for lint:sql)"
        has_all=false
    fi
    
    # Check node_modules dependencies
    if [ -d "node_modules" ]; then
        print_success "node_modules directory exists"
        
        if [ -f "node_modules/.bin/nodemon" ]; then
            print_success "nodemon is installed (required for types:watch)"
        else
            print_warning "nodemon is not installed"
            has_all=false
        fi
        
        if [ -f "node_modules/.bin/npm-run-all" ]; then
            print_success "npm-run-all is installed (required for dev script)"
        else
            print_warning "npm-run-all is not installed"
            has_all=false
        fi
    else
        print_error "node_modules directory not found. Run: npm install"
        has_all=false
    fi
    
    echo ""
    if [ "$has_all" = true ]; then
        print_info "All prerequisites are met!"
    else
        print_warning "Some prerequisites are missing. Some tests will be skipped."
    fi
}

# Test npm script syntax
test_script_syntax() {
    print_header "Testing Script Syntax"
    
    # Verify package.json is valid JSON
    if jq empty package.json &> /dev/null; then
        print_success "package.json is valid JSON"
    else
        print_error "package.json is not valid JSON"
        return 1
    fi
    
    # Check if all scripts are defined
    local scripts=$(jq -r '.scripts | keys[]' package.json 2>/dev/null)
    local script_count=$(echo "$scripts" | wc -l)
    print_success "Found $script_count npm scripts defined"
}

# Test database scripts
test_database_scripts() {
    print_header "Testing Database Scripts"
    
    if ! command_exists supabase; then
        print_skip "Database scripts (Supabase CLI not installed)"
        return
    fi
    
    # Test db:status (non-destructive, can run even if Supabase is not running)
    print_info "Testing db:status..."
    if npm run db:status &> /tmp/db_status_test.log; then
        print_success "db:status works correctly"
    else
        # It's okay if Supabase is not running, we just want to verify the command works
        if grep -q "not running" /tmp/db_status_test.log || grep -q "Cannot connect" /tmp/db_status_test.log; then
            print_warning "db:status: Supabase is not running (command works, but service is down)"
        else
            print_error "db:status failed with unexpected error"
            cat /tmp/db_status_test.log | head -5
        fi
    fi
    
    # Test that other database scripts exist and have correct syntax
    for script in db:start db:stop db:reset db:diff migration:new migration:up; do
        if jq -e ".scripts.\"$script\"" package.json &> /dev/null; then
            print_success "Script '$script' is defined"
        else
            print_error "Script '$script' is not defined in package.json"
        fi
    done
}

# Test edge function scripts
test_function_scripts() {
    print_header "Testing Edge Function Scripts"
    
    if ! command_exists deno; then
        print_skip "Edge function scripts (Deno not installed)"
        return
    fi
    
    if ! command_exists supabase; then
        print_skip "Edge function management scripts (Supabase CLI not installed)"
        return
    fi
    
    # Test lint:functions
    print_info "Testing lint:functions..."
    if [ -d "supabase/functions" ]; then
        if npm run lint:functions &> /tmp/lint_functions_test.log; then
            print_success "lint:functions works correctly"
        else
            print_warning "lint:functions found issues (expected if code has lint errors)"
        fi
    else
        print_error "supabase/functions directory not found"
    fi
    
    # Test format:functions (check only, not modify)
    print_info "Testing format:functions --check..."
    if [ -d "supabase/functions" ]; then
        if cd supabase/functions && deno fmt --check &> /tmp/format_functions_test.log; then
            print_success "format:functions check works correctly"
            cd ../..
        else
            print_warning "format:functions check found formatting issues"
            cd ../..
        fi
    fi
    
    # Test that function management scripts exist
    for script in functions:new functions:serve functions:deploy; do
        if jq -e ".scripts.\"$script\"" package.json &> /dev/null; then
            print_success "Script '$script' is defined"
        else
            print_error "Script '$script' is not defined in package.json"
        fi
    done
}

# Test type generation scripts
test_type_scripts() {
    print_header "Testing Type Generation Scripts"
    
    if ! command_exists supabase; then
        print_skip "Type generation scripts (Supabase CLI not installed)"
        return
    fi
    
    # Check if types:generate script exists
    if jq -e '.scripts."types:generate"' package.json &> /dev/null; then
        print_success "Script 'types:generate' is defined"
    else
        print_error "Script 'types:generate' is not defined"
    fi
    
    # Check if types:watch script exists
    if jq -e '.scripts."types:watch"' package.json &> /dev/null; then
        print_success "Script 'types:watch' is defined"
        
        # Check if nodemon is available
        if [ -f "node_modules/.bin/nodemon" ]; then
            print_success "nodemon is available for types:watch"
        else
            print_warning "nodemon is not installed (required for types:watch)"
        fi
    else
        print_error "Script 'types:watch' is not defined"
    fi
}

# Test testing scripts
test_testing_scripts() {
    print_header "Testing Testing Scripts"
    
    # Test RLS test script definition
    if jq -e '.scripts."test:rls"' package.json &> /dev/null; then
        print_success "Script 'test:rls' is defined"
        
        if [ -f "tests/rls_test_suite.sql" ]; then
            print_success "RLS test file exists: tests/rls_test_suite.sql"
        else
            print_error "RLS test file not found: tests/rls_test_suite.sql"
        fi
    else
        print_error "Script 'test:rls' is not defined"
    fi
    
    # Test function testing scripts
    for script in test:functions test:functions:watch test:functions:coverage test:functions:coverage-lcov test:functions:integration; do
        if jq -e ".scripts.\"$script\"" package.json &> /dev/null; then
            print_success "Script '$script' is defined"
        else
            print_error "Script '$script' is not defined in package.json"
        fi
    done
    
    # Check for function test files
    if [ -d "supabase/functions" ]; then
        local test_count=0
        for dir in supabase/functions/*/; do
            if [ -f "${dir}test.ts" ]; then
                ((test_count++))
            fi
        done
        if [ $test_count -gt 0 ]; then
            print_success "Found $test_count function(s) with test files"
        else
            print_warning "No function test files found (test.ts)"
        fi
    fi
    
    # Test realtime test script
    if jq -e '.scripts."test:realtime"' package.json &> /dev/null; then
        print_success "Script 'test:realtime' is defined"
        
        if [ -d "examples/realtime" ]; then
            print_success "Realtime examples directory exists"
        else
            print_warning "Realtime examples directory not found"
        fi
    else
        print_error "Script 'test:realtime' is not defined"
    fi
    
    # Test SAML test scripts
    for script in test:saml test:saml:endpoints test:saml:logs; do
        if jq -e ".scripts.\"$script\"" package.json &> /dev/null; then
            print_success "Script '$script' is defined"
            
            # Check if the script file exists
            local script_path=$(jq -r ".scripts.\"$script\"" package.json)
            local script_file=$(echo "$script_path" | awk '{print $1}')
            if [ -f "$script_file" ]; then
                print_success "Script file exists: $script_file"
            else
                print_warning "Script file not found: $script_file"
            fi
        else
            print_error "Script '$script' is not defined in package.json"
        fi
    done
}

# Test linting and formatting scripts
test_lint_format_scripts() {
    print_header "Testing Linting and Formatting Scripts"
    
    # Test SQL linting
    if jq -e '.scripts."lint:sql"' package.json &> /dev/null; then
        print_success "Script 'lint:sql' is defined"
        
        if command_exists sqlfluff; then
            print_info "Testing lint:sql..."
            if [ -d "supabase/migrations" ]; then
                if npm run lint:sql &> /tmp/lint_sql_test.log; then
                    print_success "lint:sql works correctly"
                else
                    print_warning "lint:sql found issues or failed (check if migrations directory has SQL files)"
                fi
            else
                print_error "supabase/migrations directory not found"
            fi
        else
            print_warning "sqlfluff not installed, cannot test lint:sql"
        fi
    else
        print_error "Script 'lint:sql' is not defined"
    fi
    
    # Test function linting and formatting (already covered in test_function_scripts)
    if jq -e '.scripts."lint:functions"' package.json &> /dev/null; then
        print_success "Script 'lint:functions' is defined"
    else
        print_error "Script 'lint:functions' is not defined"
    fi
    
    if jq -e '.scripts."format:functions"' package.json &> /dev/null; then
        print_success "Script 'format:functions' is defined"
    else
        print_error "Script 'format:functions' is not defined"
    fi
}

# Test utility scripts
test_utility_scripts() {
    print_header "Testing Utility Scripts"
    
    # Test dev script
    if jq -e '.scripts."dev"' package.json &> /dev/null; then
        print_success "Script 'dev' is defined"
        
        if [ -f "node_modules/.bin/npm-run-all" ]; then
            print_success "npm-run-all is available for dev script"
        else
            print_warning "npm-run-all is not installed (required for dev script)"
        fi
    else
        print_error "Script 'dev' is not defined"
    fi
    
    # Test setup script
    if jq -e '.scripts."setup"' package.json &> /dev/null; then
        print_success "Script 'setup' is defined"
    else
        print_error "Script 'setup' is not defined"
    fi
    
    # Test examples:realtime script
    if jq -e '.scripts."examples:realtime"' package.json &> /dev/null; then
        print_success "Script 'examples:realtime' is defined"
    else
        print_error "Script 'examples:realtime' is not defined"
    fi
}

# Test actual function execution (safe tests only)
test_function_execution() {
    print_header "Testing Function Execution (Safe Tests Only)"
    
    # Test that we can actually run some safe commands
    if command_exists deno && [ -d "supabase/functions" ]; then
        print_info "Testing actual Deno function execution..."
        
        # Check if we can run deno check on functions
        local checked_count=0
        local failed_count=0
        for dir in supabase/functions/*/; do
            if [ -f "${dir}index.ts" ]; then
                local func_name=$(basename "$dir")
                if deno check "${dir}index.ts" &> /dev/null; then
                    ((checked_count++))
                else
                    ((failed_count++))
                    print_warning "Type check failed for function: $func_name"
                fi
            fi
        done
        
        if [ $checked_count -gt 0 ]; then
            print_success "Successfully type-checked $checked_count function(s)"
        fi
        
        if [ $failed_count -gt 0 ]; then
            print_warning "$failed_count function(s) failed type checking"
        fi
    else
        print_skip "Function execution tests (Deno not installed or functions directory missing)"
    fi
}

# Generate summary report
generate_summary() {
    print_header "Verification Summary"
    
    echo "Results:"
    echo "--------"
    for result in "${RESULTS[@]}"; do
        echo "$result"
    done
    
    echo ""
    echo "Statistics:"
    echo "-----------"
    echo -e "${GREEN}Passed:${NC}  $PASSED"
    echo -e "${RED}Failed:${NC}  $FAILED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${BLUE}Skipped:${NC} $SKIPPED"
    echo ""
    
    local total=$((PASSED + FAILED + WARNINGS + SKIPPED))
    local success_rate=$((PASSED * 100 / total))
    
    echo "Success Rate: $success_rate%"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All critical tests passed!${NC}"
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠ There are $WARNINGS warning(s) that may require attention.${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ Some tests failed. Please review the results above.${NC}"
        return 1
    fi
}

# Installation instructions
show_installation_instructions() {
    print_header "Installation Instructions for Missing Dependencies"
    
    if ! command_exists supabase; then
        echo "To install Supabase CLI:"
        echo "  npm install -g supabase"
        echo "  # or"
        echo "  brew install supabase/tap/supabase"
        echo ""
    fi
    
    if ! command_exists deno; then
        echo "To install Deno:"
        echo "  curl -fsSL https://deno.land/install.sh | sh"
        echo "  # or"
        echo "  brew install deno"
        echo ""
    fi
    
    if ! command_exists sqlfluff; then
        echo "To install sqlfluff:"
        echo "  pip install sqlfluff"
        echo "  # or"
        echo "  pipx install sqlfluff"
        echo ""
    fi
    
    if [ ! -d "node_modules" ]; then
        echo "To install npm dependencies:"
        echo "  npm install"
        echo ""
    fi
}

# Main execution
main() {
    clear
    print_header "NPM Scripts Verification"
    print_info "This script verifies all npm scripts defined in package.json"
    print_info "Some tests may be skipped if dependencies are not installed"
    echo ""
    
    # Change to script directory
    cd "$(dirname "$0")/.."
    
    check_prerequisites
    test_script_syntax
    test_database_scripts
    test_function_scripts
    test_type_scripts
    test_testing_scripts
    test_lint_format_scripts
    test_utility_scripts
    test_function_execution
    
    generate_summary
    local exit_code=$?
    
    show_installation_instructions
    
    exit $exit_code
}

# Run main function
main "$@"
