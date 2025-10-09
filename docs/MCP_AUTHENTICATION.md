# MCP Server Authentication Strategies

## Overview

This document outlines secure authentication strategies for AI agents connecting to Supabase databases through MCP servers. Proper authentication ensures that only authorized agents can access database resources while maintaining security and scalability.

## Authentication Methods

### 1. Service Role Key Authentication

**Best For:** Trusted server-side AI agents with full database access

#### Description

Service role keys bypass Row Level Security (RLS) and provide unrestricted access to all database resources. Use only in secure, server-side environments.

#### Configuration

```typescript
// MCP Server Configuration
{
  authentication: {
    method: "service_role",
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY
  }
}

// Usage Example
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// Full access - bypasses RLS
const { data, error } = await supabase
  .from('users')
  .select('*');
```

#### Security Requirements

✅ **DO:**
- Store service role key in environment variables
- Use only in backend/server environments
- Rotate keys regularly (quarterly recommended)
- Enable audit logging for all service role operations
- Restrict network access with IP allowlisting

❌ **DON'T:**
- Never expose service role key to client-side code
- Don't commit service role key to version control
- Don't share service role key across environments
- Don't use for user-facing applications

#### Connection String Format

```bash
# PostgreSQL connection with service role
DATABASE_URL=postgresql://postgres.project-ref:[service-role-password]@db.project-ref.supabase.co:5432/postgres
```

### 2. Database User Credentials

**Best For:** Dedicated AI agents with specific permission requirements

#### Description

Create dedicated database users with limited permissions for AI agents. This provides granular control over what each agent can access.

#### Setup

```sql
-- Create dedicated database user for AI agent
CREATE USER ai_agent_readonly WITH PASSWORD 'secure_password_here';

-- Grant specific permissions
GRANT CONNECT ON DATABASE postgres TO ai_agent_readonly;
GRANT USAGE ON SCHEMA public TO ai_agent_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ai_agent_readonly;

-- Set default permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO ai_agent_readonly;

-- Set resource limits
ALTER ROLE ai_agent_readonly SET statement_timeout = '30s';
ALTER ROLE ai_agent_readonly SET work_mem = '64MB';
ALTER ROLE ai_agent_readonly SET max_connections = 10;
```

#### Configuration

```typescript
// MCP Server Configuration
{
  authentication: {
    method: "database_credentials",
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD
  }
}

// Connection with dedicated user
const connectionString = `postgresql://${username}:${password}@host:5432/postgres`;
```

#### Permission Patterns

**Read-Only Agent:**
```sql
CREATE USER ai_agent_reader WITH PASSWORD 'password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ai_agent_reader;
```

**Read-Write Agent (Specific Tables):**
```sql
CREATE USER ai_agent_writer WITH PASSWORD 'password';
GRANT SELECT, INSERT, UPDATE ON TABLE documents TO ai_agent_writer;
GRANT SELECT ON TABLE users TO ai_agent_writer;
```

**Analytics Agent:**
```sql
CREATE USER ai_agent_analytics WITH PASSWORD 'password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ai_agent_analytics;
-- Allow materialized view refresh
GRANT CREATE ON SCHEMA public TO ai_agent_analytics;
```

### 3. JWT Token Authentication

**Best For:** User-context aware AI agents with RLS enforcement

#### Description

Use JSON Web Tokens (JWT) to authenticate AI agents on behalf of specific users. This enables Row Level Security (RLS) policies to apply, ensuring agents only access data users are authorized to see.

#### Setup

```typescript
// Generate JWT for AI agent acting on behalf of user
import jwt from 'jsonwebtoken';

function generateAgentJWT(userId: string, agentType: string) {
  const payload = {
    sub: userId,
    role: 'authenticated',
    agent_type: agentType,
    iss: 'supabase',
    aud: 'authenticated',
    exp: Math.floor(Date.now() / 1000) + (60 * 60), // 1 hour
  };
  
  return jwt.sign(payload, process.env.JWT_SECRET!);
}

// Use in MCP server
const token = generateAgentJWT(userId, 'ai_assistant');
```

#### Configuration

```typescript
// MCP Server Configuration
{
  authentication: {
    method: "jwt",
    jwtSecret: process.env.JWT_SECRET,
    jwtExpiry: 3600, // 1 hour
    jwtIssuer: "supabase",
    jwtAudience: "authenticated"
  }
}

