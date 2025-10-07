# Supavisor Transaction Mode for Serverless AI Agents

## Overview

This document provides comprehensive guidance for configuring Supabase MCP servers using **Supavisor Transaction Mode**, specifically optimized for serverless and edge AI agents with short-lived, transient database connections.

## Table of Contents

- [Overview](#overview)
- [When to Use Transaction Mode](#when-to-use-transaction-mode)
- [Connection String Format](#connection-string-format)
- [Critical Limitations](#critical-limitations)
- [Library Configuration](#library-configuration)
- [MCP Server Configuration](#mcp-server-configuration)
- [Connection Lifecycle Management](#connection-lifecycle-management)
- [Monitoring and Metrics](#monitoring-and-metrics)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## When to Use Transaction Mode

Transaction mode is ideal for:

- **Serverless AI Agents**: AWS Lambda, Google Cloud Functions, Azure Functions
- **Edge AI Agents**: Cloudflare Workers, Deno Deploy, Vercel Edge Functions
- **Auto-scaling Systems**: Agents that scale to zero or dynamically scale
- **High-Concurrency, Low-Duration**: Many concurrent connections with short query execution
- **Intermittent Access**: AI agents that connect, execute queries, and disconnect quickly

### Comparison: Session vs Transaction Mode

| Feature | Session Mode (Port 5432) | Transaction Mode (Port 6543) |
|---------|-------------------------|------------------------------|
| **Connection Lifetime** | Persistent (minutes-hours) | Transient (seconds) |
| **Prepared Statements** | ✅ Supported | ❌ **Not Supported** |
| **Session State** | Maintained | Not maintained |
| **Best For** | Persistent agents | Serverless/Edge agents |
| **Connection Overhead** | Low (reused) | Higher (per-transaction) |
| **Scalability** | Limited by pool size | Highly scalable |

## Connection String Format

### Standard Transaction Mode Connection

```
postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres
```

### Component Breakdown

| Component | Description | Example |
|-----------|-------------|---------|
| `postgres.[project-ref]` | Username format | `postgres.apbkobhfnmcqqzqeeqss` |
| `[password]` | Database password | Your database password |
| `pooler.supabase.com` | Supavisor pooler hostname | `aws-0-us-east-1.pooler.supabase.com` |
| `6543` | **Transaction mode port** | Always `6543` for transaction mode |
| `postgres` | Database name | `postgres` (default) |

### Regional Endpoints

Choose the closest region to your serverless deployment:

```bash
# US East (Virginia)
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres

# US West (Oregon)
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-us-west-2.pooler.supabase.com:6543/postgres

# Europe (Ireland)
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-eu-west-1.pooler.supabase.com:6543/postgres

# Asia Pacific (Singapore)
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres
```

### Connection String with Parameters

```bash
# With statement timeout
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres?statement_timeout=30000

# With SSL mode
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require

# Multiple parameters
postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres?statement_timeout=30000&sslmode=require
```

## Critical Limitations

### ⚠️ Prepared Statements NOT Supported

**Transaction mode does NOT support prepared statements.** This is the most critical limitation to understand.

#### What Are Prepared Statements?

Prepared statements are pre-compiled SQL queries that can be executed multiple times with different parameters:

```sql
-- Prepared statement (NOT supported in transaction mode)
PREPARE user_query (UUID) AS 
  SELECT * FROM users WHERE id = $1;
  
EXECUTE user_query('123e4567-e89b-12d3-a456-426614174000');
```

#### Why They're Not Supported

In transaction mode, each transaction gets a new backend connection from the pool. Prepared statements are session-specific and don't persist across different backend connections, making them incompatible with transaction pooling.

#### Impact on Libraries

Most database libraries use prepared statements by default for performance. **You must explicitly disable them** when using transaction mode.

### Other Limitations

1. **No Session Variables**: `SET` commands don't persist across transactions
2. **No Temporary Tables**: Temporary tables are cleared after each transaction
3. **No LISTEN/NOTIFY**: Pub/sub requires persistent connections
4. **No Cursors**: Server-side cursors require session state
5. **No Advisory Locks**: Session-level locks not available

## Library Configuration

### Node.js (pg)

**❌ Default (Prepared Statements Enabled)**
```typescript
import { Pool } from 'pg';

// This will FAIL in transaction mode
const pool = new Pool({
  connectionString: process.env.SUPABASE_TRANSACTION_POOLER,
});
```

**✅ Correct (Prepared Statements Disabled)**
```typescript
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.SUPABASE_TRANSACTION_POOLER,
  // Disable prepared statements for transaction mode
  options: '-c statement_timeout=30000'
});

// OR use inline queries without parameters
async function query(sql: string, params?: any[]) {
  const client = await pool.connect();
  try {
    // Use simple query protocol (no prepared statements)
    const result = await client.query({
      text: sql,
      values: params,
      rowMode: 'array'
    });
    return result.rows;
  } finally {
    client.release();
  }
}
```

### Node.js (@supabase/supabase-js)

**✅ Recommended (Handles Transaction Mode Automatically)**
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    db: {
      schema: 'public'
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false
    },
    global: {
      headers: {
        'x-application-name': 'serverless-ai-agent'
      }
    }
  }
);

// Supabase client handles connection pooling internally
const { data, error } = await supabase
  .from('documents')
  .select('*')
  .limit(10);
```

### Python (psycopg2)

**✅ Correct Configuration**
```python
import psycopg2
from psycopg2 import pool

# Create connection pool with transaction mode settings
connection_pool = pool.SimpleConnectionPool(
    1, 5,  # min=1, max=5 connections
    host="aws-0-us-east-1.pooler.supabase.com",
    port=6543,  # Transaction mode port
    database="postgres",
    user="postgres.PROJECT_REF",
    password="YOUR_PASSWORD",
    sslmode="require",
    options="-c statement_timeout=30000"
)

# Use context manager for automatic connection cleanup
def execute_query(sql, params=None):
    conn = connection_pool.getconn()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchall()
    finally:
        connection_pool.putconn(conn)
```

### Python (asyncpg)

**✅ Correct Configuration**
```python
import asyncpg

async def create_pool():
    return await asyncpg.create_pool(
        host="aws-0-us-east-1.pooler.supabase.com",
        port=6543,  # Transaction mode port
        database="postgres",
        user="postgres.PROJECT_REF",
        password="YOUR_PASSWORD",
        ssl="require",
        min_size=1,
        max_size=5,
        command_timeout=30,
        # Disable prepared statements
        statement_cache_size=0
    )

# Usage
pool = await create_pool()
async with pool.acquire() as conn:
    rows = await conn.fetch('SELECT * FROM users LIMIT 10')
```

### Deno (postgres)

**✅ Correct Configuration**
```typescript
import { Pool } from "https://deno.land/x/postgres/mod.ts";

const pool = new Pool({
  hostname: "aws-0-us-east-1.pooler.supabase.com",
  port: 6543,  // Transaction mode port
  database: "postgres",
  user: "postgres.PROJECT_REF",
  password: "YOUR_PASSWORD",
  tls: {
    enabled: true,
    enforce: true
  }
}, 5); // Max 5 connections

// Query function
async function query(sql: string, params?: any[]) {
  const client = await pool.connect();
  try {
    const result = await client.queryObject(sql, params);
    return result.rows;
  } finally {
    client.release();
  }
}
```

### Go (pgx)

**✅ Correct Configuration**
```go
package main

import (
    "context"
    "github.com/jackc/pgx/v5/pgxpool"
)

func createPool() (*pgxpool.Pool, error) {
    config, err := pgxpool.ParseConfig(
        "postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require",
    )
    if err != nil {
        return nil, err
    }
    
    // Disable prepared statements for transaction mode
    config.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
    config.MaxConns = 5
    config.MinConns = 1
    
    return pgxpool.NewWithConfig(context.Background(), config)
}
```

## MCP Server Configuration

### Basic Transaction Mode Configuration

```json
{
  "mcpServers": {
    "supabase-transaction": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_TRANSACTION_POOLER}",
        "--disable-prepared-statements"
      ],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_TRANSACTION_POOLER}",
        "POOL_MODE": "transaction",
        "DISABLE_PREPARED_STATEMENTS": "true",
        "MAX_CONNECTIONS": "5",
        "CONNECTION_TIMEOUT": "5000",
        "STATEMENT_TIMEOUT": "30000"
      }
    }
  }
}
```

### Complete Serverless Agent Configuration

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "serverless",
    "server": {
      "name": "serverless-ai-agent-mcp",
      "runtime": "lambda",
      "coldStart": {
        "optimized": true,
        "keepWarmInterval": 300000
      }
    },
    "database": {
      "connectionString": "${SUPABASE_TRANSACTION_POOLER}",
      "connectionType": "supavisor_transaction",
      "pooler": {
        "mode": "transaction",
        "port": 6543,
        "disablePreparedStatements": true
      },
      "ssl": {
        "rejectUnauthorized": true
      },
      "pool": {
        "min": 0,
        "max": 5,
        "idleTimeoutMillis": 5000,
        "connectionTimeoutMillis": 5000,
        "acquireTimeoutMillis": 10000,
        "evictionRunIntervalMillis": 5000,
        "softIdleTimeoutMillis": 3000
      },
      "query": {
        "statementTimeout": 30000,
        "queryTimeout": 25000
      }
    },
    "optimization": {
      "connectionReuse": true,
      "lazyConnection": true,
      "preparedStatements": false
    }
  }
}
```

### Complete Edge Agent Configuration

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "edge",
    "server": {
      "name": "edge-ai-agent-mcp",
      "runtime": "edge",
      "region": "auto"
    },
    "database": {
      "connectionString": "${SUPABASE_TRANSACTION_POOLER}",
      "connectionType": "supavisor_transaction",
      "pooler": {
        "mode": "transaction",
        "port": 6543,
        "region": "auto",
        "disablePreparedStatements": true
      },
      "ssl": {
        "rejectUnauthorized": true
      },
      "pool": {
        "min": 0,
        "max": 3,
        "idleTimeoutMillis": 1000,
        "connectionTimeoutMillis": 3000,
        "acquireTimeoutMillis": 5000
      },
      "query": {
        "statementTimeout": 10000,
        "queryTimeout": 8000
      }
    },
    "optimization": {
      "connectionReuse": false,
      "lazyConnection": true,
      "preparedStatements": false
    }
  }
}
```

## Connection Lifecycle Management

### Serverless Connection Pattern

```typescript
// AWS Lambda Handler
import { createClient } from '@supabase/supabase-js';

