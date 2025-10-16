# MCP Dedicated Pooler Configuration

## Overview

This guide covers the configuration and optimization of dedicated PgBouncer connection poolers for high-performance AI agents running on Supabase paid tiers. Dedicated poolers provide isolated, co-located connection pooling resources for maximum performance and lowest latency.

## What is a Dedicated Pooler?

A dedicated pooler is a PgBouncer instance that runs co-located with your Supabase Postgres database, providing:

- **Isolated Resources**: Not shared with other projects
- **Lowest Latency**: Direct connection to database, no network hops
- **Dedicated Compute**: Allocated CPU and memory for your project
- **Optimal Performance**: Tuned for high-throughput AI workloads
- **Predictable Behavior**: No noisy neighbor issues

## When to Use Dedicated Pooler

### Ideal Use Cases

✅ **High-Performance AI Agents**
- Intensive workloads with many concurrent operations
- Production AI services with SLA requirements
- Real-time AI processing pipelines
- AI agents with strict latency requirements

✅ **Production Workloads**
- Mission-critical applications
- High-traffic AI services
- Enterprise deployments
- Applications requiring consistent performance

### Not Recommended For

❌ **Development/Testing**
- Use direct connection or Supavisor transaction mode instead
- Dedicated pooler incurs additional costs

❌ **Low-Volume Agents**
- Serverless/edge agents with sporadic access
- Use Supavisor transaction mode for better resource efficiency

❌ **Free Tier Projects**
- Dedicated pooler requires paid tier (Pro or Enterprise)

## Prerequisites

### 1. Paid Tier Subscription

Dedicated pooler is available on:
- **Pro Plan**: $25/month + compute costs
- **Enterprise Plan**: Custom pricing

Check your plan: https://app.supabase.com/project/[project-ref]/settings/billing

### 2. IPv6 or IPv4 Add-On

**IPv6 (Recommended)**
- Native support, no additional cost
- Best performance
- Required for direct database access

**IPv4 Add-On**
- Available if IPv6 is not possible
- Additional cost: $4/month per project
- Enable in Dashboard → Settings → Add-ons

### 3. Provisioning

Enable dedicated pooler in your Supabase Dashboard:

1. Navigate to: https://app.supabase.com/project/[project-ref]/settings/database
2. Scroll to "Connection Pooling" section
3. Click "Enable Dedicated Pooler"
4. Wait 2-5 minutes for provisioning
5. Dedicated pooler endpoint will appear

## Connection String Format

### Structure

```
postgresql://postgres.[project-ref]:[password]@db.[project-ref].supabase.co:6543/postgres
```

### Components

| Component | Description | Example |
|-----------|-------------|---------|
| `postgres` | Database username | `postgres` |
| `project-ref` | Your Supabase project reference ID | `apbkobhfnmcqqzqeeqss` |
| `password` | Your database password | `your-secure-password` |
| `db.[project-ref].supabase.co` | Dedicated pooler hostname | `db.apbkobhfnmcqqzqeeqss.supabase.co` |
| `6543` | Transaction mode port | `6543` |
| `postgres` | Database name | `postgres` |

### Example Connection Strings

**Basic Connection**
```bash
postgresql://postgres.apbkobhfnmcqqzqeeqss:mypassword@db.apbkobhfnmcqqzqeeqss.supabase.co:6543/postgres
```

**With SSL Mode**
```bash
postgresql://postgres.apbkobhfnmcqqzqeeqss:mypassword@db.apbkobhfnmcqqzqeeqss.supabase.co:6543/postgres?sslmode=require
```

**With Statement Timeout**
```bash
postgresql://postgres.apbkobhfnmcqqzqeeqss:mypassword@db.apbkobhfnmcqqzqeeqss.supabase.co:6543/postgres?statement_timeout=30000
```

## Important Constraints

### Transaction Mode Only

Dedicated pooler currently operates in **transaction mode**, which means:

❌ **No Prepared Statements**
- Prepared statements are not supported
- Use regular parameterized queries instead
- Disable prepared statements in your database client

