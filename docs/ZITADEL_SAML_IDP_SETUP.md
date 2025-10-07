# ZITADEL SAML Identity Provider Setup

Complete guide for configuring ZITADEL as a SAML 2.0 Identity Provider for **self-hosted Supabase** authentication.

> **Important**: This guide is for self-hosted Supabase instances, not supabase.com

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Phase 1: ZITADEL Configuration](#phase-1-zitadel-configuration)
  - [1. Create SAML Application](#1-create-saml-application)
  - [2. Configure Attribute Mapping](#2-configure-attribute-mapping)
  - [3. Export Metadata](#3-export-metadata)
  - [4. Create Test Users](#4-create-test-users)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Next Steps](#next-steps)
- [References](#references)

---

## Overview

ZITADEL is an open-source identity and access management (IAM) platform that supports SAML 2.0. This guide walks through configuring ZITADEL as a SAML Identity Provider (IdP) to enable Single Sign-On (SSO) for your self-hosted Supabase instance.

### What You'll Accomplish

- Create and configure a SAML application in ZITADEL
- Map user attributes from ZITADEL to SAML assertions
- Export SAML metadata for Supabase configuration
- Set up test users for validation

### Architecture

```
┌─────────────────┐         SAML Request          ┌─────────────────┐
│   User Browser  │ ───────────────────────────▶ │    ZITADEL      │
│                 │                                │  (Identity      │
│                 │ ◀───────────────────────────  │   Provider)     │
│                 │         SAML Response          └─────────────────┘
│                 │              ▼
│                 │         SAML Assertion
│                 │              │
│                 │              ▼
└─────────────────┘         ┌─────────────────┐
                            │    Supabase     │
                            │ (Service        │
                            │  Provider)      │
                            └─────────────────┘
```

---

## Prerequisites

Before starting, ensure you have:

- ✅ **ZITADEL Instance**: Cloud (zitadel.cloud) or self-hosted instance
- ✅ **Admin Access**: Full administrative rights to ZITADEL console
- ✅ **Organization**: Created in ZITADEL
- ✅ **Project**: Created within your ZITADEL organization
- ✅ **Supabase URL**: Your self-hosted Supabase instance URL/domain

### ZITADEL Access

1. **Cloud**: Sign up at [zitadel.cloud](https://zitadel.cloud)
2. **Self-hosted**: Follow [ZITADEL installation docs](https://zitadel.com/docs/self-hosting/deploy/overview)

### Supabase URLs

Determine your Supabase instance URLs:

- **Local Development**: `http://localhost:8000`
- **Production**: `https://your-domain.com` (with SSL configured)

---

## Phase 1: ZITADEL Configuration

### 1. Create SAML Application

#### Step 1.1: Navigate to Applications

1. Log in to ZITADEL Console
2. Select your **Organization**
3. Navigate to **Projects** → Select your project
4. Click on **Applications** tab

#### Step 1.2: Create New Application

1. Click **New Application**
2. Select **SAML 2.0** as the application type
3. Enter application details:
   - **Name**: `Supabase SSO`
   - **Description**: `SAML SSO for Supabase Authentication`

#### Step 1.3: Configure SAML Endpoints

Configure the following SAML Service Provider (SP) endpoints:

**For Local Development:**
```
Entity ID (SP): http://localhost:8000/auth/v1/sso/saml/metadata
ACS URL:        http://localhost:8000/auth/v1/sso/saml/acs
```

**For Production (with SSL):**
```
Entity ID (SP): https://your-domain.com/auth/v1/sso/saml/metadata
ACS URL:        https://your-domain.com/auth/v1/sso/saml/acs
```

#### Configuration Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| **Entity ID** | Unique identifier for Supabase as Service Provider | `http://localhost:8000/auth/v1/sso/saml/metadata` |
| **ACS URL** | Assertion Consumer Service URL where SAML responses are sent | `http://localhost:8000/auth/v1/sso/saml/acs` |
| **Protocol** | Use `https://` for production, `http://` for local development | `https://` or `http://` |

#### Step 1.4: Save Application

1. Review the configuration
2. Click **Save** or **Create**
3. Note the **Application ID** for reference

---

### 2. Configure Attribute Mapping

SAML attribute mapping ensures user information from ZITADEL is properly transmitted to Supabase in the SAML assertion.

#### Required Attributes

Configure the following attribute mappings:

| ZITADEL User Attribute | SAML Assertion Attribute | Required | Description |
|------------------------|--------------------------|----------|-------------|
| Email | `Email` | ✅ Yes | User's email address (used as primary identifier) |
| First Name | `FirstName` | Recommended | User's given name |
| Last Name | `SurName` | Recommended | User's family name |
| Display Name / Full Name | `FullName` | Recommended | User's complete name |
| Username | `UserName` | Optional | User's login username |
| User ID | `UserID` | Recommended | ZITADEL user unique identifier |

#### Configuration Steps

1. In your SAML application settings, navigate to **Attribute Mapping** or **SAML Configuration**
2. Click **Add Attribute** for each mapping
3. For each attribute:
   - **ZITADEL Attribute**: Select from dropdown (e.g., `user.email`)
   - **SAML Attribute Name**: Enter exact name (e.g., `Email`)
   - **Format**: Leave as default or select `Basic`

#### Example Configuration

```xml
<!-- Example SAML Assertion with mapped attributes -->
<saml:AttributeStatement>
  <saml:Attribute Name="Email">
    <saml:AttributeValue>user@example.com</saml:AttributeValue>
  </saml:Attribute>
  <saml:Attribute Name="FirstName">
    <saml:AttributeValue>John</saml:AttributeValue>
  </saml:Attribute>
  <saml:Attribute Name="SurName">
    <saml:AttributeValue>Doe</saml:AttributeValue>
  </saml:Attribute>
  <saml:Attribute Name="FullName">
    <saml:AttributeValue>John Doe</saml:AttributeValue>
  </saml:Attribute>
  <saml:Attribute Name="UserName">
    <saml:AttributeValue>johndoe</saml:AttributeValue>
  </saml:Attribute>
  <saml:Attribute Name="UserID">
    <saml:AttributeValue>123456789</saml:AttributeValue>
  </saml:Attribute>
</saml:AttributeStatement>
```

#### Verification

After configuring attributes:
1. Save the configuration
2. Test with a user account (covered in Section 4)
3. Verify attributes appear in SAML response using browser developer tools or SAML debugger

---

### 3. Export Metadata

SAML metadata XML contains all necessary information for Supabase to trust and communicate with ZITADEL.

#### Step 3.1: Locate Metadata

In your SAML application settings:

1. Look for **Metadata** or **Download Metadata** section
2. Find the **Metadata URL** (typically):
   ```
   https://<instance-id>.zitadel.cloud/saml/v2/metadata
   ```
   Or for self-hosted:
   ```
   https://your-zitadel-domain.com/saml/v2/metadata
   ```

#### Step 3.2: Download Metadata XML

**Option 1: Download via Console**
1. Click **Download Metadata XML** button
2. Save as `zitadel-saml-metadata.xml`

**Option 2: Download via URL**
```bash
curl -o zitadel-saml-metadata.xml https://<instance-id>.zitadel.cloud/saml/v2/metadata
```

#### Step 3.3: Extract Key Information

From the metadata XML, note these critical values:

| Value | Description | Location in Metadata |
|-------|-------------|---------------------|
| **Entity ID (Issuer)** | ZITADEL IdP identifier | `<EntityDescriptor entityID="...">` |
| **SSO Endpoint** | Single Sign-On URL | `<SingleSignOnService Location="...">` |
| **X.509 Certificate** | Signing certificate | `<X509Certificate>...</X509Certificate>` |

**Example Values:**
```
Entity ID:     https://<instance-id>.zitadel.cloud/saml/v2/metadata
SSO Endpoint:  https://<instance-id>.zitadel.cloud/saml/v2/SSO
```

#### Step 3.4: Store Metadata Securely

**Important**: Keep the metadata file secure as it will be needed for Supabase configuration.

```bash
# Recommended: Store in a secure configuration directory
mkdir -p /secure/configs/saml
cp zitadel-saml-metadata.xml /secure/configs/saml/
chmod 600 /secure/configs/saml/zitadel-saml-metadata.xml
```

#### Metadata Contents

The metadata XML should contain:

- **EntityDescriptor**: Root element with entity ID
- **IDPSSODescriptor**: IdP role descriptor
- **KeyDescriptor**: Signing and encryption keys
- **SingleSignOnService**: SSO endpoint URLs
- **NameIDFormat**: Supported name identifier formats
- **Attributes**: Available user attributes

---

### 4. Create Test Users

Test users are essential for validating the SAML SSO integration before production deployment.

#### Step 4.1: Create Users in ZITADEL

1. Navigate to **Users** in ZITADEL Console
2. Click **Create User** or **New User**
3. Create at least 2 test users:

**Test User 1:**
```
Email:     test.user1@example.com
First Name: Test
Last Name:  User One
Username:   testuser1
Password:   [Strong password - document securely]
```

**Test User 2:**
```
Email:     test.user2@example.com
First Name: Test
Last Name:  User Two
Username:   testuser2
Password:   [Strong password - document securely]
```

#### Step 4.2: Assign Users to SAML Application

Users must be granted access to the SAML application:

1. Go to your **Project** → **Applications** → **Supabase SSO**
2. Navigate to **Authorizations** or **User Grants**
3. Click **Add Authorization**
4. Select each test user
5. Grant appropriate roles/permissions
6. Save the authorization

#### Step 4.3: Document Credentials Securely

**⚠️ Security Warning**: Never store passwords in plain text or commit them to version control.

**Recommended Approach:**

1. Use a password manager (1Password, LastPass, Bitwarden)
2. Create a secure note with:
   - ZITADEL instance URL
   - Test user credentials
   - Application name
   - Purpose (Testing only)

**Example Secure Note Structure:**
```
ZITADEL SAML Test Users
========================
Instance: https://your-instance.zitadel.cloud
Application: Supabase SSO
Environment: Testing/Development

User 1:
- Email: test.user1@example.com
- Username: testuser1
- Password: [Stored securely in password manager]

User 2:
- Email: test.user2@example.com
- Username: testuser2
- Password: [Stored securely in password manager]

Created: [Date]
Expires: [Date] (if applicable)
```

#### Step 4.4: Verify User Access

Before proceeding to Supabase configuration:

1. Log in to ZITADEL console with test user credentials
2. Verify the user can access their profile
3. Confirm all required attributes (email, name, etc.) are populated
4. Ensure the user sees the "Supabase SSO" application in their app list

---

## Configuration Reference

### ZITADEL SAML Application Settings

Complete reference of key configuration values:

```yaml
# ZITADEL SAML Application Configuration
application_name: "Supabase SSO"
application_type: "SAML 2.0"

# Service Provider (Supabase) Configuration
service_provider:
  entity_id: "http://localhost:8000/auth/v1/sso/saml/metadata"
  acs_url: "http://localhost:8000/auth/v1/sso/saml/acs"
  
# Identity Provider (ZITADEL) Information
identity_provider:
  entity_id: "https://<instance-id>.zitadel.cloud/saml/v2/metadata"
  sso_url: "https://<instance-id>.zitadel.cloud/saml/v2/SSO"
  metadata_url: "https://<instance-id>.zitadel.cloud/saml/v2/metadata"

# Attribute Mapping
attributes:
  - zitadel: "user.email"
    saml: "Email"
    required: true
  - zitadel: "user.firstName"
    saml: "FirstName"
    required: false
  - zitadel: "user.lastName"
    saml: "SurName"
    required: false
  - zitadel: "user.displayName"
    saml: "FullName"
    required: false
  - zitadel: "user.username"
    saml: "UserName"
    required: false
  - zitadel: "user.id"
    saml: "UserID"
    required: false
```

### URLs by Environment

| Environment | Entity ID | ACS URL |
|-------------|-----------|---------|
| Local Dev | `http://localhost:8000/auth/v1/sso/saml/metadata` | `http://localhost:8000/auth/v1/sso/saml/acs` |
| Staging | `https://staging.yourdomain.com/auth/v1/sso/saml/metadata` | `https://staging.yourdomain.com/auth/v1/sso/saml/acs` |
| Production | `https://yourdomain.com/auth/v1/sso/saml/metadata` | `https://yourdomain.com/auth/v1/sso/saml/acs` |

---

## Troubleshooting

### Common Issues

#### 1. Cannot Access ZITADEL Console

**Symptoms:**
- Cannot log in to ZITADEL
- Console is unreachable

**Solutions:**
- Verify ZITADEL instance is running (for self-hosted)
- Check internet connectivity
- Verify URL is correct (`https://<instance-id>.zitadel.cloud`)
- Clear browser cache and cookies
- Try incognito/private browsing mode

#### 2. Application Not Appearing in Project

**Symptoms:**
- SAML application doesn't show in applications list

**Solutions:**
- Verify you're in the correct organization
- Confirm you're viewing the correct project
- Check user permissions (need project admin role)
- Refresh the page

#### 3. Attribute Mapping Not Working

**Symptoms:**
- User attributes missing in SAML response
- Incomplete user profile in Supabase

**Solutions:**
- Verify attribute names match exactly (case-sensitive)
- Ensure user profile has all required fields populated in ZITADEL
- Check attribute mapping configuration in SAML app settings
- Test with a different user account
- Review SAML assertion in browser developer tools

#### 4. Metadata Export Issues

**Symptoms:**
- Cannot download metadata XML
- Metadata URL returns 404

**Solutions:**
- Verify SAML application is saved and active
- Check metadata URL format
- Ensure application is properly configured
- Try downloading via curl/wget
- Contact ZITADEL support if self-hosted

#### 5. Test Users Cannot Access Application

**Symptoms:**
- Users don't see "Supabase SSO" in their app list
- "Access Denied" errors when attempting SSO

**Solutions:**
- Verify users are assigned to the SAML application
- Check user authorizations in application settings
- Ensure users are active (not disabled or locked)
- Verify organization/project permissions
- Re-assign user authorizations

### Debugging Tools

#### SAML Tracer (Browser Extension)

Install SAML-tracer for Chrome or Firefox to inspect SAML requests/responses:

1. Install extension from browser store
2. Open SAML-tracer
3. Attempt SSO login
4. Review SAML Request, Response, and Assertion
5. Verify attributes are present and correct

#### Command-Line Metadata Verification

```bash
# Download and verify metadata
curl -v https://<instance-id>.zitadel.cloud/saml/v2/metadata

# Pretty-print XML for easier reading
curl -s https://<instance-id>.zitadel.cloud/saml/v2/metadata | xmllint --format -

# Extract certificate
curl -s https://<instance-id>.zitadel.cloud/saml/v2/metadata | \
  grep -A 1 "X509Certificate" | \
  grep -v "X509Certificate" | \
  base64 -d | \
  openssl x509 -text -noout
```

### Getting Help

If issues persist:

1. **ZITADEL Documentation**: https://zitadel.com/docs
2. **ZITADEL Community**: https://github.com/zitadel/zitadel/discussions
3. **Supabase SAML Docs**: https://supabase.com/docs/guides/auth/sso/auth-sso-saml
4. **GitHub Issues**: Open an issue in your repository with:
   - ZITADEL version (cloud or self-hosted version)
   - Supabase version
   - Configuration (sanitized - no secrets)
   - Error messages
   - Steps to reproduce

---

## Security Best Practices

### 1. Use HTTPS in Production

**Always** use HTTPS for production SAML endpoints:

```
✅ GOOD:  https://yourdomain.com/auth/v1/sso/saml/acs
❌ BAD:   http://yourdomain.com/auth/v1/sso/saml/acs
```

HTTP is only acceptable for local development.

### 2. Rotate Signing Certificates

- ZITADEL automatically rotates certificates
- Monitor certificate expiration dates
- Update Supabase configuration when certificates change
- Set up alerts for certificate expiration

### 3. Secure Metadata Storage

- Store metadata XML in secure location
- Restrict file permissions (`chmod 600`)
- Do not commit to public repositories
- Use environment variables or secret management

### 4. User Provisioning

- Use Just-In-Time (JIT) provisioning when possible
- Implement user deprovisioning workflows
- Regularly audit user access
- Remove test users after validation

### 5. Audit Logging

Enable and monitor:
- SAML authentication attempts
- Failed login attempts
- User provisioning events
- Configuration changes

### 6. Network Security

- Restrict access to ZITADEL console (IP allowlisting if possible)
- Use VPN for administrative access
- Enable MFA for all admin accounts
- Regularly review user permissions

### 7. Test in Staging First

- Never test configuration changes in production
- Maintain separate ZITADEL applications for staging and production
- Use different test users for each environment
- Validate thoroughly before production deployment

---

## Next Steps

After completing ZITADEL configuration:

### 1. Configure Supabase

Proceed to configure the Supabase side of the SAML integration:

- Refer to issue **#70: Supabase SAML Configuration**
- Use the metadata XML exported from ZITADEL
- Configure Supabase Auth with SAML provider

**Key Files Needed:**
- `zitadel-saml-metadata.xml` (exported in Step 3)
- ZITADEL Entity ID and SSO URL (noted in Step 3)

### 2. Test SSO Flow

1. Attempt login via Supabase with SAML
2. Verify redirect to ZITADEL login page
3. Log in with test user credentials
4. Confirm successful redirect back to Supabase
5. Verify user profile populated correctly

### 3. Validate Attribute Mapping

- Check user email is correctly mapped
- Verify first name, last name, full name
- Confirm user ID is stored
- Validate any custom attributes

### 4. Production Readiness

Before production deployment:

- [ ] Test with multiple users
- [ ] Verify all user roles work correctly
- [ ] Test error scenarios (wrong credentials, cancelled login)
- [ ] Enable production logging and monitoring
- [ ] Document user onboarding process
- [ ] Create user support documentation
- [ ] Set up incident response procedures

### 5. Documentation Updates

Update your project documentation:

- Add SAML SSO to authentication methods in README
- Document user login flow
- Create troubleshooting guide for users
- Add SAML configuration to DEVOPS.md

---

## References

### ZITADEL Documentation

- **SAML Overview**: https://zitadel.com/docs/guides/integrate/services/saml
- **SAML Configuration**: https://zitadel.com/docs/guides/integrate/saml/configuration
- **User Management**: https://zitadel.com/docs/guides/manage/console/users
- **API Reference**: https://zitadel.com/docs/apis/introduction

### Supabase Documentation

- **Auth Overview**: https://supabase.com/docs/guides/auth
- **SSO with SAML**: https://supabase.com/docs/guides/auth/sso/auth-sso-saml
- **Self-hosting**: https://supabase.com/docs/guides/self-hosting

### SAML Specifications

- **SAML 2.0 Core**: http://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf
- **SAML 2.0 Bindings**: http://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf
- **SAML 2.0 Profiles**: http://docs.oasis-open.org/security/saml/v2.0/saml-profiles-2.0-os.pdf

### Related Issues

- **#70**: Supabase SAML Configuration (Next Phase)
- **Integration Plan**: [Link to integration planning document]

### Project Documentation

- [README.md](../README.md) - Project overview
- [DEVOPS.md](../DEVOPS.md) - DevOps and deployment guide
- [MCP_AUTHENTICATION.md](./MCP_AUTHENTICATION.md) - AI agent authentication strategies

---

## Appendix

### A. Example SAML Request

Example SAML authentication request sent from Supabase to ZITADEL:

```xml
<samlp:AuthnRequest
    xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    ID="_generated_id_123456"
    Version="2.0"
    IssueInstant="2024-01-01T12:00:00Z"
    Destination="https://<instance-id>.zitadel.cloud/saml/v2/SSO"
    AssertionConsumerServiceURL="http://localhost:8000/auth/v1/sso/saml/acs"
    ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST">
    <saml:Issuer>http://localhost:8000/auth/v1/sso/saml/metadata</saml:Issuer>
</samlp:AuthnRequest>
```

### B. Example SAML Response

Example SAML response from ZITADEL containing user assertions:

```xml
<samlp:Response
    xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    ID="_response_id_123456"
    Version="2.0"
    IssueInstant="2024-01-01T12:00:05Z"
    Destination="http://localhost:8000/auth/v1/sso/saml/acs"
    InResponseTo="_generated_id_123456">
    <saml:Issuer>https://<instance-id>.zitadel.cloud/saml/v2/metadata</saml:Issuer>
    <samlp:Status>
        <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
    </samlp:Status>
    <saml:Assertion
        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
        ID="_assertion_id_123456"
        Version="2.0"
        IssueInstant="2024-01-01T12:00:05Z">
        <saml:Issuer>https://<instance-id>.zitadel.cloud/saml/v2/metadata</saml:Issuer>
        <saml:Subject>
            <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">
                test.user1@example.com
            </saml:NameID>
        </saml:Subject>
        <saml:Conditions
            NotBefore="2024-01-01T12:00:00Z"
            NotOnOrAfter="2024-01-01T12:05:00Z">
            <saml:AudienceRestriction>
                <saml:Audience>http://localhost:8000/auth/v1/sso/saml/metadata</saml:Audience>
            </saml:AudienceRestriction>
        </saml:Conditions>
        <saml:AttributeStatement>
            <saml:Attribute Name="Email">
                <saml:AttributeValue>test.user1@example.com</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="FirstName">
                <saml:AttributeValue>Test</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="SurName">
                <saml:AttributeValue>User One</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="FullName">
                <saml:AttributeValue>Test User One</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="UserName">
                <saml:AttributeValue>testuser1</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="UserID">
                <saml:AttributeValue>123456789</saml:AttributeValue>
            </saml:Attribute>
        </saml:AttributeStatement>
    </saml:Assertion>
</samlp:Response>
```

### C. Checklist for Implementation

Use this checklist to track your ZITADEL SAML IdP configuration:

```markdown
## ZITADEL Configuration Checklist

### Prerequisites
- [ ] ZITADEL instance available (cloud or self-hosted)
- [ ] Admin access to ZITADEL console
- [ ] Organization created in ZITADEL
- [ ] Project created in ZITADEL
- [ ] Self-hosted Supabase instance URL/domain known

### SAML Application Setup
- [ ] Navigated to Project → Applications
- [ ] Created new SAML application
- [ ] Named application "Supabase SSO"
- [ ] Configured Entity ID (SP)
- [ ] Configured ACS URL
- [ ] Saved application

### Attribute Mapping
- [ ] Mapped Email → Email (required)
- [ ] Mapped First Name → FirstName
- [ ] Mapped Last Name → SurName
- [ ] Mapped Full Name → FullName
- [ ] Mapped Username → UserName
- [ ] Mapped User ID → UserID
- [ ] Saved attribute mapping

### Metadata Export
- [ ] Downloaded ZITADEL SAML metadata XML
- [ ] Noted Entity ID (Issuer)
- [ ] Noted SSO endpoint URL
- [ ] Extracted X.509 signing certificate
- [ ] Saved metadata URL for Supabase configuration
- [ ] Stored metadata file securely

### Test Users
- [ ] Created test user 1
- [ ] Created test user 2
- [ ] Assigned users to SAML application
- [ ] Documented test user credentials securely
- [ ] Verified users can access ZITADEL
- [ ] Confirmed users see Supabase SSO app

### Validation
- [ ] Reviewed all configuration settings
- [ ] Verified attribute mapping with test login
- [ ] Confirmed metadata URL is accessible
- [ ] Documented all configuration values
- [ ] Ready to proceed to Supabase configuration
```

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-10-07  
**Status**: ✅ Complete  
**Next Phase**: Supabase SAML Configuration (Issue #70)

For questions or issues with this guide, please open an issue in the repository.