// Initialize outside handler (reused across invocations)
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false
    }
  }
);

export async function handler(event: any) {
  try {
    // Connection auto-created and cleaned up per transaction
    const { data, error } = await supabase
      .from('logs')
      .insert({ message: 'Lambda invoked', timestamp: new Date() });
    
    if (error) throw error;
    
    return { statusCode: 200, body: JSON.stringify({ success: true }) };
  } catch (error) {
    console.error('Database error:', error);
    return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
  }
  // Connection automatically released after transaction
}
```

### Connection Cleanup Utilities

```typescript
// connection-utils.ts
import { Pool } from 'pg';

class TransactionPoolManager {
  private pool: Pool;
  private activeConnections = new Set<any>();

  constructor(connectionString: string) {
    this.pool = new Pool({
      connectionString,
      max: 5,
      idleTimeoutMillis: 5000,
      connectionTimeoutMillis: 5000
    });

    // Track active connections
    this.pool.on('connect', (client) => {
      this.activeConnections.add(client);
    });

    this.pool.on('remove', (client) => {
      this.activeConnections.delete(client);
    });
  }

  async executeTransaction<T>(
    callback: (client: any) => Promise<T>
  ): Promise<T> {
    const client = await this.pool.connect();
    
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async healthCheck(): Promise<boolean> {
    const client = await this.pool.connect();
    try {
      await client.query('SELECT 1');
      return true;
    } catch {
      return false;
    } finally {
      client.release();
    }
  }

  getStats() {
    return {
      total: this.pool.totalCount,
      idle: this.pool.idleCount,
      waiting: this.pool.waitingCount,
      active: this.activeConnections.size
    };
  }

  async gracefulShutdown() {
    await this.pool.end();
  }
}

export default TransactionPoolManager;
```

### Timeout Configuration

```typescript
// Recommended timeouts for different scenarios

// Quick queries (< 5 seconds)
const quickQueryConfig = {
  connectionTimeoutMillis: 3000,
  statementTimeout: 5000,
  queryTimeout: 4000
};

// Standard queries (< 30 seconds)
const standardQueryConfig = {
  connectionTimeoutMillis: 5000,
  statementTimeout: 30000,
  queryTimeout: 25000
};

// Long-running operations (< 60 seconds)
const longRunningConfig = {
  connectionTimeoutMillis: 10000,
  statementTimeout: 60000,
  queryTimeout: 55000
};
```

## Monitoring and Metrics

### Connection Monitoring Queries

```sql
-- View active transaction pooler connections
SELECT 
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  state_change,
  NOW() - query_start as query_duration,
  query
FROM pg_stat_activity
WHERE 
  client_addr IS NOT NULL
  AND application_name LIKE '%transaction%'
ORDER BY query_start DESC;

-- Check connection pool saturation
SELECT 
  datname,
  numbackends as active_connections,
  xact_commit as transactions_committed,
  xact_rollback as transactions_rolled_back,
  blks_read as disk_reads,
  blks_hit as cache_hits,
  ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) as cache_hit_ratio