❌ **No Session-Level Features**
- Temporary tables not persisted across queries
- Session variables reset after each transaction
- No advisory locks across transactions

✅ **Supported Features**
- Parameterized queries
- Transactions (single transaction per connection)
- All standard SQL operations
- Row Level Security (RLS)

### Configuration Flags Required

When connecting via dedicated pooler, **you must disable prepared statements**:

**Node.js (pg library)**
```javascript
{
  connectionString: process.env.SUPABASE_DEDICATED_POOLER,
  ssl: { rejectUnauthorized: true },
  // Disable prepared statements for transaction mode
  statement_cache_size: 0
}
```

**PostgreSQL connection string**
```bash
postgresql://...?prepared_statements=false
```

**MCP Server Args**
```json
{
  "args": [
    "--connection-string", "${SUPABASE_DEDICATED_POOLER}",
    "--disable-prepared-statements"
  ]
}
```

## Environment Variables

Add to your `.env` file:

```bash
# Dedicated Pooler Configuration
# Get from: Supabase Dashboard → Settings → Database → Connection Pooling
SUPABASE_DEDICATED_POOLER=postgresql://postgres.[project-ref]:[password]@db.[project-ref].supabase.co:6543/postgres

# Connection type indicator
DB_CONNECTION_TYPE=dedicated_pooler

# Pooler configuration
DEDICATED_POOLER_MODE=transaction
DEDICATED_POOLER_PORT=6543
DEDICATED_POOLER_ENABLED=true

# Disable prepared statements (required for transaction mode)
DISABLE_PREPARED_STATEMENTS=true

# Performance tuning
DB_POOL_MIN=10
DB_POOL_MAX=100
DB_POOL_IDLE_TIMEOUT=600000
DB_POOL_CONNECTION_TIMEOUT=10000
DB_POOL_ACQUIRE_TIMEOUT=30000

# Statement timeouts (milliseconds)
DB_STATEMENT_TIMEOUT=60000
DB_QUERY_TIMEOUT=60000
DB_IDLE_IN_TRANSACTION_TIMEOUT=300000
```

## MCP Server Configuration

### Full MCP Configuration

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "high_performance",
    "server": {
      "name": "dedicated-pooler-mcp",
      "port": 3000,
      "host": "0.0.0.0",
      "workers": 4
    },
    "database": {
      "connectionString": "${SUPABASE_DEDICATED_POOLER}",
      "connectionType": "dedicated_pooler",
      "pooler": {
        "mode": "transaction",
        "port": 6543,
        "dedicated": true,
        "disablePreparedStatements": true
      },
      "ssl": {
        "rejectUnauthorized": true,
        "ca": "${DB_SSL_CERT}"
      },
      "pool": {
        "min": 10,
        "max": 100,
        "idleTimeoutMillis": 600000,
        "connectionTimeoutMillis": 10000,
        "acquireTimeoutMillis": 30000,
        "queueLimit": 1000
      },
      "query": {
        "statementTimeout": 60000,
        "queryTimeout": 60000,
        "idleInTransactionSessionTimeout": 300000
      }
    },
    "security": {
      "authentication": {
        "method": "service_role",
        "serviceRoleKey": "${SUPABASE_SERVICE_ROLE_KEY}"
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 1000,
        "windowMs": 60000
      }
    },
    "monitoring": {
      "enabled": true,
      "metrics": {
        "port": 9090,
        "path": "/metrics",
        "detailed": true
      },
      "logging": {
        "level": "info",
        "format": "json",
        "auditQueries": true,
        "slowQueryThreshold": 1000
      },
      "alerts": {
        "enabled": true,
        "poolSaturation": 0.8,
        "errorRate": 0.05,
        "responseTime": 5000
      }
    },
    "optimization": {
      "connectionReuse": true,
      "preparedStatements": false,
      "queryCache": true,
      "parallelQueries": true
    }
  }
}
```

### Minimal MCP Configuration

```json
{
  "mcpServers": {
    "supabase-dedicated": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string", "${SUPABASE_DEDICATED_POOLER}",
        "--disable-prepared-statements"
      ],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_DEDICATED_POOLER}",
        "POOLER_TYPE": "dedicated",
        "DISABLE_PREPARED_STATEMENTS": "true"
      }
    }
  }
}
```

## Connection Pool Sizing Strategy

### Recommended Pool Sizes

**Small AI Agent (1-10 concurrent operations)**
```javascript
{
  min: 5,
  max: 20,
  idleTimeoutMillis: 300000
}
```

**Medium AI Agent (10-50 concurrent operations)**
```javascript
{
  min: 10,
  max: 50,
  idleTimeoutMillis: 600000
}
```

**Large AI Agent (50+ concurrent operations)**
```javascript
{
  min: 20,
  max: 100,
  idleTimeoutMillis: 600000
}
```

### Sizing Formula

```
pool.max = (concurrent_operations * 1.2) + buffer
pool.min = pool.max * 0.2
```

Where:
- `concurrent_operations`: Expected peak concurrent database operations
- `1.2`: Safety multiplier for spikes
- `buffer`: 5-10 connections for overhead

### Monitoring Pool Utilization

Track these metrics to optimize pool size:

```javascript
const metrics = {
  activeConnections: pool.totalCount - pool.idleCount,
  idleConnections: pool.idleCount,
  waitingClients: pool.waitingCount,
  utilizationRate: (pool.totalCount - pool.idleCount) / pool.totalCount
};

