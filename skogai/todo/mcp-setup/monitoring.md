# MCP Server Monitoring and Observability Guide

## Overview

Effective monitoring is essential for maintaining reliable MCP server connections to Supabase. This guide covers connection monitoring, performance metrics, alerting, and troubleshooting using observability data.

## Monitoring Categories

1. **Connection Health** - Active connections, pool status, connection errors
2. **Query Performance** - Query execution time, slow queries, failed queries
3. **Resource Usage** - CPU, memory, connection pool utilization
4. **Security Events** - Failed authentication, SSL errors, rate limiting
5. **Application Metrics** - Request rate, error rate, latency

## Connection Monitoring

### Monitor Active Connections

**SQL Query:**
```sql
-- Current connection count
SELECT 
  count(*) as active_connections,
  max(max_conn) as connection_limit,
  round(100.0 * count(*) / max(max_conn), 2) as percent_used
FROM pg_stat_activity, 
     (SELECT setting::int as max_conn FROM pg_settings WHERE name = 'max_connections') mc
WHERE datname = 'postgres';

-- Connections by state
SELECT 
  state,
  count(*) as count,
  round(100.0 * count(*) / sum(count(*)) OVER (), 2) as percentage
FROM pg_stat_activity
WHERE datname = 'postgres'
GROUP BY state
ORDER BY count DESC;

-- Connections by application
SELECT 
  application_name,
  count(*) as connections,
  string_agg(DISTINCT state, ', ') as states
FROM pg_stat_activity
WHERE datname = 'postgres'
GROUP BY application_name
ORDER BY connections DESC;
```

### Monitor Connection Pool

**Node.js (pg):**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Monitor pool metrics
setInterval(() => {
  console.log({
    totalCount: pool.totalCount,
    idleCount: pool.idleCount,
    waitingCount: pool.waitingCount,
    // Pool health indicator
    poolUtilization: ((pool.totalCount - pool.idleCount) / pool.options.max * 100).toFixed(2) + '%'
  });
}, 60000); // Every minute

// Monitor pool events
pool.on('connect', (client) => {
  console.log('Client connected to pool');
});

pool.on('acquire', (client) => {
  console.log('Client acquired from pool');
});

pool.on('error', (err, client) => {
  console.error('Pool error:', err);
  // Send to monitoring service
});

pool.on('remove', (client) => {
  console.log('Client removed from pool');
});
```

**Python (SQLAlchemy):**
```python
from sqlalchemy import create_engine, event
from sqlalchemy.pool import QueuePool

engine = create_engine(
    os.environ['DATABASE_URL'],
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    echo_pool=True  # Enable pool logging
)

@event.listens_for(engine, "connect")
def receive_connect(dbapi_conn, connection_record):
    print("Connection established")

@event.listens_for(engine, "checkout")
def receive_checkout(dbapi_conn, connection_record, connection_proxy):
    print("Connection checked out from pool")

# Check pool status
pool_status = engine.pool.status()
print(pool_status)
```

### Connection Leak Detection

**Node.js:**
```javascript
// Track client checkout duration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const activeClients = new Map();

pool.on('acquire', (client) => {
  activeClients.set(client, Date.now());
});

pool.on('release', (client) => {
  const checkoutTime = activeClients.get(client);
  if (checkoutTime) {
    const duration = Date.now() - checkoutTime;
    if (duration > 30000) {  // Held for >30 seconds
      console.warn(`Client held for ${duration}ms - possible leak`);
    }
    activeClients.delete(client);
  }
});

// Periodic leak check
setInterval(() => {
  const now = Date.now();
  activeClients.forEach((checkoutTime, client) => {
    const duration = now - checkoutTime;
    if (duration > 60000) {  // Held for >1 minute
      console.error(`Client leak detected! Held for ${duration}ms`);
      // Alert monitoring system
    }
  });
}, 30000);
```

**SQL Query:**
```sql
-- Find long-running connections
SELECT 
  pid,
  usename,
  application_name,
  client_addr,
  state,
  NOW() - state_change AS duration,
  query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
