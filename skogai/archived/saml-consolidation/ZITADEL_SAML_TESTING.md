# ZITADEL SAML Integration Testing & Validation

Complete guide for testing and validating ZITADEL + **self-hosted Supabase** SAML SSO integration.

> **Important**: This is Phase 3 of the SAML integration. Ensure Phases 1 and 2 are complete before testing.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Test Scenarios](#test-scenarios)
  - [1. Verify SAML Endpoints](#1-verify-saml-endpoints)
  - [2. Happy Path Authentication](#2-happy-path-authentication)
  - [3. SAML Assertion Validation](#3-saml-assertion-validation)
  - [4. Attribute Mapping Tests](#4-attribute-mapping-tests)
  - [5. Error Handling Tests](#5-error-handling-tests)
  - [6. Multi-User Testing](#6-multi-user-testing)
  - [7. Docker Logs Validation](#7-docker-logs-validation)
  - [8. Security Validation](#8-security-validation)
- [Automated Test Scripts](#automated-test-scripts)
- [Test Results Documentation](#test-results-documentation)
- [Troubleshooting](#troubleshooting)
- [Known Issues](#known-issues)
- [References](#references)

---

## Overview

This guide provides comprehensive testing procedures for ZITADEL SAML integration with self-hosted Supabase. It includes both manual testing procedures and automated test scripts.

### What You'll Test

- ✅ SAML metadata endpoints
- ✅ SSO authentication flow
- ✅ SAML assertion validation
- ✅ User attribute mapping
- ✅ Error handling scenarios
- ✅ Multi-user authentication
- ✅ Security configurations
- ✅ Docker service logs

### Testing Phases

```
┌─────────────────────────┐
│  1. Endpoint Validation │ ← Verify SAML infrastructure
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  2. Authentication Flow │ ← Test happy path login
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  3. Assertion Validation│ ← Validate SAML responses
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  4. Attribute Mapping   │ ← Verify user data mapping
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  5. Error Scenarios     │ ← Test failure cases
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  6. Multi-User Testing  │ ← Test multiple users
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│  7. Security Validation │ ← Final security checks
└─────────────────────────┘
```

---

## Prerequisites

Before testing, ensure:

### Required Configurations

- ✅ **ZITADEL SAML Application**: Configured with correct Entity ID and ACS URL
- ✅ **Supabase SAML Provider**: Added to Supabase Auth configuration
- ✅ **Test Users**: At least 3 test users created in ZITADEL and assigned to SAML app
- ✅ **Service Role Key**: Available from Supabase Dashboard or `.env` file
- ✅ **Supabase Running**: Local instance running on http://localhost:8000

### Environment Variables

Set these in your `.env` file or export them:

```bash
# Service role key from Supabase Dashboard
export SERVICE_ROLE_KEY="your-service-role-key-here"

# Supabase URL (local or production)
export SUPABASE_URL="http://localhost:8000"

# ZITADEL domain (for reference)
export ZITADEL_DOMAIN="https://<instance-id>.zitadel.cloud"

# SSO domain configured in Supabase
export SSO_DOMAIN="yourcompany.com"
```

### Tools Required

- `curl` - For API testing
- `jq` - For JSON parsing (optional but recommended)
- Browser with Developer Tools - For inspecting SAML assertions
- SAML Tracer Browser Extension - For detailed SAML debugging (optional)

Install tools:

```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get install curl jq

# Check installation
curl --version
jq --version
```

---

## Quick Start

Run the automated test suite:

```bash
# 1. Ensure Supabase is running
npm run db:start

# 2. Run SAML test suite
npm run test:saml

# Or manually
./scripts/test_saml.sh
```

For detailed manual testing, follow the test scenarios below.

---

## Test Scenarios

### 1. Verify SAML Endpoints

#### Test 1.1: Metadata Endpoint Accessibility

**Purpose**: Verify that Supabase SAML metadata endpoint is accessible and returns valid XML.

**Steps**:

```bash
# Test metadata endpoint
curl -v http://localhost:8000/auth/v1/sso/saml/metadata

# Or download metadata
curl -o supabase-saml-metadata.xml http://localhost:8000/auth/v1/sso/saml/metadata?download=true
```

**Expected Results**:
- HTTP 200 OK response
- Valid XML document
- Contains `<EntityDescriptor>` element
- Entity ID matches: `http://localhost:8000/auth/v1/sso/saml/metadata`
- Contains `<AssertionConsumerService>` with location: `http://localhost:8000/auth/v1/sso/saml/acs`

**Validation**:

```bash
# Check if XML is valid
xmllint --noout supabase-saml-metadata.xml && echo "Valid XML" || echo "Invalid XML"

# Verify Entity ID
grep -o 'entityID="[^"]*"' supabase-saml-metadata.xml
```

#### Test 1.2: List SSO Providers

**Purpose**: Verify ZITADEL provider is registered in Supabase.

**Steps**:

```bash
# List all SSO providers
curl -X GET "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json"
```

**Expected Results**:
- HTTP 200 OK response
- JSON array containing provider objects
- At least one provider with `provider: "saml"`
- Provider domain matches your SSO domain configuration
- Provider includes ZITADEL metadata URL or configuration

**Validation with jq**:

```bash
# Count SAML providers
curl -s -X GET "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '[.[] | select(.provider == "saml")] | length'

# Display SAML provider details
curl -s -X GET "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '[.[] | select(.provider == "saml")]'
```

#### Test 1.3: Verify SSO Initiation URL

**Purpose**: Verify SSO login URL is accessible.

**Steps**:

```bash
# Test SSO initiation (should redirect to ZITADEL)
curl -I "http://localhost:8000/auth/v1/sso?domain=${SSO_DOMAIN}"
```

**Expected Results**:
- HTTP 302 or 303 redirect response
- `Location` header points to ZITADEL SSO endpoint
- URL contains SAML authentication request parameters

**Pass Criteria**:
- ✅ Metadata endpoint returns valid XML
- ✅ ZITADEL provider appears in provider list
- ✅ Provider configuration matches ZITADEL settings
- ✅ SSO initiation URL redirects to ZITADEL

---

### 2. Happy Path Authentication

#### Test 2.1: Full SSO Authentication Flow

**Purpose**: Test complete end-to-end authentication with a valid user.

**Steps**:

1. **Start SSO Flow**
   - Open browser and navigate to: `http://localhost:8000/auth/v1/sso?domain=${SSO_DOMAIN}`
   - Or use your application's SSO login button

2. **Verify Redirect to ZITADEL**
   - Browser should redirect to ZITADEL login page
   - URL should contain ZITADEL domain
   - Page displays ZITADEL login form

3. **Enter Test User Credentials**
   - Enter test user email and password
   - Click "Sign In" or "Login"

4. **Complete Authentication**
   - ZITADEL processes authentication
   - User may see consent screen (first time)
   - Accept consent if prompted

5. **Verify Redirect to Supabase**
   - Browser redirects back to `http://localhost:8000/auth/v1/sso/saml/acs`
   - SAML assertion is posted to ACS endpoint
   - User should be redirected to application callback URL

6. **Verify Session Creation**
   - Check browser cookies for Supabase auth token
   - Verify session is active

**Browser DevTools Verification**:

```javascript
// In browser console, check for auth cookie
document.cookie.split(';').filter(c => c.includes('auth'));

// Check localStorage
localStorage.getItem('supabase.auth.token');
```

#### Test 2.2: Verify User Created in Database

**Purpose**: Confirm user was created in `auth.users` table.

**Steps**:

```bash
# Get test user email
TEST_USER_EMAIL="testuser1@example.com"

# Query user by email
curl -X GET "http://localhost:8000/auth/v1/admin/users?email=${TEST_USER_EMAIL}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.users[0]'
```

**Expected Results**:
- User object returned with matching email
- `provider` field shows "saml" or SAML provider identifier
- `raw_user_meta_data` contains attributes from ZITADEL
- `created_at` timestamp is recent

#### Test 2.3: Verify User Metadata

**Purpose**: Check that all SAML attributes were mapped correctly.

**Steps**:

```bash
# Get user details including metadata
USER_ID="<user-id-from-previous-step>"

curl -X GET "http://localhost:8000/auth/v1/admin/users/${USER_ID}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.raw_user_meta_data'
```

**Expected Attributes in Metadata**:
- `email` - User's email address
- `first_name` or `given_name` - User's first name
- `last_name` or `family_name` - User's last name
- `full_name` or `name` - User's full name
- `sub` or `user_id` - ZITADEL user ID

**Pass Criteria**:
- ✅ SSO flow completes without errors
- ✅ User is redirected to ZITADEL login page
- ✅ Authentication at ZITADEL succeeds
- ✅ User is redirected back to Supabase ACS
- ✅ Session is created successfully
- ✅ User appears in `auth.users` table
- ✅ User metadata is populated correctly

---

### 3. SAML Assertion Validation

#### Test 3.1: Capture SAML Response

**Purpose**: Inspect the actual SAML assertion to verify its structure and content.

**Using Browser DevTools**:

1. Open Browser Developer Tools (F12)
2. Go to "Network" tab
3. Filter by "Doc" or "All"
4. Clear network log
5. Initiate SSO login
6. Find POST request to `/auth/v1/sso/saml/acs`
7. View "Payload" or "Request" tab
8. Look for `SAMLResponse` parameter (Base64 encoded)
9. Copy the Base64 value

**Decode SAML Response**:

```bash
# Save Base64 SAML response to file
echo "PD94bWw..." > saml_response_b64.txt

# Decode Base64
base64 -d saml_response_b64.txt > saml_response.xml

# Pretty print XML
xmllint --format saml_response.xml
```

**Using SAML Tracer Extension**:

1. Install SAML Tracer (Firefox or Chrome)
2. Open SAML Tracer window
3. Initiate SSO login
4. SAML Tracer will capture and display SAML request/response
5. View decoded SAML assertion

#### Test 3.2: Validate SAML Assertion Structure

**Purpose**: Verify SAML response contains all required elements.

**Required Elements**:

```xml
<samlp:Response>
  <saml:Issuer><!-- ZITADEL Entity ID --></saml:Issuer>
  <samlp:Status>
    <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
  </samlp:Status>
  <saml:Assertion>
    <saml:Subject>
      <saml:NameID><!-- User identifier --></saml:NameID>
    </saml:Subject>
    <saml:Conditions>
      <saml:AudienceRestriction>
        <saml:Audience><!-- Supabase Entity ID --></saml:Audience>
      </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AttributeStatement>
      <saml:Attribute Name="Email">
        <saml:AttributeValue>...</saml:AttributeValue>
      </saml:Attribute>
      <!-- More attributes -->
    </saml:AttributeStatement>
  </saml:Assertion>
</samlp:Response>
```

**Validation Checklist**:
- [ ] Response status is "Success"
- [ ] Issuer matches ZITADEL Entity ID
- [ ] Audience matches Supabase Entity ID: `http://localhost:8000/auth/v1/sso/saml/metadata`
- [ ] Subject NameID is present
- [ ] AttributeStatement contains expected attributes
- [ ] Response is signed (has `<Signature>` element)
- [ ] Assertion is signed (optional, depending on config)
- [ ] Timestamps are within acceptable window

#### Test 3.3: Verify Required Attributes

**Purpose**: Ensure all mapped attributes are present in SAML assertion.

**Check for Attributes**:

```bash
# Extract attributes from decoded XML
xmllint --xpath "//saml:Attribute/@Name" saml_response.xml
```

**Required Attributes** (from ZITADEL config):
- `Email`
- `FirstName`
- `SurName`
- `FullName`
- `UserName`
- `UserID`

#### Test 3.4: Verify Signature

**Purpose**: Confirm SAML assertion is properly signed by ZITADEL.

**Manual Verification**:
- Check for `<ds:Signature>` element in assertion
- Verify signature algorithm (RSA-SHA256 recommended)
- Certificate DN should match ZITADEL's certificate

**Note**: Supabase validates the signature automatically. If authentication succeeds, signature is valid.

#### Test 3.5: Validate Timestamps

**Purpose**: Verify timestamps are within acceptable time window.

**Check These Elements**:

```xml
<saml:Conditions NotBefore="..." NotOnOrAfter="...">
  <!-- Assertion validity window -->
</saml:Conditions>

<saml:AuthnStatement AuthnInstant="...">
  <!-- Authentication time -->
</saml:AuthnStatement>
```

**Validation**:
- `NotBefore` should be recent (within last few minutes)
- `NotOnOrAfter` should be in the future (typically 5-10 minutes)
- `AuthnInstant` should match login time
- Clock skew should be minimal (< 5 seconds)

**Pass Criteria**:
- ✅ SAML response captured successfully
- ✅ Response status is Success
- ✅ Issuer matches ZITADEL Entity ID
- ✅ Audience matches Supabase Entity ID
- ✅ All required attributes present
- ✅ Response is properly signed
- ✅ Timestamps are valid and within window

---

### 4. Attribute Mapping Tests

#### Test 4.1: Verify All Attributes Mapped

**Purpose**: Confirm all ZITADEL attributes are correctly mapped to Supabase user metadata.

**Steps**:

```bash
# Get user metadata
USER_EMAIL="testuser1@example.com"

curl -s -X GET "http://localhost:8000/auth/v1/admin/users?email=${USER_EMAIL}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.users[0].raw_user_meta_data'
```

**Expected Mappings**:

| ZITADEL Attribute | Supabase Field | Example Value |
|-------------------|----------------|---------------|
| Email | `email` | `testuser1@example.com` |
| FirstName | `first_name` or `given_name` | `Test` |
| SurName | `last_name` or `family_name` | `User` |
| FullName | `full_name` or `name` | `Test User` |
| UserName | `username` or `preferred_username` | `testuser1` |
| UserID | `sub` or `user_id` | `123456789` |

**Validation Script**:

```bash
# Check all required fields are present
./scripts/validate_saml_attributes.sh "${USER_EMAIL}"
```

#### Test 4.2: Test with Missing Optional Attributes

**Purpose**: Verify system handles users with incomplete profiles.

**Steps**:

1. Create a test user in ZITADEL with minimal profile (only email)
2. Attempt SSO login
3. Check user metadata in Supabase

**Expected Behavior**:
- Authentication succeeds even with missing optional fields
- Required field (email) is present
- Optional fields are null or absent
- No errors in logs

#### Test 4.3: Test Special Characters in Attributes

**Purpose**: Verify proper handling of special characters.

**Test Cases**:
- Names with accented characters: `José García`
- Names with apostrophes: `O'Brien`
- Names with hyphens: `Mary-Jane`
- Email with plus sign: `user+test@example.com`

**Pass Criteria**:
- ✅ All mapped attributes appear in `raw_user_meta_data`
- ✅ Email correctly populated
- ✅ Name fields correctly populated
- ✅ System handles missing optional attributes
- ✅ Special characters preserved correctly

---

### 5. Error Handling Tests

#### Test 5.1: Invalid Credentials

**Purpose**: Verify proper error handling for failed authentication.

**Steps**:

1. Navigate to SSO login URL
2. Enter incorrect password at ZITADEL
3. Attempt to sign in

**Expected Results**:
- ZITADEL displays error message
- User remains on ZITADEL login page
- No session created in Supabase
- No error in Supabase logs

**Verification**:

```bash
# Check if session was created (should be none)
curl -s -X GET "http://localhost:8000/auth/v1/admin/users?email=${TEST_USER_EMAIL}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.users | length'
# Should return 0 if user doesn't exist yet
```

#### Test 5.2: Disabled User

**Purpose**: Test behavior when user is disabled in ZITADEL.

**Steps**:

1. Disable test user in ZITADEL console
2. Attempt SSO login with disabled user
3. Observe error handling

**Expected Results**:
- ZITADEL prevents login
- Error message displayed at ZITADEL
- No session created in Supabase
- Appropriate error logged

#### Test 5.3: Invalid Domain

**Purpose**: Test SSO with non-configured domain.

**Steps**:

```bash
# Try SSO with invalid domain
curl -I "http://localhost:8000/auth/v1/sso?domain=invalid-domain.com"
```

**Expected Results**:
- HTTP 400 or 404 error
- Error message indicating domain not configured
- No redirect to ZITADEL

#### Test 5.4: Expired SAML Assertion

**Purpose**: Verify rejection of expired assertions (advanced test).

**Note**: This requires manipulating SAML assertions, which is complex. In production, Supabase automatically rejects expired assertions.

**Verification**:
- Check that `NotOnOrAfter` time is respected
- Test with clock skew scenarios

#### Test 5.5: Tampered SAML Assertion

**Purpose**: Verify signature validation prevents tampering.

**Note**: Modifying a signed SAML assertion will invalidate its signature.

**Expected Behavior**:
- Supabase rejects tampered assertions
- Error logged about invalid signature
- No session created

**Pass Criteria**:
- ✅ Failed authentication handled at ZITADEL
- ✅ Disabled user cannot authenticate
- ✅ Invalid domain returns error
- ✅ Expired assertions rejected
- ✅ Tampered assertions rejected

---

### 6. Multi-User Testing

#### Test 6.1: Sequential User Logins

**Purpose**: Verify multiple users can authenticate independently.

**Steps**:

1. **Login User 1**
   - Open browser in normal mode
   - Complete SSO login
   - Note session token

2. **Login User 2**
   - Open browser in incognito/private mode
   - Complete SSO login with different user
   - Note session token

3. **Login User 3**
   - Open another incognito window
   - Complete SSO login with third user
   - Note session token

**Verify Each User**:

```bash
# List all users
curl -s -X GET "http://localhost:8000/auth/v1/admin/users" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '.users[] | {email: .email, id: .id, created_at: .created_at}'
```

#### Test 6.2: Verify User Isolation

**Purpose**: Ensure users cannot access each other's data.

**Steps**:

```bash
# Assuming you have RLS policies on profiles table
# Test that User 1 can only see/modify their own profile

# This would be tested through your application
# or by querying with user JWT tokens
```

**Note**: User isolation is enforced by RLS policies, not SAML. See `tests/rls_test_suite.sql` for RLS testing.

#### Test 6.3: Query All SAML Users

**Purpose**: Verify all users created via SAML.

**Steps**:

```bash
# Get all users with SAML provider
curl -s -X GET "http://localhost:8000/auth/v1/admin/users" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  | jq '[.users[] | select(.app_metadata.provider == "saml")]'
```

**Expected Results**:
- At least 3 users returned
- Each has unique ID and email
- Each has SAML provider metadata

**Pass Criteria**:
- ✅ Multiple users can authenticate sequentially
- ✅ Each user gets separate session
- ✅ User isolation maintained in database
- ✅ All users queryable in `auth.users`

---

### 7. Docker Logs Validation

#### Test 7.1: Check Auth Service Logs

**Purpose**: Verify SAML authentication logs are clean.

**Steps**:

```bash
# View auth service logs
docker-compose logs auth | grep -i saml

# Or follow logs in real-time
docker-compose logs -f auth | grep -i saml
```

**What to Look For**:
- SAML authentication requests logged
- SAML assertions processed
- User session creation logged
- **No error messages**

**Example Good Logs**:
```
auth    | INFO: SAML authentication initiated for domain: yourcompany.com
auth    | INFO: SAML assertion validated for user: testuser1@example.com
auth    | INFO: User session created: <user-id>
```

**Red Flags**:
```
auth    | ERROR: SAML signature validation failed
auth    | ERROR: Invalid SAML response
auth    | ERROR: Audience mismatch
```

#### Test 7.2: Check Kong Gateway Logs

**Purpose**: Verify API gateway is routing SAML requests correctly.

**Steps**:

```bash
# View Kong logs
docker-compose logs kong | grep -i saml

# Look for requests to SAML endpoints
docker-compose logs kong | grep -E '/sso/saml/(metadata|acs)'
```

**Expected Logs**:
- GET requests to `/auth/v1/sso/saml/metadata`
- POST requests to `/auth/v1/sso/saml/acs`
- HTTP 200 responses
- No 500 errors

#### Test 7.3: Check All Service Health

**Purpose**: Ensure all services are healthy during SAML testing.

**Steps**:

```bash
# Check status of all services
docker-compose ps

# Check for any error logs
docker-compose logs --tail=100 | grep -i error
```

**Expected Results**:
- All services show "Up" status
- No critical errors in logs
- Network connectivity stable

**Pass Criteria**:
- ✅ No error messages in auth logs
- ✅ SAML requests/responses logged properly
- ✅ Kong routing SAML traffic correctly
- ✅ All services healthy during testing

---

### 8. Security Validation

#### Test 8.1: HTTPS Configuration

**Purpose**: Verify HTTPS is used in production (or planned).

**For Local Development**:
- HTTP is acceptable for `localhost:8000`
- Document plan to migrate to HTTPS for production

**For Production**:
- **Required**: HTTPS must be configured
- Entity ID: `https://your-domain.com/auth/v1/sso/saml/metadata`
- ACS URL: `https://your-domain.com/auth/v1/sso/saml/acs`

**Verification**:

```bash
# Check if SSL is enabled
curl -I https://your-domain.com/auth/v1/sso/saml/metadata

# Verify certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

#### Test 8.2: Verify Assertions are Signed

**Purpose**: Confirm SAML responses include digital signatures.

**Check in ZITADEL Configuration**:
- Sign Response: ✅ Enabled
- Sign Assertion: ✅ Enabled (recommended)

**Verify in SAML Response**:
```bash
# Check for Signature element
grep -o "<ds:Signature" saml_response.xml
```

#### Test 8.3: Verify Signature Verification Enabled

**Purpose**: Confirm Supabase validates signatures.

**Note**: Supabase validates signatures automatically when SAML provider is configured with IdP certificate.

**Verification**:
- Test with valid signature: Authentication succeeds
- Test with invalid signature: Authentication fails

#### Test 8.4: Verify Relay State Protection

**Purpose**: Confirm SAML flow prevents CSRF attacks.

**What to Check**:
- `RelayState` parameter is used in SAML flow
- RelayState is validated on return from IdP
- State cannot be guessed or manipulated

**Verification**: Supabase handles this automatically.

#### Test 8.5: Test Tampered Assertions Rejected

**Purpose**: Verify modified assertions are rejected.

**Test Approach**:
1. Capture valid SAML response
2. Decode Base64
3. Modify XML content
4. Re-encode and replay

**Expected Result**:
- Signature validation fails
- Authentication rejected
- Error logged

**Note**: This is an advanced test. Supabase's automatic signature validation provides this protection.

**Pass Criteria**:
- ✅ HTTPS configured for production (or planned)
- ✅ SAML assertions are signed
- ✅ Signature verification enabled in Supabase
- ✅ Relay state prevents CSRF
- ✅ Tampered assertions rejected

---

## Automated Test Scripts

### Running All Tests

```bash
# Run complete test suite
npm run test:saml

# Or manually
./scripts/test_saml.sh
```

### Individual Test Scripts

```bash
# Test SAML endpoints
./scripts/test_saml_endpoints.sh

# Test user attributes
./scripts/validate_saml_attributes.sh "user@example.com"

# Check Docker logs
./scripts/check_saml_logs.sh
```

### Test Output

Expected output when all tests pass:

```
================================================================================
ZITADEL SAML INTEGRATION TEST SUITE
================================================================================

TEST 1: SAML Endpoints
  ✅ Metadata endpoint accessible
  ✅ Metadata is valid XML
  ✅ SSO provider registered
  ✅ SSO initiation URL redirects

TEST 2: Authentication Flow
  ⚠️  Manual test required - See Test Scenarios section

TEST 3: SAML Assertion
  ⚠️  Manual test required - See Test Scenarios section

TEST 4: Attribute Mapping
  ✅ All required attributes mapped
  ✅ Email field populated
  ✅ Name fields populated

TEST 5: Error Handling
  ⚠️  Manual test required - See Test Scenarios section

TEST 6: Multi-User Testing
  ✅ Multiple users created
  ✅ Each user has unique session

TEST 7: Docker Logs
  ✅ No errors in auth logs
  ✅ SAML requests logged
  ✅ All services healthy

TEST 8: Security
  ⚠️  HTTPS: Not configured (OK for local dev)
  ✅ Signatures enabled in ZITADEL config
  ✅ Signature verification enabled

================================================================================
TEST SUMMARY
================================================================================
Automated Tests: 12 passed
Manual Tests: 5 require manual verification
Status: ✅ SAML integration ready for use

Next Steps:
1. Complete manual authentication flow test
2. Test with all user types
3. Review security configurations for production
4. Document test results
================================================================================
```

---

## Test Results Documentation

### Test Report Template

Document your test results using this template:

```markdown
# SAML Integration Test Results

**Test Date**: YYYY-MM-DD
**Tester**: Your Name
**Environment**: Local Development / Staging / Production
**Supabase URL**: http://localhost:8000
**ZITADEL Domain**: https://<instance-id>.zitadel.cloud

## Test Results Summary

| Test Category | Status | Notes |
|---------------|--------|-------|
| SAML Endpoints | ✅ Pass | All endpoints accessible |
| Authentication Flow | ✅ Pass | Login successful for 3 users |
| SAML Assertions | ✅ Pass | All attributes present |
| Attribute Mapping | ✅ Pass | Metadata populated correctly |
| Error Handling | ✅ Pass | Errors handled gracefully |
| Multi-User | ✅ Pass | 3 users tested |
| Docker Logs | ✅ Pass | No errors |
| Security | ⚠️ Partial | HTTPS planned for production |

## Detailed Results

### 1. SAML Endpoints
- Metadata endpoint: ✅ Accessible
- Provider registration: ✅ Confirmed
- SSO initiation: ✅ Redirects correctly

### 2. Authentication Flow
- Test User 1: ✅ Successful login
- Test User 2: ✅ Successful login
- Test User 3: ✅ Successful login
- Session creation: ✅ Tokens issued

### 3. SAML Assertions
- Response structure: ✅ Valid XML
- Required elements: ✅ All present
- Signature: ✅ Valid
- Timestamps: ✅ Within window

### 4. Attribute Mapping
- Email: ✅ Mapped
- First Name: ✅ Mapped
- Last Name: ✅ Mapped
- Full Name: ✅ Mapped
- User ID: ✅ Mapped

### 5. Error Scenarios
- Invalid credentials: ✅ Handled at ZITADEL
- Disabled user: ✅ Access denied
- Invalid domain: ✅ Error returned

### 6. Issues Found
None

### 7. Recommendations
1. Configure HTTPS for production deployment
2. Enable audit logging for SAML events
3. Document user onboarding process

## Acceptance Criteria Met
- ✅ All happy path tests pass
- ✅ SAML assertions validated correctly
- ✅ Attribute mapping works as expected
- ✅ Error scenarios handled gracefully
- ✅ Multi-user testing successful
- ✅ No errors in Docker logs
- ⚠️ Security validation: HTTPS pending for production
```

### Save Test Results

```bash
# Save test results
./scripts/test_saml.sh > test_results/saml_test_$(date +%Y%m%d_%H%M%S).log

# Or with test report
./scripts/test_saml.sh | tee docs/SAML_TEST_RESULTS.md
```

---

## Troubleshooting

### Issue: Metadata Endpoint Returns 404

**Symptoms**:
- Cannot access `/auth/v1/sso/saml/metadata`
- Returns 404 Not Found

**Solutions**:
1. Verify Supabase is running: `docker-compose ps`
2. Check Kong gateway configuration
3. Verify SAML is enabled in Supabase Auth
4. Check GoTrue configuration

### Issue: SSO Provider Not Listed

**Symptoms**:
- SAML provider doesn't appear when listing providers
- Cannot initiate SSO flow

**Solutions**:
1. Verify SAML provider was added via Supabase Dashboard or API
2. Check provider configuration in database
3. Restart auth service: `docker-compose restart auth`
4. Verify service role key is correct

### Issue: User Not Created After Successful Login

**Symptoms**:
- Authentication succeeds at ZITADEL
- User redirected back to Supabase
- But no user in `auth.users` table

**Solutions**:
1. Check auth service logs for errors
2. Verify SAML assertion contains email attribute
3. Check attribute mapping configuration
4. Verify ACS endpoint is processing responses
5. Look for signature validation errors

### Issue: Attributes Not Mapped

**Symptoms**:
- User created but `raw_user_meta_data` is empty or incomplete
- Missing name or other fields

**Solutions**:
1. Verify attribute mapping in ZITADEL (Step 2 of setup)
2. Check that user profile in ZITADEL has all fields populated
3. Review SAML assertion to confirm attributes are sent
4. Check attribute names are correct (case-sensitive)

### Issue: Authentication Loop

**Symptoms**:
- User redirected to ZITADEL
- Logs in successfully
- Redirected back to Supabase
- Then redirected to ZITADEL again (loop)

**Solutions**:
1. Check Entity ID and ACS URL match between ZITADEL and Supabase
2. Verify Audience in SAML assertion matches Supabase Entity ID
3. Check for cookie issues in browser
4. Clear browser cookies and try again
5. Check for RelayState issues in logs

### Issue: Signature Validation Failed

**Symptoms**:
- Error in logs about invalid signature
- Authentication fails after ZITADEL login

**Solutions**:
1. Verify ZITADEL metadata was imported correctly to Supabase
2. Check that certificate in Supabase matches ZITADEL's certificate
3. Re-export and re-import ZITADEL metadata
4. Verify clock sync between ZITADEL and Supabase servers
5. Check signature algorithm compatibility

### Issue: HTTPS Certificate Errors

**Symptoms**:
- SSL/TLS errors
- Certificate validation failures

**Solutions**:
1. For local dev: Use HTTP (HTTPS not required for localhost)
2. For production: Ensure valid SSL certificate installed
3. Check certificate chain is complete
4. Verify domain names match certificate CN

### Debugging Tools

#### Enable Verbose Logging

```bash
# Set environment variable for GoTrue (Supabase Auth)
export LOG_LEVEL=debug

# Restart auth service
docker-compose restart auth

# View detailed logs
docker-compose logs -f auth
```

#### Use SAML Tracer

1. Install SAML Tracer browser extension
2. Open SAML Tracer panel
3. Perform SSO login
4. Review all SAML messages in detail

#### Validate XML Syntax

```bash
# Check SAML metadata XML
xmllint --noout supabase-saml-metadata.xml
xmllint --noout zitadel-saml-metadata.xml

# Pretty print for easier reading
xmllint --format saml_response.xml
```

#### Test with cURL

```bash
# Test endpoints with verbose output
curl -v http://localhost:8000/auth/v1/sso/saml/metadata

# Test with custom headers
curl -H "User-Agent: SAML-Test" http://localhost:8000/auth/v1/sso?domain=yourcompany.com
```

---

## Known Issues

### Self-Hosted Supabase Limitations

1. **No Automatic Account Linking**
   - Self-hosted Supabase does not support automatic account linking
   - If user exists with same email but different provider, second account created
   - Workaround: Manually link accounts or enforce single provider

2. **Single Logout (SLO) Not Fully Supported**
   - Logout at application doesn't always trigger IdP logout
   - Users may remain logged in at ZITADEL
   - Workaround: Implement application-level logout that redirects to ZITADEL logout URL

3. **Email Uniqueness Not Guaranteed**
   - Users from different SAML providers may have same email
   - Can cause confusion in user management
   - Workaround: Use unique identifier (sub) instead of email

### Browser-Specific Issues

1. **Safari Private Browsing**
   - May block third-party cookies
   - Can prevent SSO flow completion
   - Solution: Test in normal browsing mode

2. **Cookie SameSite Attribute**
   - Modern browsers enforce SameSite cookie policies
   - May affect cross-domain SSO
   - Solution: Ensure cookies configured correctly in Supabase

### Performance Considerations

1. **First Login Slower**
   - Initial SAML authentication involves multiple redirects
   - Subsequent logins faster with session cookies
   - Expected behavior, not an issue

2. **Metadata Caching**
   - ZITADEL metadata may be cached by Supabase
   - Changes to ZITADEL config may not reflect immediately
   - Solution: Restart auth service or wait for cache expiry

---

## References

### Internal Documentation

- [ZITADEL SAML IdP Setup](ZITADEL_SAML_IDP_SETUP.md) - Phase 1: ZITADEL configuration
- [README.md Authentication Section](../README.md#authentication--sso) - Authentication overview
- [RLS Testing Guide](../tests/README.md) - Testing user isolation
- [DEVOPS.md](../DEVOPS.md) - Deployment and operations

### External Documentation

- [Supabase Auth SSO](https://supabase.com/docs/guides/auth/sso/auth-sso-saml) - Official SAML documentation
- [ZITADEL SAML Guide](https://zitadel.com/docs/guides/integrate/services/saml) - ZITADEL SAML setup
- [SAML 2.0 Technical Overview](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html) - SAML specification
- [SAML Tracer Extension](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) - Debugging tool

### Related Issues

- Issue #69: ZITADEL SAML IdP Configuration
- Issue #70: Supabase SAML Configuration
- Issue #71: ZITADEL + Supabase SAML Testing & Validation (This document)
- Issue #72: Production Deployment

---

**Last Updated**: 2024-10-07  
**Version**: 1.0.0  
**Phase**: 3 - Testing & Validation  
**Status**: Ready for Testing

For questions or issues with this guide, please open an issue in the repository.
