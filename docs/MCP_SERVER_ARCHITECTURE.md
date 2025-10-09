# MCP Server Architecture for Supabase

## Overview

This document defines the Model Context Protocol (MCP) server architecture for enabling AI agents to securely connect to and interact with Supabase databases. MCP servers provide a standardized interface for AI agents to access database resources while maintaining security, scalability, and performance.

## What is MCP?

The Model Context Protocol (MCP) is an open standard that enables AI agents to securely connect to various data sources, including databases. MCP servers act as intermediaries that:

- Provide standardized interfaces for AI agents
- Handle authentication and authorization
- Manage connection pooling and resource allocation
- Enforce security policies and rate limiting
- Abstract away infrastructure complexity

## Architecture Components

### 1. MCP Server Layer

The MCP server layer sits between AI agents and the Supabase database, providing:

```
┌─────────────────┐
│   AI Agents     │
│  (Claude, GPT)  │
└────────┬────────┘
         │ MCP Protocol
         ▼
┌─────────────────┐
│   MCP Server    │
│  - Auth Layer   │
│  - Connection   │
│    Management   │
│  - Query Proxy  │
└────────┬────────┘
         │ PostgreSQL Protocol
         ▼
┌─────────────────┐
│   Supabase DB   │
│  - PostgreSQL   │
│  - RLS Policies │
│  - Extensions   │
└─────────────────┘
```

### 2. Connection Layer

Different connection methods are supported based on agent execution environment:

#### Direct Connection (IPv6)
- **Use Case**: Persistent AI agents with stable environments
- **Protocol**: PostgreSQL native protocol over IPv6
- **Advantages**: Lowest latency, full PostgreSQL feature support
- **Considerations**: Requires IPv6 network support

#### Supavisor Session Mode
- **Use Case**: IPv4-required persistent agents
- **Protocol**: PostgreSQL protocol via Supavisor pooler
- **Advantages**: IPv4 compatibility, connection persistence
- **Pooling**: Session-level (one connection per client session)

#### Supavisor Transaction Mode
- **Use Case**: Serverless and edge AI agents
- **Protocol**: PostgreSQL protocol via Supavisor pooler
- **Advantages**: Efficient resource usage, automatic cleanup
- **Pooling**: Transaction-level (connections released after each transaction)

#### Dedicated Pooler
- **Use Case**: High-performance AI workloads with many concurrent requests on paid tiers
- **Protocol**: PgBouncer-compatible pooling in transaction mode
- **Port**: 6543 (transaction mode only)
- **Advantages**: Maximum throughput, isolated resources, lowest latency (co-located with database)
- **Requirements**: Pro/Enterprise plan, IPv6 or IPv4 add-on
- **Limitations**: No prepared statements, no session-level features
- **Configuration**: Custom pool sizes and timeouts
- **Documentation**: See [MCP Dedicated Pooler Guide](./MCP_DEDICATED_POOLER.md)

### 3. Authentication Layer

```
┌──────────────────────────────────────┐
│     Authentication Methods           │
├──────────────────────────────────────┤
│  1. Service Role Key (Full Access)   │
│  2. Database User Credentials        │
│  3. JWT Token (Row Level Security)   │
│  4. API Key (Rate-Limited Access)    │
└──────────────────────────────────────┘
```

### 4. Security Layer

- **Row Level Security (RLS)**: Database-level access control
- **Network Policies**: IP allowlisting and CIDR restrictions
- **SSL/TLS**: Encrypted connections required
- **Rate Limiting**: Query and connection limits per agent
- **Audit Logging**: Connection and query tracking

## Agent Type Classifications

### Persistent Agents

**Characteristics:**
- Long-running processes
- Stable execution environment
- Dedicated resources
- Consistent network access

**Recommended Connection:**
- Primary: Direct Connection (IPv6)
- Fallback: Supavisor Session Mode

**Configuration:**
```typescript
{
  type: "persistent",
  connection: {
    method: "direct_ipv6",
    host: "[::1]:54322",
    database: "postgres",
    poolSize: 10,
    idleTimeout: 300000 // 5 minutes
  }
}
```

### Serverless Agents

**Characteristics:**
- Short-lived execution
- Cold start initialization
- Shared infrastructure
- Variable resource availability

**Recommended Connection:**
- Primary: Supavisor Transaction Mode
- Optimize for: Fast connection establishment

**Configuration:**
```typescript
{
  type: "serverless",
  connection: {
    method: "supavisor_transaction",
    pooler: "transaction",
    maxConnections: 5,
    connectionTimeout: 5000,
    statementTimeout: 30000
  }
}
```

### Edge Agents

**Characteristics:**
- Global distribution
- Minimal latency requirements
- Limited execution time
- Resource constraints

