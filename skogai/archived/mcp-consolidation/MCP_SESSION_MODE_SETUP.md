# Supavisor Session Mode Setup for AI Agents

## Overview

This guide provides step-by-step instructions for configuring Supavisor session mode connections for persistent AI agents requiring IPv4 support. Session mode is ideal for long-running AI agents that need connection persistence, prepared statements, and full PostgreSQL feature support.

## What is Supavisor Session Mode?

Supavisor session mode is a connection pooling mode that maintains persistent database connections for the entire duration of a client session. It provides:

- **IPv4 Compatibility**: Works with IPv4-only network environments
- **Connection Persistence**: Maintains connection state throughout the session
- **Prepared Statements**: Full support for prepared statement caching
- **Session Variables**: Preserves session-level PostgreSQL settings
- **Full Feature Support**: All PostgreSQL features work as expected

## Connection String Format

```bash
postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres
```

### Components

| Component | Description | Example |
|-----------|-------------|---------|
| `postgres` | Database username | `postgres` |
| `[project-ref]` | Your Supabase project reference ID | `apbkobhfnmcqqzqeeqss` |
| `[password]` | Your database password | `your-db-password` |
| `[region]` | AWS region where your project is hosted | `us-east-1`, `eu-west-1` |
| Port | Session mode port | `5432` |

### Finding Your Connection Details

1. **Project Reference ID**: 
   - Go to your Supabase Dashboard
   - Settings → Database
   - Find "Reference ID" or "Project ID"

2. **Database Password**:
   - Settings → Database
   - Database password (set during project creation)

3. **Region**:
   - Settings → General
   - Your project region (e.g., `us-east-1`)

### Example Connection Strings

```bash
# US East 1
postgresql://postgres.apbkobhfnmcqqzqeeqss:mypassword123@aws-0-us-east-1.pooler.supabase.com:5432/postgres

# EU West 1
postgresql://postgres.apbkobhfnmcqqzqeeqss:mypassword123@aws-0-eu-west-1.pooler.supabase.com:5432/postgres

# AP Southeast 1
postgresql://postgres.apbkobhfnmcqqzqeeqss:mypassword123@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres
```

## Environment Variable Setup

### Step 1: Update `.env` File

Create or update your `.env` file with session pooler configuration:

```bash
# Supabase Session Pooler Connection
SUPABASE_SESSION_POOLER=postgresql://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres

# Connection Type
DB_CONNECTION_TYPE=supavisor_session

# Connection Pool Settings
DB_POOL_MIN=5
DB_POOL_MAX=20
DB_POOL_IDLE_TIMEOUT=300000
DB_POOL_CONNECTION_TIMEOUT=10000

# MCP Server Configuration
MCP_SERVER_NAME=supabase-session-mcp
MCP_SERVER_PORT=3000

# Authentication
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
JWT_SECRET=your-jwt-secret

# Monitoring
ENABLE_MCP_MONITORING=true
LOG_LEVEL=info
```

### Step 2: Secure Your Credentials

Never commit `.env` files to version control:

```bash
# Add to .gitignore
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
```

## MCP Server Configuration

### Configuration File: `mcp-config.json`

Create an MCP server configuration file optimized for session mode:

```json
{
  "mcpServers": {
    "supabase-session": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_SESSION_POOLER}"
      ],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_SESSION_POOLER}",
        "POOL_MODE": "session",
        "POOL_SIZE": "20",
        "POOL_TIMEOUT": "300000",
        "CONNECTION_TIMEOUT": "10000",
        "STATEMENT_TIMEOUT": "30000",
        "IDLE_IN_TRANSACTION_TIMEOUT": "60000"
      }
    }
  }
}
```

### Configuration Options Explained

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| `POOL_MODE` | Connection pooling mode | `session` |
| `POOL_SIZE` | Maximum connections in pool | `10-30` |
| `POOL_TIMEOUT` | Idle connection timeout (ms) | `300000` (5 min) |
| `CONNECTION_TIMEOUT` | Connection establishment timeout (ms) | `10000` (10 sec) |
| `STATEMENT_TIMEOUT` | Query execution timeout (ms) | `30000` (30 sec) |
| `IDLE_IN_TRANSACTION_TIMEOUT` | Idle transaction timeout (ms) | `60000` (60 sec) |

## Connection Pool Sizing

### Default Pool Configuration

The default Supabase pooler provides 30 connections per compute tier. Choose your pool size based on your agent's concurrency needs:

### Small Agent (1-5 concurrent operations)

```bash
DB_POOL_MIN=2
DB_POOL_MAX=5
```

**Use case:**
- Single-user AI assistants
- Development/testing
- Low-traffic agents

