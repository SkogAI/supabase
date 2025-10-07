#!/bin/bash
# Register ZITADEL as SAML provider in Supabase
# See: docs/SUPABASE_SAML_SP_CONFIGURATION.md

set -e

# ================================
# Configuration - UPDATE THESE VALUES
# ================================

# Supabase configuration
SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-your-service-role-key-here}"

# ZITADEL configuration
ZITADEL_INSTANCE="${ZITADEL_INSTANCE:-your-instance-id}"  # e.g., my-company-abc123
COMPANY_DOMAINS="${COMPANY_DOMAINS:-yourcompany.com}"     # Comma-separated if multiple

# ================================
# Validation
# ================================

if [ "$SERVICE_ROLE_KEY" = "your-service-role-key-here" ]; then
    echo "❌ Error: Please set SERVICE_ROLE_KEY environment variable or edit the script"
    echo "   Find it in: Supabase Dashboard → Settings → API → service_role key"
    exit 1
fi

if [ "$ZITADEL_INSTANCE" = "your-instance-id" ]; then
    echo "❌ Error: Please set ZITADEL_INSTANCE environment variable or edit the script"
    echo "   Format: your-instance-id (from https://your-instance-id.zitadel.cloud)"
    exit 1
fi

if [ "$COMPANY_DOMAINS" = "yourcompany.com" ]; then
    echo "⚠️  Warning: Using default domain 'yourcompany.com'"
    echo "   Update COMPANY_DOMAINS to your actual email domain(s)"
fi

# ================================
# Register Provider
# ================================

echo "🔐 Registering ZITADEL as SAML provider in Supabase..."
echo ""
echo "Configuration:"
echo "  Supabase URL: $SUPABASE_URL"
echo "  ZITADEL Instance: $ZITADEL_INSTANCE.zitadel.cloud"
echo "  Domains: $COMPANY_DOMAINS"
echo ""

# Convert comma-separated domains to JSON array
IFS=',' read -ra DOMAINS_ARRAY <<< "$COMPANY_DOMAINS"
DOMAINS_JSON="["
for i in "${!DOMAINS_ARRAY[@]}"; do
    DOMAINS_JSON+="\"${DOMAINS_ARRAY[$i]}\""
    if [ $i -lt $((${#DOMAINS_ARRAY[@]} - 1)) ]; then
        DOMAINS_JSON+=","
    fi
done
DOMAINS_JSON+="]"

# Make API request
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "type": "saml",
  "metadata_url": "https://${ZITADEL_INSTANCE}.zitadel.cloud/saml/v2/metadata",
  "domains": ${DOMAINS_JSON},
  "attribute_mapping": {
    "keys": {
      "email": {"name": "Email"},
      "name": {"name": "FullName"},
      "given_name": {"name": "FirstName"},
      "family_name": {"name": "SurName"}
    }
  }
}
EOF
)

# Parse response
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "✅ Provider registered successfully!"
    echo ""
    echo "Response:"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    
    # Extract and display provider ID if available
    PROVIDER_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    if [ "$PROVIDER_ID" != "null" ] && [ -n "$PROVIDER_ID" ]; then
        echo "📋 Provider ID: $PROVIDER_ID"
        echo "   Save this ID for future reference"
        echo ""
    fi
    
    echo "Next steps:"
    echo "  1. Verify configuration: ./verify-saml-setup.sh"
    echo "  2. Test SSO flow with a user from: $COMPANY_DOMAINS"
else
    echo "❌ Failed to register provider (HTTP $HTTP_CODE)"
    echo ""
    echo "Response:"
    echo "$BODY"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check SERVICE_ROLE_KEY is correct"
    echo "  2. Verify Supabase is running: curl ${SUPABASE_URL}/auth/v1/health"
    echo "  3. Verify ZITADEL metadata is accessible:"
    echo "     curl https://${ZITADEL_INSTANCE}.zitadel.cloud/saml/v2/metadata"
    exit 1
fi
