#!/bin/bash

# ============================================================================
# SAML Endpoints Test Script
# ============================================================================
# Tests SAML endpoints accessibility and configuration
#
# Usage:
#   ./scripts/test_saml_endpoints.sh
#
# Environment Variables:
#   SUPABASE_URL - Supabase URL (default: http://localhost:8000)
#   SERVICE_ROLE_KEY - Service role key for admin API access
#   SSO_DOMAIN - Configured SSO domain (optional)
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
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"
SSO_DOMAIN="${SSO_DOMAIN:-}"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

# Helper functions
print_header() {
  echo ""
  echo "================================================================================"
  echo "$1"
  echo "================================================================================"
  echo ""
}

print_test() {
  echo -e "${BLUE}TEST: $1${NC}"
}

print_pass() {
  echo -e "${GREEN}✅ PASS: $1${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
  echo -e "${RED}❌ FAIL: $1${NC}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_warning() {
  echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
  WARNINGS=$((WARNINGS + 1))
}

print_info() {
  echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

# Check prerequisites
check_prerequisites() {
  print_header "Checking Prerequisites"

  # Check if curl is installed
  if ! command -v curl &>/dev/null; then
    print_fail "curl not found. Please install curl."
    exit 1
  fi
  print_pass "curl is installed"

  # Check if jq is installed (optional)
  if command -v jq &>/dev/null; then
    print_pass "jq is installed (JSON parsing available)"
    HAS_JQ=true
  else
    print_warning "jq not installed (JSON parsing limited)"
    HAS_JQ=false
  fi

  # Check if xmllint is installed (optional)
  if command -v xmllint &>/dev/null; then
    print_pass "xmllint is installed (XML validation available)"
    HAS_XMLLINT=true
  else
    print_warning "xmllint not installed (XML validation limited)"
    HAS_XMLLINT=false
  fi

  # Check if Supabase is accessible
  print_test "Checking Supabase accessibility"
  if curl -s -f -o /dev/null -m 5 "${SUPABASE_URL}/auth/v1/health"; then
    print_pass "Supabase is accessible at ${SUPABASE_URL}"
  else
    print_fail "Cannot access Supabase at ${SUPABASE_URL}"
    print_info "Make sure Supabase is running: npm run db:start"
    exit 1
  fi

  # Check if SERVICE_ROLE_KEY is set
  if [ -z "$SERVICE_ROLE_KEY" ]; then
    print_warning "SERVICE_ROLE_KEY not set - some tests will be skipped"
    print_info "Export SERVICE_ROLE_KEY or set in .env file"
  else
    print_pass "SERVICE_ROLE_KEY is set"
  fi
}

# Test 1: SAML Metadata Endpoint
test_metadata_endpoint() {
  print_header "TEST 1: SAML Metadata Endpoint"

  print_test "Testing metadata endpoint accessibility"
  METADATA_URL="${SUPABASE_URL}/auth/v1/sso/saml/metadata"

  # Test if endpoint is accessible
  HTTP_CODE=$(curl -s -o /tmp/saml_metadata.xml -w "%{http_code}" "${METADATA_URL}")

  if [ "$HTTP_CODE" = "200" ]; then
    print_pass "Metadata endpoint returned HTTP 200"
  else
    print_fail "Metadata endpoint returned HTTP ${HTTP_CODE}"
    return
  fi

  # Test if response is XML
  print_test "Validating XML format"
  if grep -q "<?xml" /tmp/saml_metadata.xml; then
    print_pass "Response is valid XML"
  else
    print_fail "Response is not XML"
    return
  fi

  # Test if contains EntityDescriptor
  if grep -q "EntityDescriptor" /tmp/saml_metadata.xml; then
    print_pass "Contains EntityDescriptor element"
  else
    print_fail "Missing EntityDescriptor element"
  fi

  # Test Entity ID
  print_test "Checking Entity ID"
  if grep -q "entityID=\"${SUPABASE_URL}/auth/v1/sso/saml/metadata\"" /tmp/saml_metadata.xml; then
    print_pass "Entity ID matches Supabase URL"
  else
    print_warning "Entity ID may not match expected value"
  fi

  # Test ACS URL
  print_test "Checking ACS URL"
  if grep -q "${SUPABASE_URL}/auth/v1/sso/saml/acs" /tmp/saml_metadata.xml; then
    print_pass "ACS URL present in metadata"
  else
    print_fail "ACS URL not found in metadata"
  fi

  # Validate XML syntax with xmllint
  if [ "$HAS_XMLLINT" = true ]; then
    print_test "Validating XML syntax with xmllint"
    if xmllint --noout /tmp/saml_metadata.xml 2>/dev/null; then
      print_pass "XML syntax is valid"
    else
      print_fail "XML syntax validation failed"
    fi
  fi

  print_info "Metadata saved to: /tmp/saml_metadata.xml"
}

# Test 2: List SSO Providers
test_sso_providers() {
  print_header "TEST 2: SSO Providers"

  if [ -z "$SERVICE_ROLE_KEY" ]; then
    print_warning "Skipping SSO providers test (SERVICE_ROLE_KEY not set)"
    return
  fi

  print_test "Listing SSO providers"
  PROVIDERS_URL="${SUPABASE_URL}/auth/v1/admin/sso/providers"

  HTTP_CODE=$(curl -s -o /tmp/sso_providers.json -w "%{http_code}" \
    -H "apikey: ${SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    "${PROVIDERS_URL}")

  if [ "$HTTP_CODE" = "200" ]; then
    print_pass "SSO providers endpoint returned HTTP 200"
  else
    print_fail "SSO providers endpoint returned HTTP ${HTTP_CODE}"
    cat /tmp/sso_providers.json
    return
  fi

  if [ "$HAS_JQ" = true ]; then
    # Count SAML providers
    SAML_COUNT=$(jq '[.[] | select(.provider == "saml")] | length' /tmp/sso_providers.json 2>/dev/null || echo "0")

    if [ "$SAML_COUNT" -gt 0 ]; then
      print_pass "Found ${SAML_COUNT} SAML provider(s)"

      # Display provider details
      print_info "SAML Provider Details:"
      jq '[.[] | select(.provider == "saml")] | .[] | {id: .id, domain: .domains[0], provider: .provider}' /tmp/sso_providers.json 2>/dev/null || echo "Could not parse provider details"
    else
      print_fail "No SAML providers configured"
      print_info "Configure SAML provider via Supabase Dashboard or API"
    fi
  else
    # Without jq, just check if response contains "saml"
    if grep -q '"provider":"saml"' /tmp/sso_providers.json || grep -q '"provider": "saml"' /tmp/sso_providers.json; then
      print_pass "SAML provider found in response"
    else
      print_fail "No SAML provider found"
    fi
  fi

  print_info "Providers saved to: /tmp/sso_providers.json"
}

# Test 3: SSO Initiation URL
test_sso_initiation() {
  print_header "TEST 3: SSO Initiation URL"

  if [ -z "$SSO_DOMAIN" ]; then
    print_warning "SSO_DOMAIN not set - skipping initiation test"
    print_info "Set SSO_DOMAIN environment variable to test SSO initiation"
    return
  fi

  print_test "Testing SSO initiation for domain: ${SSO_DOMAIN}"
  SSO_URL="${SUPABASE_URL}/auth/v1/sso?domain=${SSO_DOMAIN}"

  # Test if SSO initiation redirects
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "${SSO_URL}")

  if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "303" ] || [ "$HTTP_CODE" = "200" ]; then
    print_pass "SSO initiation returned HTTP ${HTTP_CODE}"
  else
    print_fail "SSO initiation returned unexpected HTTP ${HTTP_CODE}"
  fi

  # Check redirect location
  print_test "Checking redirect location"
  REDIRECT_LOCATION=$(curl -s -I "${SSO_URL}" | grep -i "^location:" | cut -d' ' -f2 | tr -d '\r\n')

  if [ -n "$REDIRECT_LOCATION" ]; then
    print_pass "Redirects to: ${REDIRECT_LOCATION}"

    # Check if redirect is to external IdP (should contain https)
    if echo "$REDIRECT_LOCATION" | grep -q "https://"; then
      print_pass "Redirect appears to be to external IdP"
    else
      print_warning "Redirect location may not be external IdP"
    fi
  else
    print_warning "No redirect location found"
  fi
}

