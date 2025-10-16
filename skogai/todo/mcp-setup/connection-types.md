# MCP Connection Types Guide

## Overview

Supabase provides four connection methods for MCP servers, each optimized for different use cases, environments, and performance requirements. This guide helps you understand when and how to use each connection type.

## Connection Methods Overview

| Method | Port | Protocol | Pooling | IPv6 Required | Best For |
|--------|------|----------|---------|---------------|----------|
| Direct Connection | 5432 | Native PostgreSQL | None | Yes | Maximum performance |
| Session Mode | 5432 | Supavisor Pooler | Session-level | No | IPv4 persistent agents |
| Transaction Mode | 6543 | Supavisor Pooler | Transaction-level | No | Serverless/Edge functions |
| Dedicated Pooler | 6543 | PgBouncer | Configurable | No | High-performance workloads |

## 1. Direct Connection (IPv6)

### Overview
Direct connection provides native PostgreSQL access over IPv6, offering the lowest latency and full feature support.

### When to Use
- ✅ Persistent AI agents (Claude Desktop, local development)
- ✅ Long-running processes
- ✅ Full PostgreSQL feature requirements
- ✅ IPv6-capable environments
- ✅ Development and testing

### Advantages
- **Lowest Latency**: Direct database access without intermediary
- **Full Features**: All PostgreSQL features available (LISTEN/NOTIFY, advisory locks, etc.)
- **Prepared Statements**: Full support for prepared statements
- **Connection State**: Maintains session state across queries
- **Simplicity**: No pooler configuration needed

### Limitations
- ❌ Requires IPv6 support
- ❌ Not recommended for serverless (connection overhead)
- ❌ Limited connection scalability
- ❌ Higher resource usage per connection

### Configuration

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres
```

**Example:**
```
postgresql://postgres.abcdefghijklmnop:mypassword@abcdefghijklmnop.supabase.co:5432/postgres
```

**MCP Server Config:**
```json
{
  "mcpServers": {
    "supabase-direct": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_DIRECT_CONNECTION}"],
      "env": {
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "${SSL_CERT_PATH}",
        "PGCONNECT_TIMEOUT": "10",
        "PGAPPNAME": "mcp-persistent-agent"
      }
    }
  }
}
```

**Pool Configuration (if using connection pooling):**
```javascript
{
  min: 5,
  max: 20,
  idleTimeoutMillis: 300000,  // 5 minutes
  connectionTimeoutMillis: 10000
}
```

### Use Cases
1. **Claude Desktop** - Local AI assistant with persistent connection
2. **Development Environment** - Testing and debugging
3. **Data Science Workflows** - Long-running analytics
4. **Admin Tools** - Database management applications

---

## 2. Session Mode (Supavisor)

### Overview
Session mode provides connection pooling at the session level, maintaining a 1:1 mapping between client and database connections for the session duration.

### When to Use
- ✅ Persistent AI agents without IPv6
- ✅ IPv4-only environments
- ✅ Long-running connections
- ✅ Applications requiring session state
- ✅ Prepared statement support needed

### Advantages
- **IPv4 Compatible**: Works in IPv4-only networks
- **Session State**: Maintains temporary tables, prepared statements, transaction state
- **Prepared Statements**: Full support
- **PostgreSQL Features**: Most PostgreSQL features available
- **Connection Reuse**: Efficient for persistent workloads

### Limitations
- ⚠️ Connection limited to pool size
- ⚠️ Slightly higher latency than direct
- ❌ Not optimal for serverless (connection held during idle time)

### Configuration

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres
```

**Example:**
```
postgresql://postgres.abcdefghijklmnop:mypassword@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

**MCP Server Config:**
```json
{
  "mcpServers": {
    "supabase-session": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_SESSION_POOLER}"],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full",
        "PGCONNECT_TIMEOUT": "10",
        "PGAPPNAME": "mcp-session-agent"
      }
    }
  }
}
```

**Pool Configuration:**
```javascript
{
  min: 2,
  max: 10,
  idleTimeoutMillis: 300000,
  connectionTimeoutMillis: 10000
}
```

### Use Cases
1. **Persistent Agents (IPv4)** - AI agents in IPv4-only networks
2. **Application Servers** - Long-running application backends
3. **Batch Processing** - Jobs requiring transaction state
4. **Development Tools** - IDEs and admin panels

---

## 3. Transaction Mode (Supavisor)

### Overview
Transaction mode provides connection pooling at the transaction level, releasing connections back to the pool after each transaction commits or rolls back.

### When to Use
- ✅ Serverless functions (AWS Lambda, Google Cloud Functions, Azure Functions)
- ✅ Edge functions (Cloudflare Workers, Deno Deploy, Vercel Edge)
- ✅ Short-lived connections
- ✅ High concurrency with low connection counts
- ✅ Auto-scaling environments

### Advantages
- **Efficient Pooling**: Many clients share fewer connections
- **Auto Cleanup**: Connections automatically returned after transaction
- **Serverless Optimized**: Minimal connection overhead
- **High Concurrency**: Supports more clients than database connections
- **Cost Effective**: Reduces database connection usage

### Limitations
- ❌ **Must disable prepared statements** (critical!)
- ❌ No session state (temporary tables, etc.)
- ❌ No cross-transaction state
- ❌ SET commands don't persist
- ⚠️ Some PostgreSQL features unavailable

### Configuration

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
```