// Alert if utilization > 80%
if (metrics.utilizationRate > 0.8) {
  console.warn('Connection pool saturation detected');
}
```

## Performance Monitoring

### Key Metrics to Track

1. **Connection Metrics**
   - Active connections
   - Idle connections
   - Waiting clients
   - Connection acquisition time
   - Connection lifetime

2. **Query Metrics**
   - Query execution time (p50, p95, p99)
   - Queries per second
   - Error rate
   - Slow query count (>1s)

3. **Resource Metrics**
   - CPU usage
   - Memory usage
   - Network throughput
   - Disk I/O

### Monitoring Implementation

```javascript
// Prometheus metrics example
const prometheus = require('prom-client');

const connectionPoolSize = new prometheus.Gauge({
  name: 'db_connection_pool_size',
  help: 'Current connection pool size',
  labelNames: ['state']
});

const queryDuration = new prometheus.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Query execution duration',
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

// Update metrics
setInterval(() => {
  connectionPoolSize.set({ state: 'active' }, pool.totalCount - pool.idleCount);
  connectionPoolSize.set({ state: 'idle' }, pool.idleCount);
  connectionPoolSize.set({ state: 'waiting' }, pool.waitingCount);
}, 5000);
```

### Supabase Dashboard Monitoring

Monitor dedicated pooler performance in Dashboard:

1. Navigate to: https://app.supabase.com/project/[project-ref]/reports/database
2. View metrics:
   - Connection count over time
   - Query performance (p50, p95, p99)
   - Error rate
   - Active vs idle connections
3. Set up alerts for:
   - High connection usage (>80%)
   - Slow queries (>1s)
   - Connection errors

## Latency Tracking

### End-to-End Latency Breakdown

```
Total Latency = Network Latency + Connection Acquisition + Query Execution + Result Transfer
```

### Implementation Example

```javascript
class LatencyTracker {
  async trackQuery(queryFn) {
    const start = Date.now();
    const metrics = {};
    
    // Network latency (connection acquisition)
    const acquireStart = Date.now();
    const client = await pool.connect();
    metrics.connectionAcquisitionMs = Date.now() - acquireStart;
    
    try {
      // Query execution
      const queryStart = Date.now();
      const result = await client.query(queryFn);
      metrics.queryExecutionMs = Date.now() - queryStart;
      
      metrics.totalLatencyMs = Date.now() - start;
      metrics.resultSize = result.rows.length;
      
      // Log if latency exceeds threshold
      if (metrics.totalLatencyMs > 1000) {
        console.warn('High latency detected:', metrics);
      }
      
      return { result, metrics };
    } finally {
      client.release();
    }
  }
}