FROM pg_stat_database
WHERE datname = 'postgres';

-- Monitor transaction performance
SELECT 
  ROUND(AVG(EXTRACT(EPOCH FROM (NOW() - query_start)) * 1000)::numeric, 2) as avg_duration_ms,
  COUNT(*) as query_count,
  state
FROM pg_stat_activity
WHERE state IS NOT NULL
GROUP BY state;
```

### CloudWatch Metrics (AWS Lambda)

```typescript
import { CloudWatch } from 'aws-sdk';

const cloudwatch = new CloudWatch();

async function logMetrics(poolStats: any) {
  await cloudwatch.putMetricData({
    Namespace: 'MCP/TransactionPool',
    MetricData: [
      {
        MetricName: 'ActiveConnections',
        Value: poolStats.active,
        Unit: 'Count',
        Timestamp: new Date()
      },
      {
        MetricName: 'IdleConnections',
        Value: poolStats.idle,
        Unit: 'Count',
        Timestamp: new Date()
      },
      {
        MetricName: 'WaitingConnections',
        Value: poolStats.waiting,
        Unit: 'Count',
        Timestamp: new Date()
      }
    ]
  }).promise();
}
```

### Performance Tracking

```typescript
// Query performance middleware
async function trackQueryPerformance(queryFn: () => Promise<any>) {
  const start = Date.now();
  let error: Error | null = null;
  
  try {
    return await queryFn();
  } catch (e) {
    error = e as Error;
    throw e;
  } finally {
    const duration = Date.now() - start;
    
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      duration_ms: duration,
      status: error ? 'error' : 'success',
      error: error?.message
    }));
    
    // Alert on slow queries
    if (duration > 30000) {
      console.warn(`Slow query detected: ${duration}ms`);
    }
  }
}
```

## Troubleshooting

### Error: "prepared statement does not exist"

**Cause**: Library is using prepared statements in transaction mode.

**Solution**:
```typescript
// ❌ WRONG
const pool = new Pool({ connectionString: TRANSACTION_POOLER });