**Example:**
```
postgresql://postgres.abcdefghijklmnop:mypassword@aws-0-us-east-1.pooler.supabase.com:6543/postgres?prepareStatement=false
```

**MCP Server Config:**
```json
{
  "mcpServers": {
    "supabase-transaction": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string", "${SUPABASE_TRANSACTION_POOLER}",
        "--disable-prepared-statements"
      ],
      "env": {
        "POOL_MODE": "transaction",
        "DISABLE_PREPARED_STATEMENTS": "true",
        "PGSSLMODE": "verify-full",
        "PGCONNECT_TIMEOUT": "5",
        "PGAPPNAME": "mcp-serverless-agent"
      }
    }
  }
}
```

**Pool Configuration:**
```javascript
{
  min: 0,  // No minimum for serverless
  max: 5,
  idleTimeoutMillis: 5000,   // Quick cleanup
  connectionTimeoutMillis: 5000,
  acquireTimeoutMillis: 10000
}
```

### Important: Prepared Statement Handling

**Why Disable Prepared Statements?**
Transaction mode doesn't maintain connection state between transactions. Prepared statements are connection-specific, so attempting to use them causes errors:

```
ERROR: prepared statement "stmtcache_1" does not exist
```

**How to Disable:**

1. **Connection String:**
   ```
   ?prepareStatement=false
   ```

2. **Environment Variable:**
   ```bash
   DISABLE_PREPARED_STATEMENTS=true
   ```

3. **Node.js pg Client:**
   ```javascript
   const pool = new Pool({
     connectionString: process.env.DATABASE_URL,
     options: '-c plan_cache_mode=force_custom_plan'
   });
   ```

4. **Prisma:**
   ```
   postgresql://...?pgbouncer=true
   ```

### Use Cases
1. **AWS Lambda Functions** - Serverless AI processing
2. **Cloudflare Workers** - Edge AI applications
3. **Vercel Edge Functions** - Serverless Next.js AI features
4. **Google Cloud Functions** - Event-driven AI workflows
5. **Azure Functions** - Serverless AI endpoints

---

## 4. Dedicated Pooler

### Overview
Dedicated pooler provides isolated PgBouncer instances with custom configuration, optimized for high-performance workloads.

### When to Use
- ✅ Production workloads with high traffic
- ✅ Many concurrent connections needed
- ✅ Predictable, intensive workloads
- ✅ Performance-critical applications
- ✅ Need for resource isolation

### Advantages
- **Isolated Resources**: Dedicated compute for your pooler
- **Custom Configuration**: Tune pool sizes, timeouts
- **Maximum Throughput**: Optimized for high concurrency
- **Predictable Performance**: No resource sharing
- **Advanced Features**: Custom routing, query rewriting

### Limitations
- 💰 Higher cost (requires paid plan)
- ⚠️ Requires manual setup in Supabase Dashboard
- ⚠️ Additional configuration complexity