# Test 4: SAML ACS Endpoint
test_acs_endpoint() {
  print_header "TEST 4: SAML ACS Endpoint"

  print_test "Testing ACS endpoint"
  ACS_URL="${SUPABASE_URL}/auth/v1/sso/saml/acs"

  # ACS endpoint should reject GET requests
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${ACS_URL}")

  if [ "$HTTP_CODE" = "405" ] || [ "$HTTP_CODE" = "400" ]; then
    print_pass "ACS endpoint correctly rejects GET requests (HTTP ${HTTP_CODE})"
  else
    print_warning "ACS endpoint returned unexpected HTTP ${HTTP_CODE} for GET"
  fi

  print_info "ACS endpoint accepts POST with SAML response"
  print_info "This endpoint is tested during authentication flow"
}

# Print Summary
print_summary() {
  print_header "Test Summary"

  echo "Tests Passed:  ${GREEN}${TESTS_PASSED}${NC}"
  echo "Tests Failed:  ${RED}${TESTS_FAILED}${NC}"
  echo "Warnings:      ${YELLOW}${WARNINGS}${NC}"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Complete manual authentication flow test"
    echo "2. Test with actual ZITADEL users"
    echo "3. Verify attribute mapping"
    echo ""
    echo "See: docs/ZITADEL_SAML_TESTING.md for complete test guide"
    return 0
  else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Verify Supabase is running: npm run db:start"
    echo "2. Check SAML provider is configured"
    echo "3. Verify SERVICE_ROLE_KEY is correct"
    echo "4. See: docs/ZITADEL_SAML_TESTING.md for help"
    return 1
  fi
}

# Main execution
main() {
  print_header "ZITADEL SAML Integration - Endpoint Tests"

  echo "Configuration:"
  echo "  Supabase URL: ${SUPABASE_URL}"
  echo "  SERVICE_ROLE_KEY: ${SERVICE_ROLE_KEY:+[SET]}${SERVICE_ROLE_KEY:-[NOT SET]}"
  echo "  SSO_DOMAIN: ${SSO_DOMAIN:-[NOT SET]}"
  echo ""

  check_prerequisites
  test_metadata_endpoint
  test_sso_providers
  test_sso_initiation
  test_acs_endpoint
  print_summary
}

# Run main function
main
exit $?
