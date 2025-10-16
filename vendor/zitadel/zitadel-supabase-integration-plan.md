# ZITADEL + Supabase SAML SSO Integration Plan
## Self-Hosted Supabase Edition

## Overview

Integrate ZITADEL as a SAML 2.0 Identity Provider (IdP) with **self-hosted Supabase** acting as the Service Provider (SP). This enables enterprise SSO authentication using ZITADEL for user identity management.

**IMPORTANT**: This guide is for **self-hosted Supabase** deployments. For Supabase cloud (supabase.com), the configuration steps differ significantly.

## Architecture

```
User → Supabase (SP) → ZITADEL (IdP) → User authenticated → Supabase session created
```

**Flow Type**: SP-Initiated (required by ZITADEL)
**Protocol**: SAML 2.0
**Authentication Method**: SSO with SAML assertions

## Components

### Supabase (Service Provider - Self-Hosted)
- **Project URL**: `http://localhost:8000` (or your custom domain)
- **Metadata URL**: `http://localhost:8000/auth/v1/sso/saml/metadata`
- **ACS URL**: `http://localhost:8000/auth/v1/sso/saml/acs`
- **Entity ID**: `http://localhost:8000/auth/v1/sso/saml/metadata`
- **API Gateway**: Kong (requires configuration)

### ZITADEL (Identity Provider)
- **Instance URL**: `https://<instance-id>.zitadel.cloud` (or self-hosted)
- **Metadata URL**: `https://<instance-id>.zitadel.cloud/saml/v2/metadata`
- **SSO Endpoint**: `https://<instance-id>.zitadel.cloud/saml/v2/SSO`
- **Signing Certificate**: X.509 certificate for SAML assertion signing

## Prerequisites