// ✅ CORRECT
const pool = new Pool({ 
  connectionString: TRANSACTION_POOLER,
  // Add library-specific option to disable prepared statements
});
```

### Error: "no more connections available"

**Cause**: Connection pool exhausted.

**Solutions**:
1. **Increase pool size**:
   ```typescript
   pool: { max: 10 }  // Increase from 5 to 10
   ```

2. **Reduce connection timeout**:
   ```typescript
   pool: { 
     idleTimeoutMillis: 3000,  // Reduce from 5000
     connectionTimeoutMillis: 3000
   }
   ```

3. **Check for connection leaks**:
   ```typescript
   // Always release connections
   const client = await pool.connect();
   try {
     await client.query(sql);
   } finally {
     client.release();  // CRITICAL!
   }
   ```

### Error: "connection timeout"

**Cause**: Network latency or database overload.

**Solutions**:
1. **Choose closer region**: Use pooler endpoint closest to your deployment
2. **Increase timeout**:
   ```typescript
   pool: { connectionTimeoutMillis: 10000 }
   ```
3. **Check database load**: Query `pg_stat_activity` for slow queries

### Error: "SSL connection error"

**Cause**: SSL/TLS configuration mismatch.

**Solution**:
```typescript
// For production
ssl: { rejectUnauthorized: true }

