# Supabase SAML Service Provider Configuration

Complete guide for configuring **self-hosted Supabase** to use ZITADEL as a SAML 2.0 Identity Provider for enterprise SSO.

> **Important**: This guide is for self-hosted Supabase instances (Docker/Docker Compose), not supabase.com

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Phase 2: Supabase Configuration](#phase-2-supabase-configuration)
  - [1. Generate SAML Private Key](#1-generate-saml-private-key)
  - [2. Update Environment Variables](#2-update-environment-variables)
  - [3. Update docker-compose.yml](#3-update-docker-composeyml)
  - [4. Configure Kong API Gateway](#4-configure-kong-api-gateway)
  - [5. Restart Supabase](#5-restart-supabase)
  - [6. Verify SAML Endpoints](#6-verify-saml-endpoints)
  - [7. Register ZITADEL Provider](#7-register-zitadel-provider)
  - [8. Verify Provider Configuration](#8-verify-provider-configuration)
- [Configuration Reference](#configuration-reference)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Production Deployment](#production-deployment)
- [References](#references)

---

## Overview

This guide covers Phase 2 of the SAML SSO integration: configuring your self-hosted Supabase instance to act as a SAML Service Provider (SP) with ZITADEL as the Identity Provider (IdP).

### What You'll Accomplish

- Generate SAML private key for signing requests
- Configure Supabase Auth (GoTrue) to enable SAML
- Set up Kong API Gateway routes for SAML endpoints
- Register ZITADEL as a trusted Identity Provider
- Test the complete SSO authentication flow

### Architecture

```
┌─────────────────┐         SAML Request          ┌─────────────────┐
│   User Browser  │ ───────────────────────────▶ │    ZITADEL      │
│                 │                                │  (Identity      │
│                 │ ◀───────────────────────────  │   Provider)     │
│                 │         SAML Response          └─────────────────┘
│                 │              │
│                 │              ▼
│                 │         Verify & Process
│                 │              │
└─────────────────┘              ▼
                            ┌─────────────────┐
                            │    Supabase     │
                            │   (Service      │
                            │    Provider)    │
                            │  - Auth (GoTrue)│
                            │  - Kong Gateway │
                            └─────────────────┘
```

---

## Prerequisites

Before starting, ensure you have:

- ✅ **Self-hosted Supabase** instance running (Docker/Docker Compose)
- ✅ **ZITADEL** SAML application configured (see [ZITADEL_SAML_IDP_SETUP.md](./ZITADEL_SAML_IDP_SETUP.md))
- ✅ **ZITADEL metadata URL** or metadata XML file
- ✅ **Access** to docker-compose.yml file
- ✅ **Access** to .env file
- ✅ **Access** to docker/volumes/api/kong.yml (Kong configuration)
- ✅ **Service role key** (from Supabase dashboard or .env)
- ✅ **OpenSSL** installed (for generating private key)
- ✅ **curl** or similar HTTP client for API calls

### Verify Prerequisites

```bash
# Check Docker is running
docker ps

# Check OpenSSL is installed
openssl version

# Check you have access to Supabase files
ls -la docker-compose.yml
ls -la .env
ls -la docker/volumes/api/kong.yml
```

---

## Phase 2: Supabase Configuration

### 1. Generate SAML Private Key

Supabase requires a private key to sign SAML requests sent to the Identity Provider.

#### Step 1.1: Generate RSA Private Key

```bash
# Generate RSA private key in DER format
openssl genpkey -algorithm rsa -outform DER -out private_key.der

# Verify the key was created
ls -lh private_key.der
```

**Expected output**: File `private_key.der` should be created (typically 1-2 KB)

#### Step 1.2: Encode to Base64

The private key must be base64-encoded for use in environment variables:

```bash
# Encode to base64 (Linux/macOS)
base64 -i private_key.der > private_key.base64

# OR for macOS alternative
base64 private_key.der > private_key.base64

# View the encoded key (should be a long single line)
cat private_key.base64
```

#### Step 1.3: Copy Base64 Key

Copy the entire base64 string (it will be multiple lines - you need to combine them into a single line):

```bash
# Convert to single line and copy
tr -d '\n' < private_key.base64 > private_key_oneline.txt
cat private_key_oneline.txt
```

**Security Note**: Keep this private key secure! Do not commit it to version control.

---

### 2. Update Environment Variables

Add SAML configuration to your `.env` file.

#### Step 2.1: Edit .env File

Open your `.env` file and add the following at the end:

```bash
# SAML SSO Configuration
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<paste-your-base64-key-here-as-single-line>
```

**Example**:
```bash
# SAML SSO Configuration
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
```

#### Step 2.2: Verify Configuration

```bash
# Check that variables are set correctly
grep GOTRUE_SAML .env

# Ensure the private key is a single line (no line breaks)
grep GOTRUE_SAML_PRIVATE_KEY .env | grep -c '^'
# Should output: 1 (meaning it's one line)
```

---

### 3. Update docker-compose.yml

Add environment variables to the `auth` service so GoTrue can use SAML.

#### Step 3.1: Locate Auth Service

Open your `docker-compose.yml` and find the `auth` service definition. It typically looks like:

```yaml
services:
  auth:
    image: supabase/gotrue:latest
    container_name: supabase-auth
    depends_on:
      - db
    environment:
      # ... existing environment variables ...
```

#### Step 3.2: Add SAML Environment Variables

Add the SAML configuration to the `environment` section:

```yaml
services:
  auth:
    image: supabase/gotrue:latest
    container_name: supabase-auth
    depends_on:
      - db
    environment:
      # ... existing environment variables ...
      
      # SAML SSO Configuration
      GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED}
      GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY}
```

#### Step 3.3: Save and Verify

```bash
# Verify the changes
grep -A 2 "GOTRUE_SAML" docker-compose.yml
```

**Note**: Make sure the indentation matches your existing docker-compose.yml structure.

---

### 4. Configure Kong API Gateway

Kong is the API gateway that routes requests to Supabase services. We need to add routes for SAML endpoints that are publicly accessible (no API key required).

#### Step 4.1: Locate Kong Configuration

Find your Kong configuration file. Common locations:
- `docker/volumes/api/kong.yml`
- `volumes/api/kong.yml`
- `kong/kong.yml`

```bash
# Find kong.yml
find . -name "kong.yml" -type f
```

#### Step 4.2: Add SAML Routes

Open `docker/volumes/api/kong.yml` (or your Kong config location) and add these routes to the **services** section:

```yaml
## Open Auth SAML routes (NO API KEY REQUIRED)
## These routes must be accessible without authentication for the SAML flow

- name: auth-v1-open-sso-acs
  url: "http://auth:9999/sso/saml/acs"
  routes:
    - name: auth-v1-open-sso-acs
      strip_path: true
      paths:
        - /auth/v1/sso/saml/acs
  plugins:
    - name: cors

- name: auth-v1-open-sso-metadata
  url: "http://auth:9999/sso/saml/metadata"
  routes:
    - name: auth-v1-open-sso-metadata
      strip_path: true
      paths:
        - /auth/v1/sso/saml/metadata
  plugins:
    - name: cors
```

#### Step 4.3: Understanding the Routes

| Route | Purpose | Public Access |
|-------|---------|---------------|
| `/auth/v1/sso/saml/acs` | **Assertion Consumer Service** - Receives SAML assertions from IdP | ✅ Yes (required for SAML flow) |
| `/auth/v1/sso/saml/metadata` | **Service Provider Metadata** - Provides SP configuration to IdP | ✅ Yes (IdP needs to fetch this) |

**Important**: These routes MUST be in the "open" section without API key requirements, or the SAML flow will fail.

#### Step 4.4: Verify Kong Configuration

```bash
# Check the configuration syntax
docker-compose config | grep -A 10 "sso/saml"

# Or validate the Kong config directly
cat docker/volumes/api/kong.yml | grep -A 5 "sso-acs"
```

---

### 5. Restart Supabase

Apply the configuration changes by restarting the Supabase services.

#### Step 5.1: Stop Services

```bash
# Stop all Supabase services
docker-compose down

# Verify all containers are stopped
docker ps | grep supabase
```

#### Step 5.2: Start Services

```bash
# Start all services with new configuration
docker-compose up -d

# Check that all services started successfully
docker-compose ps
```

#### Step 5.3: Verify Auth Service

Check that the auth service (GoTrue) started correctly with SAML enabled:

```bash
# Check auth container logs
docker-compose logs auth | tail -n 50

# Look for SAML-related log messages (if any)
docker-compose logs auth | grep -i saml
```

**Expected**: The auth service should start without errors.

---

### 6. Verify SAML Endpoints

Test that the SAML endpoints are accessible through Kong.

#### Step 6.1: Check Metadata Endpoint

```bash
# Test metadata endpoint (should return XML)
curl -i http://localhost:8000/auth/v1/sso/saml/metadata?download=true

# OR with just the path
curl http://localhost:8000/auth/v1/sso/saml/metadata
```

**Expected output**:
```xml
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" 
                  entityID="http://localhost:8000/auth/v1/sso/saml/metadata">
  <SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <!-- Service Provider configuration -->
  </SPSSODescriptor>
</EntityDescriptor>
```

#### Step 6.2: Save Metadata XML

If the endpoint works, save the metadata for reference:

```bash
# Save Supabase SP metadata
curl http://localhost:8000/auth/v1/sso/saml/metadata > supabase-sp-metadata.xml

# View the metadata
cat supabase-sp-metadata.xml
```

#### Step 6.3: Verify Key Information

From the metadata, note these values:

| Value | Location in Metadata |
|-------|---------------------|
| **Entity ID (SP)** | `<EntityDescriptor entityID="...">` |
| **ACS URL** | `<AssertionConsumerService Location="...">` |
| **Public Certificate** | `<X509Certificate>...</X509Certificate>` (if present) |

---

### 7. Register ZITADEL Provider

Add ZITADEL as a trusted SAML Identity Provider using the Supabase Admin API.

#### Step 7.1: Get Service Role Key

Your service role key is needed for admin API calls. Find it in:
- Supabase Dashboard → Settings → API → `service_role` key
- OR in your `.env` file: `SUPABASE_SERVICE_ROLE_KEY` or `SERVICE_ROLE_KEY`

```bash
# Check .env for service role key
grep SERVICE_ROLE .env

# Set as environment variable for convenience
export SERVICE_ROLE_KEY="your-service-role-key-here"
```

#### Step 7.2: Get ZITADEL Metadata URL

From Phase 1 (ZITADEL setup), you should have the metadata URL:

**Format**: `https://<instance-id>.zitadel.cloud/saml/v2/metadata`

Example: `https://my-company-abc123.zitadel.cloud/saml/v2/metadata`

```bash
# Test that the ZITADEL metadata is accessible
curl https://<instance-id>.zitadel.cloud/saml/v2/metadata
```

#### Step 7.3: Register Provider via API

Use curl to register ZITADEL as a SAML provider:

```bash
curl -X POST http://localhost:8000/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "saml",
    "metadata_url": "https://<instance-id>.zitadel.cloud/saml/v2/metadata",
    "domains": ["yourcompany.com"],
    "attribute_mapping": {
      "keys": {
        "email": {"name": "Email"},
        "name": {"name": "FullName"},
        "given_name": {"name": "FirstName"},
        "family_name": {"name": "SurName"}
      }
    }
  }'
```

#### Step 7.4: Customize Configuration

**Replace these values**:

| Field | Description | Example |
|-------|-------------|---------|
| `metadata_url` | ZITADEL metadata endpoint | `https://abc123.zitadel.cloud/saml/v2/metadata` |
| `domains` | Email domains that trigger this SSO | `["yourcompany.com", "example.com"]` |
| `attribute_mapping` | Map ZITADEL SAML attributes to Supabase user fields | See below |

**Attribute Mapping Reference**:

```json
{
  "keys": {
    "email": {"name": "Email"},           // Required: User's email
    "name": {"name": "FullName"},         // Full display name
    "given_name": {"name": "FirstName"},  // First name
    "family_name": {"name": "SurName"},   // Last name
    "user_name": {"name": "UserName"}     // Optional: Username
  }
}
```

The `"name"` values must match the SAML attribute names configured in ZITADEL (see Phase 1 documentation).

#### Step 7.5: Successful Response

If successful, you'll receive a response with the provider details:

```json
{
  "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "saml": {
    "entity_id": "https://<instance-id>.zitadel.cloud/saml/v2/metadata",
    "metadata_url": "https://<instance-id>.zitadel.cloud/saml/v2/metadata",
    "attribute_mapping": {
      "keys": {
        "email": {"name": "Email"},
        "name": {"name": "FullName"},
        "given_name": {"name": "FirstName"},
        "family_name": {"name": "SurName"}
      }
    }
  },
  "domains": ["yourcompany.com"]
}
```

**Important**: Save the `id` value (provider UUID) for future reference.

---

### 8. Verify Provider Configuration

Confirm that the ZITADEL provider was registered successfully.

#### Step 8.1: List All Providers

```bash
curl http://localhost:8000/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

**Expected output**: An array of providers, including your ZITADEL configuration.

#### Step 8.2: Get Specific Provider

If you have the provider ID:

```bash
curl http://localhost:8000/auth/v1/admin/sso/providers/{provider-id} \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

#### Step 8.3: Verify Configuration

Check that:
- ✅ Provider type is `saml`
- ✅ Metadata URL is correct
- ✅ Domains match your organization
- ✅ Attribute mapping is correct

---

## Configuration Reference

### Environment Variables Summary

Add these to your `.env` file:

```bash
# SAML SSO Configuration
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<base64-encoded-private-key>
```

### Docker Compose Configuration

Add to `auth` service in `docker-compose.yml`:

```yaml
auth:
  environment:
    GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED}
    GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY}
```

### Kong Routes Configuration

Add to `kong.yml` services section:

```yaml
- name: auth-v1-open-sso-acs
  url: "http://auth:9999/sso/saml/acs"
  routes:
    - name: auth-v1-open-sso-acs
      strip_path: true
      paths:
        - /auth/v1/sso/saml/acs
  plugins:
    - name: cors

- name: auth-v1-open-sso-metadata
  url: "http://auth:9999/sso/saml/metadata"
  routes:
    - name: auth-v1-open-sso-metadata
      strip_path: true
      paths:
        - /auth/v1/sso/saml/metadata
  plugins:
    - name: cors
```

### SAML Endpoints

| Endpoint | Purpose | Access |
|----------|---------|--------|
| `/auth/v1/sso/saml/metadata` | Service Provider metadata (XML) | Public |
| `/auth/v1/sso/saml/acs` | Assertion Consumer Service (receives SAML response) | Public |
| `/auth/v1/admin/sso/providers` | Manage SSO providers (API) | Service Role only |

---

## Testing

### Complete SSO Flow Test

#### Step 1: Initiate Login

Navigate to your application's login page and trigger SSO:

```bash
# For testing, you can simulate the flow by calling the SSO endpoint
curl -i http://localhost:8000/auth/v1/sso?domain=yourcompany.com
```

This should redirect to ZITADEL's login page.

#### Step 2: ZITADEL Login

1. You should be redirected to ZITADEL login page
2. Enter test user credentials (from Phase 1)
3. Complete any MFA if configured
4. ZITADEL will send SAML response back to Supabase

#### Step 3: Verify User Creation

After successful login, check that the user was created:

```bash
# Query users table (requires database access)
psql -h localhost -p 54322 -U postgres -d postgres \
  -c "SELECT id, email, raw_user_meta_data FROM auth.users;"

# OR use Supabase Admin API
curl http://localhost:8000/auth/v1/admin/users \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

#### Step 4: Verify User Attributes

Check that user attributes were mapped correctly:

```bash
# Check user metadata includes SAML attributes
psql -h localhost -p 54322 -U postgres -d postgres \
  -c "SELECT email, raw_user_meta_data->>'name' as full_name, 
             raw_user_meta_data->>'given_name' as first_name,
             raw_user_meta_data->>'family_name' as last_name
      FROM auth.users 
      WHERE email = 'test.user@yourcompany.com';"
```

---

## Troubleshooting

### Issue 1: Metadata Endpoint Returns 404

**Symptoms**:
```bash
curl http://localhost:8000/auth/v1/sso/saml/metadata
# Returns: 404 Not Found
```

**Solutions**:
1. **Check Kong routes**: Ensure SAML routes are in `kong.yml`
2. **Restart Docker Compose**: `docker-compose down && docker-compose up -d`
3. **Check Auth service logs**: `docker-compose logs auth`
4. **Verify GOTRUE_SAML_ENABLED**: `docker-compose exec auth env | grep GOTRUE_SAML`

```bash
# Verify environment variable is set
docker-compose exec auth env | grep GOTRUE_SAML_ENABLED
# Should output: GOTRUE_SAML_ENABLED=true
```

### Issue 2: API Call to Register Provider Fails

**Symptoms**:
```bash
curl -X POST http://localhost:8000/auth/v1/admin/sso/providers ...
# Returns: 401 Unauthorized or 403 Forbidden
```

**Solutions**:
1. **Verify Service Role Key**: Check that `SERVICE_ROLE_KEY` is correct
2. **Check Headers**: Both `APIKey` and `Authorization` headers are required
3. **Test Admin Endpoint**: Try listing users to verify credentials

```bash
# Test admin access
curl http://localhost:8000/auth/v1/admin/users \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

### Issue 3: SAML Response Not Accepted

**Symptoms**: User is redirected back from ZITADEL but login fails

**Solutions**:
1. **Check SAML metadata URLs match**: 
   - Entity ID in Supabase metadata must match what's configured in ZITADEL
   - ACS URL must be exactly `http://localhost:8000/auth/v1/sso/saml/acs`

2. **Verify attribute mapping**: Ensure SAML attribute names match:
   ```bash
   # Check ZITADEL metadata for attribute names
   curl https://<instance-id>.zitadel.cloud/saml/v2/metadata | grep AttributeStatement
   ```

3. **Check Auth logs**:
   ```bash
   docker-compose logs auth | grep -i error
   docker-compose logs auth | grep -i saml
   ```

### Issue 4: Private Key Format Error

**Symptoms**: Auth service fails to start or SAML operations fail

**Solutions**:
1. **Verify key format**: Must be base64-encoded DER format, single line
2. **Re-generate key**:
   ```bash
   openssl genpkey -algorithm rsa -outform DER -out private_key.der
   base64 private_key.der | tr -d '\n' > private_key_oneline.txt
   ```
3. **Check for line breaks**: `GOTRUE_SAML_PRIVATE_KEY` must be one line

### Issue 5: CORS Errors in Browser

**Symptoms**: Browser console shows CORS errors during SSO flow

**Solutions**:
1. **Verify CORS plugin**: Ensure `plugins: - name: cors` is set in Kong routes
2. **Check Kong logs**: `docker-compose logs kong`
3. **Add explicit CORS config** in `kong.yml`:
   ```yaml
   plugins:
     - name: cors
       config:
         origins:
           - "http://localhost:3000"
           - "http://localhost:8000"
         methods:
           - GET
           - POST
           - OPTIONS
         headers:
           - Authorization
           - Content-Type
         credentials: true
   ```

### Debugging Tools

#### View Auth Service Environment

```bash
# Check environment variables in auth container
docker-compose exec auth env | grep GOTRUE
```

#### Test SAML Metadata Parsing

```bash
# Download and validate Supabase SP metadata
curl http://localhost:8000/auth/v1/sso/saml/metadata > sp-metadata.xml
xmllint --format sp-metadata.xml

# Download and validate ZITADEL IdP metadata
curl https://<instance-id>.zitadel.cloud/saml/v2/metadata > idp-metadata.xml
xmllint --format idp-metadata.xml
```

#### Enable Verbose Logging

Add to `docker-compose.yml` auth service:

```yaml
auth:
  environment:
    LOG_LEVEL: debug
```

Then restart: `docker-compose restart auth`

---

## Security Best Practices

### 1. Secure Private Key Storage

**Protect the SAML private key**:

```bash
# Set restrictive permissions on key files
chmod 600 private_key.der private_key.base64

# Never commit private keys to version control
echo "private_key.*" >> .gitignore
echo "*.der" >> .gitignore
```

**Production**: Use secret management (AWS Secrets Manager, HashiCorp Vault, etc.)

### 2. Use HTTPS in Production

**Always use HTTPS for production SAML endpoints**:

```
✅ GOOD:  https://yourdomain.com/auth/v1/sso/saml/acs
❌ BAD:   http://yourdomain.com/auth/v1/sso/saml/acs
```

Update in production:
- ZITADEL SAML app ACS URL
- Supabase `site_url` in config.toml
- All redirect URLs

### 3. Restrict Domain Access

Only allow SSO for verified company email domains:

```json
{
  "domains": ["verified-company.com", "subsidiary.com"]
}
```

**Do not use public domains**: `gmail.com`, `yahoo.com`, etc.

### 4. Implement Just-In-Time Provisioning

Supabase automatically creates users on first SSO login (JIT provisioning). Consider:

- **User lifecycle**: Implement deprovisioning when users leave
- **Role mapping**: Map ZITADEL roles to Supabase user metadata
- **Audit logging**: Track SSO login events

### 5. Monitor and Audit

```sql
-- Track SSO logins
SELECT 
  email,
  last_sign_in_at,
  raw_app_meta_data->>'provider' as auth_provider
FROM auth.users
WHERE raw_app_meta_data->>'provider' = 'saml'
ORDER BY last_sign_in_at DESC;
```

### 6. Rotate Keys Regularly

Schedule private key rotation:

```bash
# Generate new key
openssl genpkey -algorithm rsa -outform DER -out private_key_new.der

# Update .env with new key
# Restart Supabase
docker-compose restart auth

# Keep old key for brief overlap period
# Then delete old key securely
shred -u private_key_old.der
```

### 7. Validate Metadata Signatures

ZITADEL metadata includes signing certificates. Verify:

```bash
# Check certificate in IdP metadata
curl https://<instance-id>.zitadel.cloud/saml/v2/metadata | \
  grep -A 1 "X509Certificate"
```

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] HTTPS configured with valid SSL certificate
- [ ] Domain name configured and DNS updated
- [ ] `site_url` updated to production domain in `supabase/config.toml`
- [ ] ZITADEL SAML app updated with production URLs
- [ ] Private key securely stored (secrets manager)
- [ ] Service role key rotated and secured
- [ ] Backup of current configuration
- [ ] Testing completed on staging environment

### Production Configuration

#### 1. Update site_url

In `supabase/config.toml`:

```toml
[auth]
site_url = "https://yourdomain.com"
additional_redirect_urls = ["https://app.yourdomain.com"]
```

#### 2. Update ZITADEL SAML App

In ZITADEL console, update:
- **Entity ID (SP)**: `https://yourdomain.com/auth/v1/sso/saml/metadata`
- **ACS URL**: `https://yourdomain.com/auth/v1/sso/saml/acs`

#### 3. Update Kong Routes

Ensure Kong routes use proper domains:

```yaml
routes:
  - name: auth-v1-open-sso-acs
    strip_path: true
    paths:
      - /auth/v1/sso/saml/acs
    hosts:
      - yourdomain.com
```

#### 4. Register Production Provider

```bash
curl -X POST https://yourdomain.com/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "saml",
    "metadata_url": "https://<instance-id>.zitadel.cloud/saml/v2/metadata",
    "domains": ["yourcompany.com"],
    "attribute_mapping": {
      "keys": {
        "email": {"name": "Email"},
        "name": {"name": "FullName"},
        "given_name": {"name": "FirstName"},
        "family_name": {"name": "SurName"}
      }
    }
  }'
```

### Post-Deployment Testing

1. **Test SSO flow** with real user accounts
2. **Verify attribute mapping** is working correctly
3. **Check logs** for any errors
4. **Monitor performance** of SAML endpoints
5. **Validate security** headers and HTTPS

---

## References

### Official Documentation

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [GoTrue (Supabase Auth) GitHub](https://github.com/supabase/gotrue)
- [ZITADEL Documentation](https://zitadel.com/docs)
- [SAML 2.0 Specification](https://docs.oasis-open.org/security/saml/v2.0/)

### Related Guides

- [ZITADEL SAML IdP Setup (Phase 1)](./ZITADEL_SAML_IDP_SETUP.md)
- [Calvin Chan's Self-Hosted Supabase SSO Guide](https://calvincchan.com/blog/self-hosted-supabase-enable-sso)
- [GitHub Issue #1335 - Supabase CLI SSO Discussion](https://github.com/supabase/cli/issues/1335)

### Project Documentation

- [README.md - Authentication & SSO](../README.md#authentication--sso)
- [DEVOPS.md - Deployment Guide](../DEVOPS.md)
- [RLS_POLICIES.md - Row Level Security](./RLS_POLICIES.md)

---

## Appendix

### A. Complete curl Example

Full command with all parameters:

```bash
#!/bin/bash
# register-zitadel-provider.sh

# Configuration
SERVICE_ROLE_KEY="your-service-role-key-here"
SUPABASE_URL="http://localhost:8000"
ZITADEL_INSTANCE="your-instance-id"
COMPANY_DOMAIN="yourcompany.com"

# Register ZITADEL as SAML provider
curl -X POST "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "type": "saml",
  "metadata_url": "https://${ZITADEL_INSTANCE}.zitadel.cloud/saml/v2/metadata",
  "domains": ["${COMPANY_DOMAIN}"],
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

### B. Environment Variables Template

Complete `.env` template for SAML SSO:

```bash
# Supabase Core Configuration
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
POSTGRES_PASSWORD=your-db-password

# SAML SSO Configuration
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...

# Site Configuration
SITE_URL=http://localhost:8000
REDIRECT_URLS=http://localhost:3000,http://localhost:8000

# Optional: SMTP for emails
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-smtp-password
```

### C. Docker Compose Complete Example

Example `docker-compose.yml` auth service configuration:

```yaml
services:
  auth:
    image: supabase/gotrue:v2.143.0
    container_name: supabase-auth
    depends_on:
      - db
    restart: unless-stopped
    environment:
      # Database
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD}@db:5432/postgres?search_path=auth
      
      # API
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      GOTRUE_SITE_URL: ${SITE_URL}
      GOTRUE_URI_ALLOW_LIST: ${REDIRECT_URLS}
      
      # JWT
      GOTRUE_JWT_SECRET: ${JWT_SECRET}
      GOTRUE_JWT_EXP: 3600
      GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated
      
      # Security
      GOTRUE_DISABLE_SIGNUP: false
      GOTRUE_EXTERNAL_EMAIL_ENABLED: true
      GOTRUE_MAILER_AUTOCONFIRM: false
      
      # SAML SSO
      GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED}
      GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY}
      
      # Logging
      GOTRUE_LOG_LEVEL: info
    ports:
      - "9999:9999"
```

### D. Kong Configuration Complete Example

Full Kong `services` section example:

```yaml
_format_version: "3.0"

services:
  ## Auth Service (Protected)
  - name: auth-v1
    url: http://auth:9999
    routes:
      - name: auth-v1-all
        strip_path: true
        paths:
          - /auth/v1
    plugins:
      - name: key-auth
      - name: cors

  ## Open Auth SAML routes (NO API KEY REQUIRED)
  - name: auth-v1-open-sso-acs
    url: "http://auth:9999/sso/saml/acs"
    routes:
      - name: auth-v1-open-sso-acs
        strip_path: true
        paths:
          - /auth/v1/sso/saml/acs
    plugins:
      - name: cors
        config:
          origins:
            - "*"
          methods:
            - GET
            - POST
            - OPTIONS
          headers:
            - Accept
            - Authorization
            - Content-Type
          credentials: true

  - name: auth-v1-open-sso-metadata
    url: "http://auth:9999/sso/saml/metadata"
    routes:
      - name: auth-v1-open-sso-metadata
        strip_path: true
        paths:
          - /auth/v1/sso/saml/metadata
    plugins:
      - name: cors
        config:
          origins:
            - "*"
          methods:
            - GET
            - OPTIONS
          headers:
            - Accept
            - Content-Type
          credentials: true
```

---

**Last Updated**: 2025-01-10  
**Version**: 1.0.0  
**Status**: ✅ Complete

**Related Issues**:
- Phase 1: Issue #69 - ZITADEL SAML IdP Setup
- Phase 2: Issue #70 - Supabase SAML Configuration (this document)
- Phase 3: Issue #71 - Testing & Validation