### Medium Agent (5-15 concurrent operations)

```bash
DB_POOL_MIN=5
DB_POOL_MAX=15
```

**Use case:**
- Multi-user AI assistants
- Production agents with moderate load
- Conversational AI with multiple concurrent sessions

### Large Agent (15-30 concurrent operations)

```bash
DB_POOL_MIN=10
DB_POOL_MAX=30
```

**Use case:**
- High-traffic AI platforms
- Multi-tenant AI services
- Enterprise AI agents

### Pool Size Formula

```
Optimal Pool Size = (CPU Cores × 2) + Effective Disk Spindles
```

For cloud databases, simplified:
```
Pool Size = Expected Concurrent Operations + 20% Buffer
```

## Connection Timeout Settings

### Recommended Timeouts

```bash
# Connection establishment
CONNECTION_TIMEOUT=10000  # 10 seconds

# Idle connection cleanup
IDLE_TIMEOUT=300000  # 5 minutes

# Statement execution
STATEMENT_TIMEOUT=30000  # 30 seconds

# Idle transaction cleanup
IDLE_IN_TRANSACTION_TIMEOUT=60000  # 60 seconds

# Connection lifetime (prevent stale connections)
CONNECTION_MAX_LIFETIME=1800000  # 30 minutes
```

### Timeout Configuration by Agent Type

#### Interactive AI Assistant
```bash
CONNECTION_TIMEOUT=10000
IDLE_TIMEOUT=600000        # 10 minutes
STATEMENT_TIMEOUT=30000
IDLE_IN_TRANSACTION_TIMEOUT=120000  # 2 minutes
```

#### Monitoring Agent
```bash
CONNECTION_TIMEOUT=5000
IDLE_TIMEOUT=300000        # 5 minutes
STATEMENT_TIMEOUT=10000
IDLE_IN_TRANSACTION_TIMEOUT=30000
```

#### Batch Processing Agent
```bash
CONNECTION_TIMEOUT=15000
IDLE_TIMEOUT=180000        # 3 minutes
STATEMENT_TIMEOUT=120000   # 2 minutes
IDLE_IN_TRANSACTION_TIMEOUT=180000
```

## Session Management Utilities

### Connection Health Check

```javascript
// health-check.js
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.SUPABASE_SESSION_POOLER,
  min: 5,
  max: 20,
  idleTimeoutMillis: 300000,
  connectionTimeoutMillis: 10000,
});

async function checkHealth() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    console.log('✅ Database connection healthy:', result.rows[0]);
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
}

// Run health check every 30 seconds
setInterval(checkHealth, 30000);
```

### Connection Pool Monitoring

```javascript
// monitor.js
async function monitorPool() {
  const stats = {
    totalConnections: pool.totalCount,
    idleConnections: pool.idleCount,
    waitingClients: pool.waitingCount,
  };
  
  console.log('Pool Status:', stats);
  
  // Alert if pool is saturated
  if (stats.waitingClients > 0) {
    console.warn('⚠️ Clients waiting for connections!');
  }
  
  // Alert if pool is mostly idle
  if (stats.idleConnections === stats.totalConnections) {
    console.log('ℹ️ All connections idle - consider reducing pool size');
  }
  
  return stats;
}

// Monitor every minute
setInterval(monitorPool, 60000);
```

### Graceful Shutdown

```javascript
// shutdown.js
async function gracefulShutdown() {
  console.log('🔄 Starting graceful shutdown...');
  
  try {
    // Stop accepting new queries
    await pool.end();
    console.log('✅ Connection pool closed');
    
    // Wait for active connections to complete
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    console.log('✅ Graceful shutdown complete');
    process.exit(0);
  } catch (error) {
    console.error('❌ Shutdown error:', error);
    process.exit(1);
  }
}

// Handle shutdown signals
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
```

## Session Monitoring and Metrics

### Key Metrics to Track

1. **Active Connections**: Number of connections currently executing queries
2. **Idle Connections**: Number of connections waiting for queries
3. **Wait Time**: Time clients wait for available connections
4. **Connection Errors**: Failed connection attempts
5. **Query Latency**: Average query execution time

### PostgreSQL Monitoring Query

```sql
-- Active connections by state
SELECT 
  state,
  count(*) as count,
  max(now() - query_start) as max_duration
FROM pg_stat_activity
WHERE datname = 'postgres'
  AND application_name LIKE '%mcp%'
GROUP BY state;
```

### Connection Pool Health Query

```sql
-- Pool utilization
SELECT 
  count(*) as total_connections,
  count(*) FILTER (WHERE state = 'active') as active,
  count(*) FILTER (WHERE state = 'idle') as idle,
  count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
  max(now() - backend_start) as oldest_connection_age
FROM pg_stat_activity
WHERE datname = 'postgres'
  AND application_name LIKE '%mcp%';
```