**Recommended Connection:**
- Primary: Supavisor Transaction Mode
- Optimize for: Geographic proximity

**Configuration:**
```typescript
{
  type: "edge",
  connection: {
    method: "supavisor_transaction",
    region: "auto", // Closest region
    pooler: "transaction",
    maxConnections: 3,
    connectionTimeout: 3000,
    statementTimeout: 10000
  }
}
```

### High-Performance Agents

**Characteristics:**
- Intensive workloads
- Many concurrent operations
- Predictable resource needs
- SLA requirements

**Recommended Connection:**
- Primary: Dedicated Pooler
- Optimize for: Throughput and consistency

**Configuration:**
```typescript
{
  type: "high_performance",
  connection: {
    method: "dedicated_pooler",
    poolSize: 50,
    minConnections: 10,
    maxConnections: 100,
    queueTimeout: 1000
  }
}
```

## Connection String Patterns

### Direct Connection (IPv6)

```
postgresql://[user]:[password]@[ipv6-host]:5432/[database]
```

Example:
```
postgresql://postgres:password@[2001:db8::1]:5432/postgres
```

### Direct Connection (IPv4)

```
postgresql://[user]:[password]@[host]:5432/[database]
```

Example:
```
postgresql://postgres:password@db.example.com:5432/postgres
```

### Supavisor Session Mode

```
postgresql://[user].[project-ref]:[password]@[pooler-host]:5432/postgres
```

Example:
```
postgresql://postgres.abcdefghijklmnop:password@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

### Supavisor Transaction Mode

```
postgresql://[user].[project-ref]:[password]@[pooler-host]:6543/postgres
```

Example:
```
postgresql://postgres.abcdefghijklmnop:password@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

**Note:** Transaction mode typically uses port 6543 (different from session mode).

### Dedicated Pooler (Paid Tier)

```
postgresql://[user].[project-ref]:[password]@db.[project-ref].supabase.co:6543/postgres
```

Example:
```
postgresql://postgres.apbkobhfnmcqqzqeeqss:password@db.apbkobhfnmcqqzqeeqss.supabase.co:6543/postgres
```

**Key Differences:**
- Co-located with database: `db.[project-ref].supabase.co` instead of pooler host
- Transaction mode only (port 6543)
- Requires paid tier and dedicated pooler provisioning
- Prepared statements must be disabled
- See [MCP_DEDICATED_POOLER.md](./MCP_DEDICATED_POOLER.md) for complete guide

### Connection String Components

| Component | Description | Example |
|-----------|-------------|---------|
| `user` | Database username | `postgres` |
| `project-ref` | Supabase project reference | `abcdefghijklmnop` |
| `password` | Database password | `your-db-password` |
| `pooler-host` | Supavisor pooler hostname | `aws-0-us-east-1.pooler.supabase.com` |
| `database` | Target database name | `postgres` |
| `port` | Connection port | `5432` (session), `6543` (transaction) |

## Security Considerations

### 1. Credential Management

**DO:**
- ✅ Use environment variables for credentials
- ✅ Rotate passwords regularly
- ✅ Use service role keys only for trusted environments
- ✅ Implement least-privilege access
- ✅ Enable SSL/TLS for all connections

**DON'T:**
- ❌ Hardcode credentials in application code
- ❌ Commit credentials to version control
- ❌ Share credentials across environments
- ❌ Use the same credentials for all agents
- ❌ Expose credentials in client-side code

### 2. Network Security

```sql
-- Enable network restrictions in Supabase
ALTER SYSTEM SET pg_hba.conf = '
# TYPE  DATABASE        USER            ADDRESS                 METHOD
hostssl all             all             0.0.0.0/0              scram-sha-256
hostssl all             all             ::/0                   scram-sha-256
';
```

### 3. Row Level Security Integration

MCP servers should leverage Supabase RLS policies:

```sql
-- AI agents use service role for unrestricted access
-- or authenticated role with RLS policies

-- Example: AI agent with limited access
CREATE POLICY "ai_agent_read_only"
    ON your_table FOR SELECT
    TO authenticated
    USING (
        auth.jwt() ->> 'agent_type' = 'ai_assistant'
        AND published = true
    );
```

### 4. Rate Limiting

Implement rate limiting at multiple layers:

```typescript
// Application-level rate limiting
const rateLimiter = {
  maxQueriesPerMinute: 100,
  maxConnectionsPerAgent: 10,
  maxQueryDuration: 30000, // 30 seconds
  maxResultSize: 10000000 // 10MB
};
```

### 5. Audit Logging

Track all MCP server operations:

```sql
-- Create audit log table
CREATE TABLE mcp_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id text NOT NULL,
  operation text NOT NULL,
  query text,
  execution_time_ms integer,
  rows_affected integer,
  error text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on audit log
ALTER TABLE mcp_audit_log ENABLE ROW LEVEL SECURITY;
```

