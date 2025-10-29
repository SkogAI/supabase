# 🔒 SECURITY NOTICE - SAML Private Key

## ⚠️ CRITICAL SECURITY WARNING

**The SAML private key has been committed to the repository in `.env` file.**

This was done as part of the development setup process, but represents a security risk for production deployments.

## Current State

- ✅ `.env` is in `.gitignore` - Future changes won't be committed
- ⚠️ However, the current version with the private key is in git history
- ⚠️ A SAML private key exists in the committed .env file

## Immediate Actions

### For Local Development/Testing
**Status**: ✅ OK - Current setup is acceptable for local development

The committed key can be used for:
- Local testing with Docker
- Development SAML integration tests
- Non-production ZITADEL instances

### For Production Deployment
**Status**: ⚠️ CRITICAL - Must take action before production use

**Required Steps:**

1. **Generate New Production Key**
   ```bash
   ./scripts/generate-saml-key.sh /secure/location/saml-certs
   ```

2. **Set Key via Environment Variable**
   - **Option A: Docker Secrets** (Recommended)
     ```bash
     # Create secret
     echo "your-new-key" | docker secret create gotrue_saml_key -
     
     # Update docker-compose.yml to use secret
     secrets:
       gotrue_saml_key:
         external: true
     ```
   
   - **Option B: Environment Variable**
     ```bash
     export GOTRUE_SAML_ENABLED=true
     export GOTRUE_SAML_PRIVATE_KEY="your-new-production-key"
     docker compose up -d
     ```
   
   - **Option C: Secrets Manager**
     - AWS Secrets Manager
     - Azure Key Vault
     - HashiCorp Vault
     - Google Secret Manager

3. **Update ZITADEL Configuration**
   - Get new SP metadata from Supabase
   - Update ZITADEL application with new certificate
   - Test authentication flow

4. **Remove Old Key from .env**
   ```bash
   # Comment out or remove the line in .env
   # GOTRUE_SAML_PRIVATE_KEY=<remove-this-line>
   ```

## Why This Matters

### Security Implications

1. **Key Exposure**: Anyone with repository access can see the private key
2. **SAML Impersonation**: The key could be used to forge SAML assertions
3. **Authentication Bypass**: Attackers could potentially authenticate as any user
4. **Compliance Issues**: Violates security best practices and compliance requirements

### Git History Concern

Even if we remove the key from the current .env, it remains in git history. For a production deployment:

1. **Do Not Use The Committed Key**: Generate a fresh key for production
2. **Consider Private Repository**: Ensure repository access is restricted
3. **Rotate Keys**: Plan for regular key rotation
4. **Audit Access**: Review who has access to the repository

## Best Practices for Production

### 1. Secrets Management

✅ **DO**:
- Use dedicated secrets management services
- Rotate keys annually or after exposure
- Implement least-privilege access
- Enable audit logging
- Use separate keys per environment

❌ **DON'T**:
- Commit secrets to version control
- Share keys via chat/email
- Use same key across environments
- Store keys in plain text

### 2. Deployment Strategy

```bash
# Production deployment example
# Set via environment or secrets manager

# Option 1: Environment variables (set outside of git)
export GOTRUE_SAML_ENABLED=true
export GOTRUE_SAML_PRIVATE_KEY="${PRODUCTION_SAML_KEY}"

# Option 2: Load from secure file (not in git)
source /secure/prod-secrets.env

# Option 3: Use secrets manager
# AWS Example:
aws secretsmanager get-secret-value \
  --secret-id prod/supabase/saml-key \
  --query SecretString \
  --output text
```

### 3. Key Rotation

Schedule annual key rotation:

1. Generate new key
2. Update Supabase configuration
3. Update ZITADEL with new metadata
4. Test authentication
5. Deploy to production
6. Revoke old key after verification period

## Remediation Checklist

Before going to production:

- [ ] Generate new production SAML key
- [ ] Store key in secrets manager or secure environment
- [ ] Update docker-compose to use secret/env var
- [ ] Comment out GOTRUE_SAML_PRIVATE_KEY in .env
- [ ] Update ZITADEL with new SP metadata
- [ ] Test complete authentication flow
- [ ] Enable audit logging
- [ ] Document key rotation schedule
- [ ] Restrict repository access
- [ ] Review and approve security posture

## For Development Teams

### Safe Development Workflow

1. **Local Development**: Use the committed key (it's already exposed)
2. **Staging Environment**: Generate separate staging key
3. **Production**: Use dedicated production key via secrets manager

### Environment Separation

```bash
# .env.development (can commit)
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<dev-key-from-git>

# .env.staging (do NOT commit)
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<staging-key>

# .env.production (do NOT commit, use secrets manager)
GOTRUE_SAML_ENABLED=true
# GOTRUE_SAML_PRIVATE_KEY loaded from secrets manager
```

## Questions or Concerns?

If you have questions about:
- Implementing secrets management
- Key rotation procedures
- Production deployment security
- Compliance requirements

Consult your security team or DevOps lead.

## References

- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/security)
- [SAML Security Considerations](https://docs.oasis-open.org/security/saml/v2.0/saml-sec-consider-2.0-os.pdf)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Last Updated**: 2025-10-29  
**Severity**: HIGH  
**Status**: DOCUMENTED - Requires Action Before Production
