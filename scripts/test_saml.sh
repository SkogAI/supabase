#!/bin/bash

# ============================================================================
# ZITADEL SAML Integration - Master Test Suite
# ============================================================================
# Runs comprehensive tests for SAML integration
#
# Usage:
#   ./scripts/test_saml.sh [options]
#
# Options:
#   --skip-endpoints    Skip endpoint tests
#   --skip-attributes   Skip attribute validation
#   --skip-logs         Skip log analysis
#   --user-email EMAIL  Specify user email for attribute testing
#   -h, --help          Show help
#
# Environment Variables:
#   SUPABASE_URL - Supabase URL (default: http://localhost:8000)
#   SERVICE_ROLE_KEY - Service role key (required for most tests)
#   SSO_DOMAIN - SSO domain for testing
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test flags
RUN_ENDPOINTS=true
RUN_ATTRIBUTES=true
RUN_LOGS=true
USER_EMAIL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-endpoints)
            RUN_ENDPOINTS=false
            shift
            ;;
        --skip-attributes)
            RUN_ATTRIBUTES=false
            shift
            ;;
        --skip-logs)
            RUN_LOGS=false
            shift
            ;;
        --user-email)
            USER_EMAIL="$2"
            shift 2
            ;;
        -h|--help)
            echo "ZITADEL SAML Integration Test Suite"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-endpoints      Skip endpoint tests"
            echo "  --skip-attributes     Skip attribute validation"
            echo "  --skip-logs           Skip log analysis"
            echo "  --user-email EMAIL    Specify user for attribute testing"
            echo "  -h, --help            Show this help"
            echo ""
            echo "Environment Variables:"
            echo "  SUPABASE_URL          Supabase URL (default: http://localhost:8000)"
            echo "  SERVICE_ROLE_KEY      Service role key (required)"
            echo "  SSO_DOMAIN            SSO domain for testing"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 --user-email testuser@example.com"
            echo "  $0 --skip-logs"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

# Helper functions
print_banner() {
    echo ""
    echo "================================================================================"
    echo -e "${BOLD}$1${NC}"
    echo "================================================================================"
    echo ""
}

print_section() {
    echo ""
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo -e "${BLUE}$1${NC}"
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo ""
}

print_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local has_errors=false
    
    # Check curl
    if command -v curl &> /dev/null; then
        print_pass "curl is installed"
    else
        print_fail "curl not found"
        has_errors=true
    fi
    
    # Check jq (optional but recommended)
    if command -v jq &> /dev/null; then
        print_pass "jq is installed"
    else
        print_warning "jq not installed (recommended for JSON parsing)"
    fi
    
    # Check xmllint (optional)
    if command -v xmllint &> /dev/null; then
        print_pass "xmllint is installed"
    else
        print_warning "xmllint not installed (recommended for XML validation)"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null || command -v docker-compose &> /dev/null; then
        print_pass "Docker is available"
    else
        print_warning "Docker not found (needed for log analysis)"
    fi
    
    # Check Supabase URL
    SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"
    print_info "Supabase URL: ${SUPABASE_URL}"
    
    # Check SERVICE_ROLE_KEY
    if [ -n "$SERVICE_ROLE_KEY" ]; then
        print_pass "SERVICE_ROLE_KEY is set"
    else
        print_warning "SERVICE_ROLE_KEY not set (some tests will be skipped)"
    fi
    
    # Check SSO_DOMAIN
    if [ -n "$SSO_DOMAIN" ]; then
        print_pass "SSO_DOMAIN is set: ${SSO_DOMAIN}"
    else
        print_warning "SSO_DOMAIN not set (SSO initiation test will be skipped)"
    fi
    
    if [ "$has_errors" = true ]; then
        echo ""
        print_fail "Prerequisites check failed"
        echo "Please install missing requirements and try again"
        exit 1
    fi
    
    echo ""
    print_pass "Prerequisites check passed"
}

# Run endpoint tests
run_endpoint_tests() {
    if [ "$RUN_ENDPOINTS" = false ]; then
        print_warning "Skipping endpoint tests (--skip-endpoints)"
        return
    fi
    
    print_section "Running Endpoint Tests"
    
    if [ -x "${SCRIPT_DIR}/test_saml_endpoints.sh" ]; then
        "${SCRIPT_DIR}/test_saml_endpoints.sh"
        ENDPOINT_RESULT=$?
    else
        print_fail "test_saml_endpoints.sh not found or not executable"
        ENDPOINT_RESULT=1
    fi
    
    return $ENDPOINT_RESULT
}

# Run attribute validation
run_attribute_tests() {
    if [ "$RUN_ATTRIBUTES" = false ]; then
        print_warning "Skipping attribute validation (--skip-attributes)"
        return 0
    fi
    
    print_section "Running Attribute Validation"
    
    if [ -z "$SERVICE_ROLE_KEY" ]; then
        print_warning "SERVICE_ROLE_KEY not set - skipping attribute tests"
        return 0
    fi
    
    if [ -z "$USER_EMAIL" ]; then
        print_warning "No user email specified - skipping attribute validation"
        print_info "Use --user-email to test specific user attributes"
        return 0
    fi
    
    if [ -x "${SCRIPT_DIR}/validate_saml_attributes.sh" ]; then
        "${SCRIPT_DIR}/validate_saml_attributes.sh" "$USER_EMAIL"
        ATTR_RESULT=$?
    else
        print_fail "validate_saml_attributes.sh not found or not executable"
        ATTR_RESULT=1
    fi
    
    return $ATTR_RESULT
}