// Supabase Client with JWT
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
  {
    global: {
      headers: {
        Authorization: `Bearer ${token}`
      }
    }
  }
);
```

#### RLS Policy Example

```sql
-- AI agents respect user-level RLS
CREATE POLICY "Users can view own documents"
    ON documents FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id
        OR auth.jwt() ->> 'agent_type' = 'ai_assistant'
    );

-- Restrict AI agents to published content only
CREATE POLICY "AI agents can view published content"
    ON articles FOR SELECT
    TO authenticated
    USING (
        published = true 
        OR (
            auth.uid() = author_id 
            AND auth.jwt() ->> 'agent_type' IS NULL
        )
    );
```

### 4. API Key Authentication

**Best For:** External AI agents with rate limiting requirements

#### Description

Issue API keys to external AI agents for controlled access with built-in rate limiting and usage tracking.

#### Setup

```sql
-- Create API keys table
CREATE TABLE api_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text UNIQUE NOT NULL,
  agent_name text NOT NULL,
  agent_type text NOT NULL,
  permissions jsonb DEFAULT '{"read": true, "write": false}'::jsonb,
  rate_limit_per_minute integer DEFAULT 60,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now(),
  last_used_at timestamptz,
  is_active boolean DEFAULT true
);

-- Enable RLS on API keys
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Service role can manage API keys
CREATE POLICY "Service role manages API keys"
    ON api_keys FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Generate API key
INSERT INTO api_keys (key, agent_name, agent_type, permissions)
VALUES (
  'sk_' || encode(gen_random_bytes(32), 'base64'),
  'Customer Support AI',
  'support_assistant',
  '{"read": true, "write": false, "tables": ["tickets", "customers"]}'::jsonb
);
```

#### Validation Function

```sql
-- Function to validate API key
CREATE OR REPLACE FUNCTION validate_api_key(api_key text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  key_record record;
BEGIN
  SELECT * INTO key_record
  FROM api_keys
  WHERE key = api_key
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > now());
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Invalid or expired API key');
  END IF;
  
  -- Update last used timestamp
  UPDATE api_keys 
  SET last_used_at = now() 
  WHERE id = key_record.id;
  
  RETURN jsonb_build_object(
    'valid', true,
    'agent_name', key_record.agent_name,
    'agent_type', key_record.agent_type,
    'permissions', key_record.permissions
  );
END;
$$;
```

#### Configuration

```typescript
// MCP Server Configuration
{
  authentication: {
    method: "api_key",
    validateFunction: "validate_api_key",
    headerName: "X-API-Key",
    rateLimit: {
      enabled: true,
      perKey: true
    }
  }
}

// Middleware for API key validation
async function validateApiKey(req: Request) {
  const apiKey = req.headers.get('X-API-Key');
  
  if (!apiKey) {
    throw new Error('API key required');
  }
  
  const { data, error } = await supabase
    .rpc('validate_api_key', { api_key: apiKey });
  
  if (error || !data?.valid) {
    throw new Error('Invalid API key');
  }
  
  return data;
}
```

### 5. OAuth 2.0 / OpenID Connect

**Best For:** Third-party AI agents with delegated access

#### Description

Use OAuth 2.0 for AI agents accessing Supabase on behalf of end-users, enabling consent-based access control.

#### Setup

```typescript
// OAuth configuration
{
  authentication: {
    method: "oauth",
    provider: "supabase",
    clientId: process.env.OAUTH_CLIENT_ID,
    clientSecret: process.env.OAUTH_CLIENT_SECRET,
    redirectUri: "https://mcp-server.example.com/callback",
    scopes: ["read:database", "write:database"]
  }
}

// OAuth flow implementation
import { oauth } from '@supabase/supabase-js';

async function initiateOAuthFlow() {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: 'https://mcp-server.example.com/callback',
      scopes: 'email profile'
    }
  });
  
  return data.url;
}
```

## Multi-Factor Authentication (MFA)

### MFA for Service Accounts

Add an additional layer of security for critical AI agents:

```typescript
// MFA Configuration
{
  authentication: {
    method: "service_role",
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    mfa: {
      enabled: true,
      method: "totp",
      secret: process.env.MFA_SECRET
    }
  }
}

// MFA verification
import speakeasy from 'speakeasy';

