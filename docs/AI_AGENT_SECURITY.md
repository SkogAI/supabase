# AI Agent Security Best Practices

## Overview

This document provides comprehensive security guidelines for AI agents accessing Supabase databases through MCP (Model Context Protocol) servers. Proper security implementation ensures that AI agents have appropriate access levels while maintaining data integrity and compliance.

## Table of Contents

- [Authentication Methods](#authentication-methods)
- [Database Roles and Permissions](#database-roles-and-permissions)
- [Credential Management](#credential-management)
- [Connection String Security](#connection-string-security)
- [Audit Logging](#audit-logging)
- [Rate Limiting](#rate-limiting)
- [Network Security](#network-security)
- [Best Practices](#best-practices)
- [Security Checklist](#security-checklist)

## Authentication Methods

### 1. Database User Credentials (Recommended for Production)

Create dedicated database users with specific roles for different AI agent types.

**Advantages:**
- Granular permission control
- Resource limits per role
- Easy credential rotation
- Clear audit trail

**Setup:**

```sql
-- Create a user for the readonly agent
CREATE USER ai_readonly_user WITH PASSWORD 'secure_password_here';
GRANT ai_agent_readonly TO ai_readonly_user;

-- Create a user for the readwrite agent
CREATE USER ai_readwrite_user WITH PASSWORD 'secure_password_here';
GRANT ai_agent_readwrite TO ai_readwrite_user;

-- Create a user for the analytics agent
CREATE USER ai_analytics_user WITH PASSWORD 'secure_password_here';
GRANT ai_agent_analytics TO ai_analytics_user;
```

**Connection String:**
```bash
postgresql://ai_readonly_user:secure_password@db.project-ref.supabase.co:5432/postgres
```

### 2. API Key Authentication

Use API keys for external AI agents with rate limiting and tracking.

**Advantages:**
- Easy to rotate
- Built-in rate limiting
- Usage tracking
- Can be scoped to specific operations

**Setup:**

```sql
-- Generate API key
SELECT public.generate_api_key();

-- Create API key record
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
) VALUES (
  'sk_ai_generated_key_here',  -- Plain text (will be cleared after first use)
  encode(digest('sk_ai_generated_key_here', 'sha256'), 'hex'),  -- Hashed for storage
  'Customer Support Bot',
  'chatbot',
  'ai_agent_readonly',
  '{"read": true, "write": false}'::jsonb,
  100,  -- 100 requests per minute
  NOW() + INTERVAL '90 days',  -- Expires in 90 days
  auth.uid()
);
```

**Validation:**

```sql
-- Validate API key
SELECT * FROM public.validate_api_key('sk_ai_generated_key_here');
```

### 3. Service Role (Use with Extreme Caution)

Service role bypasses RLS and has full database access. **Only use for trusted, server-side agents.**

**Use Cases:**
- Administrative operations
- Trusted internal tools
- Backend automation

**⚠️ Security Requirements:**
- Never expose to client-side code
- Store only in secure environment variables
- Rotate quarterly
- Enable comprehensive audit logging
- Restrict network access with IP allowlisting

## Database Roles and Permissions

### ai_agent_readonly

**Purpose:** Read-only access for AI agents that query data without modifications.

**Permissions:**
- `SELECT` on all tables in `public` schema
- `CONNECT` to database
- `USAGE` on `public` schema

**Resource Limits:**
- Statement timeout: 30 seconds
- Work memory: 64MB
- Idle transaction timeout: 60 seconds

**Use Cases:**
- Chatbots answering questions
- Analytics viewers
- Content recommendation engines
- Search assistants

**Example Agents:**
- Customer support chatbot
- Product recommendation AI
- FAQ assistant

### ai_agent_readwrite

**Purpose:** Read and write access for AI agents that create or modify data.

**Permissions:**
- `SELECT`, `INSERT`, `UPDATE` on all tables in `public` schema
- `CONNECT` to database
- `USAGE` on `public` schema
- **No DELETE** permission (must be granted explicitly if needed)

**Resource Limits:**
- Statement timeout: 45 seconds
- Work memory: 128MB
- Idle transaction timeout: 90 seconds

**Use Cases:**
- Content generation
- Data enrichment
- Form processing
- Document creation

**Example Agents:**
- Blog post generator
- Email drafter
- Data entry automation
- Translation service

### ai_agent_analytics

**Purpose:** Analytics and reporting access with ability to create materialized views.

**Permissions:**
- `SELECT` on all tables in `public` schema
- `CREATE` on `public` schema (for materialized views)
- `CONNECT` to database
- `USAGE` on `public` schema

**Resource Limits:**
- Statement timeout: 120 seconds (longer for complex analytics)
- Work memory: 256MB (higher for aggregations)
- Idle transaction timeout: 120 seconds

**Use Cases:**
- Business intelligence
- Data science analysis
- Report generation
- Metrics calculation

**Example Agents:**
- BI dashboard generator
- Trend analyzer
- Performance metrics calculator

## Credential Management

### Environment Variables (Required)

**Never commit credentials to version control.** Always use environment variables or secret management systems.

#### Development (.env file)

```bash
# Read-only agent
SUPABASE_AI_AGENT_READONLY_CONNECTION=postgresql://ai_readonly_user:dev_password@localhost:54322/postgres

# Read-write agent
SUPABASE_AI_AGENT_READWRITE_CONNECTION=postgresql://ai_readwrite_user:dev_password@localhost:54322/postgres

# Analytics agent
SUPABASE_AI_AGENT_ANALYTICS_CONNECTION=postgresql://ai_analytics_user:dev_password@localhost:54322/postgres
```

#### Production (Secret Management)

**Use secure secret management:**
- AWS Secrets Manager
- HashiCorp Vault
- Kubernetes Secrets
- Cloud provider secret stores

**Example with Environment Variables:**

```bash
# Set in production environment (not in code)
export SUPABASE_AI_AGENT_READONLY_CONNECTION="postgresql://ai_readonly_user:prod_secure_password@db.project-ref.supabase.co:5432/postgres"
export SUPABASE_AI_AGENT_READWRITE_CONNECTION="postgresql://ai_readwrite_user:prod_secure_password@db.project-ref.supabase.co:5432/postgres"
export SUPABASE_AI_AGENT_ANALYTICS_CONNECTION="postgresql://ai_analytics_user:prod_secure_password@db.project-ref.supabase.co:5432/postgres"
```

### Password Requirements

**Minimum Requirements:**
- 32 characters minimum
- Mix of uppercase, lowercase, numbers, and symbols
- No dictionary words
- Unique per environment
- Generated using cryptographically secure random generator

**Generation:**

```bash
# Generate secure password (32 characters)
openssl rand -base64 32

# Generate even stronger password (64 characters)
openssl rand -base64 64
```

### Storage Best Practices

✅ **DO:**
- Store in environment variables
- Use secret management systems
- Encrypt at rest and in transit
- Restrict access to credentials
- Audit access to secrets
- Use separate credentials per environment

❌ **DON'T:**
- Commit to git
- Store in plain text files
- Share across environments
- Email or message credentials
- Log credentials
- Hardcode in application code

## Connection String Security

### Secure Connection String Format

Always use SSL/TLS encrypted connections:

```bash
# With SSL enforcement
postgresql://username:password@host:5432/postgres?sslmode=require

# With connection pooling (Supavisor)
postgresql://username:password@db.project-ref.supabase.co:6543/postgres?sslmode=require&pgbouncer=true
```

### SSL/TLS Configuration

**Required settings:**
- `sslmode=require` - Minimum requirement
- `sslmode=verify-ca` - Verify server certificate (recommended)
- `sslmode=verify-full` - Verify certificate and hostname (most secure)

**Example:**

```typescript
// MCP Server Configuration with SSL
const config = {
  database: {
    connectionString: process.env.SUPABASE_AI_AGENT_READONLY_CONNECTION,
    ssl: {
      rejectUnauthorized: true,
      ca: process.env.SUPABASE_SSL_CERT // Optional: custom CA certificate
    }
  }
};
```

### Connection Pooling

Use Supavisor for connection pooling with AI agents:

**Transaction Mode (Recommended for AI agents):**
- Port: 6543
- Best for: Serverless AI agents, short-lived connections
- Automatic connection cleanup

```bash
postgresql://username:password@db.project-ref.supabase.co:6543/postgres?sslmode=require
```

**Session Mode (For persistent agents):**
- Port: 5432
- Best for: Long-running AI agents with persistent connections
- Maintains session state

```bash
postgresql://username:password@db.project-ref.supabase.co:5432/postgres?sslmode=require
```

## Audit Logging

### Enable Audit Logging

All authentication attempts and queries by AI agents are logged automatically when using the provided functions.

### Log Authentication Attempts

```sql
-- Log successful authentication
SELECT public.log_auth_attempt(
  agent_id := 'chatbot_001',
  method := 'database_credentials',
  success := true,
  ip := '192.168.1.100'::inet,
  user_agent_str := 'MCP Server v1.0',
  meta := '{"connection_type": "transaction"}'::jsonb
);

-- Log failed authentication
SELECT public.log_auth_attempt(
  agent_id := 'chatbot_001',
  method := 'api_key',
  success := false,
  ip := '192.168.1.100'::inet,
  error := 'Invalid API key',
  meta := '{"attempts": 3}'::jsonb
);
```

### Log Query Execution

```sql
-- Log query execution
SELECT public.log_mcp_query(
  agent_id := 'chatbot_001',
  agent_role := 'ai_agent_readonly',
  operation := 'SELECT',
  query_text := 'SELECT * FROM profiles WHERE username = $1',
  exec_time_ms := 45,
  rows := 1,
  ip := '192.168.1.100'::inet,
  meta := '{"table": "profiles"}'::jsonb
);
```

### Monitor Audit Logs

```sql
-- View recent authentication attempts
SELECT * FROM public.recent_auth_attempts;

-- View failed authentication attempts
SELECT * 
FROM public.auth_audit_log 
WHERE success = false 
  AND timestamp > NOW() - INTERVAL '1 hour'
ORDER BY timestamp DESC;

-- View query statistics by agent
SELECT * FROM public.mcp_query_stats;

-- View slow queries
SELECT * 
FROM public.mcp_query_audit_log 
WHERE execution_time_ms > 1000 
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY execution_time_ms DESC;
```

### Audit Log Retention

Configure retention policies based on compliance requirements:

```sql
-- Delete audit logs older than 90 days (example)
DELETE FROM public.auth_audit_log 
WHERE created_at < NOW() - INTERVAL '90 days';

DELETE FROM public.mcp_query_audit_log 
WHERE created_at < NOW() - INTERVAL '90 days';

-- Or archive to cold storage
INSERT INTO archive.auth_audit_log 
SELECT * FROM public.auth_audit_log 
WHERE created_at < NOW() - INTERVAL '90 days';
```

## Rate Limiting

### Database-Level Rate Limiting

Implemented through API key rate limits:

```sql
-- Set rate limit for API key
UPDATE public.ai_agent_api_keys 
SET rate_limit_per_minute = 100 
WHERE agent_name = 'Customer Support Bot';
```

### Connection-Level Rate Limiting

Limit connections per role:

```sql
-- Limit connections for readonly role
ALTER ROLE ai_agent_readonly CONNECTION LIMIT 10;

-- Limit connections for readwrite role
ALTER ROLE ai_agent_readwrite CONNECTION LIMIT 5;

-- Limit connections for analytics role
ALTER ROLE ai_agent_analytics CONNECTION LIMIT 3;
```

### Query Timeout Enforcement

Resource limits are already set per role. To modify:

```sql
-- Adjust statement timeout
ALTER ROLE ai_agent_readonly SET statement_timeout = '45s';

-- Adjust work memory
ALTER ROLE ai_agent_readonly SET work_mem = '128MB';
```

## Network Security

### IP Allowlisting

Configure IP allowlisting in Supabase Dashboard:

1. Go to Project Settings → Database
2. Enable "Restrict database access"
3. Add allowed IP addresses/ranges

**Example IP ranges:**
```
# Office network
203.0.113.0/24

# Cloud provider (AWS, GCP, Azure)
52.0.0.0/8

# Specific MCP server
198.51.100.42/32
```

### VPC/Private Network

For enhanced security, deploy MCP servers in a private network:

1. Use Supabase VPC peering (Enterprise feature)
2. Deploy MCP servers in same VPC
3. Configure private connection strings
4. Disable public database access

## Best Practices

### 1. Principle of Least Privilege

✅ **DO:**
- Grant only necessary permissions
- Use readonly role by default
- Upgrade to readwrite only when needed
- Review permissions regularly

❌ **DON'T:**
- Use service role for AI agents
- Grant DELETE permissions unless required
- Use superuser accounts
- Give same permissions to all agents

### 2. Credential Rotation

**Recommended rotation schedule:**
- **Production:** Every 30-90 days
- **Development:** Every 180 days
- **After security incident:** Immediately
- **When team member leaves:** Immediately

**See [CREDENTIAL_ROTATION.md](CREDENTIAL_ROTATION.md) for detailed procedures.**

### 3. Monitoring and Alerting

Set up alerts for:
- Failed authentication attempts (> 5 in 5 minutes)
- Slow queries (> 5 seconds)
- High error rates (> 10% of queries)
- Unusual query patterns
- Expired API keys still in use

### 4. Encryption

Ensure encryption at all layers:
- **In transit:** SSL/TLS for all connections (sslmode=require)
- **At rest:** Database encryption (Supabase default)
- **Application:** Encrypt sensitive data in application layer
- **Backups:** Encrypted backups (Supabase default)

### 5. Access Control

Implement proper access control:
- Use RLS policies for user-scoped data
- Separate AI agents by role
- Review access logs weekly
- Audit permissions quarterly

### 6. Incident Response

Prepare for security incidents:
1. Document incident response procedures
2. Have credential rotation scripts ready
3. Set up automated alerts
4. Maintain audit log backups
5. Test response procedures quarterly

## Security Checklist

### Initial Setup

- [ ] Create dedicated database roles (readonly, readwrite, analytics)
- [ ] Set resource limits on roles
- [ ] Create database users with strong passwords
- [ ] Store credentials in environment variables or secret manager
- [ ] Enable SSL/TLS for all connections
- [ ] Configure IP allowlisting
- [ ] Enable audit logging

### Regular Maintenance

- [ ] Rotate credentials every 30-90 days
- [ ] Review audit logs weekly
- [ ] Monitor for failed authentication attempts
- [ ] Check for slow queries
- [ ] Update API key expiration dates
- [ ] Review and update IP allowlist
- [ ] Test credential rotation procedures

### Incident Response

- [ ] Document security incident procedures
- [ ] Have emergency credential rotation ready
- [ ] Set up alerting for suspicious activity
- [ ] Maintain audit log backups
- [ ] Test incident response quarterly

### Compliance

- [ ] Document data access policies
- [ ] Implement data retention policies
- [ ] Set up audit log retention
- [ ] Review compliance requirements
- [ ] Conduct security audits

## Related Documentation

- [MCP Server Authentication](MCP_AUTHENTICATION.md) - Detailed authentication methods
- [MCP Server Architecture](MCP_SERVER_ARCHITECTURE.md) - Overall architecture
- [Credential Rotation](CREDENTIAL_ROTATION.md) - Credential rotation procedures
- [MCP Server Configuration](MCP_SERVER_CONFIGURATION.md) - Configuration templates

## References

- [Supabase Database Security](https://supabase.com/docs/guides/database/database-security)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
- [OWASP Database Security](https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html)
