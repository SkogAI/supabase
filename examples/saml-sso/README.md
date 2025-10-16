# SAML SSO Configuration Examples

This directory contains example scripts and configuration files for setting up SAML SSO with ZITADEL and self-hosted Supabase.

## Quick Start

1. **Phase 1**: Configure ZITADEL as SAML IdP
   - See [../../docs/ZITADEL_SAML_IDP_SETUP.md](../../docs/ZITADEL_SAML_IDP_SETUP.md)

2. **Phase 2**: Configure Supabase as SAML SP
   - See [../../docs/SUPABASE_SAML_SP_CONFIGURATION.md](../../docs/SUPABASE_SAML_SP_CONFIGURATION.md)

## Example Files

### 1. `.env.saml.example`
Environment variables template for SAML configuration.

Copy to your `.env` file:
```bash
cat .env.saml.example >> ../.env
```

### 2. `generate-saml-key.sh`
Script to generate SAML private key and encode it for use in environment variables.

Usage:
```bash
./generate-saml-key.sh
```

### 3. `register-zitadel-provider.sh`
Script to register ZITADEL as a SAML provider via Supabase Admin API.

Edit the configuration variables first, then run:
```bash
./register-zitadel-provider.sh
```

### 4. `docker-compose.auth.example.yml`
Example auth service configuration for docker-compose.yml with SAML support.

Copy the relevant sections to your `docker-compose.yml`.

### 5. `kong.saml-routes.example.yml`
Example Kong configuration for SAML endpoints.

Add to your `kong.yml` services section.

### 6. `verify-saml-setup.sh`
Script to verify SAML configuration is working correctly.

Usage:
```bash
./verify-saml-setup.sh
```

## Security Notes

⚠️ **Important Security Reminders**:

1. **Never commit private keys** to version control
2. **Use HTTPS in production** (HTTP only for local development)
3. **Restrict service role key** access
4. **Rotate keys regularly** (at least annually)
5. **Use strong passwords** for service accounts
6. **Enable audit logging** for SSO events
7. **Limit domain access** to verified company domains

## Support

For issues or questions:
- Review the [troubleshooting guide](../../docs/SUPABASE_SAML_SP_CONFIGURATION.md#troubleshooting)
- Check [ZITADEL documentation](https://zitadel.com/docs)
- Check [Supabase documentation](https://supabase.com/docs)

## Related Documentation

- [ZITADEL SAML IdP Setup](../../docs/ZITADEL_SAML_IDP_SETUP.md)
- [Supabase SAML SP Configuration](../../docs/SUPABASE_SAML_SP_CONFIGURATION.md)
- [DevOps Guide](../../DEVOPS.md)
- [README - Authentication & SSO](../../README.md#authentication--sso)