function verifyMFA(token: string): boolean {
  return speakeasy.totp.verify({
    secret: process.env.MFA_SECRET!,
    encoding: 'base32',
    token: token,
    window: 2
  });
}
```

## Authentication Flow Examples

### Flow 1: Service Role Authentication

```
┌────────────┐                 ┌────────────┐                 ┌────────────┐
│ AI Agent   │                 │ MCP Server │                 │  Supabase  │
└─────┬──────┘                 └──────┬─────┘                 └──────┬─────┘
      │                               │                              │
      │ 1. Request with Service Key   │                              │
      │─────────────────────────────>│                              │
      │                               │                              │
      │                               │ 2. Validate Service Key      │
      │                               │─────────────────────────────>│
      │                               │                              │
      │                               │ 3. Service Key Valid         │
      │                               │<─────────────────────────────│
      │                               │                              │
      │                               │ 4. Execute Query (No RLS)    │
      │                               │─────────────────────────────>│
      │                               │                              │
      │                               │ 5. Return Results            │
      │                               │<─────────────────────────────│
      │                               │                              │
      │ 6. Response                   │                              │
      │<─────────────────────────────│                              │
```

### Flow 2: JWT Authentication with RLS

```
┌────────────┐          ┌────────────┐          ┌────────────┐          ┌────────────┐
│ End User   │          │ AI Agent   │          │ MCP Server │          │  Supabase  │
└─────┬──────┘          └──────┬─────┘          └──────┬─────┘          └──────┬─────┘
      │                        │                       │                       │
      │ 1. Grant Permission    │                       │                       │
      │───────────────────────>│                       │                       │
      │                        │                       │                       │
      │                        │ 2. Request JWT        │                       │
      │                        │──────────────────────>│                       │
      │                        │                       │                       │
      │                        │                       │ 3. Generate JWT       │
      │                        │                       │      (User Context)   │
      │                        │                       │                       │
      │                        │ 4. Return JWT         │                       │
      │                        │<──────────────────────│                       │
      │                        │                       │                       │
      │                        │ 5. Query with JWT     │                       │
      │                        │──────────────────────>│                       │
      │                        │                       │                       │
      │                        │                       │ 6. Execute Query      │
      │                        │                       │    (With RLS)         │
      │                        │                       │──────────────────────>│
      │                        │                       │                       │
      │                        │                       │ 7. Filtered Results   │
      │                        │                       │<──────────────────────│
      │                        │                       │                       │
      │                        │ 8. Response           │                       │
      │                        │<──────────────────────│                       │
```

### Flow 3: API Key Authentication

```
┌────────────┐                 ┌────────────┐                 ┌────────────┐
│ AI Agent   │                 │ MCP Server │                 │  Supabase  │
└─────┬──────┘                 └──────┬─────┘                 └──────┬─────┘
      │                               │                              │
      │ 1. Request with API Key       │                              │
      │    (X-API-Key: sk_xxx)        │                              │
      │─────────────────────────────>│                              │
      │                               │                              │
      │                               │ 2. Validate API Key          │
      │                               │─────────────────────────────>│
      │                               │                              │
      │                               │ 3. Key Valid + Permissions   │
      │                               │<─────────────────────────────│
      │                               │                              │
      │                               │ 4. Check Rate Limit          │
      │                               │                              │
      │                               │ 5. Execute Query             │
      │                               │    (Permission Filtered)     │
      │                               │─────────────────────────────>│
      │                               │                              │
      │                               │ 6. Return Results            │
      │                               │<─────────────────────────────│
      │                               │                              │
      │ 7. Response                   │                              │
      │<─────────────────────────────│                              │
```

## Security Best Practices

### 1. Credential Storage

```typescript
// ✅ GOOD: Use environment variables
const config = {
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  dbPassword: process.env.DB_PASSWORD
};

// ❌ BAD: Hardcoded credentials
const config = {
  serviceRoleKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  dbPassword: "my-secret-password"
};
```

### 2. Credential Rotation

```bash
#!/bin/bash
# Automated credential rotation script

# Rotate database password
NEW_PASSWORD=$(openssl rand -base64 32)
psql -c "ALTER USER ai_agent PASSWORD '$NEW_PASSWORD';"

# Update environment variable
echo "DB_PASSWORD=$NEW_PASSWORD" >> .env.new
mv .env.new .env

