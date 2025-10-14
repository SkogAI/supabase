# AI Agent Credential Rotation Workflow

## Overview

This document provides step-by-step procedures for rotating AI agent credentials safely and efficiently. Regular credential rotation is a critical security practice that minimizes the impact of credential compromise.

## Table of Contents

- [Rotation Schedule](#rotation-schedule)
- [Prerequisites](#prerequisites)
- [Rotation Procedures](#rotation-procedures)
  - [Database User Password Rotation](#database-user-password-rotation)
  - [API Key Rotation](#api-key-rotation)
  - [Service Role Key Rotation](#service-role-key-rotation)
- [Emergency Rotation](#emergency-rotation)
- [Automation](#automation)
- [Verification](#verification)
- [Rollback Procedures](#rollback-procedures)

## Rotation Schedule

### Recommended Rotation Intervals

| Credential Type | Production | Staging | Development | Emergency |
|----------------|------------|---------|-------------|-----------|
| Database Passwords | 30-90 days | 90 days | 180 days | Immediately |
| API Keys | 30-90 days | 90 days | 180 days | Immediately |
| Service Role Key | 90 days | 90 days | N/A | Immediately |

### Triggers for Immediate Rotation

Rotate credentials immediately if:
- Security breach detected
- Credentials exposed in logs or code
- Team member with access leaves
- Compromised MCP server
- Suspicious activity detected in audit logs
- Compliance requirement

## Prerequisites

Before starting credential rotation:

- [ ] **Backup access:** Ensure you have alternative admin access
- [ ] **Audit logs:** Review current audit logs for suspicious activity
- [ ] **Downtime window:** Plan for brief service interruption (if needed)
- [ ] **Communication:** Notify team members of planned rotation
- [ ] **Tools ready:** Have all necessary tools and scripts prepared
- [ ] **Rollback plan:** Document rollback procedure
- [ ] **Testing environment:** Test rotation in staging first

## Rotation Procedures

### Database User Password Rotation

#### Step 1: Generate New Password

```bash
# Generate cryptographically secure password (32 characters)
NEW_PASSWORD=$(openssl rand -base64 32)

# Save to secure location temporarily (use secret manager in production)
echo "New password for ai_readonly_user: $NEW_PASSWORD"
```

#### Step 2: Update Database Password

```sql
-- Connect as superuser (postgres role)
-- Change password for readonly agent user
ALTER USER ai_readonly_user WITH PASSWORD 'new_secure_password_here';

-- Change password for readwrite agent user
ALTER USER ai_readwrite_user WITH PASSWORD 'new_secure_password_here';

-- Change password for analytics agent user
ALTER USER ai_analytics_user WITH PASSWORD 'new_secure_password_here';
```

#### Step 3: Update Environment Variables

**Development:**
```bash
# Update .env file (local development only)
# DO NOT commit this file to git
SUPABASE_AI_AGENT_READONLY_CONNECTION=postgresql://ai_readonly_user:new_password@localhost:54322/postgres
```

**Production (using secret manager):**

```bash
# AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id supabase/ai-agent/readonly \
  --secret-string "postgresql://ai_readonly_user:new_password@db.project-ref.supabase.co:5432/postgres"

# Or using environment variables in deployment system
export SUPABASE_AI_AGENT_READONLY_CONNECTION="postgresql://ai_readonly_user:new_password@db.project-ref.supabase.co:5432/postgres"
```

#### Step 4: Deploy Updated Credentials

```bash
# Restart MCP servers with new credentials
# Method varies by deployment platform

# Kubernetes
kubectl rollout restart deployment mcp-server-readonly
kubectl rollout restart deployment mcp-server-readwrite
kubectl rollout restart deployment mcp-server-analytics

# Docker
docker-compose restart mcp-server

# Systemd
sudo systemctl restart mcp-server

# Cloud provider specific commands
# AWS ECS: Update task definition and restart service
# GCP Cloud Run: Deploy new revision
# Azure Container Instances: Update container
```

#### Step 5: Verify Connectivity

```bash
# Test connection with new credentials
psql "postgresql://ai_readonly_user:new_password@db.project-ref.supabase.co:5432/postgres" \
  -c "SELECT current_user, current_database();"

# Expected output:
#  current_user    | current_database
# -----------------+------------------
#  ai_readonly_user | postgres
```

#### Step 6: Monitor Audit Logs

```sql
-- Check for successful authentication with new credentials
SELECT * 
FROM public.auth_audit_log 
WHERE agent_identifier LIKE '%readonly%'
  AND timestamp > NOW() - INTERVAL '10 minutes'
ORDER BY timestamp DESC
LIMIT 10;

-- Verify no failed authentication attempts
SELECT COUNT(*) as failed_attempts
FROM public.auth_audit_log 
WHERE success = false
  AND timestamp > NOW() - INTERVAL '10 minutes';
```

#### Step 7: Clean Up

```bash
# Remove temporary password from memory/files
unset NEW_PASSWORD

# Clear shell history (optional)
history -c

# Verify old credentials no longer work (optional)
# psql "postgresql://ai_readonly_user:old_password@..." -c "SELECT 1;"
# Expected: authentication failed
```

### API Key Rotation

#### Step 1: Generate New API Key

```sql
-- Generate new API key
SELECT public.generate_api_key() as new_api_key;

-- Example output: sk_ai_AbCdEf123456...
```

#### Step 2: Create New API Key Record

```sql
-- Create new API key with same permissions as old key
INSERT INTO public.ai_agent_api_keys (
  key,
  key_hash,
  agent_name,
  agent_type,
  agent_role,
  permissions,
  rate_limit_per_minute,
  expires_at,
  created_by
)
SELECT 
  'sk_ai_AbCdEf123456...',  -- New API key
  encode(digest('sk_ai_AbCdEf123456...', 'sha256'), 'hex'),
  agent_name,
  agent_type,
  agent_role,
  permissions,
  rate_limit_per_minute,
  NOW() + INTERVAL '90 days',
  created_by
FROM public.ai_agent_api_keys
WHERE key_hash = encode(digest('sk_ai_old_key...', 'sha256'), 'hex');
```

#### Step 3: Update API Key in Applications

```bash
# Update environment variable
export SUPABASE_AI_AGENT_API_KEY="sk_ai_AbCdEf123456..."

# Or update in secret manager
aws secretsmanager update-secret \
  --secret-id supabase/ai-agent/api-key \
  --secret-string "sk_ai_AbCdEf123456..."
```

#### Step 4: Deploy Updated API Key

```bash
# Restart services with new API key
kubectl rollout restart deployment mcp-server-api
```

#### Step 5: Verify New API Key Works

```sql
-- Test validation of new API key
SELECT * FROM public.validate_api_key('sk_ai_AbCdEf123456...');

-- Expected output:
--  valid | agent_name          | agent_type | agent_role          | ...
-- -------+---------------------+------------+---------------------+
--  true  | Customer Support Bot| chatbot    | ai_agent_readonly   | ...
```

#### Step 6: Monitor Usage

```sql
-- Check that new API key is being used
SELECT * 
FROM public.ai_agent_api_keys 
WHERE key_hash = encode(digest('sk_ai_AbCdEf123456...', 'sha256'), 'hex');

-- Verify last_used_at is recent
```

#### Step 7: Deactivate Old API Key

```sql
-- Wait 24-48 hours to ensure all services updated
-- Then deactivate old API key
UPDATE public.ai_agent_api_keys
SET is_active = false
WHERE key_hash = encode(digest('sk_ai_old_key...', 'sha256'), 'hex');

-- Optionally delete after retention period
-- DELETE FROM public.ai_agent_api_keys
-- WHERE key_hash = encode(digest('sk_ai_old_key...', 'sha256'), 'hex')
--   AND is_active = false
--   AND created_at < NOW() - INTERVAL '90 days';
```

### Service Role Key Rotation

⚠️ **Warning:** Service role key rotation is more complex and requires careful coordination.

#### Step 1: Generate New Service Role Key

1. Go to Supabase Dashboard
2. Navigate to Settings → API
3. Click "Reset Service Role Key"
4. Confirm action
5. Copy new service role key immediately

#### Step 2: Update in Secret Manager

```bash
# Update service role key in secret manager
aws secretsmanager update-secret \
  --secret-id supabase/service-role-key \
  --secret-string "new_service_role_key_here"

# Or update environment variable
export SUPABASE_SERVICE_ROLE_KEY="new_service_role_key_here"
```

#### Step 3: Deploy to All Services

```bash
# Update all services that use service role
# This may include multiple deployments

# MCP servers
kubectl rollout restart deployment mcp-server-admin

# Backend services
kubectl rollout restart deployment api-server

# Scheduled jobs
kubectl rollout restart deployment background-worker
```

#### Step 4: Verify All Services Updated

```bash
# Check deployment status
kubectl get deployments

# Check pod logs for successful connections
kubectl logs -l app=mcp-server-admin --tail=50

# Verify no authentication errors
```

#### Step 5: Monitor for Issues

```sql
-- Check for authentication failures
SELECT * 
FROM public.auth_audit_log 
WHERE auth_method = 'service_role'
  AND success = false
  AND timestamp > NOW() - INTERVAL '1 hour'
ORDER BY timestamp DESC;
```

## Emergency Rotation

### Immediate Actions (< 5 minutes)

When credentials are compromised:

1. **Revoke access immediately:**
   ```sql
   -- Disable all AI agent users
   ALTER USER ai_readonly_user WITH NOLOGIN;
   ALTER USER ai_readwrite_user WITH NOLOGIN;
   ALTER USER ai_analytics_user WITH NOLOGIN;
   
   -- Deactivate all API keys
   UPDATE public.ai_agent_api_keys SET is_active = false;
   ```

2. **Notify team:**
   - Send alert to security team
   - Notify stakeholders of service disruption
   - Document time of compromise discovery

3. **Review audit logs:**
   ```sql
   -- Check for suspicious activity
   SELECT * 
   FROM public.mcp_query_audit_log 
   WHERE created_at > NOW() - INTERVAL '24 hours'
   ORDER BY created_at DESC;
   
   -- Check authentication attempts
   SELECT * 
   FROM public.auth_audit_log 
   WHERE timestamp > NOW() - INTERVAL '24 hours'
   ORDER BY timestamp DESC;
   ```

### Short-Term Actions (< 1 hour)

4. **Generate new credentials:**
   ```bash
   # Generate new passwords
   NEW_READONLY_PASSWORD=$(openssl rand -base64 32)
   NEW_READWRITE_PASSWORD=$(openssl rand -base64 32)
   NEW_ANALYTICS_PASSWORD=$(openssl rand -base64 32)
   ```

5. **Update database passwords:**
   ```sql
   -- Update passwords
   ALTER USER ai_readonly_user WITH PASSWORD 'new_password' LOGIN;
   ALTER USER ai_readwrite_user WITH PASSWORD 'new_password' LOGIN;
   ALTER USER ai_analytics_user WITH PASSWORD 'new_password' LOGIN;
   ```

6. **Deploy new credentials:**
   ```bash
   # Update secret manager
   aws secretsmanager update-secret \
     --secret-id supabase/ai-agent/readonly \
     --secret-string "postgresql://ai_readonly_user:${NEW_READONLY_PASSWORD}@..."
   
   # Restart services
   kubectl rollout restart deployment -l app=mcp-server
   ```

### Post-Incident Actions (< 24 hours)

7. **Conduct security review:**
   - Analyze how credentials were compromised
   - Review access controls
   - Update security procedures
   - Document lessons learned

8. **Update monitoring:**
   - Add alerts for similar patterns
   - Improve audit logging
   - Strengthen access controls

## Automation

### Automated Rotation Script

```bash
#!/bin/bash
# rotate_ai_agent_credentials.sh
# Automates credential rotation for AI agents

set -e

# Configuration
ENVIRONMENT=${1:-staging}
SECRET_MANAGER=${2:-aws}
AGENT_USER=${3:-ai_readonly_user}

echo "Starting credential rotation for ${AGENT_USER} in ${ENVIRONMENT}"

# Step 1: Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)
echo "✓ Generated new password"

# Step 2: Update database
psql "${DATABASE_URL}" -c "ALTER USER ${AGENT_USER} WITH PASSWORD '${NEW_PASSWORD}';"
echo "✓ Updated database password"

# Step 3: Update secret manager
case ${SECRET_MANAGER} in
  aws)
    aws secretsmanager update-secret \
      --secret-id "supabase/ai-agent/${AGENT_USER}" \
      --secret-string "postgresql://${AGENT_USER}:${NEW_PASSWORD}@${DB_HOST}:5432/postgres"
    ;;
  gcp)
    echo -n "postgresql://${AGENT_USER}:${NEW_PASSWORD}@${DB_HOST}:5432/postgres" | \
      gcloud secrets versions add "supabase-ai-agent-${AGENT_USER}" --data-file=-
    ;;
esac
echo "✓ Updated secret manager"

# Step 4: Restart services
kubectl rollout restart deployment mcp-server-${AGENT_USER%-user} -n ${ENVIRONMENT}
echo "✓ Restarted services"

# Step 5: Verify
sleep 10
kubectl rollout status deployment mcp-server-${AGENT_USER%-user} -n ${ENVIRONMENT}
echo "✓ Verified deployment"

# Step 6: Clean up
unset NEW_PASSWORD
echo "✓ Cleaned up temporary credentials"

echo "Credential rotation completed successfully for ${AGENT_USER}"
```

### Schedule Automated Rotation

```yaml
# Kubernetes CronJob for automated rotation
apiVersion: batch/v1
kind: CronJob
metadata:
  name: rotate-ai-agent-credentials
spec:
  schedule: "0 2 1 * *"  # First day of month at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: credential-rotator
            image: credential-rotator:latest
            env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: database-admin-credentials
                  key: url
            command:
            - /bin/bash
            - -c
            - |
              ./rotate_ai_agent_credentials.sh production aws ai_readonly_user
              ./rotate_ai_agent_credentials.sh production aws ai_readwrite_user
              ./rotate_ai_agent_credentials.sh production aws ai_analytics_user
          restartPolicy: OnFailure
```

## Verification

### Post-Rotation Checklist

After completing rotation:

- [ ] New credentials tested successfully
- [ ] All services restarted with new credentials
- [ ] No authentication failures in audit logs
- [ ] Old credentials no longer work (if tested)
- [ ] Monitoring shows normal activity
- [ ] Documentation updated
- [ ] Team notified of completion
- [ ] Rotation logged in change management system

### Verification Queries

```sql
-- Verify AI agent connections are working
SELECT 
  agent_id,
  agent_role,
  COUNT(*) as query_count,
  MAX(created_at) as last_query
FROM public.mcp_query_audit_log
WHERE created_at > NOW() - INTERVAL '10 minutes'
GROUP BY agent_id, agent_role;

-- Check for authentication failures
SELECT COUNT(*) as failed_auth_count
FROM public.auth_audit_log
WHERE success = false
  AND timestamp > NOW() - INTERVAL '10 minutes';

-- Verify API keys are active and being used
SELECT 
  agent_name,
  is_active,
  last_used_at,
  created_at
FROM public.ai_agent_api_keys
WHERE is_active = true
ORDER BY last_used_at DESC NULLS LAST;
```

## Rollback Procedures

### When to Rollback

Rollback if:
- Services fail to connect with new credentials
- High error rate detected (> 50% failures)
- Critical functionality broken
- Cannot verify new credentials working

### Rollback Steps

#### Database Password Rollback

```sql
-- Restore old password (if known and stored securely)
ALTER USER ai_readonly_user WITH PASSWORD 'old_secure_password';
ALTER USER ai_readwrite_user WITH PASSWORD 'old_secure_password';
ALTER USER ai_analytics_user WITH PASSWORD 'old_secure_password';
```

#### API Key Rollback

```sql
-- Reactivate old API key
UPDATE public.ai_agent_api_keys
SET is_active = true
WHERE key_hash = encode(digest('sk_ai_old_key...', 'sha256'), 'hex');

-- Deactivate new API key
UPDATE public.ai_agent_api_keys
SET is_active = false
WHERE key_hash = encode(digest('sk_ai_new_key...', 'sha256'), 'hex');
```

#### Service Rollback

```bash
# Rollback to previous deployment
kubectl rollout undo deployment mcp-server-readonly
kubectl rollout undo deployment mcp-server-readwrite
kubectl rollout undo deployment mcp-server-analytics

# Verify rollback
kubectl rollout status deployment mcp-server-readonly
```

### Post-Rollback Actions

1. **Document failure:**
   - What went wrong
   - Why rollback was necessary
   - Lessons learned

2. **Fix issues:**
   - Identify root cause
   - Implement fixes
   - Test in staging

3. **Retry rotation:**
   - Schedule new rotation attempt
   - Apply lessons learned
   - Increase monitoring during retry

## Related Documentation

- [AI Agent Security](AI_AGENT_SECURITY.md) - Security best practices
- [MCP Authentication](MCP_AUTHENTICATION.md) - Authentication methods
- [MCP Server Configuration](MCP_SERVER_CONFIGURATION.md) - Configuration templates

## References

- [Supabase Dashboard - API Settings](https://app.supabase.com/project/_/settings/api)
- [PostgreSQL ALTER USER](https://www.postgresql.org/docs/current/sql-alteruser.html)
- [NIST Password Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)
