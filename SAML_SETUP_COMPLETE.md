# SAML SSO Setup Complete

## Changes Made

This document summarizes the changes made to enable SAML SSO authentication for the Supabase instance.

### 1. Generated SAML Certificates

- Generated RSA 2048-bit private key using `scripts/generate-saml-key.sh`
- Created base64-encoded private key for GoTrue configuration
- Key stored securely in `.env` file (NOT committed to git in production)

### 2. Updated Docker Compose Configuration

**File**: `supabase/docker/docker-compose.yml`

Added SAML environment variables to the `auth` service:
```yaml
# SAML SSO Configuration
GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED:-false}
GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY:-}
```

These variables are read from the `.env` file and passed to the GoTrue auth service.

### 3. Updated Environment Configuration

**File**: `.env`

Added active SAML configuration:
```bash
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<base64-encoded-key>
```

## Current Status

✅ **Auth Service**: Already enabled in docker-compose.yml (lines 84-166)
✅ **SAML Configuration**: Added to auth service environment
✅ **SAML Certificates**: Generated and configured
✅ **Environment Variables**: Set in .env file

## Next Steps

To complete the SAML SSO setup, follow these steps:

### 1. Start/Restart Supabase

```bash
cd supabase/docker
docker compose down
docker compose up -d
```

### 2. Verify SAML Endpoints

Check that SAML metadata endpoint is accessible:
```bash
curl http://localhost:8000/auth/v1/sso/saml/metadata
```

Expected: XML metadata response with service provider configuration

### 3. Configure ZITADEL Identity Provider

1. Create SAML application in ZITADEL
2. Set Entity ID: `http://localhost:8000/auth/v1/sso/saml/metadata`
3. Set ACS URL: `http://localhost:8000/auth/v1/sso/saml/acs`
4. Map attributes: `Email`, `FullName`, `FirstName`, `SurName`
5. Get ZITADEL metadata URL

### 4. Register SAML Provider in Supabase

Use the automated setup script:
```bash
./scripts/saml-setup.sh \
  -d yourdomain.com \
  -m https://your-zitadel-instance/saml/v2/metadata
```

Or register manually via Admin API (requires SERVICE_ROLE_KEY):
```bash
curl -X POST "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "saml",
    "domains": ["yourdomain.com"],
    "metadata_url": "https://your-zitadel-instance/saml/v2/metadata"
  }'
```

### 5. Test SAML Authentication

Run the test suite:
```bash
./scripts/test_saml.sh --user-email test@yourdomain.com
```

Or test manually:
```bash
# Initiate SAML login
curl -L "http://localhost:8000/auth/v1/sso?domain=yourdomain.com"
```

## Security Notes

⚠️ **CRITICAL**: The SAML private key has been committed to `.env` for development.

**Current Status:**
- ✅ OK for local development and testing
- ⚠️ MUST CHANGE before production deployment

**Production Requirements:**
1. **Generate new production key** - DO NOT use the committed key
2. **Use secrets management** (AWS Secrets Manager, HashiCorp Vault, etc.)
3. **Never commit production keys** to version control
4. **Rotate keys annually** or after any exposure
5. **Enable audit logging** for authentication events
6. **Use HTTPS** for all endpoints
7. **Implement key rotation** schedule

**Important:** See `SECURITY_NOTICE.md` for detailed security guidance and remediation steps.

## Troubleshooting

### 404 on SAML Endpoints
- Check that auth service is running: `docker ps | grep supabase-auth`
- Verify Kong routes are configured correctly
- Check auth service logs: `docker logs supabase-auth`

### Invalid Signature Error
- Verify certificate matches between ZITADEL and Supabase
- Check that GOTRUE_SAML_PRIVATE_KEY is correctly base64-encoded
- Ensure no line breaks or extra spaces in the private key

### User Not Created
- Check attribute mapping in provider registration
- Verify email attribute is present in SAML assertion
- Check auth service logs for errors

## Documentation References

- SAML Implementation Guide: `skogai/guides/saml/SAML Implementation Summary.md`
- ZITADEL Setup: `skogai/guides/saml/ZITADEL SAML Integration Guide.md`
- Supabase SAML Docs: https://supabase.com/docs/guides/auth/enterprise-sso/auth-sso-saml
- ZITADEL SAML Docs: https://zitadel.com/docs/guides/integrate/login/saml

## Scripts Available

- `scripts/generate-saml-key.sh` - Generate SAML certificates
- `scripts/saml-setup.sh` - Automated SAML provider registration
- `scripts/test_saml.sh` - Test SAML authentication flow
- `scripts/check_saml_logs.sh` - View SAML-related logs
- `scripts/validate_saml_attributes.sh` - Validate attribute mapping
