# Supabase SAML SSO Configuration Guide

Complete guide for configuring **self-hosted Supabase** (via Supabase CLI) to use ZITADEL as a SAML 2.0 Identity Provider for enterprise SSO.

> **Important**: This guide is for self-hosted Supabase using Supabase CLI, not supabase.com or traditional Docker Compose setups.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Phase 2: Supabase Configuration](#phase-2-supabase-configuration)
  - [1. Generate SAML Private Key](#1-generate-saml-private-key)
  - [2. Update Environment Variables](#2-update-environment-variables)
  - [3. Update Supabase Configuration](#3-update-supabase-configuration)
  - [4. Restart Supabase Services](#4-restart-supabase-services)
  - [5. Verify SAML Endpoints](#5-verify-saml-endpoints)
  - [6. Register ZITADEL Provider](#6-register-zitadel-provider)
  - [7. Test SSO Flow](#7-test-sso-flow)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [References](#references)

---

## Overview

This guide covers **Phase 2** of the SAML SSO integration: configuring Supabase to accept authentication from ZITADEL via SAML 2.0.

### What You'll Accomplish

- Generate SAML private key for Supabase
- Configure GoTrue (Supabase Auth) to enable SAML
- Expose SAML metadata and ACS endpoints
- Register ZITADEL as a trusted Identity Provider
- Test end-to-end SSO authentication flow

### Architecture

```
┌─────────────────┐                              ┌─────────────────┐
│   User Browser  │                              │    ZITADEL      │
│                 │  1. Login Request            │  (Identity      │
│                 │ ──────────────────────────▶  │   Provider)     │
│                 │                              │                 │
│                 │  2. SAML AuthnRequest        │   - Verifies    │
│                 │ ──────────────────────────▶  │     user        │
│                 │                              │   - Creates     │
│                 │  3. User Authentication      │     SAML        │
│                 │     (ZITADEL login page)     │     assertion   │
│                 │ ◀──────────────────────────  │                 │
│                 │                              └─────────────────┘
│                 │  4. SAML Response                     │
│                 │ ◀─────────────────────────────────────┘
│                 │
│                 │  5. POST to ACS endpoint
│                 │ ──────────────────────────▶
└─────────────────┘                              ┌─────────────────┐
                                                 │    Supabase     │
                                                 │  (Service       │
                                                 │   Provider)     │
                                                 │                 │
                                                 │   - Validates   │
                                                 │     SAML        │
                                                 │   - Creates     │
                                                 │     session     │
                                                 │   - Creates     │
                                                 │     user        │
                                                 └─────────────────┘
```

---

## Prerequisites

Before starting, ensure you have:

- ✅ **Supabase CLI installed**: Run `supabase --version` to verify
- ✅ **Docker Desktop running**: Required for Supabase local services
- ✅ **ZITADEL configured**: Phase 1 completed (see [ZITADEL_SAML_IDP_SETUP.md](./ZITADEL_SAML_IDP_SETUP.md))
- ✅ **ZITADEL metadata URL**: Available from ZITADEL SAML application
- ✅ **OpenSSL installed**: For generating SAML private key
- ✅ **Service role key**: From Supabase (obtained after starting services)

### Verify Prerequisites

```bash
# Check Supabase CLI
supabase --version
# Expected: supabase 1.x.x or higher

# Check Docker is running
docker info
# Should show Docker information without errors

# Check OpenSSL
openssl version
# Expected: OpenSSL 1.x or higher

# Check if Supabase is running
supabase status
# If not running: supabase start
```

---

## Phase 2: Supabase Configuration

### 1. Generate SAML Private Key

Supabase requires a private key to sign SAML requests and decrypt responses from the Identity Provider.

#### Step 1.1: Create Keys Directory

```bash
# Create secure directory for keys
mkdir -p ~/supabase-saml-keys
cd ~/supabase-saml-keys
```

#### Step 1.2: Generate RSA Private Key

```bash
# Generate RSA private key in DER format (2048-bit)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform DER -out private_key.der
```

**Why DER format?**
- GoTrue (Supabase Auth) expects the private key in DER (Distinguished Encoding Rules) binary format
- DER is more compact than PEM and suitable for environment variables

#### Step 1.3: Encode to Base64

```bash
# Encode the DER key to base64 (single line, no line breaks)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  base64 -i private_key.der -o private_key.base64
else
  # Linux
  base64 -w 0 private_key.der > private_key.base64
fi
```

#### Step 1.4: Verify Key Generation

```bash
# Check the base64 key exists and has content
cat private_key.base64
# Should output a long base64 string without line breaks

# Store the key securely
chmod 600 private_key.der private_key.base64
```

**⚠️ Security Warning:**
- **Never commit these keys to git**
- Store them securely (password manager, encrypted vault)
- Consider using different keys for development and production

---

### 2. Update Environment Variables

Add SAML configuration to your `.env` file.

#### Step 2.1: Open .env File

```bash
# Navigate to repository root
cd /path/to/your/supabase/repo

# Copy example if .env doesn't exist
cp .env.example .env

# Edit .env file
nano .env
# or use your preferred editor: code .env, vim .env, etc.
```

#### Step 2.2: Add SAML Variables

Add these variables to the **end** of your `.env` file:

```bash
# ============================================
# SAML SSO Configuration
# ============================================

# Enable SAML SSO authentication
GOTRUE_SAML_ENABLED=true

# SAML private key (base64-encoded DER format)
# Paste the entire content from private_key.base64 (single line, no spaces/breaks)
GOTRUE_SAML_PRIVATE_KEY=<paste-your-base64-key-here>

# Optional: SAML RelayState parameter for post-login redirect
# GOTRUE_SAML_RELAY_STATE=http://localhost:3000/dashboard
```

**Example:**
```bash
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC8...
```

#### Step 2.3: Verify Environment File

```bash
# Check that variables are set (without exposing the key)
grep "GOTRUE_SAML_ENABLED" .env
# Should show: GOTRUE_SAML_ENABLED=true

# Verify .env is in .gitignore
git check-ignore .env
# Should output: .env
```

---

### 3. Update Supabase Configuration

Configure `supabase/config.toml` to pass SAML environment variables to the auth service.

#### Step 3.1: Open config.toml

```bash
# Edit Supabase configuration
nano supabase/config.toml
# or: code supabase/config.toml
```

#### Step 3.2: Add SAML Configuration

Locate the `[auth]` section and add SAML settings:

```toml
[auth]
enabled = true
site_url = "http://localhost:8000"
# ... existing auth configuration ...

# SAML SSO Configuration
# Environment variables for SAML authentication
[auth.external.saml]
enabled = true
```

**Note:** The Supabase CLI automatically passes environment variables prefixed with `GOTRUE_` to the auth service, so we only need to enable SAML support in config.toml.

#### Step 3.3: Verify Configuration

```bash
# Check the configuration is valid
grep -A 2 "\[auth.external.saml\]" supabase/config.toml
# Should show the SAML configuration
```

---

### 4. Restart Supabase Services

Apply the configuration changes by restarting Supabase.

#### Step 4.1: Stop Supabase

```bash
# Stop all Supabase services
supabase stop

# Verify services are stopped
docker ps | grep supabase
# Should show no running containers
```

#### Step 4.2: Start Supabase

```bash
# Start Supabase with new configuration
supabase start

# Wait for services to be ready (30-60 seconds)
# Watch for "Started supabase local development setup" message
```

#### Step 4.3: Verify Services

```bash
# Check status of all services
supabase status

# Expected output should include:
# API URL: http://localhost:54321
# GraphQL URL: http://localhost:54321/graphql/v1
# DB URL: postgresql://postgres:postgres@localhost:54322/postgres
# Studio URL: http://localhost:54000
# Inbucket URL: http://localhost:54324
```

#### Step 4.4: Get Service Role Key

```bash
# Display service role key (needed for API calls)
supabase status | grep "service_role key"

# Save this key - you'll need it for registering the SAML provider
export SERVICE_ROLE_KEY="<your-service-role-key>"
```

---

### 5. Verify SAML Endpoints

Confirm that SAML endpoints are accessible and returning valid metadata.

#### Step 5.1: Check Metadata Endpoint

```bash
# Request SAML metadata (should return XML)
curl -v "http://localhost:54321/auth/v1/sso/saml/metadata"

# Or download to file for inspection
curl "http://localhost:54321/auth/v1/sso/saml/metadata" -o supabase-saml-metadata.xml
```

**Expected Response:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="http://localhost:54321/auth/v1/sso/saml/metadata">
  <SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <!-- Service Provider metadata -->
    <AssertionConsumerService 
      Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" 
      Location="http://localhost:54321/auth/v1/sso/saml/acs" 
      index="0"/>
  </SPSSODescriptor>
</EntityDescriptor>
```

#### Step 5.2: Verify Key Information in Metadata

```bash
# Check if metadata includes signing/encryption keys
grep -A 5 "KeyDescriptor" supabase-saml-metadata.xml
```

#### Step 5.3: Test ACS Endpoint

```bash
# Verify ACS endpoint is reachable (should return error without valid SAML response)
curl -v "http://localhost:54321/auth/v1/sso/saml/acs"

# Expected: 400 Bad Request or 405 Method Not Allowed (GET not allowed)
# This confirms the endpoint exists
```

**Troubleshooting:**
- **404 Not Found**: SAML is not enabled or services not restarted
- **Connection Refused**: Supabase is not running (`supabase start`)
- **Empty Response**: Check environment variables are set correctly

---

### 6. Register ZITADEL Provider

Add ZITADEL as a trusted SAML Identity Provider using the Supabase Admin API.

#### Step 6.1: Prepare Provider Configuration

Create a JSON file with ZITADEL provider details:

```bash
# Create provider configuration
cat > /tmp/zitadel-provider.json <<EOF
{
  "type": "saml",
  "metadata_url": "https://<your-instance-id>.zitadel.cloud/saml/v2/metadata",
  "domains": ["yourcompany.com"],
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
```

**Configuration Fields:**
- `type`: Always "saml" for SAML providers
- `metadata_url`: ZITADEL metadata endpoint (from Phase 1)
- `domains`: Email domains allowed to use this provider (e.g., ["example.com", "company.com"])
- `attribute_mapping`: Maps ZITADEL SAML attributes to Supabase user fields

#### Step 6.2: Register Provider via API

```bash
# Set your service role key
export SERVICE_ROLE_KEY="<your-service-role-key-from-step-4.4>"

# Register the SAML provider
curl -X POST "http://localhost:54321/auth/v1/admin/sso/providers" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d @/tmp/zitadel-provider.json

# Expected response includes provider UUID
```

**Expected Success Response:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "type": "saml",
  "metadata_url": "https://<instance-id>.zitadel.cloud/saml/v2/metadata",
  "domains": ["yourcompany.com"],
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Save the provider ID** from the response - you may need it later.

#### Step 6.3: Verify Provider Registration

```bash
# List all registered SSO providers
curl "http://localhost:54321/auth/v1/admin/sso/providers" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# Expected: Array with your ZITADEL provider
```

#### Step 6.4: Update ZITADEL with Supabase Metadata

In your ZITADEL SAML application settings, update the Service Provider metadata:

1. Log in to ZITADEL Console
2. Navigate to your SAML application
3. Update **Entity ID (SP)**: `http://localhost:54321/auth/v1/sso/saml/metadata`
4. Update **ACS URL**: `http://localhost:54321/auth/v1/sso/saml/acs`
5. Save changes

**For Production:**
Replace `http://localhost:54321` with your production URL (e.g., `https://api.yourcompany.com`)

---

### 7. Test SSO Flow

Validate the complete SAML authentication flow.

#### Step 7.1: Initiate SSO Login

There are two ways to initiate SAML SSO:

**Option 1: Identity Provider-Initiated (IdP-initiated)**
1. Go to ZITADEL Console
2. Navigate to your organization
3. Click on the Supabase SAML application
4. Click "Test Login" or access the application URL

**Option 2: Service Provider-Initiated (SP-initiated)**
```bash
# Construct SSO login URL
SSO_URL="http://localhost:54321/auth/v1/sso?domain=yourcompany.com"

# Open in browser
echo "Open this URL in your browser: ${SSO_URL}"
```

#### Step 7.2: Complete Authentication

1. **Browser Redirect**: Should redirect to ZITADEL login page
2. **Login**: Enter ZITADEL credentials for test user
3. **Consent** (if required): Approve attribute sharing
4. **Redirect Back**: Should redirect to Supabase with SAML response
5. **Session Created**: User should be authenticated in Supabase

#### Step 7.3: Verify User Creation

```bash
# Check if user was created in Supabase
curl "http://localhost:54321/auth/v1/admin/users" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.users[] | select(.email=="testuser@yourcompany.com")'

# Expected: User object with SAML identity
```

#### Step 7.4: Inspect User Metadata

```bash
# Get detailed user information
curl "http://localhost:54321/auth/v1/admin/users/<user-id>" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.identities[] | select(.provider=="saml")'

# Should show SAML identity with provider details
```

---

## Configuration Reference

### Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `GOTRUE_SAML_ENABLED` | Yes | Enable SAML SSO | `true` |
| `GOTRUE_SAML_PRIVATE_KEY` | Yes | Base64-encoded DER private key | `MIIEvgIBADAN...` |
| `GOTRUE_SAML_RELAY_STATE` | No | Default post-login redirect URL | `http://localhost:3000/dashboard` |

### config.toml Settings

```toml
[auth]
enabled = true
site_url = "http://localhost:8000"

[auth.external.saml]
enabled = true
```

### API Endpoints

| Endpoint | Method | Description | Authentication |
|----------|--------|-------------|----------------|
| `/auth/v1/sso/saml/metadata` | GET | Service Provider metadata (XML) | None (public) |
| `/auth/v1/sso/saml/acs` | POST | Assertion Consumer Service | None (SAML response) |
| `/auth/v1/sso?domain=<domain>` | GET | Initiate SSO login | None (public) |
| `/auth/v1/admin/sso/providers` | GET | List SSO providers | Service role key |
| `/auth/v1/admin/sso/providers` | POST | Register SSO provider | Service role key |
| `/auth/v1/admin/sso/providers/{id}` | GET | Get provider details | Service role key |
| `/auth/v1/admin/sso/providers/{id}` | PUT | Update provider | Service role key |
| `/auth/v1/admin/sso/providers/{id}` | DELETE | Remove provider | Service role key |

### Attribute Mapping

Maps ZITADEL SAML attributes to Supabase user fields:

| Supabase Field | ZITADEL SAML Attribute | Required | Description |
|----------------|------------------------|----------|-------------|
| `email` | `Email` | Yes | User email address |
| `name` | `FullName` | No | Full name |
| `given_name` | `FirstName` | No | First name |
| `family_name` | `SurName` | No | Last name |

Additional custom attributes can be included in `user_metadata`.

---

## Troubleshooting

### SAML Endpoints Return 404

**Symptoms:**
- `/auth/v1/sso/saml/metadata` returns 404
- `/auth/v1/sso/saml/acs` returns 404

**Solutions:**

1. **Verify SAML is enabled**
   ```bash
   grep "GOTRUE_SAML_ENABLED" .env
   # Should show: GOTRUE_SAML_ENABLED=true
   ```

2. **Check environment variables are loaded**
   ```bash
   # Restart Supabase to reload .env
   supabase stop
   supabase start
   ```

3. **Verify auth service is running**
   ```bash
   docker ps | grep supabase_auth
   # Should show running container
   ```

4. **Check auth service logs**
   ```bash
   docker logs supabase_auth_supabase 2>&1 | grep -i saml
   # Look for SAML initialization messages
   ```

---

### Invalid SAML Private Key Error

**Symptoms:**
- Auth service fails to start
- Logs show "invalid private key" or "failed to parse key"

**Solutions:**

1. **Verify key format is DER**
   ```bash
   # Check key file type
   file private_key.der
   # Should show: private_key.der: data
   ```

2. **Regenerate key without line breaks**
   ```bash
   # macOS
   base64 -i private_key.der -o private_key.base64
   
   # Linux (ensure -w 0 for no line wrapping)
   base64 -w 0 private_key.der > private_key.base64
   ```

3. **Verify base64 string has no spaces or newlines**
   ```bash
   # Check for newlines
   cat private_key.base64 | wc -l
   # Should show: 1 (single line)
   
   # Check for spaces
   grep " " private_key.base64
   # Should show nothing
   ```

4. **Test key validity**
   ```bash
   # Decode and verify key structure
   cat private_key.base64 | base64 -d | openssl rsa -inform DER -check -noout
   # Should show: RSA key ok
   ```

---

### SAML Response Validation Fails

**Symptoms:**
- Login redirects to ZITADEL successfully
- Redirect back to Supabase fails with error
- Logs show "invalid signature" or "SAML assertion validation failed"

**Solutions:**

1. **Verify metadata URLs match**
   ```bash
   # Check Supabase metadata
   curl "http://localhost:54321/auth/v1/sso/saml/metadata" | grep entityID
   
   # Compare with ZITADEL configuration
   # Entity ID in ZITADEL must exactly match Supabase metadata URL
   ```

2. **Check ACS URL configuration**
   - Supabase ACS: `http://localhost:54321/auth/v1/sso/saml/acs`
   - ZITADEL ACS: Must match exactly (check SAML app settings)

3. **Verify clock synchronization**
   ```bash
   # SAML assertions are time-sensitive
   date
   # Ensure system time is accurate
   ```

4. **Check SAML assertion attributes**
   - Use browser developer tools → Network tab
   - Inspect SAML response POST to `/acs`
   - Verify attributes match the configured mapping

---

### Provider Registration Fails

**Symptoms:**
- POST to `/admin/sso/providers` returns error
- Response shows authentication error

**Solutions:**

1. **Verify service role key**
   ```bash
   # Get correct service role key
   supabase status | grep "service_role key"
   
   # Ensure it's exported
   echo $SERVICE_ROLE_KEY
   ```

2. **Check API endpoint URL**
   ```bash
   # Use correct port (54321, not 8000)
   curl "http://localhost:54321/auth/v1/admin/sso/providers" \
     -H "apikey: ${SERVICE_ROLE_KEY}" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
   ```

3. **Validate JSON payload**
   ```bash
   # Check JSON syntax
   cat /tmp/zitadel-provider.json | jq .
   # Should pretty-print without errors
   ```

4. **Test with minimal configuration**
   ```bash
   curl -X POST "http://localhost:54321/auth/v1/admin/sso/providers" \
     -H "apikey: ${SERVICE_ROLE_KEY}" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "saml",
       "metadata_url": "https://<instance-id>.zitadel.cloud/saml/v2/metadata",
       "domains": ["example.com"]
     }'
   ```

---

### User Not Created After Successful Login

**Symptoms:**
- SAML authentication succeeds
- User redirected back to Supabase
- No user appears in database

**Solutions:**

1. **Check required attributes are provided**
   ```bash
   # Email is required - verify it's in SAML assertion
   # Check ZITADEL attribute mapping includes "Email"
   ```

2. **Verify domain matches**
   ```bash
   # User email domain must match registered provider domains
   # Example: user@example.com requires domains: ["example.com"]
   ```

3. **Check user creation in logs**
   ```bash
   docker logs supabase_auth_supabase 2>&1 | grep -i "user created"
   ```

4. **Inspect auth service errors**
   ```bash
   docker logs supabase_auth_supabase 2>&1 | tail -50
   ```

---

## Security Best Practices

### Key Management

1. **Never commit private keys to git**
   ```bash
   # Verify .env is gitignored
   git check-ignore .env
   
   # Add key directory to .gitignore
   echo "supabase-saml-keys/" >> .gitignore
   ```

2. **Use different keys for dev/prod**
   - Generate separate keys for each environment
   - Store production keys in secure vault (AWS Secrets Manager, HashiCorp Vault)

3. **Rotate keys regularly**
   ```bash
   # Generate new key
   openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform DER -out private_key_new.der
   
   # Update .env with new key
   # Update ZITADEL metadata if needed
   # Restart Supabase
   ```

4. **Restrict file permissions**
   ```bash
   chmod 600 ~/supabase-saml-keys/*.der
   chmod 600 ~/supabase-saml-keys/*.base64
   ```

### Network Security

1. **Use HTTPS in production**
   - Never use HTTP for SAML in production
   - Configure SSL certificates for your domain
   - Update URLs in both Supabase and ZITADEL

2. **Restrict API access**
   - Protect admin endpoints with firewall rules
   - Use service role key only in backend services
   - Never expose service role key to frontend

3. **Enable CORS properly**
   ```toml
   # In config.toml
   [api]
   # Only allow specific origins
   # cors_allowed_origins = ["https://yourapp.com"]
   ```

### SAML Configuration

1. **Limit domains**
   ```json
   {
     "domains": ["company.com", "trusted-partner.com"]
   }
   ```

2. **Validate assertions**
   - GoTrue automatically validates SAML signatures
   - Ensure ZITADEL signing certificates are valid
   - Monitor certificate expiration

3. **Use assertion encryption (optional)**
   - Configure in ZITADEL for additional security
   - Requires public certificate on ZITADEL side

### Monitoring

1. **Log SAML events**
   ```bash
   # Monitor auth logs
   docker logs -f supabase_auth_supabase | grep -i saml
   ```

2. **Set up alerts**
   - Failed SAML authentications
   - Invalid signatures
   - Provider metadata fetch failures

3. **Regular audits**
   ```bash
   # Review registered providers
   curl "http://localhost:54321/auth/v1/admin/sso/providers" \
     -H "apikey: ${SERVICE_ROLE_KEY}" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
   
   # Review SSO users
   curl "http://localhost:54321/auth/v1/admin/users" \
     -H "apikey: ${SERVICE_ROLE_KEY}" \
     -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
     | jq '.users[] | select(.app_metadata.provider=="saml")'
   ```

---

## References

### Official Documentation

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli/introduction)
- [ZITADEL SAML Documentation](https://zitadel.com/docs/guides/integrate/saml)
- [SAML 2.0 Specification](http://docs.oasis-open.org/security/saml/v2.0/)

### Related Guides

- [ZITADEL SAML IdP Setup](./ZITADEL_SAML_IDP_SETUP.md) - Phase 1 configuration
- [README.md](../README.md) - Project overview and authentication section
- [DEVOPS.md](../DEVOPS.md) - Deployment and CI/CD

### Community Resources

- [Calvin Chan's Self-Hosted Supabase SSO Guide](https://calvincchan.com/blog/self-hosted-supabase-enable-sso)
- [Supabase CLI GitHub Discussions](https://github.com/supabase/cli/discussions)
- [ZITADEL Community](https://zitadel.com/community)

### Troubleshooting Resources

- [Supabase GitHub Issues](https://github.com/supabase/supabase/issues)
- [SAML Tracer Browser Extension](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/)
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - General troubleshooting

---

## Next Steps

After completing this configuration:

1. **Test thoroughly**
   - Test with multiple users
   - Test different email domains
   - Test error scenarios (invalid user, expired session)

2. **Configure production**
   - Update URLs to production domains
   - Use HTTPS for all endpoints
   - Generate production-specific keys

3. **Deploy to production**
   - Follow [DEVOPS.md](../DEVOPS.md) deployment guide
   - Update environment variables in production
   - Test SSO flow in production environment

4. **Enable additional features**
   - Multi-factor authentication in ZITADEL
   - Custom attribute mapping
   - Multiple SAML providers

5. **Monitor and maintain**
   - Set up logging and monitoring
   - Regular security audits
   - Key rotation schedule

---

## Appendix

### Example: Complete .env Configuration

```bash
# Supabase Configuration
SUPABASE_OPENAI_API_KEY=sk-...

# SAML SSO Configuration
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=MIIEvgIBADANBgkqhkiG9w0BAQEFAASC...
# GOTRUE_SAML_RELAY_STATE=http://localhost:3000/dashboard
```

### Example: Provider Registration Script

```bash
#!/bin/bash
# register-saml-provider.sh

set -e

# Configuration
SUPABASE_URL="http://localhost:54321"
SERVICE_ROLE_KEY="your-service-role-key"
ZITADEL_METADATA_URL="https://your-instance.zitadel.cloud/saml/v2/metadata"
ALLOWED_DOMAINS=("company.com" "example.com")

# Build JSON payload
DOMAINS_JSON=$(printf '%s\n' "${ALLOWED_DOMAINS[@]}" | jq -R . | jq -s .)

PAYLOAD=$(cat <<EOF
{
  "type": "saml",
  "metadata_url": "${ZITADEL_METADATA_URL}",
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

# Register provider
echo "Registering SAML provider..."
RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}")

# Check response
if echo "${RESPONSE}" | jq -e '.id' > /dev/null 2>&1; then
  PROVIDER_ID=$(echo "${RESPONSE}" | jq -r '.id')
  echo "✓ Provider registered successfully"
  echo "  Provider ID: ${PROVIDER_ID}"
else
  echo "✗ Provider registration failed"
  echo "${RESPONSE}" | jq .
  exit 1
fi
```

### Example: Testing Script

```bash
#!/bin/bash
# test-saml-endpoints.sh

set -e

SUPABASE_URL="http://localhost:54321"
SERVICE_ROLE_KEY="your-service-role-key"

echo "Testing SAML endpoints..."

# Test metadata endpoint
echo -n "1. Metadata endpoint... "
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_URL}/auth/v1/sso/saml/metadata")
if [ "$RESPONSE" -eq 200 ]; then
  echo "✓ OK"
else
  echo "✗ Failed (HTTP ${RESPONSE})"
fi

# Test ACS endpoint (should return 400 or 405 for GET)
echo -n "2. ACS endpoint... "
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_URL}/auth/v1/sso/saml/acs")
if [ "$RESPONSE" -eq 400 ] || [ "$RESPONSE" -eq 405 ]; then
  echo "✓ OK (endpoint exists)"
else
  echo "✗ Failed (HTTP ${RESPONSE})"
fi

# Test admin API
echo -n "3. Admin API... "
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  "${SUPABASE_URL}/auth/v1/admin/sso/providers")
if [ "$RESPONSE" -eq 200 ]; then
  echo "✓ OK"
else
  echo "✗ Failed (HTTP ${RESPONSE})"
fi

echo "Testing complete!"
```

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-01-15  
**Status**: ✅ Production Ready