### Supabase Dashboard Metrics

Monitor these in your Supabase Dashboard (Settings → Database):

- **Connection count**: Should stay under pool limit
- **Active connections**: Should match your expected load
- **Database CPU**: Should be reasonable (<70%)
- **Database memory**: Should have headroom

## IPv4 Verification

### Verify IPv4 Connectivity

```bash
# Test DNS resolution
nslookup aws-0-us-east-1.pooler.supabase.com

# Expected output should show IPv4 addresses (A records)
# Example: 54.xxx.xxx.xxx
```

### Test Connection

```bash
# Using psql
psql "postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:5432/postgres"

# Using telnet (check port connectivity)
telnet aws-0-us-east-1.pooler.supabase.com 5432
```

### Verify in Code

```javascript
const net = require('net');
const { URL } = require('url');

async function verifyIPv4() {
  const url = new URL(process.env.SUPABASE_SESSION_POOLER);
  const host = url.hostname;
  const port = url.port || 5432;
  
  return new Promise((resolve, reject) => {
    const socket = net.connect(port, host, () => {
      console.log(`✅ IPv4 connection to ${host}:${port} successful`);
      socket.end();
      resolve(true);
    });
    
    socket.on('error', (error) => {
      console.error(`❌ IPv4 connection failed:`, error.message);
      reject(error);
    });
    
    socket.setTimeout(5000, () => {
      console.error('❌ Connection timeout');
      socket.destroy();
      reject(new Error('Connection timeout'));
    });
  });
}
```

## Complete Implementation Examples

### Python with asyncpg

```python
import asyncio
import asyncpg
import os
from typing import Optional

class SessionPoolManager:
    def __init__(self):
        self.pool: Optional[asyncpg.Pool] = None
    
    async def initialize(self):
        """Initialize connection pool"""
        self.pool = await asyncpg.create_pool(
            os.getenv('SUPABASE_SESSION_POOLER'),
            min_size=5,
            max_size=20,
            max_inactive_connection_lifetime=300,  # 5 minutes
            command_timeout=30,
            server_settings={
                'application_name': 'ai-agent-session',
                'statement_timeout': '30000',
                'idle_in_transaction_session_timeout': '60000'
            }
        )
        print("✅ Connection pool initialized")
    
    async def health_check(self) -> bool:
        """Check pool health"""
        try:
            async with self.pool.acquire() as conn:
                result = await conn.fetchval('SELECT 1')
                return result == 1
        except Exception as e:
            print(f"❌ Health check failed: {e}")
            return False
    
    async def get_pool_stats(self) -> dict:
        """Get pool statistics"""
        return {
            'size': self.pool.get_size(),
            'free': self.pool.get_idle_size(),
            'max': self.pool.get_max_size(),
            'min': self.pool.get_min_size()
        }
    
    async def close(self):
        """Close pool gracefully"""
        if self.pool:
            await self.pool.close()
            print("✅ Connection pool closed")

# Usage
async def main():
    manager = SessionPoolManager()
    await manager.initialize()
    
    # Check health
    is_healthy = await manager.health_check()
    print(f"Pool healthy: {is_healthy}")
    
    # Get stats
    stats = await manager.get_pool_stats()
    print(f"Pool stats: {stats}")
    
    # Use the pool
    async with manager.pool.acquire() as conn:
        users = await conn.fetch('SELECT * FROM users LIMIT 10')
        print(f"Found {len(users)} users")
    
    # Cleanup
    await manager.close()

if __name__ == '__main__':
    asyncio.run(main())
```

### Node.js with pg

