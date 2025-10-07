#!/bin/bash

# ============================================================================
# SAML Attribute Validation Script
# ============================================================================
# Validates that SAML attributes are correctly mapped to Supabase user metadata
#
# Usage:
#   ./scripts/validate_saml_attributes.sh <user-email>
#
# Example:
#   ./scripts/validate_saml_attributes.sh testuser1@example.com
#
# Environment Variables:
#   SUPABASE_URL - Supabase URL (default: http://localhost:8000)
#   SERVICE_ROLE_KEY - Service role key for admin API access (required)
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-}"
USER_EMAIL="$1"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo ""
    echo "================================================================================"
    echo "$1"
    echo "================================================================================"
    echo ""
}

print_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    if [ -z "$USER_EMAIL" ]; then
        echo "Error: User email required"
        echo ""
        echo "Usage: $0 <user-email>"
        echo "Example: $0 testuser1@example.com"
        exit 1
    fi
    
    if [ -z "$SERVICE_ROLE_KEY" ]; then
        echo "Error: SERVICE_ROLE_KEY not set"
        echo ""
        echo "Set the SERVICE_ROLE_KEY environment variable:"
        echo "  export SERVICE_ROLE_KEY='your-service-role-key'"
        echo ""
        echo "Get it from: Supabase Dashboard → Settings → API"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo "Error: curl not found. Please install curl."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "Error: jq not found. This script requires jq for JSON parsing."
        echo ""
        echo "Install jq:"
        echo "  macOS: brew install jq"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        exit 1
    fi
}

# Fetch user by email
fetch_user() {
    print_header "Fetching User: ${USER_EMAIL}"
    
    USERS_URL="${SUPABASE_URL}/auth/v1/admin/users"
    
    HTTP_CODE=$(curl -s -o /tmp/user_response.json -w "%{http_code}" \
        "${USERS_URL}" \
        -H "apikey: ${SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
        -H "Content-Type: application/json")
    
    if [ "$HTTP_CODE" != "200" ]; then
        print_fail "Failed to fetch users (HTTP ${HTTP_CODE})"
        cat /tmp/user_response.json
        exit 1
    fi
    
    # Find user by email
    USER_DATA=$(jq --arg email "$USER_EMAIL" '.users[] | select(.email == $email)' /tmp/user_response.json)
    
    if [ -z "$USER_DATA" ] || [ "$USER_DATA" = "null" ]; then
        print_fail "User not found: ${USER_EMAIL}"
        print_info "Available users:"
        jq -r '.users[] | .email' /tmp/user_response.json
        exit 1
    fi
    
    print_pass "User found"
    
    # Extract user ID
    USER_ID=$(echo "$USER_DATA" | jq -r '.id')
    print_info "User ID: ${USER_ID}"
    
    # Save user data
    echo "$USER_DATA" > /tmp/user_data.json
}

# Validate user metadata
validate_metadata() {
    print_header "Validating SAML Attributes"
    
    # Extract metadata
    RAW_META=$(jq '.raw_user_meta_data' /tmp/user_data.json)
    APP_META=$(jq '.app_metadata' /tmp/user_data.json)
    
    print_info "Raw User Metadata:"
    echo "$RAW_META" | jq '.'
    echo ""
    
    # Check required fields
    print_header "Checking Required Attributes"
    
    # Email
    EMAIL=$(jq -r '.email' /tmp/user_data.json)
    if [ -n "$EMAIL" ] && [ "$EMAIL" != "null" ]; then
        print_pass "Email: ${EMAIL}"
    else
        print_fail "Email: Missing or empty"
    fi
    
    # Provider
    PROVIDER=$(jq -r '.app_metadata.provider' /tmp/user_data.json)
    if [ "$PROVIDER" = "saml" ] || echo "$PROVIDER" | grep -q "saml"; then
        print_pass "Provider: ${PROVIDER}"
    else
        print_warning "Provider: ${PROVIDER} (expected 'saml')"
    fi
    
    print_header "Checking SAML Attributes in Metadata"
    
    # First name / Given name
    FIRST_NAME=$(echo "$RAW_META" | jq -r '.first_name // .given_name // .FirstName // empty')
    if [ -n "$FIRST_NAME" ] && [ "$FIRST_NAME" != "null" ]; then
        print_pass "First Name: ${FIRST_NAME}"
    else
        print_warning "First Name: Not found (checked: first_name, given_name, FirstName)"
    fi
    
    # Last name / Family name / Surname
    LAST_NAME=$(echo "$RAW_META" | jq -r '.last_name // .family_name // .surname // .SurName // empty')
    if [ -n "$LAST_NAME" ] && [ "$LAST_NAME" != "null" ]; then
        print_pass "Last Name: ${LAST_NAME}"
    else
        print_warning "Last Name: Not found (checked: last_name, family_name, surname, SurName)"
    fi
    
    # Full name
    FULL_NAME=$(echo "$RAW_META" | jq -r '.full_name // .name // .FullName // empty')
    if [ -n "$FULL_NAME" ] && [ "$FULL_NAME" != "null" ]; then
        print_pass "Full Name: ${FULL_NAME}"
    else
        print_warning "Full Name: Not found (checked: full_name, name, FullName)"
    fi
    
    # Username
    USERNAME=$(echo "$RAW_META" | jq -r '.username // .preferred_username // .UserName // empty')
    if [ -n "$USERNAME" ] && [ "$USERNAME" != "null" ]; then
        print_pass "Username: ${USERNAME}"
    else
        print_warning "Username: Not found (checked: username, preferred_username, UserName)"
    fi
    
    # User ID / Subject
    USER_ID_ATTR=$(echo "$RAW_META" | jq -r '.sub // .user_id // .UserID // empty')
    if [ -n "$USER_ID_ATTR" ] && [ "$USER_ID_ATTR" != "null" ]; then
        print_pass "User ID (sub): ${USER_ID_ATTR}"
    else
        print_warning "User ID: Not found (checked: sub, user_id, UserID)"
    fi
    
    print_header "All Metadata Fields"
    echo "Raw User Metadata:"
    echo "$RAW_META" | jq '.'
    echo ""
    echo "App Metadata:"
    echo "$APP_META" | jq '.'
}

# Print summary
print_summary() {
    print_header "Validation Summary"
    
    echo "User: ${USER_EMAIL}"
    echo "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ Attribute mapping validated successfully${NC}"
        echo ""
        echo "All expected SAML attributes are present in user metadata."
        return 0
    else
        echo -e "${YELLOW}⚠️  Some attributes may be missing${NC}"
        echo ""
        echo "Troubleshooting:"
        echo "1. Verify attribute mapping in ZITADEL SAML app"
        echo "2. Ensure user profile in ZITADEL has all fields populated"
        echo "3. Check SAML assertion for attribute names (case-sensitive)"
        echo "4. See: docs/ZITADEL_SAML_TESTING.md for attribute mapping guide"
        return 1
    fi
}

# Main execution
main() {
    print_header "SAML Attribute Validation"
    
    echo "Configuration:"
    echo "  Supabase URL: ${SUPABASE_URL}"
    echo "  User Email: ${USER_EMAIL}"
    echo ""
    
    check_prerequisites
    fetch_user
    validate_metadata
    print_summary
}

# Run main function
main
exit $?