AND NOW() - state_change > interval '5 minutes'
ORDER BY duration DESC;
```

## Query Performance Monitoring

### Enable Query Statistics

**PostgreSQL Configuration:**
```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verify it's enabled
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';
```

### Monitor Slow Queries

**SQL Query:**
```sql
-- Top 10 slowest queries (by average time)
SELECT 
  round(mean_exec_time::numeric, 2) as avg_time_ms,
  calls,
  round(total_exec_time::numeric, 2) as total_time_ms,
  round((100.0 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 2) as percent_total,
  query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'postgres')
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Queries with most calls
SELECT 
  calls,
  round(mean_exec_time::numeric, 2) as avg_time_ms,
  round(total_exec_time::numeric, 2) as total_time_ms,
  query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'postgres')
ORDER BY calls DESC
LIMIT 10;

-- Queries consuming most total time
SELECT 
  round(total_exec_time::numeric, 2) as total_time_ms,
  calls,
  round(mean_exec_time::numeric, 2) as avg_time_ms,
  round((100.0 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 2) as percent_total,
  query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'postgres')
ORDER BY total_exec_time DESC
LIMIT 10;
```

### Application-Level Query Monitoring

**Node.js with Logging:**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Wrap query method to add monitoring
const originalQuery = pool.query.bind(pool);
pool.query = function(...args) {
  const start = Date.now();
  const query = args[0];
  
  return originalQuery(...args)
    .then(result => {
      const duration = Date.now() - start;
      
      // Log slow queries
      if (duration > 1000) {
        console.warn({
          type: 'slow_query',
          duration_ms: duration,
          query: query.text || query,
          rows: result.rowCount
        });
      }
      
      // Send metrics to monitoring service
      recordQueryMetric({
        duration,
        success: true,
        rows: result.rowCount
      });
      
      return result;
    })
    .catch(error => {
      const duration = Date.now() - start;
      
      console.error({
        type: 'query_error',
        duration_ms: duration,
        query: query.text || query,
        error: error.message
      });
      
      recordQueryMetric({
        duration,
        success: false,
        error: error.message
      });
      
      throw error;
    });
};

function recordQueryMetric(data) {
  // Send to monitoring service (Prometheus, DataDog, etc.)
  // Example: metrics.histogram('db_query_duration', data.duration);
}
```

## SSL Connection Monitoring

**Check SSL Status:**
```sql
-- View SSL connections
SELECT 
  pid,
  usename,
  application_name,
  client_addr,
  ssl,
  version as ssl_version,
  cipher as ssl_cipher,
  bits as ssl_bits
FROM pg_stat_ssl
JOIN pg_stat_activity USING (pid)
WHERE datname = 'postgres'
ORDER BY pid;

-- SSL connection summary
SELECT 
  ssl,
  count(*) as connection_count,
  array_agg(DISTINCT version) as ssl_versions
FROM pg_stat_ssl
JOIN pg_stat_activity USING (pid)
WHERE datname = 'postgres'
GROUP BY ssl;
```

**Monitor SSL Errors:**
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync(process.env.SSL_CERT_PATH).toString()
  }
});

pool.on('error', (err, client) => {
  if (err.message.includes('SSL') || err.message.includes('certificate')) {
    console.error({
      type: 'ssl_error',
      message: err.message,
      code: err.code,
      timestamp: new Date().toISOString()
    });
    // Alert security team
  }
});
```

## Resource Usage Monitoring

### Database Resource Monitoring

**SQL Queries:**
```sql
-- Database size
SELECT 
  pg_database.datname,
  pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
WHERE datname = 'postgres';

-- Table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Cache hit ratio
SELECT 
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit) as heap_hit,
  round(sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100, 2) as cache_hit_ratio
FROM pg_statio_user_tables;

-- Index usage
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

### Application Resource Monitoring

**Node.js:**
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Monitor memory usage
setInterval(() => {
  const memUsage = process.memoryUsage();
  console.log({
    rss: Math.round(memUsage.rss / 1024 / 1024) + ' MB',
    heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + ' MB',
    heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + ' MB',
    external: Math.round(memUsage.external / 1024 / 1024) + ' MB',
    poolSize: {
      total: pool.totalCount,
      idle: pool.idleCount,
      waiting: pool.waitingCount
    }
  });
}, 60000);
```

## Alerting and Notifications

### Connection Pool Saturation Alert

```javascript
const POOL_SATURATION_THRESHOLD = 0.8; // 80%