# Run log analysis
run_log_analysis() {
    if [ "$RUN_LOGS" = false ]; then
        print_warning "Skipping log analysis (--skip-logs)"
        return 0
    fi
    
    print_section "Running Log Analysis"
    
    if [ -x "${SCRIPT_DIR}/check_saml_logs.sh" ]; then
        "${SCRIPT_DIR}/check_saml_logs.sh"
        LOG_RESULT=$?
    else
        print_fail "check_saml_logs.sh not found or not executable"
        LOG_RESULT=1
    fi
    
    return $LOG_RESULT
}

# Display manual test instructions
show_manual_tests() {
    print_section "Manual Tests Required"
    
    echo "The following tests require manual verification:"
    echo ""
    echo "1. ${BOLD}Authentication Flow${NC}"
    echo "   - Navigate to: ${SUPABASE_URL}/auth/v1/sso?domain=\${SSO_DOMAIN}"
    echo "   - Complete login at ZITADEL"
    echo "   - Verify successful redirect and session creation"
    echo ""
    echo "2. ${BOLD}SAML Assertion Inspection${NC}"
    echo "   - Use browser DevTools Network tab"
    echo "   - Capture POST to /auth/v1/sso/saml/acs"
    echo "   - Review SAMLResponse parameter"
    echo ""
    echo "3. ${BOLD}Error Scenarios${NC}"
    echo "   - Test with incorrect password"
    echo "   - Test with disabled user"
    echo "   - Test with invalid domain"
    echo ""
    echo "4. ${BOLD}Multi-User Testing${NC}"
    echo "   - Login with 3+ different users"
    echo "   - Verify each gets separate session"
    echo "   - Check user isolation"
    echo ""
    echo "See ${BOLD}docs/ZITADEL_SAML_TESTING.md${NC} for detailed instructions"
}

# Print final summary
print_summary() {
    print_banner "Test Suite Summary"
    
    local total_passed=0
    local total_failed=0
    local manual_tests=4
    
    echo "Automated Tests:"
    
    if [ "$RUN_ENDPOINTS" = true ]; then
        if [ $ENDPOINT_RESULT -eq 0 ]; then
            print_pass "Endpoint Tests: PASSED"
            total_passed=$((total_passed + 1))
        else
            print_fail "Endpoint Tests: FAILED"
            total_failed=$((total_failed + 1))
        fi
    else
        echo "  • Endpoint Tests: SKIPPED"
    fi
    
    if [ "$RUN_ATTRIBUTES" = true ]; then
        if [ -n "$USER_EMAIL" ] && [ -n "$SERVICE_ROLE_KEY" ]; then
            if [ $ATTR_RESULT -eq 0 ]; then
                print_pass "Attribute Validation: PASSED"
                total_passed=$((total_passed + 1))
            else
                print_fail "Attribute Validation: FAILED"
                total_failed=$((total_failed + 1))
            fi
        else
            echo "  • Attribute Validation: SKIPPED (no user email or SERVICE_ROLE_KEY)"
        fi
    else
        echo "  • Attribute Validation: SKIPPED"
    fi
    
    if [ "$RUN_LOGS" = true ]; then
        if [ $LOG_RESULT -eq 0 ]; then
            print_pass "Log Analysis: PASSED"
            total_passed=$((total_passed + 1))
        else
            print_fail "Log Analysis: FAILED"
            total_failed=$((total_failed + 1))
        fi
    else
        echo "  • Log Analysis: SKIPPED"
    fi
    
    echo ""
    echo "Results:"
    echo "  Automated Tests Passed: ${GREEN}${total_passed}${NC}"
    echo "  Automated Tests Failed: ${RED}${total_failed}${NC}"
    echo "  Manual Tests Required:  ${YELLOW}${manual_tests}${NC}"
    echo ""
    
    if [ $total_failed -eq 0 ]; then
        print_pass "All automated tests passed!"
        echo ""
        echo "Next Steps:"
        echo "1. Complete manual authentication flow tests"
        echo "2. Test with multiple users"
        echo "3. Validate in production environment"
        echo "4. Document test results"
        echo ""
        print_info "See docs/ZITADEL_SAML_TESTING.md for complete test guide"
        return 0
    else
        print_fail "Some automated tests failed"
        echo ""
        echo "Troubleshooting:"
        echo "1. Check logs for detailed error messages"
        echo "2. Verify SAML configuration in ZITADEL and Supabase"
        echo "3. Ensure all environment variables are set correctly"
        echo "4. See docs/ZITADEL_SAML_TESTING.md for help"
        return 1
    fi
}

# Main execution
main() {
    print_banner "ZITADEL SAML Integration Test Suite"
    
    echo "Configuration:"
    echo "  Supabase URL: ${SUPABASE_URL:-http://localhost:8000}"
    echo "  SERVICE_ROLE_KEY: ${SERVICE_ROLE_KEY:+[SET]}${SERVICE_ROLE_KEY:-[NOT SET]}"
    echo "  SSO_DOMAIN: ${SSO_DOMAIN:-[NOT SET]}"
    echo "  User Email: ${USER_EMAIL:-[NOT SET]}"
    echo ""
    
    check_prerequisites
    
    # Run tests
    ENDPOINT_RESULT=0
    ATTR_RESULT=0
    LOG_RESULT=0
    
    run_endpoint_tests
    ENDPOINT_RESULT=$?
    
    run_attribute_tests
    ATTR_RESULT=$?
    
    run_log_analysis
    LOG_RESULT=$?
    
    # Show manual test instructions
    show_manual_tests
    
    # Print summary
    print_summary
    
    exit $?
}

# Run main function
main