// Usage
const tracker = new LatencyTracker();
const { result, metrics } = await tracker.trackQuery('SELECT * FROM users');
console.log('Query metrics:', metrics);
```

### Expected Latency Ranges

**Dedicated Pooler (Ideal)**
- Connection acquisition: 1-5ms
- Simple query: 5-20ms
- Complex query: 50-500ms
- Total (simple): 10-30ms

**For Comparison**
- **Supavisor Transaction**: 20-50ms (simple query)
- **Supavisor Session**: 15-40ms (simple query)
- **Direct IPv6**: 10-30ms (similar to dedicated pooler)

## Cost-Benefit Analysis

### Dedicated Pooler vs Shared Pooler

| Feature | Dedicated Pooler | Supavisor (Shared) |
|---------|------------------|-------------------|
| **Latency** | Lowest (co-located) | Low (network hop) |
| **Throughput** | Highest | High |
| **Resources** | Dedicated | Shared |
| **Cost** | Paid tier + compute | Included in plan |
| **Isolation** | Complete | Shared with others |
| **Predictability** | High | Medium |
| **Setup Complexity** | Medium | Low |

### Cost Breakdown

**Dedicated Pooler Costs**
```
Base Cost: Pro Plan ($25/month)
+ Dedicated Pooler Compute: ~$10-50/month (based on usage)
+ IPv4 Add-on (optional): $4/month
= Total: $39-79/month minimum
```

**When Dedicated Pooler is Worth It**

✅ **High Value Scenarios**
- Serving 10,000+ AI requests per day
- Revenue-generating AI services
- Enterprise customers with SLA requirements
- Real-time AI applications (<100ms latency requirement)
- Applications where consistency is critical

❌ **Not Worth It**
- Hobby projects
- Development/testing
- Low-traffic applications (<1,000 requests/day)
- Cost-sensitive deployments

### ROI Calculation

```javascript
// Calculate ROI based on request volume and latency improvement

const monthlyRequests = 100000;
const avgLatencyImprovement = 15; // ms reduction vs Supavisor
const userTimeValue = 0.001; // $ per second of user time saved
const dedicatedPoolerCost = 50; // $/month

const timeSavedSeconds = (monthlyRequests * avgLatencyImprovement) / 1000;
const valueSaved = timeSavedSeconds * userTimeValue;
const roi = (valueSaved - dedicatedPoolerCost) / dedicatedPoolerCost;

console.log({
  timeSavedSeconds,
  valueSaved,
  roi: `${(roi * 100).toFixed(2)}%`,
  recommendation: roi > 0 ? 'Use dedicated pooler' : 'Use Supavisor'
});
```

## IPv6 and IPv4 Connectivity

### IPv6 Setup (Recommended)

**Check IPv6 Support**
```bash
# Test IPv6 connectivity to Supabase
ping6 db.[project-ref].supabase.co

# Test connection
psql "postgresql://postgres.[project-ref]:[password]@db.[project-ref].supabase.co:6543/postgres"
```

**Enable IPv6 on Your System**

**Linux**
```bash
# Check if IPv6 is enabled
ip -6 addr show

# Enable IPv6 if disabled
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
```

**macOS**
```bash
# Check IPv6 configuration
networksetup -getinfo "Wi-Fi"

# IPv6 is typically enabled by default
```

**Docker**
```yaml
# docker-compose.yml
version: '3'
services:
  app:
    image: your-app
    networks:
      - ipv6_network
    environment:
      - DATABASE_URL=${SUPABASE_DEDICATED_POOLER}

networks:
  ipv6_network:
    enable_ipv6: true
    ipam:
      config:
        - subnet: 2001:db8::/64
```

### IPv4 Add-On Setup

If IPv6 is not available:

1. Navigate to: https://app.supabase.com/project/[project-ref]/settings/addons
2. Enable "IPv4" add-on ($4/month)
3. Wait for provisioning (5-10 minutes)
4. Use the same connection string (auto-routes via IPv4)

**Verify IPv4 Connectivity**
```bash
# Test IPv4 connection
ping db.[project-ref].supabase.co