# Restart MCP server to pick up new credentials
systemctl restart mcp-server
```

### 3. Audit Logging

```sql
-- Create audit log for authentication attempts
CREATE TABLE auth_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp timestamptz DEFAULT now(),
  agent_identifier text NOT NULL,
  auth_method text NOT NULL,
  success boolean NOT NULL,
  ip_address inet,
  user_agent text,
  error_message text,
  metadata jsonb
);

-- Enable RLS
ALTER TABLE auth_audit_log ENABLE ROW LEVEL SECURITY;

-- Log authentication attempts
CREATE OR REPLACE FUNCTION log_auth_attempt(
  agent_id text,
  method text,
  success boolean,
  ip inet DEFAULT NULL,
  error text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO auth_audit_log (
    agent_identifier,
    auth_method,
    success,
    ip_address,
    error_message
  ) VALUES (
    agent_id,
    method,
    success,
    ip,
    error
  );
END;
$$;
```

### 4. Rate Limiting by Authentication Method

```typescript
// Configure different rate limits per auth method
const rateLimits = {
  service_role: {
    maxRequests: 1000,
    windowMs: 60000 // 1 minute
  },
  database_credentials: {
    maxRequests: 500,
    windowMs: 60000
  },
  jwt: {
    maxRequests: 200,
    windowMs: 60000
  },
  api_key: {
    maxRequests: 100,
    windowMs: 60000
  }
};

// Apply rate limit based on auth method
function getRateLimit(authMethod: string) {
  return rateLimits[authMethod] || rateLimits.api_key;
}
```

### 5. IP Allowlisting

```sql
-- Create IP allowlist table
CREATE TABLE ip_allowlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_name text NOT NULL,
  ip_range cidr NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  is_active boolean DEFAULT true
);

-- Function to check IP allowlist
CREATE OR REPLACE FUNCTION check_ip_allowed(client_ip inet, agent text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM ip_allowlist 
    WHERE agent_name = agent
      AND client_ip << ip_range
      AND is_active = true
  );
END;
$$;
```

## Authentication Decision Matrix

| Agent Type | Environment | Recommended Auth | RLS Enforced | Use Case |
|------------|-------------|------------------|--------------|----------|
| Persistent | Server-side | Service Role | No | Full database access for trusted agents |
| Persistent | Server-side | DB Credentials | Depends on role | Limited permissions for specific tasks |
| Serverless | Cloud Function | JWT | Yes | User-context aware operations |
| Edge | Edge Runtime | JWT | Yes | Fast, user-scoped queries |
| External | Third-party | API Key | Configurable | Controlled access with rate limiting |
| User-facing | Client-side | OAuth + JWT | Yes | Delegated user access |

## Troubleshooting

### Common Authentication Issues

#### 1. "Invalid service role key"

**Cause:** Incorrect or expired service role key

**Solution:**
```bash
# Verify service role key in Supabase dashboard
# Settings > API > service_role key

# Test connection
curl https://your-project.supabase.co/rest/v1/your_table \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

#### 2. "JWT expired"

**Cause:** Token expiration time too short

**Solution:**
```typescript
// Increase JWT expiry
const payload = {
  sub: userId,
  exp: Math.floor(Date.now() / 1000) + (60 * 60 * 24) // 24 hours
};
```

#### 3. "Permission denied for table"

**Cause:** Database user lacks required permissions

**Solution:**
```sql
-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON TABLE your_table TO ai_agent;

-- Verify permissions
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name='your_table' AND grantee='ai_agent';
```

#### 4. "Rate limit exceeded"

**Cause:** Too many requests from agent

**Solution:**
```typescript
// Implement exponential backoff
async function queryWithRetry(query, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await query();
    } catch (error) {
      if (error.message.includes('rate limit') && i < maxRetries - 1) {
        await sleep(Math.pow(2, i) * 1000);
      } else {
        throw error;
      }
    }
  }
}
```

## Related Documentation

- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Server Configuration](./MCP_SERVER_CONFIGURATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [SSL/TLS Security Guide](./MCP_SSL_TLS_SECURITY.md) - **Critical for Production**
- [Row Level Security Policies](./RLS_POLICIES.md)

---

**Last Updated**: 2025-10-05  
**Version**: 1.0.0  
**Status**: ✅ Initial Release