setInterval(() => {
  const utilization = (pool.totalCount - pool.idleCount) / pool.options.max;
  
  if (utilization > POOL_SATURATION_THRESHOLD) {
    sendAlert({
      severity: 'warning',
      message: `Connection pool ${(utilization * 100).toFixed(2)}% utilized`,
      poolStats: {
        total: pool.totalCount,
        idle: pool.idleCount,
        waiting: pool.waitingCount,
        max: pool.options.max
      }
    });
  }
}, 30000); // Check every 30 seconds
```

### Error Rate Alert

```javascript
let errorCount = 0;
let queryCount = 0;
const ERROR_RATE_THRESHOLD = 0.05; // 5%

pool.on('error', (err) => {
  errorCount++;
});

setInterval(() => {
  const errorRate = queryCount > 0 ? errorCount / queryCount : 0;
  
  if (errorRate > ERROR_RATE_THRESHOLD) {
    sendAlert({
      severity: 'critical',
      message: `High error rate: ${(errorRate * 100).toFixed(2)}%`,
      errors: errorCount,
      total: queryCount
    });
  }
  
  // Reset counters
  errorCount = 0;
  queryCount = 0;
}, 60000); // Check every minute
```

### Slow Query Alert

```javascript
const SLOW_QUERY_THRESHOLD = 5000; // 5 seconds

pool.query = function(...args) {
  const start = Date.now();
  
  return originalQuery(...args)
    .then(result => {
      const duration = Date.now() - start;
      
      if (duration > SLOW_QUERY_THRESHOLD) {
        sendAlert({
          severity: 'warning',
          message: 'Slow query detected',
          duration_ms: duration,
          query: args[0]
        });
      }
      
      return result;
    });
};
```

## Integration with Monitoring Services

### Prometheus Metrics

```javascript
const prometheus = require('prom-client');

// Create metrics
const poolSize = new prometheus.Gauge({
  name: 'db_pool_size',
  help: 'Current database connection pool size'
});

const poolIdle = new prometheus.Gauge({
  name: 'db_pool_idle',
  help: 'Number of idle connections in pool'
});

const poolWaiting = new prometheus.Gauge({
  name: 'db_pool_waiting',
  help: 'Number of waiting requests for connections'
});

const queryDuration = new prometheus.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Database query duration in seconds',
  buckets: [0.001, 0.01, 0.1, 0.5, 1, 2, 5]
});

const queryErrors = new prometheus.Counter({
  name: 'db_query_errors_total',
  help: 'Total number of database query errors'
});

// Update metrics
setInterval(() => {
  poolSize.set(pool.totalCount);
  poolIdle.set(pool.idleCount);
  poolWaiting.set(pool.waitingCount);
}, 5000);

// Expose metrics endpoint
const express = require('express');
const app = express();

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', prometheus.register.contentType);
  res.end(await prometheus.register.metrics());
});

app.listen(9090);
```

### DataDog Integration

```javascript
const StatsD = require('hot-shots');
const dogstatsd = new StatsD();

// Track pool metrics
setInterval(() => {
  dogstatsd.gauge('db.pool.size', pool.totalCount);
  dogstatsd.gauge('db.pool.idle', pool.idleCount);
  dogstatsd.gauge('db.pool.waiting', pool.waitingCount);
  dogstatsd.gauge('db.pool.utilization', 
    (pool.totalCount - pool.idleCount) / pool.options.max * 100
  );
}, 10000);

// Track query metrics
const originalQuery = pool.query.bind(pool);
pool.query = function(...args) {
  const start = Date.now();
  
  return originalQuery(...args)
    .then(result => {
      const duration = Date.now() - start;
      dogstatsd.histogram('db.query.duration', duration);
      dogstatsd.increment('db.query.success');
      return result;
    })
    .catch(error => {
      const duration = Date.now() - start;
      dogstatsd.histogram('db.query.duration', duration);
      dogstatsd.increment('db.query.error');
      throw error;
    });
};
```

### CloudWatch Integration (AWS)

```javascript
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