### Supabase Requirements (Self-Hosted)
- ✅ Self-hosted Supabase instance running (Docker/Docker Compose)
- ✅ Access to docker-compose.yml and .env files
- ✅ Access to Kong configuration (docker/volumes/api/kong.yml)
- ✅ Service role key (anon key won't work for admin endpoints)
- ✅ OpenSSL installed (for generating private keys)
- ⚠️  **Note**: No "Pro plan" required - SAML is available in self-hosted

### ZITADEL Requirements
- ✅ ZITADEL instance (cloud or self-hosted)
- ✅ Organization created in ZITADEL
- ✅ Project created in ZITADEL
- ✅ Admin access to ZITADEL console
- ✅ Test users created for validation

## Integration Steps

### Phase 1: ZITADEL Configuration
1. **Create SAML Application in ZITADEL**
   - Log into ZITADEL console
   - Navigate to Project → Applications
   - Create new SAML application
   - Configure SP metadata:
     - Entity ID: `http://localhost:8000/auth/v1/sso/saml/metadata` (or your domain)
     - ACS URL: `http://localhost:8000/auth/v1/sso/saml/acs` (or your domain)
     - **Note**: Use `https://` if you have SSL configured on your self-hosted instance

2. **Configure Attribute Mapping**
   - Email (required): Map to ZITADEL email attribute
   - FirstName: Map to given name
   - LastName: Map to family name
   - UserID: Map to ZITADEL user ID
   - Custom attributes as needed

3. **Download IdP Metadata**
   - Export ZITADEL SAML metadata XML
   - Note the Entity ID (Issuer)
   - Note the SSO endpoint URL
   - Download signing certificate

### Phase 2: Supabase Configuration (Self-Hosted)

**Step 1: Generate SAML Private Key**
```bash
# Generate RSA private key in DER format
openssl genpkey -algorithm rsa -outform DER -out private_key.der

# Encode to base64
base64 -i private_key.der > private_key.base64
```

**Step 2: Update Environment Variables**
Add to `.env` file:
```bash
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<paste-base64-encoded-key-here>
```

**Step 3: Update docker-compose.yml**
Add to `auth` service environment:
```yaml
auth:
  environment:
    GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED}
    GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY}
```

**Step 4: Configure Kong API Gateway**
Edit `docker/volumes/api/kong.yml` and add these services to the **Open Auth routes** section:

```yaml
services:
  ## Open Auth routes - SAML endpoints (NO API KEY REQUIRED)
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

**Step 5: Restart Supabase**
```bash
docker-compose down
docker-compose up -d
```

**Step 6: Verify SAML Endpoints**
```bash
# Should return XML metadata
curl http://localhost:8000/auth/v1/sso/saml/metadata?download=true
```

**Step 7: Add ZITADEL as SSO Provider via API**
Use the Admin API (NOT dashboard - self-hosted doesn't have SSO UI):

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
        "email": {
          "name": "Email"
        },
        "name": {
          "name": "FullName"
        },
        "given_name": {
          "name": "FirstName"
        },
        "family_name": {
          "name": "SurName"
        }
      }
    }
  }'
```

**Step 8: Save Provider UUID**
The response will include a `uuid` - save this for managing the provider later:
```bash
# List providers
curl http://localhost:8000/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

### Phase 3: Testing & Validation
1. **Test Authentication Flow**
   - Create test user in ZITADEL
   - Initiate login from Supabase application
   - Verify redirect to ZITADEL
   - Complete authentication at ZITADEL
   - Verify redirect back to Supabase
   - Confirm session creation in Supabase

2. **Validate SAML Assertions**
   - Check SAML response contains expected attributes
   - Verify signature validation passes
   - Confirm user metadata is correctly mapped
   - Test with multiple user accounts

3. **Error Handling Tests**
   - Test failed authentication (wrong password)
   - Test disabled user account
   - Test expired session
   - Test attribute mapping failures

### Phase 4: Production Deployment
1. **Environment Configuration**
   - Set up production ZITADEL instance (if using self-hosted)
   - Configure production Supabase project
   - Update metadata URLs for production

2. **Security Hardening**
   - Verify SSL/TLS encryption on all endpoints
   - Confirm signature validation is enabled
   - Set appropriate session timeouts
   - Enable audit logging on both platforms

3. **User Migration (if applicable)**
   - Plan user migration from existing auth system
   - Consider account linking strategies
   - Document manual linking process for existing users

## Key Configuration Details

### SAML Assertion Attributes (from ZITADEL)
```xml
<AttributeStatement>
  <Attribute Name="Email">
    <AttributeValue>user@example.com</AttributeValue>
  </Attribute>
  <Attribute Name="FirstName">
    <AttributeValue>John</AttributeValue>
  </Attribute>
  <Attribute Name="SurName">
    <AttributeValue>Doe</AttributeValue>
  </Attribute>
  <Attribute Name="FullName">
    <AttributeValue>John Doe</AttributeValue>
  </Attribute>
  <Attribute Name="UserName">
    <AttributeValue>user@example.com</AttributeValue>
  </Attribute>
  <Attribute Name="UserID">
    <AttributeValue>260242264868201995</AttributeValue>
  </Attribute>
</AttributeStatement>
```

### Supabase Expected Format
- Email: Required, used as primary identifier
- Additional attributes stored in `raw_user_meta_data` field
- Profile information can be synced to custom `profiles` table

## Known Limitations

### Supabase Self-Hosted Limitations
- ❌ No automatic account linking for existing users
- ❌ Emails not guaranteed unique across providers
- ❌ Single Logout (SLO) not fully supported
- ⚠️  Session duration limited by Supabase config
- ⚠️  **No UI for SSO management** - must use Admin API endpoints
- ⚠️  Kong configuration must be done manually (not via CLI)
- ⚠️  Requires Docker/Docker Compose access

### ZITADEL Limitations
- ❌ Only SP-initiated flow supported (no IdP-initiated)
- ✅ Full SAML 2.0 compliance
- ✅ Supports metadata exchange

## Key Differences: Self-Hosted vs Cloud

| Aspect | Self-Hosted | Supabase Cloud |
|--------|-------------|----------------|
| Configuration | Manual (env vars, Kong, API calls) | Dashboard UI + CLI |
| Prerequisites | Docker, Kong access, OpenSSL | Pro/Enterprise plan |
| SAML Setup | Admin API endpoints | Dashboard or `supabase sso` CLI |
| Kong Routes | Manual editing of kong.yml | Automatic |
| Private Key | Generate yourself with OpenSSL | Managed automatically |
| Metadata URL | Your domain/localhost | `*.supabase.co` |
| SSO Provider Management | cURL commands to Admin API | Dashboard UI |

## Troubleshooting

### Common Issues
1. **Invalid signature errors**
   - Verify certificate matches between IdP and SP
   - Check clock sync between systems
   - Validate XML canonicalization

2. **Attribute mapping failures**
   - Check attribute names match exactly (case-sensitive)
   - Verify ZITADEL sends expected attributes
   - Review Supabase attribute mapping JSON

3. **Redirect loops**
   - Verify ACS URL is correctly configured
   - Check relay state handling
   - Ensure session cookie settings are correct

## Testing Checklist

- [ ] ZITADEL SAML application created
- [ ] Supabase SAML provider configured
- [ ] Metadata exchanged between systems
- [ ] Test user can authenticate via ZITADEL
- [ ] User attributes correctly mapped to Supabase
- [ ] Session created successfully in Supabase
- [ ] User can access protected resources
- [ ] Logout flow tested
- [ ] Error scenarios tested
- [ ] Production configuration documented

## References

### Self-Hosted Specific
- [Calvin Chan's Blog: Enabling SAML SSO on Self-Hosted Supabase](https://calvincchan.com/blog/self-hosted-supabase-enable-sso)
- [GitHub Issue #1335: SSO/SAML Support for Supabase Local](https://github.com/supabase/cli/issues/1335)
- [GoTrue SAML Configuration](https://github.com/supabase/gotrue) - Auth service source code
- [GoTrue Admin API Documentation](https://github.com/supabase/gotrue/blob/master/openapi.yaml#L1434-L1600)

### General SAML Resources
- [Supabase SAML SSO Documentation](https://supabase.com/docs/guides/auth/enterprise-sso/auth-sso-saml) (Cloud version)
- [ZITADEL SAML Documentation](https://zitadel.com/docs)
- [SAML 2.0 Specification](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)
- [tmp/saml-zitadel.md](./saml-zitadel.md) - Local ZITADEL SAML reference

## Next Steps

1. Create GitHub issues for each integration phase
2. Assign owners and timeline for each phase
3. Set up development/staging environment for testing
4. Schedule implementation kickoff