// For development/testing only
ssl: { rejectUnauthorized: false }

// Connection string parameter
postgresql://...?sslmode=require
```

### Warning: "statement timeout"

**Cause**: Query exceeded configured timeout.

**Solutions**:
1. **Optimize query**: Add indexes, reduce data
2. **Increase timeout** (if legitimate):
   ```typescript
   query: { statementTimeout: 60000 }  // 60 seconds
   ```
3. **Break into smaller queries**: Use pagination

### High Connection Churn

**Symptoms**: Many connections created/destroyed rapidly.

**Solutions**:
1. **Reuse client instances**: Initialize outside Lambda handler
2. **Increase idle timeout**:
   ```typescript
   pool: { idleTimeoutMillis: 10000 }
   ```
3. **Use keep-warm strategy**:
   ```typescript
   // Lambda: EventBridge rule to invoke every 5 minutes
   if (event.source === 'aws.events') {
     return { statusCode: 200, body: 'warmed' };
   }
   ```

## Best Practices

### 1. Environment Variable Configuration

Store connection string in environment variables:

```bash
# .env (DO NOT COMMIT)
SUPABASE_TRANSACTION_POOLER=postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

```typescript
// Use in code
const connectionString = process.env.SUPABASE_TRANSACTION_POOLER;
if (!connectionString) {
  throw new Error('SUPABASE_TRANSACTION_POOLER not configured');
}
```

### 2. Connection Pool Sizing

**Serverless Functions**:
- **Min**: 0 (scale to zero)
- **Max**: 3-5 connections
- **Reason**: Short-lived, auto-cleanup

**Edge Functions**:
- **Min**: 0 (minimal overhead)
- **Max**: 1-3 connections
- **Reason**: Very short execution time

### 3. Timeout Strategy

```typescript
// Tiered timeouts based on query type
const timeouts = {
  critical: {
    connection: 3000,
    statement: 5000
  },
  standard: {
    connection: 5000,
    statement: 30000
  },
  background: {
    connection: 10000,
    statement: 60000
  }
};
```

### 4. Error Handling

```typescript
async function safeQuery(sql: string, params: any[]) {
  const maxRetries = 3;
  let attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      return await pool.query(sql, params);
    } catch (error) {
      attempt++;
      
      // Retry on connection errors
      if (error.code === 'ECONNREFUSED' && attempt < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
        continue;
      }
      
      throw error;
    }
  }
}
```

### 5. Query Optimization

```typescript
// ✅ Use indexes
await supabase
  .from('users')
  .select('id, email')
  .eq('status', 'active')  // Ensure 'status' is indexed
  .limit(100);

// ✅ Use pagination
const PAGE_SIZE = 50;
await supabase
  .from('documents')
  .select('*')
  .range(0, PAGE_SIZE - 1);

// ❌ Avoid SELECT *
// ✅ Select only needed columns
await supabase
  .from('posts')
  .select('id, title, created_at');
```

### 6. Logging and Debugging

```typescript
// Structured logging
function logQuery(sql: string, duration: number, error?: Error) {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    type: 'database_query',
    sql: sql.substring(0, 100),  // Truncate for logs
    duration_ms: duration,
    success: !error,
    error: error?.message
  }));
}
```

### 7. Health Checks

```typescript
// Serverless health check
export async function healthHandler() {
  const client = await pool.connect();
  try {
    await client.query('SELECT 1');
    return {
      statusCode: 200,
      body: JSON.stringify({ status: 'healthy', pooler: 'transaction' })
    };
  } catch (error) {
    return {
      statusCode: 503,
      body: JSON.stringify({ status: 'unhealthy', error: error.message })
    };
  } finally {
    client.release();
  }
}
```

## Related Documentation

- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Server Configuration Templates](./MCP_SERVER_CONFIGURATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [MCP Authentication Strategies](./MCP_AUTHENTICATION.md)

## References

- [Supabase Connection Pooling](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)
- [Supavisor Documentation](https://supabase.com/docs/guides/database/supavisor)
- [PostgreSQL Connection Pooling](https://www.postgresql.org/docs/current/runtime-config-connection.html)
- [PgBouncer Transaction Pooling](https://www.pgbouncer.org/features.html)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0  
**Status**: ✅ Complete Documentation
