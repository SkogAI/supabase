#!/bin/bash
# Verify SAML configuration is working correctly
# See: docs/SUPABASE_SAML_SP_CONFIGURATION.md

set -e

# ================================
# Configuration
# ================================

SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-}"

# ================================
# Colors for output
# ================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    return 1
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
}

# ================================
# Tests
# ================================

echo "🔍 Verifying SAML Configuration..."
echo "   Supabase URL: $SUPABASE_URL"
echo ""

# Test 1: Check Supabase is running
echo "Test 1: Checking if Supabase is running..."
if curl -sf "${SUPABASE_URL}/auth/v1/health" > /dev/null; then
    pass "Supabase is running"
else
    fail "Supabase is not reachable at $SUPABASE_URL"
fi
echo ""

# Test 2: Check SAML metadata endpoint
echo "Test 2: Checking SAML metadata endpoint..."
METADATA_RESPONSE=$(curl -s -w "\n%{http_code}" "${SUPABASE_URL}/auth/v1/sso/saml/metadata")
METADATA_CODE=$(echo "$METADATA_RESPONSE" | tail -n1)
METADATA_BODY=$(echo "$METADATA_RESPONSE" | sed '$d')

if [ "$METADATA_CODE" = "200" ]; then
    if echo "$METADATA_BODY" | grep -q "EntityDescriptor"; then
        pass "SAML metadata endpoint returns valid XML"
        
        # Extract Entity ID
        ENTITY_ID=$(echo "$METADATA_BODY" | grep -oP 'entityID="\K[^"]+' | head -1)
        if [ -n "$ENTITY_ID" ]; then
            echo "   Entity ID: $ENTITY_ID"
        fi
    else
        fail "SAML metadata endpoint returns invalid XML"
    fi
else
    fail "SAML metadata endpoint returned HTTP $METADATA_CODE"
    echo "   This usually means SAML is not enabled or Kong routes are not configured"
fi
echo ""

# Test 3: Check if service role key is provided (for provider check)
if [ -z "$SERVICE_ROLE_KEY" ]; then
    warn "SERVICE_ROLE_KEY not set - skipping provider verification"
    echo "   Set SERVICE_ROLE_KEY to verify registered providers"
else
    echo "Test 3: Checking registered SAML providers..."
    PROVIDERS_RESPONSE=$(curl -s -w "\n%{http_code}" "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
        -H "APIKey: ${SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${SERVICE_ROLE_KEY}")
    
    PROVIDERS_CODE=$(echo "$PROVIDERS_RESPONSE" | tail -n1)
    PROVIDERS_BODY=$(echo "$PROVIDERS_RESPONSE" | sed '$d')
    
    if [ "$PROVIDERS_CODE" = "200" ]; then
        PROVIDER_COUNT=$(echo "$PROVIDERS_BODY" | jq '. | length' 2>/dev/null || echo "0")
        if [ "$PROVIDER_COUNT" -gt 0 ]; then
            pass "Found $PROVIDER_COUNT SAML provider(s)"
            echo ""
            echo "   Registered providers:"
            echo "$PROVIDERS_BODY" | jq -r '.[] | "   - \(.saml.entity_id) (domains: \(.domains | join(", ")))"' 2>/dev/null || echo "$PROVIDERS_BODY"
        else
            warn "No SAML providers registered"
            echo "   Run: ./register-zitadel-provider.sh"
        fi
    else
        fail "Failed to fetch providers (HTTP $PROVIDERS_CODE)"
        echo "   Check SERVICE_ROLE_KEY is correct"
    fi
fi
echo ""

# Test 4: Check SAML ACS endpoint (will return 405 for GET)
echo "Test 4: Checking SAML ACS endpoint..."
ACS_RESPONSE=$(curl -s -w "\n%{http_code}" "${SUPABASE_URL}/auth/v1/sso/saml/acs")
ACS_CODE=$(echo "$ACS_RESPONSE" | tail -n1)

# ACS should reject GET requests (405) but be accessible
if [ "$ACS_CODE" = "405" ] || [ "$ACS_CODE" = "400" ]; then
    pass "SAML ACS endpoint is accessible (rejects GET as expected)"
elif [ "$ACS_CODE" = "404" ]; then
    fail "SAML ACS endpoint returns 404 - Kong routes may not be configured"
else
    warn "SAML ACS endpoint returned HTTP $ACS_CODE (expected 405)"
fi
echo ""

# Summary
echo "================================"
echo "📊 Verification Summary"
echo "================================"
echo ""

if [ "$METADATA_CODE" = "200" ] && echo "$METADATA_BODY" | grep -q "EntityDescriptor"; then
    echo "✅ SAML is configured and endpoints are accessible"
    echo ""
    echo "Next steps:"
    echo "  1. Ensure ZITADEL provider is registered: ./register-zitadel-provider.sh"
    echo "  2. Test SSO flow with a user account"
    echo "  3. Verify user attributes are mapped correctly"
    echo ""
    echo "Documentation:"
    echo "  - Configuration: docs/SUPABASE_SAML_SP_CONFIGURATION.md"
    echo "  - Testing: docs/SUPABASE_SAML_SP_CONFIGURATION.md#testing"
else
    echo "❌ SAML configuration incomplete"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check GOTRUE_SAML_ENABLED=true in .env"
    echo "  2. Check GOTRUE_SAML_PRIVATE_KEY is set in .env"
    echo "  3. Verify Kong routes are configured in kong.yml"
    echo "  4. Restart Supabase: docker-compose down && docker-compose up -d"
    echo ""
    echo "Documentation:"
    echo "  - Setup Guide: docs/SUPABASE_SAML_SP_CONFIGURATION.md"
    echo "  - Troubleshooting: docs/SUPABASE_SAML_SP_CONFIGURATION.md#troubleshooting"
fi
