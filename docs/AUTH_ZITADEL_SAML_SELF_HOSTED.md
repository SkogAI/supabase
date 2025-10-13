# ZITADEL SAML Integration for Self-Hosted Supabase

Complete end-to-end guide for implementing SAML 2.0 Single Sign-On (SSO) using ZITADEL with **self-hosted Supabase** instances.

> **Important**: This guide is for self-hosted Supabase deployments. For supabase.com, refer to the [official Supabase SSO documentation](https://supabase.com/docs/guides/auth/sso/auth-sso-saml).

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Phase 1: ZITADEL Configuration](#phase-1-zitadel-configuration)
- [Phase 2: Supabase Configuration](#phase-2-supabase-configuration)
- [Phase 3: Integration Testing](#phase-3-integration-testing)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Maintenance & Operations](#maintenance--operations)
- [References](#references)

---

## Overview

This guide provides comprehensive instructions for integrating ZITADEL as a SAML Identity Provider (IdP) with your self-hosted Supabase instance, enabling enterprise-grade Single Sign-On authentication.

### What You'll Accomplish

- ✅ Configure ZITADEL as SAML Identity Provider
- ✅ Set up self-hosted Supabase as SAML Service Provider
- ✅ Configure Kong API Gateway for SAML routing
- ✅ Implement secure certificate management
- ✅ Enable user authentication via SAML SSO
- ✅ Set up monitoring and audit logging

### Key Features

- **Single Sign-On**: Users authenticate once with ZITADEL
- **Centralized Identity**: Manage users in ZITADEL
- **Secure Authentication**: SAML 2.0 with certificate-based security
- **Self-Hosted Control**: Full control over authentication infrastructure
- **Enterprise Ready**: Suitable for production deployments

---

## Architecture

### System Components

```
┌──────────────────────────────────────────────────────────────────┐
│                         User Browser                              │
└─────────────┬───────────────────────────────────┬────────────────┘
              │                                   │
              │ 1. Access App                     │ 5. SAML Response
              ▼                                   │
┌─────────────────────────────────────────────────▼────────────────┐
│                     Supabase (Service Provider)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │     Kong     │  │   GoTrue     │  │     PostgreSQL        │  │
│  │  API Gateway │─▶│  Auth Server │─▶│   auth.saml_providers │  │
│  │  :8000       │  │              │  │   auth.users          │  │
│  └──────────────┘  └──────────────┘  └───────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
              │                                   ▲
              │ 2. SAML Request                   │ 4. Assertion
              ▼                                   │
┌─────────────────────────────────────────────────────────────────┐
│                    ZITADEL (Identity Provider)                   │
│  ┌──────────────────────┐  ┌────────────────────────────────┐  │
│  │  SAML 2.0 Endpoint   │  │      User Directory            │  │
│  │  /saml/v2/SSO        │  │  - Users                       │  │
│  │  /saml/v2/metadata   │  │  - Organizations               │  │
│  └──────────────────────┘  │  - Attributes                  │  │
│            │                └────────────────────────────────┘  │
│            │ 3. User Authentication                              │
│            ▼                                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              User Authentication UI                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Docker Container Architecture

```
Self-Hosted Supabase Stack:

┌─────────────────────────────────────────────┐
│  Docker Compose Environment                 │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │  kong:latest                          │ │
│  │  - Port 8000 (HTTP)                   │ │
│  │  - Port 8443 (HTTPS)                  │ │
│  │  - Routes SAML endpoints              │ │
│  └───────────────────────────────────────┘ │
│  ┌───────────────────────────────────────┐ │
│  │  supabase/gotrue:latest               │ │
│  │  - SAML provider management           │ │
│  │  - User authentication                │ │
│  │  - JWT token generation               │ │
│  └───────────────────────────────────────┘ │
│  ┌───────────────────────────────────────┐ │
│  │  postgres:17-alpine                   │ │
│  │  - auth.saml_providers table          │ │
│  │  - auth.saml_relay_states table       │ │
│  │  - auth.users table                   │ │
│  └───────────────────────────────────────┘ │
│  ┌───────────────────────────────────────┐ │
│  │  Other services (studio, storage...)  │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### SAML Authentication Flow

**SP-Initiated Flow** (User starts at Supabase):

```
1. User accesses application → Supabase
   GET /auth/v1/sso/saml/acs?provider_id={id}

2. Supabase generates SAML Request
   - Creates AuthnRequest XML
   - Signs with SP private key
   - Encodes and redirects

3. Browser redirects to ZITADEL
   POST https://instance.zitadel.cloud/saml/v2/SSO
   (SAML Request in POST body)

4. User authenticates with ZITADEL
   - Username/password
   - MFA if enabled
   - Consent screen (first time)

5. ZITADEL generates SAML Response
   - Creates Response XML with assertions
   - Signs with IdP private key
   - Encodes response

6. Browser POST to Supabase ACS endpoint
   POST /auth/v1/sso/saml/acs
   (SAML Response in POST body)

7. Supabase validates response
   - Verifies signature
   - Validates assertions
   - Checks timestamp/audience

8. Supabase creates/updates user
   - Extracts attributes from assertion
   - Creates user in auth.users table
   - Links to SAML provider

9. Supabase generates JWT token
   - Returns session token
   - Sets auth cookies

10. User authenticated
    - Redirected to application
    - Session established
```

### Kong Routing Configuration

Kong routes SAML endpoints to GoTrue auth server:

```yaml
# Kong automatically routes these paths:
/auth/v1/sso/saml/metadata     → GoTrue (GET)
/auth/v1/sso/saml/acs          → GoTrue (POST)
/auth/v1/admin/sso/providers   → GoTrue Admin API (GET, POST, PUT, DELETE)
```

---

## Prerequisites

### Required Infrastructure

- ✅ **Docker & Docker Compose**: Version 20.10+ with sufficient resources
- ✅ **Self-Hosted Supabase**: Running instance (see [setup guide](../README.md))
- ✅ **ZITADEL Instance**: Cloud or self-hosted (see [ZITADEL setup](ZITADEL_SAML_IDP_SETUP.md))
- ✅ **Domain Name**: Production domain with SSL certificate
- ✅ **OpenSSL**: For certificate generation

### Access Requirements

- ✅ **Supabase Admin**: Access to database and configuration
- ✅ **ZITADEL Admin**: Full administrative access
- ✅ **Server Access**: SSH/shell access to Supabase host
- ✅ **Service Role Key**: Supabase service role API key

### Knowledge Requirements

- Basic understanding of SAML 2.0 concepts
- Docker and docker-compose experience
- PostgreSQL database administration
- Linux command line proficiency

### Environment Setup

```bash
# Verify Docker is running
docker info

# Verify Supabase is running
docker ps | grep supabase

# Check Supabase status
cd /path/to/supabase/project
npm run db:status
```

---

## Phase 1: ZITADEL Configuration

Complete ZITADEL Identity Provider setup as documented in:

📖 **[ZITADEL SAML IdP Setup Guide](ZITADEL_SAML_IDP_SETUP.md)**

This phase covers:
1. Creating SAML application in ZITADEL
2. Configuring attribute mapping
3. Exporting SAML metadata
4. Creating test users

**Output from Phase 1:**
- ZITADEL SAML metadata XML file
- Entity ID (IdP identifier)
- SSO endpoint URL
- X.509 certificate
- Test user credentials

---

## Phase 2: Supabase Configuration

### Step 1: Generate Service Provider Certificates

Supabase requires a private key and certificate for SAML signing.

#### Generate Private Key and Certificate

```bash
# Create directory for SAML certificates
mkdir -p /secure/saml/certs
cd /secure/saml/certs

# Generate private key (2048-bit RSA)
openssl genrsa -out saml_sp_private.key 2048

# Generate self-signed certificate (valid 10 years)
openssl req -new -x509 -key saml_sp_private.key \
  -out saml_sp_cert.pem -days 3650 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"

# Secure the private key
chmod 600 saml_sp_private.key
chmod 644 saml_sp_cert.pem
```

#### Certificate Parameters

| Field | Description | Example |
|-------|-------------|---------|
| `C` | Country | `US` |
| `ST` | State/Province | `California` |
| `L` | Locality/City | `San Francisco` |
| `O` | Organization | `Your Company` |
| `CN` | Common Name (domain) | `auth.yourdomain.com` |

#### Verify Certificate

```bash
# View certificate details
openssl x509 -in saml_sp_cert.pem -text -noout

# Should show:
# - Subject: your organization details
# - Validity: 10 years from creation
# - Public Key: RSA 2048-bit
```

### Step 2: Configure Environment Variables

Add SAML configuration to your Supabase environment.

#### Update Docker Compose Configuration

Edit your `docker-compose.yml` or create environment file:

```yaml
# docker-compose.yml (excerpt)
services:
  auth:
    image: supabase/gotrue:latest
    environment:
      # Existing variables...
      
      # SAML Configuration
      GOTRUE_SAML_ENABLED: "true"
      
      # Private key for signing SAML requests (base64 encoded)
      GOTRUE_SAML_PRIVATE_KEY: "${SAML_SP_PRIVATE_KEY}"
      
      # Service Provider metadata URL
      GOTRUE_SITE_URL: "https://your-domain.com"
      
      # Admin API access
      GOTRUE_ADMIN_JWT_SECRET: "${JWT_SECRET}"
    volumes:
      - ./volumes/gotrue:/etc/gotrue
```

#### Encode Private Key for Environment Variable

```bash
# Base64 encode the private key (single line)
cat /secure/saml/certs/saml_sp_private.key | base64 -w 0

# Add to .env file
echo "SAML_SP_PRIVATE_KEY=$(cat /secure/saml/certs/saml_sp_private.key | base64 -w 0)" >> .env
```

#### Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `GOTRUE_SAML_ENABLED` | Yes | Enable SAML support | `true` |
| `GOTRUE_SAML_PRIVATE_KEY` | Yes | Base64-encoded private key | `LS0tLS1CRUdJTi...` |
| `GOTRUE_SITE_URL` | Yes | Your Supabase URL | `https://auth.yourdomain.com` |
| `GOTRUE_ADMIN_JWT_SECRET` | Yes | JWT secret for admin API | `your-secret-key` |

### Step 3: Restart Supabase Services

Apply the new configuration:

```bash
# Stop services
docker-compose down

# Start with new configuration
docker-compose up -d

# Verify auth service started correctly
docker-compose logs auth | grep -i saml

# Should see: "SAML enabled: true"
```

### Step 4: Add SAML Provider via Admin API

Use the GoTrue Admin API to register ZITADEL as a SAML provider.

#### Prepare SAML Provider Configuration

Create a JSON file with ZITADEL metadata:

```bash
# Create configuration file
cat > /tmp/saml-provider.json <<'EOF'
{
  "type": "saml",
  "domains": ["yourdomain.com"],
  "metadata_url": "https://instance.zitadel.cloud/saml/v2/metadata",
  "metadata_xml": "<?xml version=\"1.0\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\"...",
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "first_name": "FirstName",
      "last_name": "SurName"
    }
  }
}
EOF
```

#### Register Provider via API

```bash
# Get your service role key
SERVICE_ROLE_KEY="your-service-role-key"
SUPABASE_URL="http://localhost:8000"

# Create SAML provider
curl -X POST "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d @/tmp/saml-provider.json

# Response:
# {
#   "id": "00000000-0000-0000-0000-000000000000",
#   "created_at": "2024-01-01T00:00:00Z",
#   "updated_at": "2024-01-01T00:00:00Z",
#   "type": "saml",
#   "domains": ["yourdomain.com"],
#   ...
# }
```

#### Verify Provider Registration

```bash
# List all SSO providers
curl -X GET "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json"

# Check database directly
docker exec -it supabase-db psql -U postgres -d postgres \
  -c "SELECT id, type, domains FROM auth.saml_providers;"
```

### Step 5: Configure Kong Routing

Kong automatically routes SAML endpoints, but you may need to verify configuration.

#### Verify Kong Routes

```bash
# Check Kong admin API
curl http://localhost:8001/services/auth/routes | jq '.data[] | select(.paths[] | contains("saml"))'

# Expected routes:
# - /auth/v1/sso/saml/metadata
# - /auth/v1/sso/saml/acs
```

#### Manual Kong Route Configuration (if needed)

If SAML routes are not automatic, add them manually:

```bash
# Create SAML metadata route
curl -X POST http://localhost:8001/services/auth/routes \
  -d "paths[]=/auth/v1/sso/saml/metadata" \
  -d "methods[]=GET" \
  -d "strip_path=false"

# Create SAML ACS route
curl -X POST http://localhost:8001/services/auth/routes \
  -d "paths[]=/auth/v1/sso/saml/acs" \
  -d "methods[]=POST" \
  -d "strip_path=false"
```

### Step 6: Update ZITADEL with Supabase SP Metadata

Return to ZITADEL and update the SAML application with Supabase Service Provider details.

#### Get Supabase SP Metadata

```bash
# Download SP metadata
curl http://localhost:8000/auth/v1/sso/saml/metadata > supabase-sp-metadata.xml

# View metadata
cat supabase-sp-metadata.xml
```

#### Update ZITADEL Application

1. Navigate to ZITADEL Console → Your Project → Applications
2. Edit your SAML application
3. Update Entity ID and ACS URL (should match what you configured initially)
4. Save changes

---

## Phase 3: Integration Testing

### Test 1: Metadata Endpoint

Verify SP metadata is accessible:

```bash
# Test metadata endpoint
curl -v http://localhost:8000/auth/v1/sso/saml/metadata

# Should return XML with:
# - EntityDescriptor
# - SPSSODescriptor
# - AssertionConsumerService URL
# - Certificate
```

### Test 2: SAML Authentication Flow

Test complete authentication flow:

#### Manual Browser Test

1. **Initiate SAML Login**
   ```
   http://localhost:8000/auth/v1/sso?provider_id={provider-id}
   ```

2. **Expected Flow:**
   - Redirects to ZITADEL login page
   - Login with test user credentials
   - Redirects back to Supabase
   - User authenticated and session created

3. **Verify User Created:**
   ```bash
   docker exec -it supabase-db psql -U postgres -d postgres \
     -c "SELECT id, email, created_at FROM auth.users WHERE email='testuser@yourdomain.com';"
   ```

#### Automated Test with curl

```bash
# This is complex due to redirects and POST data
# Consider using a SAML test tool like:
# - saml-chrome-panel (Chrome extension)
# - SAML-tracer (Firefox extension)
```

### Test 3: Attribute Mapping

Verify user attributes are correctly mapped:

```bash
# Query user metadata
docker exec -it supabase-db psql -U postgres -d postgres \
  -c "SELECT email, raw_user_meta_data FROM auth.users WHERE email='testuser@yourdomain.com';"

# Should show:
#        email         |           raw_user_meta_data
# ---------------------+----------------------------------------
# testuser@domain.com  | {"name": "Test User", "first_name": "Test", ...}
```

### Test 4: Session Management

Verify JWT tokens are generated:

```bash
# After successful login, check for session token
# In browser console or via API response

# Decode JWT (replace with actual token)
echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." | \
  cut -d'.' -f2 | base64 -d | jq

# Should show user ID, email, and expiry
```

### Common Test Failures

| Issue | Cause | Solution |
|-------|-------|----------|
| 404 on /auth/v1/sso/saml/metadata | Kong not routing | Check Kong routes |
| 500 error on ACS endpoint | Private key not loaded | Check SAML_SP_PRIVATE_KEY env var |
| User not created | Attribute mapping wrong | Review attribute configuration |
| Invalid signature error | Certificate mismatch | Re-sync metadata between IdP/SP |

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] SSL/TLS certificates configured
- [ ] Production domain configured
- [ ] Environment variables in secure secret management
- [ ] Database backups configured
- [ ] Monitoring and alerting set up
- [ ] Certificate expiry monitoring enabled
- [ ] Load testing completed
- [ ] Security audit performed
- [ ] Documentation updated

### SSL/TLS Configuration

#### Configure HTTPS for Supabase

```yaml
# docker-compose.yml
services:
  kong:
    ports:
      - "80:8000"
      - "443:8443"
    environment:
      KONG_SSL_CERT: /etc/kong/ssl/cert.pem
      KONG_SSL_CERT_KEY: /etc/kong/ssl/key.pem
    volumes:
      - ./ssl:/etc/kong/ssl:ro
```

#### Update URLs to HTTPS

```bash
# Update environment variables
GOTRUE_SITE_URL=https://auth.yourdomain.com

# Update ZITADEL SAML application
# - Entity ID: https://auth.yourdomain.com/auth/v1/sso/saml/metadata
# - ACS URL: https://auth.yourdomain.com/auth/v1/sso/saml/acs
```

### Environment Variable Security

**Never commit secrets to git!**

Use secret management:

```bash
# Example with Docker Swarm secrets
docker secret create saml_private_key /secure/saml/certs/saml_sp_private.key

# docker-compose.yml
services:
  auth:
    secrets:
      - saml_private_key
    environment:
      GOTRUE_SAML_PRIVATE_KEY_FILE: /run/secrets/saml_private_key

secrets:
  saml_private_key:
    external: true
```

### Monitoring Setup

#### Log SAML Events

Enable detailed logging:

```yaml
services:
  auth:
    environment:
      GOTRUE_LOG_LEVEL: "debug"
      GOTRUE_LOG_FILE: "/var/log/gotrue/auth.log"
    volumes:
      - ./logs:/var/log/gotrue
```

#### Monitor Authentication Events

```bash
# Monitor SAML authentications
docker-compose logs -f auth | grep -i saml

# Monitor failed logins
docker-compose logs auth | grep -i "authentication failed"
```

#### Database Audit Logging

```sql
-- Enable audit logging for SAML providers table
CREATE EXTENSION IF NOT EXISTS pgaudit;

ALTER DATABASE postgres SET pgaudit.log = 'write';
ALTER DATABASE postgres SET pgaudit.log_catalog = off;
ALTER DATABASE postgres SET pgaudit.log_relation = on;

-- Monitor auth events
SELECT * FROM auth.audit_log_entries 
WHERE table_name = 'saml_providers' 
ORDER BY created_at DESC 
LIMIT 10;
```

### Backup Procedures

#### Backup SAML Configuration

```bash
# Backup certificates
tar -czf saml-certs-backup-$(date +%Y%m%d).tar.gz /secure/saml/certs/

# Backup SAML provider configuration
docker exec -it supabase-db pg_dump -U postgres \
  -t auth.saml_providers \
  -t auth.saml_relay_states \
  --data-only \
  postgres > saml-config-backup-$(date +%Y%m%d).sql
```

#### Restore Procedures

```bash
# Restore certificates
tar -xzf saml-certs-backup-20240101.tar.gz -C /

# Restore configuration
docker exec -i supabase-db psql -U postgres postgres < saml-config-backup-20240101.sql
```

---

## Troubleshooting

See comprehensive troubleshooting guide:

📖 **[SAML Troubleshooting Runbook](runbooks/saml-troubleshooting-self-hosted.md)**

### Quick Diagnostic Commands

```bash
# Check if SAML is enabled
docker-compose exec auth env | grep SAML

# Test metadata endpoint
curl -v http://localhost:8000/auth/v1/sso/saml/metadata

# Check database provider registration
docker exec -it supabase-db psql -U postgres -d postgres \
  -c "SELECT * FROM auth.saml_providers;"

# View recent auth logs
docker-compose logs --tail=100 auth | grep -i saml

# Verify Kong routes
curl http://localhost:8001/services/auth/routes | jq
```

### Common Issues

#### 1. SAML Endpoint Returns 404

**Symptoms:**
- `/auth/v1/sso/saml/metadata` returns 404
- `/auth/v1/sso/saml/acs` returns 404

**Solutions:**
```bash
# Check Kong is routing to auth service
curl http://localhost:8001/services | jq '.data[] | select(.name=="auth")'

# Verify auth service is running
docker ps | grep gotrue

# Check auth service logs
docker-compose logs auth
```

#### 2. Invalid Signature Error

**Symptoms:**
- "Invalid SAML response signature"
- Authentication fails after ZITADEL login

**Solutions:**
```bash
# Verify IdP certificate matches
# 1. Extract certificate from ZITADEL metadata
curl https://instance.zitadel.cloud/saml/v2/metadata | \
  grep -o '<X509Certificate>.*</X509Certificate>' | \
  sed 's/<[^>]*>//g'

# 2. Compare with database stored certificate
docker exec -it supabase-db psql -U postgres -d postgres \
  -c "SELECT certificate FROM auth.saml_providers WHERE type='saml';"

# 3. Re-sync if different - update provider via API
```

#### 3. User Not Created After Login

**Symptoms:**
- SAML login succeeds but user not in database
- Repeated login prompts

**Solutions:**
```bash
# Check attribute mapping
docker exec -it supabase-db psql -U postgres -d postgres \
  -c "SELECT attribute_mapping FROM auth.saml_providers;"

# Verify email attribute is mapped
# Should include: {"keys": {"email": "Email", ...}}

# Check auth logs for errors
docker-compose logs auth | grep -i "attribute"
```

---

## Security Considerations

### Threat Model

| Threat | Mitigation |
|--------|------------|
| Private key compromise | Secure storage, rotation, encryption at rest |
| Man-in-the-middle | TLS/HTTPS required, certificate pinning |
| Replay attacks | Timestamp validation, nonce checking |
| Session hijacking | Secure cookies, short session lifetime |
| Metadata tampering | Signature verification, HTTPS metadata URLs |

### Security Best Practices

#### 1. Private Key Protection

```bash
# File permissions
chmod 600 /secure/saml/certs/saml_sp_private.key

# Use encrypted storage
# Example: LUKS encrypted volume
cryptsetup luksFormat /dev/sdb1
cryptsetup open /dev/sdb1 saml-certs
mkfs.ext4 /dev/mapper/saml-certs
mount /dev/mapper/saml-certs /secure/saml/certs
```

#### 2. Certificate Rotation

**Recommended: Rotate certificates every 12 months**

```bash
# Generate new certificate
openssl genrsa -out saml_sp_private_new.key 2048
openssl req -new -x509 -key saml_sp_private_new.key \
  -out saml_sp_cert_new.pem -days 3650 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"

# Update Supabase configuration
# 1. Base64 encode new key
# 2. Update GOTRUE_SAML_PRIVATE_KEY environment variable
# 3. Restart services

# Update ZITADEL
# 1. Export new SP metadata from Supabase
# 2. Update ZITADEL SAML application with new certificate
```

#### 3. Audit Logging

Enable comprehensive audit logging:

```sql
-- Track SAML authentication events
CREATE TABLE IF NOT EXISTS auth.saml_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  event_type TEXT NOT NULL,
  user_id UUID,
  provider_id UUID,
  success BOOLEAN,
  error_message TEXT,
  ip_address INET,
  user_agent TEXT
);

-- Create trigger to log SAML events
-- (Implementation depends on your application layer)
```

#### 4. Network Security

```yaml
# docker-compose.yml
# Restrict database access
services:
  db:
    networks:
      - private
    # No ports exposed to host

  auth:
    networks:
      - private
      - public
    # Only expose via Kong

networks:
  private:
    internal: true
  public:
    driver: bridge
```

#### 5. Compliance Considerations

**SOC 2:**
- Enable audit logging for all SAML operations
- Implement access controls for SAML configuration
- Regular security reviews and penetration testing
- Incident response procedures documented

**GDPR:**
- Document data flows in SAML assertions
- Implement user consent mechanisms
- Provide data access and deletion capabilities
- Data processing agreements with ZITADEL

---

## Maintenance & Operations

### Regular Maintenance Tasks

| Task | Frequency | Procedure |
|------|-----------|-----------|
| Certificate check | Monthly | Verify expiry dates |
| Security updates | Weekly | Update Docker images |
| Backup verification | Monthly | Test restore procedures |
| Audit log review | Weekly | Check for anomalies |
| Performance monitoring | Daily | Review metrics |

### Certificate Expiry Monitoring

```bash
# Check certificate expiry
openssl x509 -in /secure/saml/certs/saml_sp_cert.pem -noout -dates

# Automated expiry check script
cat > /usr/local/bin/check-saml-cert-expiry.sh <<'EOF'
#!/bin/bash
CERT_FILE="/secure/saml/certs/saml_sp_cert.pem"
EXPIRY_DATE=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
  echo "WARNING: SAML certificate expires in $DAYS_UNTIL_EXPIRY days!"
  # Send alert (email, Slack, PagerDuty, etc.)
fi
EOF

chmod +x /usr/local/bin/check-saml-cert-expiry.sh

# Add to cron
echo "0 9 * * * /usr/local/bin/check-saml-cert-expiry.sh" | crontab -
```

### Updating SAML Provider Configuration

```bash
# Get provider ID
PROVIDER_ID=$(curl -s -X GET "${SUPABASE_URL}/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" | jq -r '.items[0].id')

# Update configuration
curl -X PUT "${SUPABASE_URL}/auth/v1/admin/sso/providers/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "attribute_mapping": {
      "keys": {
        "email": "Email",
        "name": "FullName",
        "department": "Department"
      }
    }
  }'
```

### Service Restart Procedures

```bash
# Graceful restart (no downtime)
docker-compose up -d --force-recreate --no-deps auth

# Full restart (brief downtime)
docker-compose restart auth

# Emergency stop and start
docker-compose stop auth
docker-compose start auth

# Verify service health
docker-compose ps auth
docker-compose logs --tail=50 auth
```

---

## References

### Documentation

- **ZITADEL SAML Setup**: [ZITADEL_SAML_IDP_SETUP.md](ZITADEL_SAML_IDP_SETUP.md)
- **SAML Admin API**: [SAML_ADMIN_API.md](SAML_ADMIN_API.md)
- **User Guide**: [USER_GUIDE_SAML.md](USER_GUIDE_SAML.md)
- **Troubleshooting**: [runbooks/saml-troubleshooting-self-hosted.md](runbooks/saml-troubleshooting-self-hosted.md)

### External Resources

- **SAML 2.0 Specification**: https://docs.oasis-open.org/security/saml/v2.0/
- **ZITADEL SAML Docs**: https://zitadel.com/docs/guides/integrate/services/saml
- **Supabase Auth Docs**: https://supabase.com/docs/guides/auth
- **GoTrue SAML**: https://github.com/supabase/gotrue

### Related Issues

- **Implementation Plan**: GitHub Issue #68
- **ZITADEL IdP Setup**: GitHub Issue #69
- **Supabase SP Setup**: GitHub Issue #70
- **Integration Testing**: GitHub Issue #71
- **Documentation**: GitHub Issue #72

---

## Appendix

### A. Complete Example Configuration

```yaml
# docker-compose.yml (SAML-related sections)
version: '3.8'

services:
  auth:
    image: supabase/gotrue:latest
    depends_on:
      - db
    environment:
      # SAML Configuration
      GOTRUE_SAML_ENABLED: "true"
      GOTRUE_SAML_PRIVATE_KEY: "${SAML_SP_PRIVATE_KEY}"
      GOTRUE_SITE_URL: "https://auth.yourdomain.com"
      GOTRUE_ADMIN_JWT_SECRET: "${JWT_SECRET}"
      
      # Database
      GOTRUE_DB_DRIVER: "postgres"
      DATABASE_URL: "postgres://postgres:postgres@db:5432/postgres"
      
      # JWT
      GOTRUE_JWT_SECRET: "${JWT_SECRET}"
      GOTRUE_JWT_EXP: "3600"
      GOTRUE_JWT_DEFAULT_GROUP_NAME: "authenticated"
    ports:
      - "9999:9999"
    networks:
      - private

  kong:
    image: kong:latest
    depends_on:
      - auth
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: "/etc/kong/kong.yml"
      KONG_DNS_ORDER: "LAST,A,CNAME"
      KONG_PLUGINS: "request-transformer,cors,key-auth"
    ports:
      - "8000:8000"
      - "8443:8443"
    networks:
      - private
      - public
    volumes:
      - ./kong.yml:/etc/kong/kong.yml:ro
      - ./ssl:/etc/kong/ssl:ro

networks:
  private:
    internal: true
  public:
    driver: bridge
```

### B. Environment Variables (.env)

```bash
# SAML Configuration
SAML_SP_PRIVATE_KEY=LS0tLS1CRUdJTi...
SAML_SP_CERT=LS0tLS1CRUdJTi...

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this

# Admin API
SERVICE_ROLE_KEY=your-service-role-key

# Supabase URL
GOTRUE_SITE_URL=https://auth.yourdomain.com
```

### C. Health Check Script

```bash
#!/bin/bash
# saml-health-check.sh

echo "=== SAML Health Check ==="

# 1. Check metadata endpoint
echo -n "Metadata endpoint: "
if curl -sf http://localhost:8000/auth/v1/sso/saml/metadata > /dev/null; then
  echo "✓ OK"
else
  echo "✗ FAILED"
fi

# 2. Check database provider
echo -n "SAML provider in database: "
PROVIDER_COUNT=$(docker exec -it supabase-db psql -U postgres -d postgres \
  -t -c "SELECT COUNT(*) FROM auth.saml_providers;" | tr -d ' \n')
if [ "$PROVIDER_COUNT" -gt 0 ]; then
  echo "✓ OK ($PROVIDER_COUNT providers)"
else
  echo "✗ FAILED (no providers)"
fi

# 3. Check certificate expiry
echo -n "Certificate expiry: "
DAYS=$(openssl x509 -in /secure/saml/certs/saml_sp_cert.pem -noout -enddate | \
  cut -d= -f2 | xargs -I {} date -d "{}" +%s | \
  xargs -I {} echo "({} - $(date +%s)) / 86400" | bc)
if [ "$DAYS" -gt 30 ]; then
  echo "✓ OK ($DAYS days remaining)"
else
  echo "⚠ WARNING ($DAYS days remaining)"
fi

# 4. Check auth service
echo -n "Auth service status: "
if docker ps | grep -q gotrue; then
  echo "✓ OK"
else
  echo "✗ FAILED"
fi

echo "=== End Health Check ==="
```

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-01-01  
**Authors**: Supabase Integration Team  
**Status**: Production Ready
