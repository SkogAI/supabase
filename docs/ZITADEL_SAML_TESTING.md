# ZITADEL SAML Testing & Validation Guide

Complete testing and validation procedures for ZITADEL + self-hosted Supabase SAML SSO integration.

> **Phase**: Phase 3 - Testing & Validation  
> **Prerequisites**: Phases 1 & 2 completed (ZITADEL configured, Supabase SAML configured)

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Test Environment Setup](#test-environment-setup)
- [Test Scenarios](#test-scenarios)
  - [1. Verify SAML Endpoints](#1-verify-saml-endpoints)
  - [2. Happy Path Authentication](#2-happy-path-authentication)
  - [3. SAML Assertion Validation](#3-saml-assertion-validation)
  - [4. Attribute Mapping Tests](#4-attribute-mapping-tests)
  - [5. Error Handling Tests](#5-error-handling-tests)
  - [6. Multi-User Testing](#6-multi-user-testing)
  - [7. Docker Logs Verification](#7-docker-logs-verification)
  - [8. Security Validation](#8-security-validation)
- [Automated Testing](#automated-testing)
- [Troubleshooting](#troubleshooting)
- [Acceptance Criteria](#acceptance-criteria)
- [References](#references)

---

## Overview

This guide provides comprehensive testing procedures to validate that your ZITADEL SAML integration with self-hosted Supabase is working correctly. All tests should be performed in sequence, and all acceptance criteria must be met before deploying to production.

### What You'll Validate

- ✅ SAML metadata endpoints are accessible
- ✅ SAML authentication flow works end-to-end
- ✅ SAML assertions are properly signed and validated
- ✅ User attributes are correctly mapped
- ✅ Error scenarios are handled gracefully
- ✅ Multiple users can authenticate successfully
- ✅ Security controls are in place
- ✅ Logs are clean and informative

---

## Prerequisites

Before beginning tests, ensure:

### Configuration Complete

- ✅ **ZITADEL SAML application configured** (see `docs/ZITADEL_SAML_IDP_SETUP.md`)
- ✅ **Supabase SAML provider configured** (Issue #70)
- ✅ **Test users created** in ZITADEL (minimum 3 users)
- ✅ **Supabase instance running** (`npm run db:start`)

### Required Information

Collect the following information before testing:

```bash
# ZITADEL Information
ZITADEL_INSTANCE_ID="your-instance-id"
ZITADEL_ENTITY_ID="https://<instance-id>.zitadel.cloud/saml/v2/metadata"
ZITADEL_SSO_URL="https://<instance-id>.zitadel.cloud/saml/v2/SSO"

# Supabase Information
SUPABASE_URL="http://localhost:8000"  # Or your production URL
SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# Test Domain (configured in SAML provider)
SSO_DOMAIN="yourcompany.com"

# Test User Credentials (from ZITADEL)
TEST_USER_1_EMAIL="testuser1@yourcompany.com"
TEST_USER_1_PASSWORD="secure-password"
TEST_USER_2_EMAIL="testuser2@yourcompany.com"
TEST_USER_2_PASSWORD="secure-password"
TEST_USER_3_EMAIL="testuser3@yourcompany.com"
TEST_USER_3_PASSWORD="secure-password"
```

### Tools Required

- ✅ **curl** - Command-line HTTP client
- ✅ **jq** - JSON processor (install: `sudo apt install jq` or `brew install jq`)
- ✅ **Browser** with developer tools (Chrome/Firefox recommended)
- ✅ **SAML Tracer** browser extension (optional but recommended)
  - Chrome: [SAML Chrome Panel](https://chrome.google.com/webstore/detail/saml-chrome-panel)
  - Firefox: [SAML-tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/)

---

## Test Environment Setup

### 1. Start Supabase Services

```bash
# Start local Supabase (ensure Docker is running)
npm run db:start

# Verify all services are running
npm run db:status
```

Expected output should show all services as "healthy":
- API: http://localhost:54321
- Studio: http://localhost:8000
- Auth: Running
- Storage: Running
- Realtime: Running

### 2. Get Service Role Key

```bash
# Service role key is shown in db:status output
# Or get it from config
supabase status --output json | jq -r '.service_role_key'
```

Save this key - you'll need it for admin API calls.

### 3. Create Test Environment File

Create a file `tests/saml_test_config.sh` with your values:

```bash
#!/bin/bash
# SAML Test Configuration

# Supabase Configuration
export SUPABASE_URL="http://localhost:8000"
export SUPABASE_ANON_KEY="your-anon-key-here"
export SERVICE_ROLE_KEY="your-service-role-key-here"

# SSO Configuration
export SSO_DOMAIN="yourcompany.com"

# ZITADEL Configuration
export ZITADEL_ENTITY_ID="https://your-instance.zitadel.cloud/saml/v2/metadata"

# Test Users (do not commit real passwords to version control!)
export TEST_USER_1_EMAIL="testuser1@yourcompany.com"
export TEST_USER_2_EMAIL="testuser2@yourcompany.com"
export TEST_USER_3_EMAIL="testuser3@yourcompany.com"
```

**⚠️ Security Note**: Add `tests/saml_test_config.sh` to `.gitignore` to prevent committing credentials.

---

## Test Scenarios

### 1. Verify SAML Endpoints

#### Test 1.1: Metadata Endpoint Accessibility

**Objective**: Verify Supabase SAML metadata endpoint is accessible and returns valid XML.

```bash
# Test metadata endpoint
curl -v "${SUPABASE_URL}/auth/v1/sso/saml/metadata?download=true" \
  -o /tmp/supabase-metadata.xml

# Verify it's valid XML
cat /tmp/supabase-metadata.xml | head -20
```

**Expected Result**:
- ✅ HTTP 200 OK response
- ✅ Content-Type: `application/samlmetadata+xml` or `text/xml`
- ✅ Valid XML structure with `<EntityDescriptor>` root element
- ✅ Contains Entity ID matching `${SUPABASE_URL}/auth/v1/sso/saml/metadata`
- ✅ Contains ACS URL: `${SUPABASE_URL}/auth/v1/sso/saml/acs`

**Validation**:
```bash
# Check for required elements
grep -q "EntityDescriptor" /tmp/supabase-metadata.xml && echo "✅ EntityDescriptor found"
grep -q "AssertionConsumerService" /tmp/supabase-metadata.xml && echo "✅ ACS endpoint found"
grep -q "auth/v1/sso/saml/metadata" /tmp/supabase-metadata.xml && echo "✅ Entity ID found"
```

#### Test 1.2: List SSO Providers

**Objective**: Verify ZITADEL SAML provider is registered in Supabase.

```bash
# List all SSO providers
curl "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.'
```

**Expected Result**:
- ✅ HTTP 200 OK response
- ✅ JSON array returned
- ✅ At least one provider with `"saml"` protocol
- ✅ Provider `domains` array includes your configured domain (e.g., "yourcompany.com")

**Validation**:
```bash
# Check for ZITADEL provider
curl -s "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq -e '.[] | select(.saml != null)' > /dev/null && echo "✅ SAML provider found"
```

#### Test 1.3: Verify Provider Configuration

**Objective**: Confirm provider configuration matches ZITADEL settings.

```bash
# Get specific provider details
curl "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.[] | select(.saml != null) | {
      id: .id,
      domains: .domains,
      entity_id: .saml.entity_id,
      metadata_url: .saml.metadata_url
    }'
```

**Expected Result**:
- ✅ `entity_id` matches ZITADEL Entity ID
- ✅ `metadata_url` points to ZITADEL metadata endpoint
- ✅ `domains` array contains your test domain

---

### 2. Happy Path Authentication

#### Test 2.1: Initiate SSO Flow

**Objective**: Test the complete SSO authentication flow with a test user.

**Manual Steps**:

1. **Open Browser** (use Chrome/Firefox with SAML Tracer enabled)

2. **Navigate to SSO initiation URL**:
   ```
   http://localhost:8000/auth/v1/sso?domain=yourcompany.com
   ```
   Replace `yourcompany.com` with your configured domain.

3. **Expected Behavior**:
   - ✅ Browser redirects to ZITADEL login page
   - ✅ URL contains `zitadel.cloud/saml/v2/SSO` or your ZITADEL domain
   - ✅ SAML request is sent (visible in SAML Tracer)

#### Test 2.2: ZITADEL Authentication

**Manual Steps**:

1. **Enter test user credentials** on ZITADEL login page
   - Username/Email: `testuser1@yourcompany.com`
   - Password: `[your test password]`

2. **Click Login**

3. **Expected Behavior**:
   - ✅ Successful authentication at ZITADEL
   - ✅ Browser redirects back to Supabase
   - ✅ Redirect URL is `${SUPABASE_URL}/auth/v1/sso/saml/acs`
   - ✅ SAML response is POSTed to ACS endpoint (visible in SAML Tracer)

#### Test 2.3: Session Creation

**Manual Steps**:

1. **After redirect**, check for session cookie
   - Open Browser DevTools → Application/Storage → Cookies
   - Look for `sb-access-token` or similar Supabase session cookie

2. **Verify session** programmatically:
   ```bash
   # Get the access token from browser cookie or redirect
   # Then verify with:
   curl "${SUPABASE_URL}/auth/v1/user" \
     -H "Authorization: Bearer ${ACCESS_TOKEN}" \
     | jq '.'
   ```

**Expected Result**:
- ✅ Session cookie is set
- ✅ User object returned with correct email
- ✅ `app_metadata` and `user_metadata` populated
- ✅ User appears in `auth.users` table

#### Test 2.4: Database Verification

**Objective**: Verify user is created in auth.users table.

```bash
# Connect to database and check
supabase db execute --sql "
  SELECT 
    id,
    email,
    raw_app_meta_data->'provider' as provider,
    raw_user_meta_data->>'full_name' as full_name,
    created_at
  FROM auth.users 
  WHERE email = '${TEST_USER_1_EMAIL}';
" | jq '.'
```

**Expected Result**:
- ✅ User record exists
- ✅ Email matches test user
- ✅ Provider is `saml`
- ✅ Full name and other attributes populated
- ✅ Created timestamp is recent

---

### 3. SAML Assertion Validation

#### Test 3.1: Capture SAML Response

**Objective**: Capture and inspect the SAML response from ZITADEL.

**Manual Steps Using SAML Tracer**:

1. **Install SAML Tracer** browser extension
2. **Open SAML Tracer** before logging in
3. **Perform SSO login** (Test 2.1 - 2.2)
4. **In SAML Tracer**, find the POST request to `/auth/v1/sso/saml/acs`
5. **Click on request** → View SAML Response

#### Test 3.2: Verify Response Structure

**Expected SAML Response Elements**:

```xml
<samlp:Response>
  <saml:Issuer>https://[instance-id].zitadel.cloud/saml/v2/metadata</saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion>
    <saml:Subject>
      <saml:NameID>testuser1@yourcompany.com</saml:NameID>
    </saml:Subject>
    <saml:Conditions>
      <saml:AudienceRestriction>
        <saml:Audience>http://localhost:8000/auth/v1/sso/saml/metadata</saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AttributeStatement>
      <saml:Attribute Name="Email">
        <saml:AttributeValue>testuser1@yourcompany.com</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="FirstName">
        <saml:AttributeValue>Test</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="SurName">
        <saml:AttributeValue>User</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="FullName">
        <saml:AttributeValue>Test User</saml:AttributeValue>
      </saml:Attribute>
      <saml:Attribute Name="UserID">
        <saml:AttributeValue>123456789</saml:AttributeValue>
      </saml:Attribute>
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>
```

**Verification Checklist**:
- ✅ Status code is `Success`
- ✅ Issuer matches ZITADEL Entity ID
- ✅ Audience matches Supabase Entity ID
- ✅ NameID contains user email
- ✅ All expected attributes present (Email, FirstName, SurName, FullName, UserID)

#### Test 3.3: Verify Signature

**Objective**: Confirm SAML assertion is properly signed.

In SAML Tracer or response XML, look for:
```xml
<ds:Signature>
  <ds:SignedInfo>
    <ds:SignatureMethod Algorithm="..."/>
  </ds:SignedInfo>
  <ds:SignatureValue>...</ds:SignatureValue>
  <ds:KeyInfo>
    <ds:X509Certificate>...</ds:X509Certificate>
  </ds:KeyInfo>
</ds:Signature>
```

**Verification**:
- ✅ `<ds:Signature>` element present
- ✅ Signature algorithm is secure (RSA-SHA256 or better)
- ✅ X.509 certificate included
- ✅ Supabase validates signature (no errors in logs)

#### Test 3.4: Verify Timestamps

**Objective**: Ensure SAML response is within acceptable time window.

Check `<saml:Conditions>`:
```xml
<saml:Conditions 
  NotBefore="2024-01-15T10:00:00Z" 
  NotOnOrAfter="2024-01-15T10:05:00Z">
```

**Verification**:
- ✅ Current time is after `NotBefore`
- ✅ Current time is before `NotOnOrAfter`
- ✅ Typical validity window: 5 minutes
- ✅ No clock skew issues (sync system clocks if needed)

---

### 4. Attribute Mapping Tests

#### Test 4.1: Verify User Metadata

**Objective**: Confirm all SAML attributes are correctly mapped to user metadata.

```bash
# Get user details including metadata
curl "${SUPABASE_URL}/auth/v1/admin/users" \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.users[] | select(.email == "testuser1@yourcompany.com") | {
      email: .email,
      full_name: .user_metadata.full_name,
      first_name: .user_metadata.first_name,
      last_name: .user_metadata.last_name,
      user_id: .user_metadata.user_id,
      provider: .app_metadata.provider,
      providers: .app_metadata.providers
    }'
```

**Expected Result**:
```json
{
  "email": "testuser1@yourcompany.com",
  "full_name": "Test User",
  "first_name": "Test",
  "last_name": "User",
  "user_id": "123456789",
  "provider": "saml",
  "providers": ["saml"]
}
```

**Verification Checklist**:
- ✅ All attributes present in `user_metadata`
- ✅ Email correctly populated
- ✅ Name fields correctly populated (first_name, last_name, full_name)
- ✅ Provider is `saml`
- ✅ No missing or null attributes

#### Test 4.2: Test with Partial Attributes

**Objective**: Verify system handles users with missing optional attributes.

**Manual Steps**:
1. Create a test user in ZITADEL with only required fields (email)
2. Leave optional fields (first name, last name) empty
3. Perform SSO login with this user
4. Check user metadata

**Expected Result**:
- ✅ User can still authenticate
- ✅ Email is populated
- ✅ Optional fields are null or not present (doesn't cause error)
- ✅ Application handles missing attributes gracefully

#### Test 4.3: Raw Metadata Inspection

**Objective**: Inspect raw SAML attributes in database.

```bash
# Query raw metadata
supabase db execute --sql "
  SELECT 
    email,
    raw_user_meta_data,
    raw_app_meta_data
  FROM auth.users 
  WHERE email = '${TEST_USER_1_EMAIL}';
" | jq '.'
```

**Expected in `raw_user_meta_data`**:
```json
{
  "email": "testuser1@yourcompany.com",
  "full_name": "Test User",
  "first_name": "Test",
  "last_name": "User",
  "user_id": "123456789",
  "iss": "https://[instance].zitadel.cloud/saml/v2/metadata",
  "sub": "..."
}
```

---

### 5. Error Handling Tests

#### Test 5.1: Failed Authentication

**Objective**: Verify error handling for incorrect credentials.

**Manual Steps**:
1. Navigate to SSO URL: `${SUPABASE_URL}/auth/v1/sso?domain=yourcompany.com`
2. On ZITADEL login page, enter **incorrect password**
3. Click Login

**Expected Behavior**:
- ✅ ZITADEL shows error message (e.g., "Invalid credentials")
- ✅ User remains on ZITADEL login page
- ✅ No redirect to Supabase
- ✅ No session created in Supabase
- ✅ No user record created in `auth.users`

**Verification**:
```bash
# Verify no new sessions created
# Check auth logs (covered in section 7)
docker logs $(docker ps -q -f name=supabase_auth) --tail 50 | grep -i error
```

#### Test 5.2: Disabled User

**Objective**: Test behavior when ZITADEL user is disabled.

**Manual Steps**:
1. In ZITADEL console, **disable** a test user
2. Attempt SSO login with disabled user
3. Observe behavior

**Expected Behavior**:
- ✅ ZITADEL prevents login or shows "user disabled" error
- ✅ No SAML response sent to Supabase
- ✅ No session created
- ✅ User sees appropriate error message

**Cleanup**: Re-enable test user after testing.

#### Test 5.3: Invalid Domain

**Objective**: Test SSO with non-configured domain.

```bash
# Try SSO with invalid domain
curl -v "${SUPABASE_URL}/auth/v1/sso?domain=invalid-domain.com"
```

**Expected Result**:
- ✅ HTTP 400 or 404 error
- ✅ Error message: "No SSO provider found for domain"
- ✅ No redirect to ZITADEL
- ✅ Clear error response

#### Test 5.4: Expired SAML Response

**Objective**: Verify Supabase rejects expired SAML assertions.

This test requires SAML response manipulation (advanced):
1. Capture a SAML response
2. Modify timestamps to be outside valid window
3. Replay modified response

**Expected Behavior**:
- ✅ Supabase rejects expired assertion
- ✅ Error logged in auth service
- ✅ No session created
- ✅ User sees error page

**Note**: This is an advanced test and may require custom tooling.

#### Test 5.5: Tampered Assertion

**Objective**: Verify signature validation prevents tampered assertions.

**Manual Test** (requires SAML debugging tools):
1. Capture SAML response
2. Modify user email or attributes
3. Replay without re-signing

**Expected Behavior**:
- ✅ Supabase detects invalid signature
- ✅ Authentication fails
- ✅ Error: "Invalid SAML signature" or similar
- ✅ Security event logged

---

### 6. Multi-User Testing

#### Test 6.1: Sequential User Logins

**Objective**: Verify multiple users can authenticate successfully.

**Manual Steps**:
1. Log in with User 1 (testuser1@yourcompany.com)
2. Note the session token
3. Log out or clear session
4. Log in with User 2 (testuser2@yourcompany.com)
5. Note the session token
6. Repeat with User 3

**Verification**:
```bash
# Check all users were created
supabase db execute --sql "
  SELECT 
    email,
    created_at,
    last_sign_in_at
  FROM auth.users 
  WHERE email IN (
    '${TEST_USER_1_EMAIL}',
    '${TEST_USER_2_EMAIL}',
    '${TEST_USER_3_EMAIL}'
  )
  ORDER BY created_at;
" | jq '.'
```

**Expected Result**:
- ✅ All 3 users exist in database
- ✅ Each user has unique `id`
- ✅ Each user has separate session
- ✅ Email addresses are correct
- ✅ Last sign-in timestamps are recent and sequential

#### Test 6.2: Concurrent Sessions

**Objective**: Verify users can have separate concurrent sessions.

**Manual Steps**:
1. Browser 1 (Chrome): Log in as User 1
2. Browser 2 (Firefox): Log in as User 2
3. In each browser, verify session:
   ```javascript
   // In browser console
   document.cookie
   ```

**Expected Behavior**:
- ✅ Both users logged in simultaneously
- ✅ Sessions are independent (different tokens)
- ✅ User 1 cannot access User 2's data (if RLS is configured)

#### Test 6.3: User Isolation

**Objective**: Verify proper data isolation between users.

```bash
# Query users table
supabase db execute --sql "
  SELECT 
    COUNT(*) as total_users,
    COUNT(DISTINCT email) as unique_emails,
    COUNT(DISTINCT id) as unique_ids
  FROM auth.users 
  WHERE email LIKE '%@yourcompany.com';
" | jq '.'
```

**Expected Result**:
- ✅ `total_users` matches number of test logins
- ✅ `unique_emails` equals `total_users`
- ✅ `unique_ids` equals `total_users`
- ✅ No duplicate users created

---

### 7. Docker Logs Verification

#### Test 7.1: Auth Service Logs

**Objective**: Check GoTrue (Auth) logs for SAML-related messages.

```bash
# View auth service logs
docker logs $(docker ps -q -f name=supabase_auth) --tail 100 | grep -i saml
```

**What to Look For**:
- ✅ SAML provider initialization messages
- ✅ Successful SAML authentications
- ✅ No error messages or stack traces
- ✅ Proper request/response logging

**Example Good Logs**:
```
INFO: SAML SSO initiated for domain: yourcompany.com
INFO: SAML response received from IdP
INFO: SAML assertion validated successfully
INFO: User authenticated via SAML: testuser1@yourcompany.com
```

**Red Flags** (should NOT see):
```
ERROR: Invalid SAML signature
ERROR: SAML assertion expired
ERROR: Failed to parse SAML response
WARN: Missing required SAML attribute
```

#### Test 7.2: Kong Gateway Logs

**Objective**: Verify API gateway is routing SAML requests correctly.

```bash
# View Kong logs
docker logs $(docker ps -q -f name=supabase_kong) --tail 100 | grep -i saml
```

**Expected**:
- ✅ Requests to `/auth/v1/sso/saml/*` are logged
- ✅ HTTP 200 responses for successful auth
- ✅ HTTP 302 redirects for SSO initiation
- ✅ No 500 errors

#### Test 7.3: Full Auth Flow Logs

**Objective**: Trace complete authentication flow through logs.

```bash
# Follow logs during login
docker logs -f $(docker ps -q -f name=supabase_auth) &
LOG_PID=$!

# Perform login in browser, then stop following logs
sleep 30
kill $LOG_PID
```

**Expected Flow in Logs**:
1. SSO initiation request received
2. Redirect to IdP (ZITADEL)
3. SAML response received at ACS endpoint
4. Assertion validation started
5. Signature verified
6. Attributes extracted
7. User created/updated in database
8. Session token issued
9. Redirect to application

#### Test 7.4: Error Log Analysis

**Objective**: Ensure no unexpected errors during testing.

```bash
# Check for any errors in auth logs
docker logs $(docker ps -q -f name=supabase_auth) --since 1h 2>&1 | grep -i error

# Check for warnings
docker logs $(docker ps -q -f name=supabase_auth) --since 1h 2>&1 | grep -i warn
```

**Expected**:
- ✅ No errors related to SAML
- ✅ No warnings about missing configuration
- ✅ No stack traces or exceptions

---

### 8. Security Validation

#### Test 8.1: HTTPS Verification

**Objective**: Verify secure connection (production only).

**For Local Development**:
- ⚠️ HTTP is acceptable for `localhost` testing
- ✅ Document plan to migrate to HTTPS for production

**For Production**:
```bash
# Check if HTTPS is used
curl -v https://your-domain.com/auth/v1/sso/saml/metadata 2>&1 | grep -i "ssl\|tls"
```

**Expected for Production**:
- ✅ TLS 1.2 or 1.3
- ✅ Valid SSL certificate
- ✅ No certificate warnings
- ✅ All SAML URLs use HTTPS

#### Test 8.2: Signature Verification Enabled

**Objective**: Confirm SAML assertions must be signed.

**Verification**:
1. Check SAML provider configuration in Supabase
2. Ensure "Require Signed Assertions" is enabled
3. Test with unsigned assertion (should fail - see Test 5.5)

**Expected**:
- ✅ Signature verification is enabled in configuration
- ✅ Unsigned assertions are rejected
- ✅ Invalid signatures are detected

#### Test 8.3: Relay State CSRF Protection

**Objective**: Verify RelayState prevents CSRF attacks.

During SSO flow, check for `RelayState` parameter:
```bash
# In SAML request (visible in SAML Tracer)
<samlp:AuthnRequest>
  ...
  <samlp:RelayState>random-state-value</samlp:RelayState>
</samlp:AuthnRequest>
```

**Expected**:
- ✅ RelayState is present and unique per request
- ✅ Same RelayState returned in SAML response
- ✅ Supabase validates RelayState matches

#### Test 8.4: Token Security

**Objective**: Verify session tokens are secure.

**Check Session Cookie Attributes**:
```javascript
// In browser console after login
document.cookie.split('; ').forEach(c => console.log(c))
```

**Expected Cookie Attributes**:
- ✅ `HttpOnly` - Prevents JavaScript access
- ✅ `Secure` - Only sent over HTTPS (production)
- ✅ `SameSite=Lax` or `SameSite=Strict` - CSRF protection
- ✅ Appropriate expiration time

#### Test 8.5: Metadata Security

**Objective**: Verify metadata endpoints don't leak sensitive information.

```bash
# Check metadata contents
curl "${SUPABASE_URL}/auth/v1/sso/saml/metadata" | grep -i "private\|secret\|password"
```

**Expected**:
- ✅ No private keys in metadata
- ✅ No secrets or passwords
- ✅ Only public information (certificates, URLs)

---

## Automated Testing

### Running Automated Tests

The project includes automated test scripts to streamline validation:

```bash
# Run all SAML tests
npm run test:saml

# Or run individual test scripts
./tests/saml_endpoint_test.sh
./tests/saml_provider_test.sh
./tests/saml_user_test.sh
```

### Test Scripts Overview

1. **saml_endpoint_test.sh** - Tests SAML endpoints (metadata, ACS)
2. **saml_provider_test.sh** - Validates SSO provider configuration
3. **saml_user_test.sh** - Verifies user creation and attributes

### Creating Custom Tests

Example custom test script:

```bash
#!/bin/bash
# tests/custom_saml_test.sh

source tests/saml_test_config.sh

echo "Running custom SAML test..."

# Your test logic here
curl -s "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq -e '.[] | select(.saml != null)' > /dev/null

if [ $? -eq 0 ]; then
  echo "✅ PASS: Custom test passed"
  exit 0
else
  echo "❌ FAIL: Custom test failed"
  exit 1
fi
```

---

## Troubleshooting

### Common Issues

#### Issue: Metadata endpoint returns 404

**Symptoms**: `/auth/v1/sso/saml/metadata` not found

**Solutions**:
- Verify Supabase is running: `npm run db:status`
- Check auth service is healthy: `docker ps`
- Ensure SAML provider is configured (see Issue #70)
- Check logs: `docker logs $(docker ps -q -f name=supabase_auth)`

#### Issue: Redirect loop during SSO

**Symptoms**: Browser keeps redirecting between Supabase and ZITADEL

**Solutions**:
- Clear browser cookies and cache
- Verify ACS URL matches in both ZITADEL and Supabase
- Check for URL encoding issues
- Verify domain configuration in SAML provider

#### Issue: User attributes not populated

**Symptoms**: User created but metadata is empty

**Solutions**:
- Check attribute mapping in ZITADEL (see `docs/ZITADEL_SAML_IDP_SETUP.md`)
- Verify user profile is complete in ZITADEL
- Check SAML assertion in SAML Tracer for missing attributes
- Verify attribute names match exactly (case-sensitive)

#### Issue: "Invalid SAML signature" error

**Symptoms**: Authentication fails with signature error

**Solutions**:
- Verify ZITADEL metadata URL is correct in Supabase
- Check X.509 certificate is current (not expired)
- Ensure metadata is up-to-date (re-import if needed)
- Verify clock synchronization between systems

#### Issue: Session not created after successful ZITADEL login

**Symptoms**: User logs in at ZITADEL but no session in Supabase

**Solutions**:
- Check auth service logs for errors
- Verify ACS endpoint is receiving POST request
- Check for CORS issues (usually not relevant for redirects)
- Verify Supabase database is accessible

### Getting Help

If issues persist:

1. **Check Documentation**:
   - [ZITADEL SAML Setup](./ZITADEL_SAML_IDP_SETUP.md)
   - [Supabase Auth Docs](https://supabase.com/docs/guides/auth/sso/auth-sso-saml)
   - [ZITADEL Documentation](https://zitadel.com/docs)

2. **Review Logs**:
   - Auth service: `docker logs supabase_auth`
   - Kong gateway: `docker logs supabase_kong`
   - Database: `docker logs supabase_db`

3. **Use Debugging Tools**:
   - SAML Tracer browser extension
   - Browser developer tools (Network tab)
   - `curl -v` for API debugging

4. **Community Support**:
   - Supabase Discord: https://discord.supabase.com
   - ZITADEL Discord: https://zitadel.com/chat
   - GitHub Issues: Open an issue with full logs and configuration

---

## Acceptance Criteria

Before considering SAML integration complete, verify all criteria are met:

### Functional Requirements
- ✅ All happy path tests pass (Section 2)
- ✅ SAML assertions validated correctly (Section 3)
- ✅ Attribute mapping works as expected (Section 4)
- ✅ Error scenarios handled gracefully (Section 5)
- ✅ Multi-user testing successful (Section 6)
- ✅ No errors in Docker logs (Section 7)
- ✅ Security validation complete (Section 8)

### Test Coverage
- ✅ Minimum 3 test users authenticated successfully
- ✅ All test scenarios executed and documented
- ✅ Both positive and negative tests performed
- ✅ Edge cases tested (missing attributes, errors, etc.)

### Documentation
- ✅ Test results documented (create `SAML_TEST_RESULTS.md`)
- ✅ Known issues documented (if any)
- ✅ Runbook created for production deployment
- ✅ Troubleshooting guide updated with findings

### Security
- ✅ HTTPS plan documented for production
- ✅ Signature verification confirmed working
- ✅ CSRF protection verified (RelayState)
- ✅ No sensitive data in logs or metadata

### Performance
- ✅ SSO flow completes within acceptable time (<5 seconds)
- ✅ No performance degradation with multiple users
- ✅ Database queries are efficient

---

## References

### Internal Documentation
- [ZITADEL SAML IdP Setup](./ZITADEL_SAML_IDP_SETUP.md) - Phase 1 configuration
- [Supabase SAML Configuration](../README.md#authentication--sso) - Phase 2 configuration
- [RLS Testing Guide](./RLS_TESTING.md) - User isolation testing patterns

### External Documentation
- [Supabase SSO Documentation](https://supabase.com/docs/guides/auth/sso/auth-sso-saml)
- [ZITADEL SAML Documentation](https://zitadel.com/docs/guides/integrate/saml)
- [SAML 2.0 Technical Overview](https://en.wikipedia.org/wiki/SAML_2.0)
- [OASIS SAML 2.0 Specification](https://docs.oasis-open.org/security/saml/v2.0/)

### Tools & Resources
- [SAML Tracer - Chrome](https://chrome.google.com/webstore/detail/saml-chrome-panel)
- [SAML Tracer - Firefox](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/)
- [SAMLTool.com](https://www.samltool.com/) - Online SAML debugging
- [SAML Validator](https://www.samltool.com/validate_response.php) - Response validation

### Related Issues
- Issue #69: ZITADEL SAML IdP Setup (Phase 1)
- Issue #70: Supabase SAML Configuration (Phase 2)
- Issue #71: SAML Testing & Validation (Phase 3 - This Document)
- Issue #72: Production SAML Deployment (Phase 4)

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-01-15  
**Maintained By**: DevOps Team
