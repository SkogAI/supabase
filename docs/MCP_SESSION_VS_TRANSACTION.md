# Session Mode vs Transaction Mode: A Guide for AI Agents

## Overview

When connecting AI agents to Supabase via Supavisor pooler, you have two primary connection modes: **Session Mode** and **Transaction Mode**. This guide helps you choose the right mode for your AI agent based on its characteristics and requirements.

## Quick Decision Matrix

| Agent Type | Network | Duration | Use Case | Recommended Mode |
|------------|---------|----------|----------|------------------|
| Persistent Agent | IPv4 | Long-running | Conversational AI, continuous monitoring | **Session Mode** |
| Persistent Agent | IPv6 | Long-running | Any persistent workload | Direct Connection or Session Mode |
| Serverless Function | IPv4/IPv6 | Short-lived | AWS Lambda, Vercel Functions | **Transaction Mode** |
| Edge Function | IPv4/IPv6 | Ultra-short | Cloudflare Workers, Edge compute | **Transaction Mode** |
| High-throughput | IPv4/IPv6 | Variable | Batch processing, analytics | Dedicated Pooler |

## Session Mode (Port 5432)

### What is Session Mode?

Session mode maintains a persistent database connection for the entire duration of a client session. Each client gets a dedicated connection from the pool that stays active until the client disconnects.

### Connection String Format

```bash
postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres
```

**Example:**
```bash
postgresql://postgres.apbkobhfnmcqqzqeeqss:your-password@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

### When to Use Session Mode

✅ **Use Session Mode when:**

1. **IPv4 Requirement**: Your AI agent runs in an IPv4-only network environment
2. **Persistent Connections**: Your agent needs long-running database sessions
3. **Prepared Statements**: You use prepared statements for performance optimization
4. **Transaction Consistency**: You need multiple transactions within the same session context
5. **Session Variables**: You set session-level PostgreSQL variables (`SET` commands)
6. **Advisory Locks**: You use PostgreSQL advisory locks
7. **Temporary Tables**: You create and use temporary tables within a session
8. **Listen/Notify**: You use PostgreSQL's LISTEN/NOTIFY pub/sub features

✅ **Ideal for:**
- Conversational AI assistants with ongoing dialogues
- Monitoring agents that continuously query the database
- AI agents that maintain session state
- Agents running on virtual machines or dedicated servers
- Development and testing environments

### Advantages

- ✅ **Full PostgreSQL Feature Support**: All PostgreSQL features work as expected
- ✅ **Predictable Performance**: No connection overhead per query
- ✅ **IPv4 Compatibility**: Works with IPv4-only networks
- ✅ **Prepared Statement Support**: Can cache query plans
- ✅ **Session State Preservation**: Session variables persist

### Considerations

- ⚠️ **Connection Limits**: Limited by pool size (default: 30 connections)
- ⚠️ **Resource Usage**: Connections stay open even when idle
- ⚠️ **Scaling**: Each agent requires a dedicated connection slot
- ⚠️ **Connection Leaks**: Proper cleanup is critical

### Configuration Example

```json
{
  "mcpServers": {
    "supabase-session": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_SESSION_POOLER}"],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_SESSION_POOLER}",
        "POOL_MODE": "session",
        "POOL_SIZE": "20",
        "POOL_TIMEOUT": "300000"
      }
    }
  }
}
```

### Best Practices

1. **Connection Pooling**: Set `min: 5, max: 20` for most AI agents
2. **Idle Timeout**: Configure 5-10 minute idle timeout
3. **Max Lifetime**: Set 30-60 minute max connection lifetime
4. **Monitoring**: Track active connections and pool utilization
5. **Cleanup**: Always close connections when agent stops

### Pool Size Recommendations

```bash
# Small AI agent (1-5 concurrent operations)
DB_POOL_MIN=2
DB_POOL_MAX=5

# Medium AI agent (5-15 concurrent operations)
DB_POOL_MIN=5
DB_POOL_MAX=15

# Large AI agent (15-30 concurrent operations)
DB_POOL_MIN=10
DB_POOL_MAX=30
```

## Transaction Mode (Port 6543)

### What is Transaction Mode?

Transaction mode assigns a connection only for the duration of a single transaction. After the transaction completes (COMMIT/ROLLBACK), the connection is returned to the pool immediately and can be reused by other clients.

### Connection String Format

```bash
postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres
```

**Example:**
```bash
postgresql://postgres.apbkobhfnmcqqzqeeqss:your-password@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

### When to Use Transaction Mode

✅ **Use Transaction Mode when:**

1. **Serverless Environment**: Your agent runs on AWS Lambda, Vercel, or similar platforms
2. **Short-lived Connections**: Your agent executes quick queries and disconnects
3. **High Concurrency**: Many agents need to share a limited connection pool
4. **Auto-scaling**: Your agent scales up/down based on demand
5. **Cost Optimization**: You want to minimize idle connections
6. **Stateless Operations**: Each request is independent