# Connect via IPv4
psql "postgresql://postgres.[project-ref]:[password]@db.[project-ref].supabase.co:6543/postgres"
```

## Code Examples

### Node.js with pg Library

```javascript
const { Pool } = require('pg');

// Dedicated pooler configuration
const pool = new Pool({
  connectionString: process.env.SUPABASE_DEDICATED_POOLER,
  ssl: {
    rejectUnauthorized: true
  },
  // Disable prepared statements for transaction mode
  statement_cache_size: 0,
  max: 50,
  min: 10,
  idleTimeoutMillis: 600000,
  connectionTimeoutMillis: 10000
});

// Query with metrics
async function queryWithMetrics(sql, params = []) {
  const start = Date.now();
  const client = await pool.connect();
  
  try {
    const result = await client.query(sql, params);
    const duration = Date.now() - start;
    
    console.log(`Query executed in ${duration}ms`);
    return result.rows;
  } catch (error) {
    console.error('Query failed:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Example usage
async function getUsers() {
  return queryWithMetrics(
    'SELECT id, email, created_at FROM profiles WHERE active = $1',
    [true]
  );
}
```

### Python with psycopg2

```python
import psycopg2
from psycopg2 import pool
import os
import time

# Create connection pool
connection_pool = psycopg2.pool.SimpleConnectionPool(
    10,  # min connections
    100,  # max connections
    os.environ['SUPABASE_DEDICATED_POOLER'],
    sslmode='require'
)

def query_with_metrics(sql, params=None):
    """Execute query with latency tracking"""
    start_time = time.time()
    conn = connection_pool.getconn()
    
    try:
        with conn.cursor() as cursor:
            # Note: Prepared statements automatically disabled in transaction mode
            cursor.execute(sql, params or [])
            result = cursor.fetchall()
            
            duration = (time.time() - start_time) * 1000
            print(f"Query executed in {duration:.2f}ms")
            
            return result
    finally:
        connection_pool.putconn(conn)

# Example usage
def get_users():
    return query_with_metrics(
        "SELECT id, email, created_at FROM profiles WHERE active = %s",
        [True]
    )
```

### Deno/Edge Function

```typescript
import { Pool } from "https://deno.land/x/postgres/mod.ts";

// Create pool for dedicated pooler
const pool = new Pool({
  connection: {
    connectionString: Deno.env.get("SUPABASE_DEDICATED_POOLER"),
  },
  max: 20,
  min: 5,
  idleTimeout: 300000
});

// Query function with error handling
async function executeQuery<T>(
  sql: string,
  params: any[] = []
): Promise<T[]> {
  const client = await pool.connect();
  
  try {
    const result = await client.queryObject<T>(sql, ...params);
    return result.rows;
  } catch (error) {
    console.error("Query error:", error);
    throw error;
  } finally {
    client.release();
  }
}

// Example: AI agent query
Deno.serve(async (req) => {
  try {
    const users = await executeQuery(
      "SELECT * FROM profiles WHERE active = $1",
      [true]
    );
    
    return new Response(JSON.stringify(users), {
      headers: { "Content-Type": "application/json" }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});
```

## Troubleshooting

### Common Issues

#### 1. "Prepared statement not supported"

**Symptom**: Error message about prepared statements in transaction mode

**Solution**: Disable prepared statements in your client:

```javascript
// Node.js pg
{ statement_cache_size: 0 }

// Connection string
postgresql://...?prepared_statements=false

// MCP server
--disable-prepared-statements
```

#### 2. "Connection timeout"

**Symptom**: Connections timing out or hanging

**Possible Causes**:
- IPv6 not available, IPv4 add-on not enabled
- Firewall blocking port 6543
- Incorrect connection string

**Solution**:
```bash
# Test connectivity
telnet db.[project-ref].supabase.co 6543

# Check IPv6
ping6 db.[project-ref].supabase.co

# Enable IPv4 add-on if needed
```

#### 3. "Too many connections"

**Symptom**: "FATAL: remaining connection slots are reserved"

**Possible Causes**:
- Pool size too large
- Connection leaks
- Multiple applications sharing database

**Solution**:
```javascript
// Reduce pool size
{ max: 20 }  // instead of 100

// Check for leaks
pool.on('error', (err) => {
  console.error('Unexpected pool error:', err);
});

// Monitor connections
console.log('Total:', pool.totalCount, 'Idle:', pool.idleCount);
```

#### 4. High Latency

**Symptom**: Queries taking longer than expected

**Possible Causes**:
- Query not optimized (missing indexes)
- Pool saturation
- Network issues
- Database under load

**Solution**:
```sql
-- Check slow queries
SELECT * FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Add indexes
CREATE INDEX idx_users_email ON users(email);

-- Check active connections
SELECT count(*) FROM pg_stat_activity;
```

### Diagnostics Checklist

When troubleshooting, verify:

- [ ] Dedicated pooler is enabled in Supabase Dashboard
- [ ] Using correct connection string (port 6543)
- [ ] Prepared statements are disabled
- [ ] IPv6 connectivity or IPv4 add-on enabled
- [ ] Firewall allows port 6543 outbound
- [ ] SSL/TLS is enabled
- [ ] Pool size is appropriate for workload
- [ ] No connection leaks in application
- [ ] Database password is correct
- [ ] Project is on paid tier

## Best Practices

### 1. Connection Management

✅ **DO**
- Use connection pooling
- Set appropriate pool sizes
- Monitor pool utilization
- Handle connection errors gracefully
- Release connections promptly

❌ **DON'T**
- Create new pools for each request
- Keep connections idle indefinitely
- Ignore connection errors
- Use unbounded pool sizes

### 2. Query Optimization

✅ **DO**
- Use parameterized queries
- Add appropriate indexes
- Monitor slow queries
- Batch operations when possible
- Use transactions for multiple operations

❌ **DON'T**
- Use prepared statements (not supported)
- Rely on session-level features
- Leave transactions open
- Execute N+1 queries

### 3. Error Handling

```javascript
async function resilientQuery(sql, params, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await pool.query(sql, params);
    } catch (error) {
      // Retry on transient errors
      if (error.code === 'ECONNRESET' && i < retries - 1) {
        await new Promise(resolve => setTimeout(resolve, 100 * (i + 1)));
        continue;
      }
      throw error;
    }
  }
}
```

### 4. Monitoring and Alerting

Set up alerts for:
- Pool utilization > 80%
- Query latency > 1s
- Error rate > 5%
- Connection failures
- Slow query threshold exceeded

## Migration Guide

### Migrating from Supavisor to Dedicated Pooler

**Step 1: Update Connection String**
```bash
# Old (Supavisor)
DATABASE_URL=postgresql://postgres.abc:pwd@aws-0-us-east-1.pooler.supabase.com:6543/postgres

# New (Dedicated Pooler)
SUPABASE_DEDICATED_POOLER=postgresql://postgres.abc:pwd@db.abc.supabase.co:6543/postgres
```

**Step 2: Disable Prepared Statements**
```javascript
// Add to your database configuration
{
  statement_cache_size: 0
}
```

**Step 3: Test in Staging**
```bash
# Test connection
psql $SUPABASE_DEDICATED_POOLER -c "SELECT version();"

# Load test
npm run load-test -- --connection-string=$SUPABASE_DEDICATED_POOLER
```

**Step 4: Monitor After Deployment**
- Watch latency metrics for 24-48 hours
- Compare performance before/after
- Adjust pool sizes if needed

## Related Documentation

- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Server Configuration](./MCP_SERVER_CONFIGURATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [MCP Authentication Strategies](./MCP_AUTHENTICATION.md)
- [Supabase Connection Pooling Docs](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)

## Support

For issues with dedicated pooler:

1. Check [Supabase Status](https://status.supabase.com)
2. Review [Troubleshooting](#troubleshooting) section above
3. Post in [GitHub Discussions](https://github.com/supabase/supabase/discussions)
4. Contact [Supabase Support](https://supabase.com/dashboard/support) (Pro/Enterprise)

---

**Last Updated**: 2025-01-09
**Version**: 1.0.0
**Status**: ✅ Initial Release