## Performance Optimization

### Connection Pooling Best Practices

1. **Pool Size Calculation:**
   ```
   Optimal Pool Size = ((Core Count × 2) + Effective Spindle Count)
   ```

2. **Persistent Agents:**
   - Pool Size: 10-20 connections
   - Idle Timeout: 5-10 minutes
   - Max Lifetime: 30 minutes

3. **Serverless Agents:**
   - Pool Size: 5-10 connections
   - Idle Timeout: 30 seconds
   - Connection Timeout: 5 seconds

4. **Edge Agents:**
   - Pool Size: 3-5 connections
   - Idle Timeout: 10 seconds
   - Connection Timeout: 3 seconds

### Query Optimization

```sql
-- Set statement timeout for all MCP connections
ALTER ROLE mcp_agent SET statement_timeout = '30s';

-- Limit work memory to prevent resource exhaustion
ALTER ROLE mcp_agent SET work_mem = '64MB';

-- Enable query planning for complex queries
ALTER ROLE mcp_agent SET plan_cache_mode = 'force_generic_plan';
```

## Monitoring and Observability

### Key Metrics to Track

1. **Connection Metrics:**
   - Active connections
   - Connection wait time
   - Connection errors
   - Pool saturation

2. **Query Metrics:**
   - Query execution time
   - Queries per second
   - Failed queries
   - Slow queries (>1s)

3. **Resource Metrics:**
   - CPU utilization
   - Memory usage
   - Network throughput
   - Disk I/O

### Monitoring Queries

```sql
-- View active MCP connections
SELECT 
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  state_change,
  query
FROM pg_stat_activity
WHERE application_name LIKE '%mcp%'
ORDER BY query_start DESC;

-- Check connection pool statistics
SELECT 
  datname,
  numbackends,
  xact_commit,
  xact_rollback,
  blks_read,
  blks_hit,
  temp_files,
  temp_bytes
FROM pg_stat_database
WHERE datname = 'postgres';
```

## Deployment Strategies

### Development Environment

```yaml
# docker-compose.yml for local MCP server
version: '3.8'
services:
  mcp-server:
    image: mcp-server:latest
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
      - MCP_PORT=3000
      - AGENT_TYPE=development
    ports:
      - "3000:3000"
    depends_on:
      - postgres
```

### Production Environment

#### Option 1: Supabase Edge Functions

Deploy MCP server as a Supabase Edge Function:

```typescript
// supabase/functions/mcp-server/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  // Handle MCP requests
  // ...
});
```

#### Option 2: Containerized Deployment

Deploy as a standalone container service:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 3000
CMD ["node", "mcp-server.js"]
```

#### Option 3: Serverless Functions

Deploy on AWS Lambda, Google Cloud Functions, or similar:

```typescript
// Lambda handler for MCP server
export const handler = async (event: any) => {
  // Initialize connection pool
  // Handle MCP protocol
  // Return response
};
```

## Configuration Management

### Environment-Based Configuration

```typescript
// config/mcp-server.config.ts
export const config = {
  development: {
    database: {
      host: 'localhost',
      port: 54322,
      poolSize: 5
    },
    security: {
      requireSSL: false,
      rateLimit: 1000
    }
  },
  staging: {
    database: {
      host: process.env.STAGING_DB_HOST,
      port: 5432,
      poolSize: 10
    },
    security: {
      requireSSL: true,
      rateLimit: 500
    }
  },
  production: {
    database: {
      host: process.env.PRODUCTION_DB_HOST,
      port: 5432,
      poolSize: 20
    },
    security: {
      requireSSL: true,
      rateLimit: 200
    }
  }
};
```

### Configuration Templates

See [MCP_SERVER_CONFIGURATION.md](./MCP_SERVER_CONFIGURATION.md) for detailed configuration templates and examples.

## Related Documentation

- [MCP Server Configuration Templates](./MCP_SERVER_CONFIGURATION.md)
- [MCP Dedicated Pooler Guide](./MCP_DEDICATED_POOLER.md) - High-performance pooler for paid tiers
- [MCP Authentication Strategies](./MCP_AUTHENTICATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [SSL/TLS Security Guide](./MCP_SSL_TLS_SECURITY.md) - **Critical for Production**
- [Row Level Security Policies](./RLS_POLICIES.md)
- [Database Security Best Practices](./RLS_TESTING.md)

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Supabase Connection Pooling](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)
- [PostgreSQL Connection Management](https://www.postgresql.org/docs/current/runtime-config-connection.html)
- [Supavisor Documentation](https://supabase.com/docs/guides/database/supavisor)

---

**Last Updated**: 2025-10-05  
**Version**: 1.0.0  
**Status**: ✅ Initial Release
