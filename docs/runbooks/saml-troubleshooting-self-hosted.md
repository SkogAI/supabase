# SAML Troubleshooting Runbook for Self-Hosted Supabase

Operational troubleshooting guide for administrators managing SAML SSO in self-hosted Supabase deployments.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Service Health Checks](#service-health-checks)
- [Log Analysis](#log-analysis)
- [Certificate Issues](#certificate-issues)
- [Network & Connectivity](#network--connectivity)
- [Database Issues](#database-issues)
- [Emergency Procedures](#emergency-procedures)

---

## Quick Diagnostics

### 5-Minute Health Check

Run these commands to quickly assess SAML SSO status:

```bash
#!/bin/bash
# saml-quick-check.sh

echo "=== SAML SSO Health Check ==="
echo

# 1. Check Docker services
echo "1. Docker Services:"
docker ps --filter "name=supabase" --format "{{.Names}}: {{.Status}}"
echo

# 2. Check SAML metadata endpoint
echo "2. Metadata Endpoint:"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/auth/v1/sso/saml/metadata)
if [ "$STATUS" = "200" ]; then
  echo "✓ OK (HTTP $STATUS)"
else
  echo "✗ FAILED (HTTP $STATUS)"
fi
echo

# 3. Check database connection
echo "3. Database Connection:"
docker exec supabase-db psql -U postgres -c "SELECT 1" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✓ OK"
else
  echo "✗ FAILED"
fi
echo

# 4. Check SAML provider count
echo "4. SAML Providers:"
PROVIDERS=$(docker exec supabase-db psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM auth.saml_providers" 2>/dev/null | tr -d ' ')
if [ -n "$PROVIDERS" ] && [ "$PROVIDERS" -gt 0 ]; then
  echo "✓ OK ($PROVIDERS configured)"
else
  echo "✗ No providers configured"
fi
echo

# 5. Check auth service environment
echo "5. SAML Configuration:"
docker exec supabase-auth env | grep GOTRUE_SAML_ENABLED > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✓ SAML enabled"
else
  echo "✗ SAML not enabled"
fi
echo

echo "=== End Health Check ==="
```

### Decision Tree

```
Login Failed?
├─ Can't access /auth/v1/sso/saml/metadata?
│  ├─ Returns 404 → Kong routing issue (see Section 3.1)
│  └─ Returns 500 → GoTrue configuration issue (see Section 3.2)
│
├─ Redirected to ZITADEL but error there?
│  ├─ "Invalid request" → SP metadata issue (see Section 4.1)
│  └─ "User not found" → ZITADEL user setup (see Section 4.2)
│
├─ Redirected back but not logged in?
│  ├─ "Invalid signature" → Certificate mismatch (see Section 5.1)
│  ├─ "Invalid assertion" → Attribute mapping (see Section 6.1)
│  └─ Silent failure → Check logs (see Section 2.1)
│
└─ User created but can't access resources?
   └─ RLS policy issue (not SAML-related)
```

---

## Common Issues

### 1. SAML Endpoint Returns 404

**Symptoms:**
```bash
$ curl http://localhost:8000/auth/v1/sso/saml/metadata
404 Not Found
```

**Diagnosis:**

```bash
# Check Kong routes
curl -s http://localhost:8001/services/auth/routes | jq '.data[] | select(.paths[] | contains("saml"))'

# Should return SAML routes, if empty:
```

**Resolution:**

```bash
# Verify auth service is registered in Kong
curl http://localhost:8001/services/auth

# If missing, check Kong configuration
docker exec supabase-kong cat /etc/kong/kong.yml

# Restart Kong to reload config
docker restart supabase-kong

# Wait 10 seconds then test
sleep 10
curl http://localhost:8000/auth/v1/sso/saml/metadata
```

**Root Causes:**
- Kong configuration not loaded
- Auth service not reachable by Kong
- SAML routes not defined in kong.yml

**Prevention:**
- Use configuration management for kong.yml
- Automated health checks
- Service dependency order in docker-compose

---

### 2. Invalid SAML Response Signature

**Symptoms:**
```
Error: "SAML response signature verification failed"
User redirected back to login
```

**Diagnosis:**

```bash
# Compare certificates
echo "=== Certificate from Database ==="
docker exec supabase-db psql -U postgres -d postgres \
  -c "SELECT substring(certificate, 1, 100) FROM auth.saml_providers WHERE type='saml';"

echo "=== Certificate from ZITADEL Metadata ==="
curl -s https://instance.zitadel.cloud/saml/v2/metadata | \
  grep -o '<X509Certificate>.*</X509Certificate>' | \
  sed 's/<[^>]*>//g' | head -c 100

# Should match
```

**Resolution:**

**Option 1: Re-fetch Metadata**

```bash
# Update provider with latest metadata
SERVICE_ROLE_KEY="your-service-role-key"
PROVIDER_ID="provider-uuid"

curl -X PUT "http://localhost:8000/auth/v1/admin/sso/providers/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata_url": "https://instance.zitadel.cloud/saml/v2/metadata"
  }'
```

**Option 2: Manual Update**

```bash
# Fetch latest metadata
curl https://instance.zitadel.cloud/saml/v2/metadata > /tmp/metadata.xml

# Extract certificate
CERT=$(xmllint --xpath "//ds:X509Certificate/text()" /tmp/metadata.xml 2>/dev/null)

# Update in database
docker exec -i supabase-db psql -U postgres -d postgres <<EOF
UPDATE auth.saml_providers 
SET certificate = '${CERT}',
    updated_at = NOW()
WHERE type = 'saml';
EOF
```

**Root Causes:**
- ZITADEL certificate rotated
- Metadata not synchronized
- Certificate extracted incorrectly

**Prevention:**
- Automated metadata refresh (daily cron)
- Certificate expiry monitoring
- Metadata update notifications

---

### 3. User Not Created After Successful Login

**Symptoms:**
- SAML authentication succeeds in ZITADEL
- User redirected back to application
- No user record in database
- Login prompt appears again

**Diagnosis:**

```bash
# Check auth logs for attribute errors
docker logs supabase-auth 2>&1 | grep -i "attribute\|assertion" | tail -20

# Check provider attribute mapping
docker exec supabase-db psql -U postgres -d postgres \
  -c "SELECT attribute_mapping FROM auth.saml_providers WHERE type='saml';"

# Expected: {"keys": {"email": "Email", ...}}
```

**Resolution:**

**Step 1: Verify Attribute Mapping**

```bash
# Check what ZITADEL sends in assertion
# Use SAML tracer browser extension to capture SAML response
# Look for AttributeStatement in response

# Common ZITADEL attributes:
# - Email (user email)
# - FirstName (given name)
# - SurName (family name)
# - FullName (display name)
```

**Step 2: Update Attribute Mapping**

```bash
SERVICE_ROLE_KEY="your-service-role-key"
PROVIDER_ID="provider-uuid"

curl -X PUT "http://localhost:8000/auth/v1/admin/sso/providers/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "attribute_mapping": {
      "keys": {
        "email": "Email",
        "name": "FullName",
        "first_name": "FirstName",
        "last_name": "SurName"
      }
    }
  }'
```

**Step 3: Verify Email Attribute**

```sql
-- Email attribute is REQUIRED
-- Check mapping includes email
SELECT 
  attribute_mapping->'keys'->>'email' as email_attribute
FROM auth.saml_providers 
WHERE type = 'saml';

-- Should return: "Email"
-- If NULL, email mapping is missing
```

**Root Causes:**
- Email attribute not mapped
- Attribute name mismatch (case-sensitive)
- ZITADEL not sending required attributes

**Prevention:**
- Test attribute mapping with test users
- Document ZITADEL attribute configuration
- Validate provider config after changes

---

### 4. Certificate Expired

**Symptoms:**
```
Error: "Certificate has expired"
All SAML logins failing
```

**Diagnosis:**

```bash
# Check SP certificate expiry
openssl x509 -in /secure/saml/certs/saml_sp_cert.pem -noout -dates

# Output:
# notBefore=Jan  1 00:00:00 2024 GMT
# notAfter=Jan  1 00:00:00 2034 GMT

# Check if expired
openssl x509 -in /secure/saml/certs/saml_sp_cert.pem -noout -checkend 0
# Exit 0: valid, Exit 1: expired
```

**Resolution - Emergency (< 10 minutes):**

```bash
# Generate new certificate immediately
cd /secure/saml/certs

# Backup old certificate
cp saml_sp_cert.pem saml_sp_cert.pem.old.$(date +%Y%m%d)
cp saml_sp_private.key saml_sp_private.key.old.$(date +%Y%m%d)

# Generate new key and certificate
openssl genrsa -out saml_sp_private.key 2048
openssl req -new -x509 -key saml_sp_private.key \
  -out saml_sp_cert.pem -days 3650 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"

# Update environment variable
NEW_KEY_BASE64=$(cat saml_sp_private.key | base64 -w 0)
sed -i "s/^SAML_SP_PRIVATE_KEY=.*/SAML_SP_PRIVATE_KEY=${NEW_KEY_BASE64}/" .env

# Restart auth service
docker restart supabase-auth

# Wait for startup
sleep 10

# Get new SP metadata
curl http://localhost:8000/auth/v1/sso/saml/metadata > supabase-sp-metadata-new.xml
```

**Update ZITADEL:**

1. Log in to ZITADEL Console
2. Navigate to your SAML application
3. Update with new SP metadata or certificate
4. Test login immediately

**Root Causes:**
- Certificate not monitored for expiry
- No rotation process in place
- Alert notifications not configured

**Prevention:**

```bash
# Create monitoring script
cat > /usr/local/bin/check-saml-cert.sh <<'EOF'
#!/bin/bash
CERT="/secure/saml/certs/saml_sp_cert.pem"
DAYS_WARNING=30

EXPIRY=$(openssl x509 -in "$CERT" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt $DAYS_WARNING ]; then
  echo "WARNING: SAML certificate expires in $DAYS_LEFT days!"
  # Send alert (customize for your environment)
  # mail -s "SAML Cert Expiry Warning" admin@company.com
  exit 1
fi

echo "OK: Certificate valid for $DAYS_LEFT days"
exit 0
EOF

chmod +x /usr/local/bin/check-saml-cert.sh

# Add to cron (daily check at 9 AM)
echo "0 9 * * * /usr/local/bin/check-saml-cert.sh" | crontab -
```

---

### 5. Metadata Not Loading

**Symptoms:**
```
Error fetching metadata from URL
Cannot parse metadata XML
```

**Diagnosis:**

```bash
# Test metadata URL directly
curl -v https://instance.zitadel.cloud/saml/v2/metadata

# Check DNS resolution
nslookup instance.zitadel.cloud

# Test from container
docker exec supabase-auth curl -v https://instance.zitadel.cloud/saml/v2/metadata

# Check network connectivity
docker exec supabase-auth ping -c 3 instance.zitadel.cloud
```

**Resolution:**

**Option 1: Network Issue**

```bash
# Check firewall rules
iptables -L -n | grep -i zitadel

# Check Docker network
docker network inspect supabase_default

# Verify DNS in container
docker exec supabase-auth cat /etc/resolv.conf

# Test with different DNS
docker exec supabase-auth sh -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
```

**Option 2: Use Metadata XML Directly**

```bash
# Fetch metadata externally
curl https://instance.zitadel.cloud/saml/v2/metadata > /tmp/zitadel-metadata.xml

# Validate XML
xmllint --format /tmp/zitadel-metadata.xml

# Create provider with metadata_xml instead of metadata_url
cat > /tmp/provider.json <<EOF
{
  "type": "saml",
  "domains": ["example.com"],
  "metadata_xml": "$(cat /tmp/zitadel-metadata.xml | sed 's/"/\\"/g' | tr -d '\n')",
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName"
    }
  }
}
EOF

curl -X POST "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d @/tmp/provider.json
```

**Root Causes:**
- Network/firewall blocking ZITADEL
- DNS resolution failure
- SSL/TLS certificate validation issues
- Proxy configuration problems

**Prevention:**
- Use metadata XML for air-gapped environments
- Configure network allowlists
- Regular connectivity tests

---

## Service Health Checks

### Database Health

```bash
# Check database is running
docker exec supabase-db pg_isready

# Check auth schema tables
docker exec supabase-db psql -U postgres -d postgres -c "\dt auth.*"

# Check SAML provider count
docker exec supabase-db psql -U postgres -d postgres \
  -c "SELECT COUNT(*) FROM auth.saml_providers;"

# Check recent authentications
docker exec supabase-db psql -U postgres -d postgres \
  -c "SELECT created_at, email FROM auth.users ORDER BY created_at DESC LIMIT 10;"

# Check for errors in logs
docker logs supabase-db 2>&1 | grep -i error | tail -20
```

### Auth Service Health

```bash
# Check service is running
docker ps | grep supabase-auth

# Check service logs
docker logs supabase-auth --tail=100

# Check environment configuration
docker exec supabase-auth env | grep -E "GOTRUE_|SAML"

# Test metadata endpoint
curl -s http://localhost:8000/auth/v1/sso/saml/metadata | xmllint --format - | head -20

# Check service resource usage
docker stats supabase-auth --no-stream
```

### Kong Gateway Health

```bash
# Check Kong is running
docker ps | grep kong

# Check Kong routes
curl -s http://localhost:8001/routes | jq '.data[] | select(.paths[] | contains("saml"))'

# Check Kong services
curl -s http://localhost:8001/services | jq '.data[] | select(.name=="auth")'

# Test through Kong
curl -v http://localhost:8000/auth/v1/health

# Check Kong logs
docker logs supabase-kong --tail=100
```

---

## Log Analysis

### Finding SAML Events

```bash
# Recent SAML authentication attempts
docker logs supabase-auth 2>&1 | grep -i saml | tail -50

# Failed authentications
docker logs supabase-auth 2>&1 | grep -i "saml.*error\|saml.*failed" | tail -20

# Successful logins
docker logs supabase-auth 2>&1 | grep -i "saml.*success\|user created" | tail -20

# Certificate validation errors
docker logs supabase-auth 2>&1 | grep -i "certificate\|signature" | tail -20
```

### Log Patterns to Watch

**Normal Flow:**
```
INFO: SAML authentication initiated for domain: example.com
INFO: Redirecting to IdP: https://instance.zitadel.cloud/saml/v2/SSO
INFO: SAML response received from IdP
INFO: SAML assertion validated successfully
INFO: User created/updated: user@example.com
INFO: Session created for user: uuid
```

**Signature Error:**
```
ERROR: SAML response signature verification failed
ERROR: Certificate mismatch or expired
```

**Attribute Error:**
```
ERROR: Required attribute 'email' not found in SAML assertion
ERROR: Invalid attribute mapping configuration
```

**Network Error:**
```
ERROR: Failed to fetch metadata from https://...
ERROR: Connection timeout
ERROR: DNS resolution failed
```

### Enabling Debug Logging

```bash
# Edit docker-compose.yml or .env
GOTRUE_LOG_LEVEL=debug

# Restart service
docker restart supabase-auth

# Watch logs in real-time
docker logs -f supabase-auth

# Remember to disable debug logging in production after troubleshooting
```

---

## Certificate Issues

### Certificate Validation

```bash
# Validate SP certificate
openssl x509 -in /secure/saml/certs/saml_sp_cert.pem -text -noout

# Check key matches certificate
openssl x509 -noout -modulus -in /secure/saml/certs/saml_sp_cert.pem | openssl md5
openssl rsa -noout -modulus -in /secure/saml/certs/saml_sp_private.key | openssl md5
# Hashes should match

# Verify certificate chain
openssl verify /secure/saml/certs/saml_sp_cert.pem

# Check IdP certificate
curl -s https://instance.zitadel.cloud/saml/v2/metadata | \
  grep -o '<X509Certificate>.*</X509Certificate>' | \
  sed 's/<[^>]*>//g' | \
  base64 -d | \
  openssl x509 -text -noout
```

### Certificate Rotation Procedure

```bash
#!/bin/bash
# rotate-saml-cert.sh - Zero-downtime certificate rotation

set -e

CERT_DIR="/secure/saml/certs"
BACKUP_DIR="$CERT_DIR/backups/$(date +%Y%m%d_%H%M%S)"

echo "=== SAML Certificate Rotation ==="

# 1. Backup existing certificates
echo "1. Creating backup..."
mkdir -p "$BACKUP_DIR"
cp "$CERT_DIR/saml_sp_cert.pem" "$BACKUP_DIR/"
cp "$CERT_DIR/saml_sp_private.key" "$BACKUP_DIR/"
echo "Backup created: $BACKUP_DIR"

# 2. Generate new certificates
echo "2. Generating new certificates..."
openssl genrsa -out "$CERT_DIR/saml_sp_private_new.key" 2048
openssl req -new -x509 -key "$CERT_DIR/saml_sp_private_new.key" \
  -out "$CERT_DIR/saml_sp_cert_new.pem" -days 3650 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"

# 3. Validate new certificates
echo "3. Validating new certificates..."
openssl x509 -in "$CERT_DIR/saml_sp_cert_new.pem" -text -noout > /dev/null
echo "Certificates valid"

# 4. Update configuration
echo "4. Updating configuration..."
NEW_KEY_BASE64=$(cat "$CERT_DIR/saml_sp_private_new.key" | base64 -w 0)
sed -i.bak "s/^SAML_SP_PRIVATE_KEY=.*/SAML_SP_PRIVATE_KEY=${NEW_KEY_BASE64}/" .env

# 5. Replace certificates
mv "$CERT_DIR/saml_sp_cert_new.pem" "$CERT_DIR/saml_sp_cert.pem"
mv "$CERT_DIR/saml_sp_private_new.key" "$CERT_DIR/saml_sp_private.key"
chmod 644 "$CERT_DIR/saml_sp_cert.pem"
chmod 600 "$CERT_DIR/saml_sp_private.key"

# 6. Restart services
echo "5. Restarting auth service..."
docker restart supabase-auth
sleep 15

# 7. Verify
echo "6. Verifying configuration..."
curl -s http://localhost:8000/auth/v1/sso/saml/metadata > /tmp/new-metadata.xml
if [ $? -eq 0 ]; then
  echo "✓ Metadata endpoint accessible"
else
  echo "✗ Metadata endpoint failed"
  echo "Rolling back..."
  cp "$BACKUP_DIR/saml_sp_cert.pem" "$CERT_DIR/"
  cp "$BACKUP_DIR/saml_sp_private.key" "$CERT_DIR/"
  docker restart supabase-auth
  exit 1
fi

echo
echo "=== Certificate Rotation Complete ==="
echo "New SP metadata: /tmp/new-metadata.xml"
echo "Update ZITADEL with new metadata"
echo "Backup location: $BACKUP_DIR"
```

---

## Network & Connectivity

### Testing Connectivity

```bash
# Test from host to Supabase
curl -v http://localhost:8000/auth/v1/health

# Test from container to ZITADEL
docker exec supabase-auth curl -v https://instance.zitadel.cloud/saml/v2/metadata

# Check DNS resolution
docker exec supabase-auth nslookup instance.zitadel.cloud

# Test SSL/TLS
docker exec supabase-auth openssl s_client -connect instance.zitadel.cloud:443 -servername instance.zitadel.cloud
```

### Firewall Configuration

```bash
# Allow outbound to ZITADEL
iptables -A OUTPUT -d <zitadel-ip> -p tcp --dport 443 -j ACCEPT

# Allow inbound to Kong
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### Proxy Configuration

```yaml
# docker-compose.yml - if using HTTP proxy
services:
  auth:
    environment:
      HTTP_PROXY: "http://proxy.company.com:8080"
      HTTPS_PROXY: "http://proxy.company.com:8080"
      NO_PROXY: "localhost,127.0.0.1,db,kong"
```

---

## Database Issues

### Provider Configuration

```sql
-- View all SAML providers
SELECT 
  id,
  created_at,
  domains,
  idp_entity_id,
  idp_sso_url
FROM auth.saml_providers;

-- Check attribute mapping
SELECT 
  id,
  domains,
  attribute_mapping
FROM auth.saml_providers;

-- View recent SAML authentications
SELECT 
  u.id,
  u.email,
  u.created_at,
  u.raw_user_meta_data
FROM auth.users u
WHERE u.created_at > NOW() - INTERVAL '1 day'
ORDER BY u.created_at DESC;

-- Check relay states (troubleshooting redirects)
SELECT *
FROM auth.saml_relay_states
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

### Database Maintenance

```bash
# Vacuum SAML tables
docker exec supabase-db psql -U postgres -d postgres -c "VACUUM ANALYZE auth.saml_providers;"
docker exec supabase-db psql -U postgres -d postgres -c "VACUUM ANALYZE auth.saml_relay_states;"

# Check table sizes
docker exec supabase-db psql -U postgres -d postgres -c "
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'auth'
  AND tablename LIKE 'saml%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"

# Clean old relay states (> 24 hours)
docker exec supabase-db psql -U postgres -d postgres -c "
DELETE FROM auth.saml_relay_states 
WHERE created_at < NOW() - INTERVAL '24 hours';"
```

---

## Emergency Procedures

### Complete Service Restart

```bash
#!/bin/bash
# emergency-restart.sh

echo "=== Emergency SAML Service Restart ==="

# 1. Health check before
echo "1. Health check before restart..."
curl -s http://localhost:8000/auth/v1/sso/saml/metadata > /dev/null
BEFORE=$?

# 2. Stop services
echo "2. Stopping services..."
docker-compose stop auth kong

# 3. Wait for clean shutdown
sleep 5

# 4. Start services
echo "3. Starting services..."
docker-compose start kong
sleep 5
docker-compose start auth
sleep 10

# 5. Verify
echo "4. Verifying services..."
curl -s http://localhost:8000/auth/v1/sso/saml/metadata > /dev/null
AFTER=$?

if [ $AFTER -eq 0 ]; then
  echo "✓ Services restored"
else
  echo "✗ Services still failing"
  echo "Check logs: docker logs supabase-auth"
  exit 1
fi

echo "=== Restart Complete ==="
```

### Rollback Procedure

```bash
#!/bin/bash
# rollback-saml-config.sh

echo "=== Rolling Back SAML Configuration ==="

# 1. Restore database backup
echo "1. Restoring database..."
docker exec -i supabase-db psql -U postgres postgres < /backups/saml-config-backup-YYYYMMDD.sql

# 2. Restore certificates
echo "2. Restoring certificates..."
cp /backups/saml_sp_cert.pem /secure/saml/certs/
cp /backups/saml_sp_private.key /secure/saml/certs/

# 3. Restore environment
echo "3. Restoring environment..."
cp /backups/.env.backup .env

# 4. Restart services
echo "4. Restarting services..."
docker-compose restart auth

# 5. Verify
sleep 10
curl -s http://localhost:8000/auth/v1/sso/saml/metadata > /dev/null
if [ $? -eq 0 ]; then
  echo "✓ Rollback successful"
else
  echo "✗ Rollback failed - manual intervention required"
fi
```

### Disable SAML Temporarily

```bash
# Quick disable without removing configuration
docker exec supabase-auth sh -c "export GOTRUE_SAML_ENABLED=false"
docker restart supabase-auth

# Users will see normal login form
# SAML providers remain in database

# Re-enable
docker exec supabase-auth sh -c "export GOTRUE_SAML_ENABLED=true"
docker restart supabase-auth
```

---

## Monitoring & Alerting

### Metrics to Monitor

```bash
# SAML authentication rate
docker exec supabase-db psql -U postgres -d postgres -c "
SELECT 
  DATE_TRUNC('hour', created_at) as hour,
  COUNT(*) as saml_logins
FROM auth.users
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;"

# Failed authentication rate
docker logs supabase-auth 2>&1 | grep -i "saml.*error" | wc -l

# Certificate expiry days
openssl x509 -in /secure/saml/certs/saml_sp_cert.pem -noout -enddate | \
  cut -d= -f2 | xargs -I {} date -d "{}" +%s | \
  xargs -I {} echo "({} - $(date +%s)) / 86400" | bc
```

### Alerting Rules

```yaml
# Example Prometheus alerting rules
groups:
  - name: saml_alerts
    rules:
      - alert: SAMLMetadataDown
        expr: probe_success{job="saml_metadata"} == 0
        for: 5m
        annotations:
          summary: "SAML metadata endpoint is down"
          
      - alert: SAMLCertificateExpiringSoon
        expr: saml_cert_expiry_days < 30
        annotations:
          summary: "SAML certificate expires in {{ $value }} days"
          
      - alert: HighSAMLFailureRate
        expr: rate(saml_auth_failures_total[5m]) > 0.1
        annotations:
          summary: "High SAML authentication failure rate"
```

---

## Contact Information

**For Emergencies:**
- On-call Engineer: [Your contact method]
- Escalation: [Manager/Director contact]

**External Support:**
- ZITADEL Support: https://zitadel.com/support
- Supabase Community: https://github.com/supabase/supabase/discussions

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-01-01  
**Maintained By**: DevOps Team
