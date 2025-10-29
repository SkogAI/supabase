# SAML SSO Quick Start Guide

This guide provides a quick reference for the SAML SSO setup that has been completed.

## What Was Done

### ✅ Phase 1: Auth Service Configuration (COMPLETE)

The Auth service was already enabled in the docker-compose.yml. Added SAML-specific environment variables:

```yaml
# SAML SSO Configuration
GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED:-false}
GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY:-}
```

### ✅ Phase 2: Certificate Generation (COMPLETE)

- Generated RSA 2048-bit SAML private key
- Encoded to base64 format for GoTrue
- Stored securely in `.env` file

### ✅ Phase 3: Environment Configuration (COMPLETE)

Added to `.env`:
```bash
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<base64-encoded-key>
```

## Validation

Run the validation script to verify configuration:

```bash
./scripts/validate-saml-config.sh
```

Expected output: All checks passed ✓

## What's Left to Do

### Phase 4: Start Supabase Services

```bash
cd supabase/docker
docker compose up -d
```

Wait for all services to be healthy:
```bash
docker compose ps
```

### Phase 5: Verify SAML Endpoints

Test the SAML metadata endpoint:
```bash
curl http://localhost:8000/auth/v1/sso/saml/metadata
```

Expected response: XML document containing Service Provider metadata

### Phase 6: Configure ZITADEL IdP

1. **Create SAML Application in ZITADEL**
   - Log into your ZITADEL instance
   - Navigate to Projects → Your Project → Applications
   - Click "New Application" → Select "SAML"

2. **Configure SAML Application**
   - **Entity ID**: `http://localhost:8000/auth/v1/sso/saml/metadata`
   - **ACS URL**: `http://localhost:8000/auth/v1/sso/saml/acs`
   - **Name ID Format**: Email Address
   - **Attribute Mapping**:
     - `email` → Email
     - `given_name` → FirstName
     - `family_name` → SurName
     - `name` → FullName

3. **Get ZITADEL Metadata URL**
   - Copy the SAML metadata URL from ZITADEL
   - Format: `https://your-instance.zitadel.cloud/saml/v2/metadata`

### Phase 7: Register SAML Provider in Supabase

**Option 1: Automated Setup (Recommended)**

```bash
./scripts/saml-setup.sh \
  -d yourdomain.com \
  -m https://your-zitadel-instance.zitadel.cloud/saml/v2/metadata
```

**Option 2: Manual Registration**

First, get your SERVICE_ROLE_KEY:
```bash
grep SERVICE_ROLE_KEY supabase/docker/.env
```

Then register the provider:
```bash
curl -X POST "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "saml",
    "domains": ["yourdomain.com"],
    "metadata_url": "https://your-zitadel-instance.zitadel.cloud/saml/v2/metadata"
  }'
```

### Phase 8: Test Authentication

**Using Test Script:**
```bash
./scripts/test_saml.sh --user-email test@yourdomain.com
```

**Manual Testing:**
1. Navigate to: `http://localhost:8000/auth/v1/sso?domain=yourdomain.com`
2. You should be redirected to ZITADEL login
3. Log in with your ZITADEL credentials
4. Upon successful authentication, you'll be redirected back to Supabase
5. A new user should be created in the database

**Verify User Creation:**
```bash
# Check users in database
docker exec supabase-db psql -U postgres -d postgres \
  -c "SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC LIMIT 5;"
```

## Troubleshooting

### Issue: Cannot access SAML endpoints (404)

**Solution:**
1. Check auth service is running: `docker ps | grep supabase-auth`
2. Check auth service logs: `docker logs supabase-auth`
3. Verify Kong is routing correctly: `docker logs supabase-kong`

### Issue: Invalid signature error

**Causes:**
- Certificate mismatch between ZITADEL and Supabase
- Private key not loaded correctly

**Solution:**
1. Regenerate certificates: `./scripts/generate-saml-key.sh /tmp/saml-certs`
2. Update .env with new key
3. Restart services: `docker compose restart auth`
4. Update ZITADEL with new metadata

### Issue: User not created after login

**Solution:**
1. Check attribute mapping in ZITADEL
2. Verify email attribute is present
3. Check auth logs: `docker logs supabase-auth | grep -i saml`

### Issue: Private key error in logs

**Solution:**
```bash
# Verify key format (should be single line, base64)
grep GOTRUE_SAML_PRIVATE_KEY .env | wc -l
# Should output: 1

# Verify no spaces in key
grep GOTRUE_SAML_PRIVATE_KEY .env | grep " " && echo "Key has spaces - FIX NEEDED"
```

## Security Checklist

⚠️ **CRITICAL SECURITY NOTICE**: Read `SECURITY_NOTICE.md` before production deployment!

The SAML private key is currently committed in `.env`. This is acceptable for local development but **MUST** be addressed before production.

### Before Going to Production:

- [ ] **Generate NEW production key** (do not use the committed key)
- [ ] **Store key in secrets manager** (AWS, Azure, Vault, etc.)
- [ ] **Remove key from .env** and use environment variables
- [ ] **Update ZITADEL** with new SP metadata
- [ ] **Use HTTPS** for all endpoints (update URLs in ZITADEL)
- [ ] **Enable audit logging** in GoTrue
- [ ] **Set up certificate rotation** schedule (annually)
- [ ] **Configure CORS** settings properly
- [ ] **Implement rate limiting** for SSO endpoints
- [ ] **Set up monitoring** and alerting for auth failures
- [ ] **Test complete flow** in staging environment
- [ ] **Document key rotation** procedures

### Development vs Production Keys

| Environment | Key Location | Notes |
|-------------|--------------|-------|
| **Development** | .env (committed) | ✅ OK - Already exposed in git |
| **Staging** | Secrets manager | ⚠️ Generate separate key |
| **Production** | Secrets manager | ⚠️ NEVER use committed key |

## Available Scripts

- `scripts/generate-saml-key.sh` - Generate SAML certificates
- `scripts/validate-saml-config.sh` - Validate SAML configuration
- `scripts/saml-setup.sh` - Automated SAML provider registration
- `scripts/test_saml.sh` - Test SAML authentication flow
- `scripts/check_saml_logs.sh` - View SAML-related logs
- `scripts/validate_saml_attributes.sh` - Validate attribute mapping

## Documentation

- **Setup Complete**: `SAML_SETUP_COMPLETE.md` - Detailed setup documentation
- **Implementation Summary**: `skogai/guides/saml/SAML Implementation Summary.md`
- **ZITADEL Integration**: `skogai/guides/saml/ZITADEL SAML Integration Guide.md`
- **User Guide**: `skogai/guides/saml/SAML User Guide.md`

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review auth service logs: `docker logs supabase-auth`
3. Check existing documentation in `skogai/guides/saml/`
4. Consult Supabase SAML docs: https://supabase.com/docs/guides/auth/enterprise-sso/auth-sso-saml

## Configuration Files Changed

- ✅ `supabase/docker/docker-compose.yml` - Added SAML env vars to auth service
- ✅ `.env` - Added GOTRUE_SAML_ENABLED and GOTRUE_SAML_PRIVATE_KEY
- ✅ `scripts/validate-saml-config.sh` - New validation script
- ✅ `SAML_SETUP_COMPLETE.md` - Detailed setup guide
- ✅ `SAML_QUICKSTART.md` - This quick reference guide