async function publishMetrics() {
  const params = {
    Namespace: 'MCP/Database',
    MetricData: [
      {
        MetricName: 'PoolSize',
        Value: pool.totalCount,
        Unit: 'Count',
        Timestamp: new Date()
      },
      {
        MetricName: 'IdleConnections',
        Value: pool.idleCount,
        Unit: 'Count',
        Timestamp: new Date()
      },
      {
        MetricName: 'PoolUtilization',
        Value: (pool.totalCount - pool.idleCount) / pool.options.max * 100,
        Unit: 'Percent',
        Timestamp: new Date()
      }
    ]
  };
  
  await cloudwatch.putMetricData(params).promise();
}

setInterval(publishMetrics, 60000); // Every minute
```

## Logging Best Practices

### Structured Logging

**Node.js with Winston:**
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'database.log' })
  ]
});

// Log connection events
pool.on('connect', () => {
  logger.info({
    event: 'pool_connect',
    pool: {
      total: pool.totalCount,
      idle: pool.idleCount
    }
  });
});

pool.on('error', (err) => {
  logger.error({
    event: 'pool_error',
    error: {
      message: err.message,
      code: err.code,
      stack: err.stack
    }
  });
});
```

### Query Logging

```javascript
// Log all queries in development
if (process.env.NODE_ENV === 'development') {
  pool.on('query', (query) => {
    logger.debug({
      event: 'query',
      sql: query.text,
      params: query.values
    });
  });
}

// Always log slow queries
const originalQuery = pool.query.bind(pool);
pool.query = function(...args) {
  const start = Date.now();
  const query = args[0];
  
  return originalQuery(...args)
    .then(result => {
      const duration = Date.now() - start;
      
      if (duration > 1000) {
        logger.warn({
          event: 'slow_query',
          duration_ms: duration,
          query: query.text || query,
          rows: result.rowCount
        });
      }
      
      return result;
    });
};
```

## Health Check Endpoint

```javascript
const express = require('express');
const app = express();

app.get('/health', async (req, res) => {
  try {
    // Test database connectivity
    const result = await pool.query('SELECT 1');
    
    // Check pool health
    const poolHealth = {
      total: pool.totalCount,
      idle: pool.idleCount,
      waiting: pool.waitingCount,
      utilization: ((pool.totalCount - pool.idleCount) / pool.options.max * 100).toFixed(2) + '%'
    };
    
    // Determine health status
    const isHealthy = 
      result.rows[0]['?column?'] === 1 &&
      poolHealth.waiting === 0 &&
      (pool.totalCount - pool.idleCount) / pool.options.max < 0.9;
    
    res.status(isHealthy ? 200 : 503).json({
      status: isHealthy ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      database: {
        connected: true,
        responsive: true
      },
      pool: poolHealth
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

app.listen(3000);
```

## Dashboard Queries

### Supabase Dashboard SQL Queries

Save these queries in Supabase Dashboard → SQL Editor for quick monitoring:

**1. Connection Overview:**
```sql
SELECT 
  count(*) FILTER (WHERE state = 'active') as active,
  count(*) FILTER (WHERE state = 'idle') as idle,
  count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
  count(*) as total,
  max(max_conn) as connection_limit
FROM pg_stat_activity, 
     (SELECT setting::int as max_conn FROM pg_settings WHERE name = 'max_connections') mc
WHERE datname = 'postgres';
```

**2. Application Connections:**
```sql
SELECT 
  application_name,
  count(*) as connections,
  string_agg(DISTINCT state, ', ') as states,
  max(NOW() - state_change) as max_idle_time
FROM pg_stat_activity
WHERE datname = 'postgres'
GROUP BY application_name
ORDER BY connections DESC;
```

**3. Query Performance:**
```sql
SELECT 
  round(mean_exec_time::numeric, 2) as avg_ms,
  calls,
  query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'postgres')
ORDER BY mean_exec_time DESC
LIMIT 5;
```

## Next Steps

- **Quick Start**: [Getting Started](./quickstart.md)
- **Troubleshooting**: [Common Issues](./troubleshooting.md)
- **Configuration**: [Configuration Templates](./configuration-templates.md)
- **SSL Setup**: [SSL Configuration](./ssl-setup.md)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0