✅ **Ideal for:**
- AWS Lambda functions
- Vercel/Netlify serverless functions
- Cloudflare Workers / Deno Deploy
- API endpoints with sporadic traffic
- Event-driven AI agents
- Microservices architectures

### Advantages

- ✅ **Efficient Resource Usage**: Connections released immediately after use
- ✅ **High Concurrency**: More clients can share fewer connections
- ✅ **Auto-cleanup**: No risk of connection leaks
- ✅ **Cost-effective**: Reduced connection overhead
- ✅ **Scales Well**: Works with auto-scaling serverless platforms

### Limitations

- ❌ **No Prepared Statements**: Cannot use prepared statements across transactions
- ❌ **No Session State**: Session variables don't persist
- ❌ **No Temporary Tables**: Temporary tables are lost after transaction
- ❌ **No Advisory Locks**: Cannot use session-level advisory locks
- ❌ **No LISTEN/NOTIFY**: Pub/sub features don't work
- ❌ **No Multi-statement Transactions**: Complex multi-step transactions may fail

### Configuration Example

```json
{
  "mcpServers": {
    "supabase-transaction": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_TRANSACTION_POOLER}"],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_TRANSACTION_POOLER}",
        "POOL_MODE": "transaction",
        "STATEMENT_TIMEOUT": "30000"
      }
    }
  }
}
```

### Best Practices

1. **Keep Transactions Short**: Minimize transaction duration
2. **Single Statements**: Use single-statement transactions when possible
3. **Connection Timeout**: Set short connection timeouts (3-5 seconds)
4. **Statement Timeout**: Set appropriate statement timeouts (10-30 seconds)
5. **Error Handling**: Always handle connection errors gracefully

### Pool Size Recommendations

```bash
# Serverless function (low concurrency)
DB_POOL_MIN=2
DB_POOL_MAX=10

# API with moderate traffic
DB_POOL_MIN=5
DB_POOL_MAX=20

# High-traffic serverless (let transaction pooling handle it)
DB_POOL_MIN=3
DB_POOL_MAX=10
```

## Direct IPv6 Connection

### When to Use Direct Connection

✅ **Use Direct IPv6 Connection when:**

1. **IPv6 Available**: Your agent has native IPv6 support
2. **Lowest Latency**: You need the absolute lowest latency
3. **Full Features**: You need all PostgreSQL features without pooler overhead
4. **Dedicated Resources**: Your agent has dedicated infrastructure
5. **Development**: Local development with Supabase CLI

### Connection String Format

```bash
postgresql://postgres.[project-ref]:[password]@db.[project-ref].supabase.co:5432/postgres
```

### Advantages

- ✅ **Lowest Latency**: Direct connection without pooler overhead
- ✅ **Full Feature Support**: All PostgreSQL features work
- ✅ **No Pooler Limits**: Not subject to pooler connection limits
- ✅ **Predictable Performance**: Direct connection characteristics

### Considerations

- ⚠️ **IPv6 Required**: Must have IPv6 network support
- ⚠️ **Connection Management**: Must implement your own pooling
- ⚠️ **Resource Usage**: Direct connections consume database resources

## Comparison Table

| Feature | Session Mode | Transaction Mode | Direct IPv6 |
|---------|--------------|------------------|-------------|
| **Port** | 5432 | 6543 | 5432 |
| **Network** | IPv4 ✅ | IPv4 ✅ | IPv6 only |
| **Connection Duration** | Long-lived | Per-transaction | Long-lived |
| **Prepared Statements** | ✅ Yes | ❌ No | ✅ Yes |
| **Session Variables** | ✅ Yes | ❌ No | ✅ Yes |
| **Temporary Tables** | ✅ Yes | ❌ No | ✅ Yes |
| **Advisory Locks** | ✅ Yes | ❌ No | ✅ Yes |
| **LISTEN/NOTIFY** | ✅ Yes | ❌ No | ✅ Yes |
| **Connection Overhead** | Low | Medium | Lowest |
| **Resource Efficiency** | Medium | High | Low |
| **Best for Serverless** | ❌ No | ✅ Yes | ❌ No |
| **Best for Persistent** | ✅ Yes | ❌ No | ✅ Yes |
| **Pool Size Limit** | ~30 | ~100 | Database limit |
| **Cold Start Impact** | Low | Very Low | Low |

## Connection Pool Sizing Guidelines

### Formula for Optimal Pool Size

```
Optimal Pool Size = (Core Count × 2) + Effective Spindle Count
```

For cloud databases, use:
```
Persistent Agents: 10-20 connections
Serverless Agents: 5-10 connections
Edge Agents: 3-5 connections
```