```javascript
const { Pool } = require('pg');

class SessionPoolManager {
  constructor() {
    this.pool = new Pool({
      connectionString: process.env.SUPABASE_SESSION_POOLER,
      min: 5,
      max: 20,
      idleTimeoutMillis: 300000,
      connectionTimeoutMillis: 10000,
      statement_timeout: 30000,
      query_timeout: 30000,
      application_name: 'ai-agent-session',
    });

    // Handle errors
    this.pool.on('error', (err) => {
      console.error('❌ Unexpected pool error:', err);
    });

    // Log connection events
    this.pool.on('connect', () => {
      console.log('🔌 New client connected');
    });

    this.pool.on('remove', () => {
      console.log('🔌 Client removed from pool');
    });
  }

  async healthCheck() {
    try {
      const result = await this.pool.query('SELECT NOW()');
      console.log('✅ Health check passed:', result.rows[0]);
      return true;
    } catch (error) {
      console.error('❌ Health check failed:', error.message);
      return false;
    }
  }

  getPoolStats() {
    return {
      totalCount: this.pool.totalCount,
      idleCount: this.pool.idleCount,
      waitingCount: this.pool.waitingCount,
    };
  }

  async query(text, params) {
    const start = Date.now();
    try {
      const result = await this.pool.query(text, params);
      const duration = Date.now() - start;
      console.log(`✅ Query executed in ${duration}ms`);
      return result;
    } catch (error) {
      console.error('❌ Query failed:', error.message);
      throw error;
    }
  }

  async close() {
    console.log('🔄 Closing connection pool...');
    await this.pool.end();
    console.log('✅ Connection pool closed');
  }
}

// Usage
async function main() {
  const manager = new SessionPoolManager();

  // Health check
  await manager.healthCheck();

  // Monitor pool
  setInterval(() => {
    const stats = manager.getPoolStats();
    console.log('📊 Pool stats:', stats);
  }, 60000);

  // Execute queries
  const users = await manager.query('SELECT * FROM users LIMIT 10');
  console.log(`Found ${users.rows.length} users`);

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    await manager.close();
    process.exit(0);
  });
}

main().catch(console.error);
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "Too many connections" Error

**Symptom:**
```
Error: remaining connection slots are reserved for non-replication superuser connections
```

**Solutions:**
- Reduce `DB_POOL_MAX` setting
- Upgrade Supabase compute tier for more connections
- Switch to transaction mode for serverless agents
- Check for connection leaks in your code

#### 2. Connection Timeouts

**Symptom:**
```
Error: Connection timeout
```

**Solutions:**
- Increase `CONNECTION_TIMEOUT` setting
- Check network connectivity to pooler
- Verify firewall rules allow outbound port 5432
- Test DNS resolution of pooler hostname

#### 3. Idle Connection Drops

**Symptom:**
```
Error: Connection terminated unexpectedly
```

**Solutions:**
- Reduce `IDLE_TIMEOUT` setting
- Implement connection keep-alive
- Add automatic retry logic
- Monitor for network instability

#### 4. Slow Query Performance

**Symptom:**
Queries taking longer than expected

**Solutions:**
- Add database indexes for frequent queries
- Optimize query structure
- Use EXPLAIN ANALYZE to identify bottlenecks
- Check database CPU/memory usage in Supabase Dashboard

#### 5. Connection Pool Saturation

**Symptom:**
```
Clients waiting for connections
```

**Solutions:**
- Increase `DB_POOL_MAX` (up to compute limit)
- Reduce query execution time
- Implement query queuing in application
- Consider upgrading compute tier

## Best Practices

### 1. Connection Lifecycle Management

✅ **DO:**
- Always release connections after use
- Implement graceful shutdown
- Handle connection errors gracefully
- Monitor pool health regularly

❌ **DON'T:**
- Keep connections open indefinitely
- Ignore connection errors
- Use global connections without pooling
- Forget to close pool on shutdown

### 2. Query Optimization

✅ **DO:**
- Use prepared statements for repeated queries
- Set appropriate statement timeouts
- Use connection pooling
- Add indexes for frequent queries

❌ **DON'T:**
- Execute long-running queries without timeouts
- Use SELECT * when specific columns needed
- Open multiple connections for single operations
- Ignore query performance metrics

### 3. Security

✅ **DO:**
- Use environment variables for credentials
- Enable SSL/TLS connections
- Use Row Level Security (RLS)
- Rotate database passwords regularly

❌ **DON'T:**
- Hard-code credentials
- Commit `.env` files
- Use superuser credentials for agents
- Disable SSL verification

### 4. Monitoring

✅ **DO:**
- Track connection pool metrics
- Monitor query latency
- Set up alerts for connection errors
- Log connection lifecycle events

❌ **DON'T:**
- Ignore connection pool warnings
- Skip health checks
- Overlook slow query logs
- Forget to monitor database CPU/memory

## Next Steps

1. ✅ Set up environment variables
2. ✅ Configure MCP server for session mode
3. ✅ Implement connection pool monitoring
4. ✅ Test IPv4 connectivity
5. ✅ Deploy to production
6. ✅ Monitor and optimize

## Additional Resources

- [Session vs Transaction Mode Guide](./MCP_SESSION_VS_TRANSACTION.md)
- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Server Configuration](./MCP_SERVER_CONFIGURATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [Supavisor Documentation](https://supabase.com/docs/guides/database/supavisor)
- [PostgreSQL Connection Pooling](https://wiki.postgresql.org/wiki/Number_Of_Database_Connections)

## Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review Supabase Dashboard metrics
3. Check connection pool logs
4. Contact Supabase Support: https://supabase.com/support
5. Open a GitHub issue with logs and configuration
