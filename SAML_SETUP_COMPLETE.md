# SAML Setup - Complete Reference

## Current Status
✅ SAML certificates generated (PKCS#1 format)
✅ `.env` file updated with correct private key format
✅ Auth service restarted

## What Still Needs to Be Done

### 1. Add SAML Provider to Database

```sql
-- Create SSO provider
INSERT INTO auth.sso_providers (id, resource_id)
VALUES (gen_random_uuid(), 'skogai-saml-provider')
RETURNING id;

-- Use the returned ID in the next step
-- Add domain
INSERT INTO auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at)
VALUES (gen_random_uuid(), '<ID_FROM_ABOVE>', 'skogai.se', NOW(), NOW());

-- Add SAML provider configuration
INSERT INTO auth.saml_providers (
  id,
  sso_provider_id,
  entity_id,
  metadata_xml,
  metadata_url,
  attribute_mapping
) VALUES (
  gen_random_uuid(),
  '<ID_FROM_ABOVE>',
  'https://auth.aldervall.se/saml/v2/metadata',
  E'<?xml version="1.0" encoding="UTF-8"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://auth.aldervall.se/saml/v2/metadata">
<IDPSSODescriptor WantAuthnRequestsSigned="1" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
<SingleSignOnService xmlns="urn:oasis:names:tc:SAML:2.0:metadata" Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://auth.aldervall.se/saml/v2/SSO"></SingleSignOnService>
</IDPSSODescriptor>
</EntityDescriptor>',
  'https://auth.aldervall.se/saml/v2/metadata',
  '{"keys": {"email": "Email", "name": "FullName", "first_name": "FirstName", "last_name": "SurName"}}'::jsonb
);
```

### 2. Quick Commands

```bash
# Add provider to database
docker exec supabase_db_SkogAI psql -U postgres -d postgres -c "
INSERT INTO auth.sso_providers (id, resource_id)
VALUES (gen_random_uuid(), 'skogai-saml-provider')
RETURNING id;
"

# Check SAML status
curl -s "https://localhost:54321/auth/v1/sso?domain=skogai.se" -k | jq '.'

# View auth logs
docker logs supabase_auth_SkogAI 2>&1 | tail -50

# Check database providers
docker exec supabase_db_SkogAI psql -U postgres -d postgres -c "
SELECT sp.id, d.domain, saml.entity_id
FROM auth.sso_providers sp
LEFT JOIN auth.sso_domains d ON d.sso_provider_id = sp.id
LEFT JOIN auth.saml_providers saml ON saml.sso_provider_id = sp.id;
"
```

## Certificate Files

Located in: `saml-certs/`
- `saml_sp_private_pkcs1.key` - PKCS#1 format (used in .env)
- `saml_sp_cert.pem` - Certificate

## ZITADEL Configuration

**Your ZITADEL IdP:**
- Metadata URL: https://auth.aldervall.se/saml/v2/metadata
- Entity ID: https://auth.aldervall.se/saml/v2/metadata
- SSO Location: https://auth.aldervall.se/saml/v2/SSO

**Your Supabase SP (configure in ZITADEL):**
- Entity ID: https://localhost:54321/auth/v1/sso/saml/metadata
- ACS URL: https://localhost:54321/auth/v1/sso/saml/acs

## Testing Flow

1. User visits: `https://localhost:54321/auth/v1/sso?domain=skogai.se`
2. Supabase redirects to ZITADEL login
3. User authenticates at ZITADEL
4. ZITADEL redirects back with SAML assertion
5. User logged into Supabase

## Troubleshooting

### "SAML 2.0 is disabled"
- Check: `docker exec supabase_auth_SkogAI env | grep SAML`
- Should see `GOTRUE_SAML_ENABLED=true`

### "SAML private key not in PKCS#1 format"
- Key must start with `-----BEGIN RSA PRIVATE KEY-----`
- Current key is correct (PKCS#1 format)

### "No SAML provider found"
- Run database insert commands above
- Check with: `SELECT * FROM auth.sso_providers;`

### Auth won't start
- Check logs: `docker logs supabase_auth_SkogAI`
- Usually means private key format is wrong

## Environment Variables in .env

```bash
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
```

**Note:** The private key must be:
1. In PKCS#1 format (`BEGIN RSA PRIVATE KEY`)
2. Single line with `\n` for newlines
3. Wrapped in double quotes

## Key Files Modified

- `.env` - Contains SAML environment variables
- `saml-certs/saml_sp_private_pkcs1.key` - PKCS#1 private key
- `saml-certs/saml_sp_cert.pem` - Certificate
- `scripts/saml-setup.sh` - Updated with local paths

## What Supabase CLI Doesn't Do

The Supabase CLI **does NOT**:
- Automatically load custom env vars from `.env` into containers
- Have config.toml support for SAML
- Persist SAML providers across `db:reset`

You must manually restart auth service after `.env` changes.