### Monitoring Pool Health

Monitor these metrics:
- **Active Connections**: Should be < max pool size
- **Idle Connections**: Should stay within idle timeout
- **Wait Time**: Should be < 1 second
- **Connection Errors**: Should be near zero

### Example Monitoring Query

```sql
SELECT 
  count(*) FILTER (WHERE state = 'active') as active,
  count(*) FILTER (WHERE state = 'idle') as idle,
  count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity
WHERE datname = 'postgres';
```

## Migration Guide

### From Direct Connection to Session Mode

1. Update connection string to use session pooler
2. Verify prepared statements still work
3. Test session variable usage
4. Monitor connection pool metrics
5. Adjust pool size based on usage

### From Session Mode to Transaction Mode

1. **Remove dependencies on:**
   - Prepared statements → Use parameterized queries
   - Session variables → Use transaction-scoped settings
   - Temporary tables → Use regular tables or CTEs
   - Advisory locks → Use row-level locking
   - LISTEN/NOTIFY → Use Supabase Realtime

2. **Update application code:**
   - Keep transactions short and focused
   - Avoid multi-statement transactions
   - Handle connection errors gracefully

3. **Update connection string:**
   - Change port from 5432 → 6543
   - Reduce pool size (fewer connections needed)
   - Set shorter timeouts

## Troubleshooting

### Session Mode Issues

**Problem:** "Too many connections" error
```
Solution: Reduce pool size or increase Supabase compute tier
```

**Problem:** Idle connections timing out
```
Solution: Configure idle_timeout and connection keep-alive
```

**Problem:** Connection leaks
```
Solution: Ensure proper connection cleanup in error handlers
```

### Transaction Mode Issues

**Problem:** "Prepared statement X does not exist"
```
Solution: Switch to session mode or use inline parameters
```

**Problem:** "Temporary table not found"
```
Solution: Switch to session mode or use CTEs/regular tables
```

**Problem:** "SET command not supported"
```
Solution: Use transaction-scoped settings or switch to session mode
```

## Example Implementations

### Python with Session Mode

```python
import asyncpg
import os

# Session mode connection
pool = await asyncpg.create_pool(
    os.getenv('SUPABASE_SESSION_POOLER'),
    min_size=5,
    max_size=20,
    command_timeout=30,
    server_settings={
        'application_name': 'ai-agent-session'
    }
)

# Use prepared statements
async with pool.acquire() as conn:
    stmt = await conn.prepare('SELECT * FROM users WHERE id = $1')
    user = await stmt.fetchone(user_id)
```

### Python with Transaction Mode

```python
import asyncpg
import os

# Transaction mode connection
pool = await asyncpg.create_pool(
    os.getenv('SUPABASE_TRANSACTION_POOLER'),
    min_size=3,
    max_size=10,
    command_timeout=10,
    server_settings={
        'application_name': 'ai-agent-transaction'
    }
)

# Use parameterized queries (no prepared statements)
async with pool.acquire() as conn:
    user = await conn.fetchrow(
        'SELECT * FROM users WHERE id = $1',
        user_id
    )
```

### Node.js with Session Mode

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.SUPABASE_SESSION_POOLER,
  min: 5,
  max: 20,
  idleTimeoutMillis: 300000,
  connectionTimeoutMillis: 10000,
});

// Use prepared statements
const client = await pool.connect();
try {
  const result = await client.query('SELECT * FROM users WHERE id = $1', [userId]);
} finally {
  client.release();
}
```

### Node.js with Transaction Mode

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.SUPABASE_TRANSACTION_POOLER,
  min: 3,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  statement_timeout: 30000,
});

// Keep transactions short
const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
```

## Decision Flowchart

```
Start: Choose Connection Mode
    ↓
Does your agent run in a serverless environment?
    ↓ Yes → Use Transaction Mode
    ↓ No
    ↓
Does your agent have IPv6 support?
    ↓ Yes → Use Direct IPv6 Connection
    ↓ No
    ↓
Does your agent need prepared statements or session state?
    ↓ Yes → Use Session Mode
    ↓ No → Use Transaction Mode
```

## Additional Resources

- [Supavisor Documentation](https://supabase.com/docs/guides/database/supavisor)
- [PostgreSQL Connection Pooling Best Practices](https://wiki.postgresql.org/wiki/Number_Of_Database_Connections)
- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Server Configuration](./MCP_SERVER_CONFIGURATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)

## Summary

**Choose Session Mode** for persistent AI agents requiring IPv4 support, prepared statements, or session state preservation.

**Choose Transaction Mode** for serverless AI agents, short-lived connections, or high-concurrency scenarios.

**Choose Direct IPv6** for persistent agents with IPv6 support needing the lowest latency and full PostgreSQL features.