### Configuration

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[DEDICATED-ID].pooler.supabase.com:6543/postgres
```

**MCP Server Config:**
```json
{
  "mcpServers": {
    "supabase-dedicated": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_DEDICATED_POOLER}"],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full",
        "DB_POOL_MIN": "10",
        "DB_POOL_MAX": "100",
        "PGAPPNAME": "mcp-high-perf-agent"
      }
    }
  }
}
```

**Pool Configuration:**
```javascript
{
  min: 10,
  max: 100,
  idleTimeoutMillis: 600000,  // 10 minutes
  connectionTimeoutMillis: 10000,
  acquireTimeoutMillis: 30000,
  queueLimit: 1000
}
```

### Setup Steps
1. Navigate to Supabase Dashboard → Database → Connection Pooling
2. Enable "Dedicated Pooler" (Pro plan required)
3. Configure pool size and mode
4. Copy dedicated pooler connection string
5. Update MCP server configuration

### Use Cases
1. **Production AI Platforms** - High-traffic AI services
2. **Multi-Tenant Applications** - SaaS with many concurrent users
3. **Real-Time AI** - Low-latency requirements
4. **Enterprise Applications** - Mission-critical workloads

---

## Connection Method Selection Guide

### By Environment

| Environment | Recommended Method | Alternative |
|-------------|-------------------|-------------|
| Local Development | Direct Connection | Session Mode |
| Staging | Session Mode | Transaction Mode |
| Production (Persistent) | Session Mode | Dedicated Pooler |
| Production (Serverless) | Transaction Mode | N/A |
| Production (High-Traffic) | Dedicated Pooler | Session Mode |

### By Agent Type

| Agent Type | Primary Method | Fallback |
|------------|----------------|----------|
| Persistent AI Agent | Direct Connection | Session Mode |
| Serverless Function | Transaction Mode | N/A |
| Edge Function | Transaction Mode | N/A |
| High-Performance Agent | Dedicated Pooler | Session Mode |

### By Requirements

| Requirement | Recommended Method |
|-------------|-------------------|
| IPv6 available | Direct Connection |
| IPv4 only | Session/Transaction/Dedicated |
| Prepared statements needed | Direct/Session/Dedicated |
| Auto-scaling | Transaction Mode |
| Maximum performance | Dedicated Pooler |
| Cost-sensitive | Transaction Mode |
| Session state needed | Direct/Session/Dedicated |
| Short-lived connections | Transaction Mode |

## Port Reference

### Port 5432 (Direct & Session Mode)
- **Direct Connection**: `[PROJECT-REF].supabase.co:5432`
- **Session Pooler**: `aws-0-[REGION].pooler.supabase.com:5432`

### Port 6543 (Transaction & Dedicated)
- **Transaction Pooler**: `aws-0-[REGION].pooler.supabase.com:6543`
- **Dedicated Pooler**: `[DEDICATED-ID].pooler.supabase.com:6543`

## Protocol Details

### Native PostgreSQL Protocol
- Used by: Direct Connection, Session Mode
- Features: Full PostgreSQL wire protocol
- Encryption: TLS 1.2+
- Authentication: SCRAM-SHA-256

### Supavisor Pooler Protocol
- Used by: Transaction Mode
- Features: PgBouncer-compatible
- Encryption: TLS 1.2+
- Authentication: SCRAM-SHA-256
- Special: Connection multiplexing

### PgBouncer Protocol
- Used by: Dedicated Pooler
- Features: PgBouncer standard
- Encryption: TLS 1.2+
- Authentication: SCRAM-SHA-256
- Special: Custom routing possible

## Performance Comparison

| Metric | Direct | Session | Transaction | Dedicated |
|--------|--------|---------|-------------|-----------|
| Latency | Lowest | Low | Medium | Low |
| Throughput | Medium | High | Very High | Highest |
| Connection Limit | Low | Medium | High | Very High |
| Feature Support | Full | Most | Limited | Most |
| Cold Start | N/A | Fast | Very Fast | Fast |

## Security Considerations

All connection methods support:
- ✅ TLS 1.2+ encryption
- ✅ Certificate verification
- ✅ SCRAM-SHA-256 authentication
- ✅ Row Level Security (RLS)
- ✅ IP allowlisting (configurable in Supabase Dashboard)
- ✅ Connection audit logging

## Migration Between Methods

### From Direct to Session Mode
- ✅ No code changes needed
- ✅ Prepared statements still work
- ⚠️ Update connection string
- ⚠️ Adjust pool configuration

### From Session to Transaction Mode
- ❌ Must disable prepared statements
- ❌ Remove session state dependencies
- ❌ Update connection string (port 6543)
- ✅ Reduce pool size

### From Transaction to Dedicated
- ✅ Can re-enable prepared statements
- ✅ Update connection string
- ✅ Increase pool size
- ⚠️ Enable in Supabase Dashboard

## Troubleshooting

### Direct Connection Issues
- **Problem**: "Connection refused"
  - **Solution**: Verify IPv6 support: `ping6 [PROJECT-REF].supabase.co`
  
### Session Mode Issues
- **Problem**: "Too many connections"
  - **Solution**: Reduce pool size or use Transaction Mode

### Transaction Mode Issues
- **Problem**: "Prepared statement does not exist"
  - **Solution**: Add `?prepareStatement=false` to connection string
  
### Dedicated Pooler Issues
- **Problem**: "Connection not found"
  - **Solution**: Verify Dedicated Pooler is enabled in Dashboard

## Next Steps

- **Quick Start**: [Quick Start Guide](./quickstart.md)
- **Configuration**: [Configuration Templates](./configuration-templates.md)
- **SSL Setup**: [SSL Setup Guide](./ssl-setup.md)
- **Troubleshooting**: [Troubleshooting Guide](./troubleshooting.md)

---

**Last Updated**: 2025-01-07
**Version**: 1.0.0
