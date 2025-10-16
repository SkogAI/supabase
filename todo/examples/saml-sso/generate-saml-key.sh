#!/bin/bash
# Generate SAML private key for Supabase
# See: docs/SUPABASE_SAML_SP_CONFIGURATION.md

set -e

echo "🔐 Generating SAML private key for Supabase..."
echo ""

# Create temporary directory for keys
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Generate RSA private key in DER format
echo "Step 1: Generating RSA private key..."
openssl genpkey -algorithm rsa -outform DER -out private_key.der

if [ ! -f private_key.der ]; then
    echo "❌ Error: Failed to generate private key"
    exit 1
fi

echo "✅ Private key generated: private_key.der"
echo ""

# Encode to base64
echo "Step 2: Encoding to base64..."
base64 private_key.der > private_key.base64

# Convert to single line
echo "Step 3: Converting to single line..."
tr -d '\n' < private_key.base64 > private_key_oneline.txt

echo "✅ Base64 encoding complete"
echo ""

# Display instructions
echo "================================================"
echo "✅ SAML Private Key Generated Successfully!"
echo "================================================"
echo ""
echo "📋 Add this to your .env file:"
echo ""
echo "GOTRUE_SAML_ENABLED=true"
echo "GOTRUE_SAML_PRIVATE_KEY=$(cat private_key_oneline.txt)"
echo ""
echo "⚠️  Security Notes:"
echo "   1. Keep this key secure - do NOT commit to git"
echo "   2. Store securely in production (use secrets manager)"
echo "   3. Add private_key* to .gitignore"
echo ""
echo "📁 Key files saved to: $TEMP_DIR"
echo ""
echo "🧹 To clean up temporary files, run:"
echo "   rm -rf $TEMP_DIR"
echo ""
