# MCP Connection Monitoring and Health Checks

## Overview

This document provides comprehensive guidance for monitoring AI agent database connections, implementing health checks, and troubleshooting connection issues in Supabase MCP server environments.

## Table of Contents

- [Health Check Functions](#health-check-functions)
- [Monitoring Queries](#monitoring-queries)
- [Connection Metrics](#connection-metrics)
- [Dashboard Integration](#dashboard-integration)
- [Alerting Configuration](#alerting-configuration)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Best Practices](#best-practices)
- [Grafana Integration](#grafana-integration)

## Health Check Functions

### 1. Database Health Check

The `check_database_health()` function provides a comprehensive health status of the database.

```sql
SELECT * FROM check_database_health();
```

**Returns:**
- `healthy` (BOOLEAN): Overall health status (true if usage < 90%)
- `total_connections` (INTEGER): Current number of connections
- `max_connections` (INTEGER): Maximum allowed connections
- `usage_percent` (NUMERIC): Connection usage percentage
- `active_connections` (INTEGER): Currently executing queries
- `idle_connections` (INTEGER): Idle connections in pool
- `idle_in_transaction` (INTEGER): Connections idle within transaction
- `oldest_connection_age` (INTERVAL): Age of oldest connection
- `check_timestamp` (TIMESTAMPTZ): When the check was performed

**Example Output:**
```
 healthy | total_connections | max_connections | usage_percent | active_connections | idle_connections | idle_in_transaction | oldest_connection_age | check_timestamp
---------+-------------------+-----------------+---------------+--------------------+------------------+---------------------+-----------------------+-------------------
 t       | 15                | 100             | 15.00         | 3                  | 12               | 0                   | 02:15:30              | 2025-10-07 10:40:08
```

### 2. Connection Limit Checks

The `check_connection_limits()` function monitors connection usage against configured limits.

```sql
SELECT * FROM check_connection_limits();
```

**Returns:**
- `within_limits` (BOOLEAN): Whether usage is within safe limits (< 90%)
- `total_connections` (INTEGER): Current connections
- `max_connections` (INTEGER): Maximum allowed
- `usage_percent` (NUMERIC): Usage percentage
- `warning_threshold_reached` (BOOLEAN): True if usage >= 70%
- `critical_threshold_reached` (BOOLEAN): True if usage >= 90%
- `recommended_action` (TEXT): Actionable recommendations

**Thresholds:**
- **OK**: < 70% usage
- **WARNING**: 70-89% usage - Monitor closely
- **CRITICAL**: >= 90% usage - Immediate action required

### 3. Connection Pool Metrics

Get detailed metrics about connection pool state:

```sql
SELECT * FROM get_connection_pool_metrics();
```

**Returns:**
- Connection counts by state (active, idle, waiting, etc.)
- Pool utilization metrics
- Transaction state breakdown

## Monitoring Queries

### Count Connections by AI Agent

Track which AI agents are consuming connections:

```sql
SELECT * FROM get_ai_agent_connections()
ORDER BY connection_count DESC;
```

**Returns:**
- `application_name`: AI agent identifier
- `user_name`: Database user
- `connection_count`: Number of connections
- `active_queries`: Currently executing queries
- `avg_connection_age`: Average connection age
- `oldest_connection_age`: Oldest connection
- `newest_connection_age`: Newest connection
- `ssl_connections`: SSL-enabled connection count
- `client_addresses`: Array of client IPs

**Example:**
```sql
-- Find AI agents with most connections
SELECT 
    application_name,
    connection_count,
    active_queries,
    ROUND(EXTRACT(epoch FROM avg_connection_age) / 60, 2) as avg_age_minutes
FROM get_ai_agent_connections()
WHERE connection_count > 5
ORDER BY connection_count DESC;
```

### View All Active Connections

Get detailed information about all active connections:

```sql
SELECT 
    sa.pid,
    ssl.ssl as ssl_connection,
    sa.datname as database,
    sa.usename as connected_role,
    sa.application_name,
    sa.client_addr,
    sa.state,
    sa.backend_start,
    NOW() - sa.backend_start as connection_age,
    sa.query_start,
    CASE 
        WHEN sa.query_start IS NOT NULL 
        THEN NOW() - sa.query_start 
        ELSE NULL 
    END as query_duration,
    LEFT(sa.query, 100) as current_query
FROM pg_stat_ssl ssl
JOIN pg_stat_activity sa ON ssl.pid = sa.pid
WHERE sa.pid != pg_backend_pid()
ORDER BY sa.backend_start;
```

### Connection Statistics by User and Application

```sql
SELECT * FROM get_connection_stats()
ORDER BY connection_count DESC
LIMIT 20;
```

### Long-Running Connections

Find connections that have been open for an extended period:

```sql
-- Connections older than 1 hour
SELECT * FROM get_long_running_connections(60);

-- Connections older than 30 minutes
SELECT * FROM get_long_running_connections(30);
```

### Connections by Client Address

Group connections by originating IP address:

```sql
SELECT * FROM get_connection_by_client_address()
ORDER BY connection_count DESC;
```

**Use Cases:**
- Identify which servers/agents are connecting
- Detect unusual connection patterns
- Verify network routing
- Security auditing

## Connection Metrics

### Real-Time Connection Tracking

Monitor connections in real-time with this query:

```sql
-- Live connection dashboard
SELECT 
    COUNT(*) FILTER (WHERE state = 'active') as active,
    COUNT(*) FILTER (WHERE state = 'idle') as idle,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_tx,
    COUNT(*) as total,
    ROUND((COUNT(*)::NUMERIC / 
        (SELECT setting::NUMERIC FROM pg_settings WHERE name = 'max_connections') * 100
    ), 2) as usage_percent
FROM pg_stat_activity
WHERE pid != pg_backend_pid();
```

### Connection Trends Over Time

Create a monitoring table to track connection history:

```sql
-- Create monitoring log table
CREATE TABLE IF NOT EXISTS connection_monitoring_log (
    id BIGSERIAL PRIMARY KEY,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    total_connections INTEGER,
    active_connections INTEGER,
    idle_connections INTEGER,
    max_connections INTEGER,
    usage_percent NUMERIC,
    ai_agent_count INTEGER
);

-- Insert current metrics (run periodically via cron or scheduled job)
INSERT INTO connection_monitoring_log (
    total_connections,
    active_connections,
    idle_connections,
    max_connections,
    usage_percent,
    ai_agent_count
)
SELECT 
    total_connections,
    active_connections,
    idle_connections,
    max_connections,
    usage_percent,
    (SELECT COUNT(DISTINCT application_name) FROM pg_stat_activity WHERE application_name IS NOT NULL)
FROM check_database_health();

-- Query trends
SELECT 
    date_trunc('hour', recorded_at) as hour,
    AVG(usage_percent) as avg_usage,
    MAX(total_connections) as peak_connections,
    AVG(ai_agent_count) as avg_agents
FROM connection_monitoring_log
WHERE recorded_at > NOW() - INTERVAL '24 hours'
GROUP BY date_trunc('hour', recorded_at)
ORDER BY hour DESC;
```

### Connection Limits Formula

Understanding the total backend load on PostgreSQL:

```
Total backend load = 
    Direct connections +
    Supavisor backend (≤ supavisor_pool_size) +
    PgBouncer backend (≤ pgbouncer_pool_size)
≤ Postgres max_connections
```

**Query to check:**
```sql
SELECT 
    (SELECT setting::INTEGER FROM pg_settings WHERE name = 'max_connections') as max_connections,
    COUNT(*) as current_connections,
    COUNT(*) FILTER (WHERE application_name LIKE '%supavisor%') as supavisor_connections,
    COUNT(*) FILTER (WHERE application_name LIKE '%pgbouncer%') as pgbouncer_connections,
    COUNT(*) FILTER (WHERE application_name NOT LIKE '%supavisor%' 
                      AND application_name NOT LIKE '%pgbouncer%') as direct_connections
FROM pg_stat_activity
WHERE pid != pg_backend_pid();
```

## Dashboard Integration

### Supabase Studio Dashboard Queries

Add these queries to your monitoring dashboard:

**1. Database Connections Summary**
```sql
SELECT 
    'Total Active' as metric,
    COUNT(*) as value
FROM pg_stat_activity
WHERE state != 'idle' AND pid != pg_backend_pid()
UNION ALL
SELECT 
    'Total Idle' as metric,
    COUNT(*) as value
FROM pg_stat_activity
WHERE state = 'idle' AND pid != pg_backend_pid()
UNION ALL
SELECT 
    'Total Connections' as metric,
    COUNT(*) as value
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
UNION ALL
SELECT 
    'Connection Usage %' as metric,
    ROUND((COUNT(*)::NUMERIC / 
        (SELECT setting::NUMERIC FROM pg_settings WHERE name = 'max_connections') * 100
    ), 2) as value
FROM pg_stat_activity
WHERE pid != pg_backend_pid();
```

**2. Dedicated Pooler Client Connections**
```sql
SELECT 
    application_name,
    COUNT(*) as connections,
    COUNT(*) FILTER (WHERE state = 'active') as active,
    COUNT(*) FILTER (WHERE state = 'idle') as idle
FROM pg_stat_activity
WHERE application_name LIKE '%pgbouncer%'
  AND pid != pg_backend_pid()
GROUP BY application_name;
```

**3. Supavisor Client Connections**
```sql
SELECT 
    application_name,
    usename,
    COUNT(*) as connections,
    state,
    client_addr
FROM pg_stat_activity
WHERE application_name LIKE '%supavisor%'
  AND pid != pg_backend_pid()
GROUP BY application_name, usename, state, client_addr
ORDER BY COUNT(*) DESC;
```

## Alerting Configuration

### Connection Limit Alerts

Set up automated alerting based on connection thresholds:

```sql
-- Check if alerting is needed
DO $$
DECLARE
    limit_check RECORD;
BEGIN
    SELECT * INTO limit_check FROM check_connection_limits();
    
    IF limit_check.critical_threshold_reached THEN
        -- CRITICAL: Send immediate alert
        RAISE WARNING 'CRITICAL: Connection usage at %% (%)/%)',
            limit_check.usage_percent,
            limit_check.total_connections,
            limit_check.max_connections;
        -- Integrate with your alerting system (email, Slack, PagerDuty)
    ELSIF limit_check.warning_threshold_reached THEN
        -- WARNING: Send notification
        RAISE NOTICE 'WARNING: Connection usage at %% (%)/%)',
            limit_check.usage_percent,
            limit_check.total_connections,
            limit_check.max_connections;
    END IF;
END $$;
```

### Alert Conditions

**Critical Alerts (Immediate Action Required):**
- Connection usage >= 90%
- Idle in transaction > 50 connections
- Long-running connections > 6 hours
- Sudden connection spike (> 50 new connections in 1 minute)

**Warning Alerts (Monitor Closely):**
- Connection usage >= 70%
- Idle in transaction > 20 connections
- Long-running connections > 2 hours
- High number of waiting connections

### Integration Examples

**PostgreSQL NOTIFY for Real-Time Alerts:**
```sql
CREATE OR REPLACE FUNCTION notify_connection_alert()
RETURNS void AS $$
DECLARE
    health RECORD;
BEGIN
    SELECT * INTO health FROM check_database_health();
    
    IF NOT health.healthy THEN
        PERFORM pg_notify(
            'connection_alert',
            json_build_object(
                'level', 'critical',
                'usage_percent', health.usage_percent,
                'total_connections', health.total_connections,
                'max_connections', health.max_connections,
                'timestamp', health.check_timestamp
            )::text
        );
    END IF;
END;
$$ LANGUAGE plpgsql;
```

## Troubleshooting Guide

### Common Connection Issues

#### Issue 1: Connection Limit Reached

**Symptoms:**
- Error: "FATAL: remaining connection slots are reserved"
- Applications unable to connect
- Health check shows usage >= 100%

**Diagnosis:**
```sql
SELECT * FROM check_connection_limits();
SELECT * FROM get_ai_agent_connections();
```

**Solutions:**
1. **Increase max_connections:**
   ```sql
   -- Requires superuser and server restart
   ALTER SYSTEM SET max_connections = 200;
   -- Then restart PostgreSQL
   ```

2. **Close idle connections:**
   ```sql
   -- Terminate idle connections older than 1 hour
   SELECT pg_terminate_backend(pid)
   FROM pg_stat_activity
   WHERE state = 'idle'
     AND NOW() - state_change > INTERVAL '1 hour'
     AND pid != pg_backend_pid();
   ```

3. **Use connection pooling:**
   - Implement PgBouncer or Supavisor
   - Use transaction mode for serverless agents
   - Configure appropriate pool sizes

#### Issue 2: Idle in Transaction Connections

**Symptoms:**
- Many connections in "idle in transaction" state
- Locks not released
- Performance degradation

**Diagnosis:**
```sql
SELECT 
    pid,
    usename,
    application_name,
    NOW() - state_change as idle_duration,
    query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
ORDER BY state_change;
```

**Solutions:**
```sql
-- Set idle_in_transaction_session_timeout
ALTER DATABASE postgres SET idle_in_transaction_session_timeout = '10min';

-- Terminate long idle in transaction connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state LIKE '%idle in transaction%'
  AND NOW() - state_change > INTERVAL '5 minutes'
  AND pid != pg_backend_pid();
```

#### Issue 3: Too Many Connections from Single Agent

**Symptoms:**
- One AI agent consuming excessive connections
- Other agents unable to connect

**Diagnosis:**
```sql
SELECT * FROM get_ai_agent_connections()
WHERE connection_count > 20
ORDER BY connection_count DESC;
```

**Solutions:**
1. **Reduce agent pool size** in MCP server configuration
2. **Use connection pooling** at agent level
3. **Implement connection limits** per application:
   ```sql
   ALTER ROLE ai_agent_user CONNECTION LIMIT 10;
   ```

#### Issue 4: Long-Running Connections

**Symptoms:**
- Connections open for hours or days
- Resource exhaustion
- Memory leaks

**Diagnosis:**
```sql
SELECT * FROM get_long_running_connections(120); -- 2 hours
```

**Solutions:**
```sql
-- Terminate connections older than 12 hours
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE NOW() - backend_start > INTERVAL '12 hours'
  AND pid != pg_backend_pid()
  AND application_name != 'critical_app'; -- Exclude critical apps
```

### Diagnostic Queries

**Check for Connection Leaks:**
```sql
SELECT 
    application_name,
    COUNT(*) as connections,
    MIN(backend_start) as oldest_connection,
    NOW() - MIN(backend_start) as age_of_oldest
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY application_name
HAVING COUNT(*) > 10
   OR NOW() - MIN(backend_start) > INTERVAL '4 hours'
ORDER BY COUNT(*) DESC;
```

**Identify Problematic Queries:**
```sql
SELECT 
    pid,
    NOW() - query_start as duration,
    usename,
    application_name,
    state,
    LEFT(query, 200) as query_preview
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start IS NOT NULL
  AND NOW() - query_start > INTERVAL '30 seconds'
  AND pid != pg_backend_pid()
ORDER BY query_start;
```

**Connection Churn Rate:**
```sql
SELECT 
    datname,
    usename,
    COUNT(*) as connection_attempts,
    SUM(CASE WHEN state = 'active' THEN 1 ELSE 0 END) as active_now
FROM pg_stat_activity
WHERE backend_start > NOW() - INTERVAL '5 minutes'
GROUP BY datname, usename
HAVING COUNT(*) > 100
ORDER BY COUNT(*) DESC;
```

## Best Practices

### 1. Regular Health Checks

**Implement periodic health checks:**
```javascript
// Node.js example for MCP server
async function periodicHealthCheck() {
    try {
        const health = await pool.query('SELECT * FROM check_database_health()');
        const result = health.rows[0];
        
        if (!result.healthy) {
            console.error('Database health check failed:', result);
            // Send alert to monitoring system
            await sendAlert({
                level: 'critical',
                message: `Connection usage at ${result.usage_percent}%`,
                data: result
            });
        }
        
        // Log metrics
        await logMetrics({
            timestamp: new Date(),
            total_connections: result.total_connections,
            usage_percent: result.usage_percent,
            active_connections: result.active_connections
        });
    } catch (error) {
        console.error('Health check failed:', error);
    }
}

// Run every 60 seconds
setInterval(periodicHealthCheck, 60000);
```

### 2. Connection Pool Configuration

**Optimize pool sizes based on workload:**

```typescript
// Persistent AI Agent (Node.js)
const poolConfig = {
    max: 20,                      // Maximum connections
    min: 5,                       // Minimum idle connections
    idleTimeoutMillis: 300000,    // 5 minutes
    connectionTimeoutMillis: 10000, // 10 seconds
    maxUses: 7500,                // Recycle connections after 7500 queries
};
```

**Guidelines:**
- **Persistent agents**: Pool size 10-50 per agent instance
- **Serverless agents**: Use transaction pooling, pool size 1-5
- **High-performance agents**: Dedicated pooler with 50-200 connections
- **Monitor pool exhaustion** and adjust based on metrics

### 3. Connection Lifecycle Management

**Graceful connection handling:**

```typescript
// Proper connection management
async function executeWithConnection<T>(
    fn: (client: PoolClient) => Promise<T>
): Promise<T> {
    const client = await pool.connect();
    try {
        const result = await fn(client);
        return result;
    } catch (error) {
        console.error('Query error:', error);
        throw error;
    } finally {
        client.release(); // Always release
    }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('Shutting down gracefully...');
    await pool.end();
    process.exit(0);
});
```

### 4. Monitoring Strategy

**Implement three-tier monitoring:**

1. **Real-time** (every 10-60 seconds):
   - Connection count
   - Pool utilization
   - Active queries

2. **Near real-time** (every 5-15 minutes):
   - Connection trends
   - Agent-specific metrics
   - Performance metrics

3. **Historical** (hourly/daily):
   - Usage patterns
   - Peak analysis
   - Capacity planning

### 5. Alerting Thresholds

**Recommended alert levels:**

| Metric | Warning | Critical |
|--------|---------|----------|
| Connection Usage | 70% | 90% |
| Idle in Transaction | 20 connections | 50 connections |
| Long-Running Connections | > 2 hours | > 6 hours |
| Connection Age | > 4 hours | > 12 hours |
| Active Queries Duration | > 30 seconds | > 2 minutes |

## Grafana Integration

### Setup Grafana Dashboard

**1. Add PostgreSQL Data Source:**
```yaml
apiVersion: 1
datasources:
  - name: Supabase
    type: postgres
    url: your-project.supabase.co:5432
    database: postgres
    user: dashboard_reader
    secureJsonData:
      password: ${SUPABASE_PASSWORD}
    jsonData:
      sslmode: require
      postgresVersion: 1500
      timescaledb: false
```

**2. Create Dashboard Panels:**

**Panel: Connection Health**
```sql
SELECT 
    NOW() as time,
    total_connections as "Total Connections",
    active_connections as "Active",
    idle_connections as "Idle",
    usage_percent as "Usage %"
FROM check_database_health();
```

**Panel: AI Agent Connections**
```sql
SELECT 
    NOW() as time,
    application_name,
    connection_count as value
FROM get_ai_agent_connections()
ORDER BY connection_count DESC
LIMIT 10;
```

**Panel: Connection Pool States**
```sql
SELECT 
    NOW() as time,
    metric_name,
    metric_value as value
FROM get_connection_pool_metrics();
```

### Grafana Alerts

**Connection Usage Alert:**
```yaml
- alert: HighConnectionUsage
  expr: connection_usage_percent > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High database connection usage"
    description: "Connection usage is at {{ $value }}%"

- alert: CriticalConnectionUsage
  expr: connection_usage_percent > 90
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Critical database connection usage"
    description: "Connection usage is at {{ $value }}% - immediate action required"
```

## Additional Resources

- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [MCP Authentication](./MCP_AUTHENTICATION.md)
- [PostgreSQL Connection Pooling](https://www.postgresql.org/docs/current/runtime-config-connection.html)
- [Supabase Connection Pooling](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)

## Summary

Connection monitoring and health checks are essential for maintaining reliable AI agent database access. This guide provides:

- ✅ Ready-to-use health check functions
- ✅ Comprehensive monitoring queries
- ✅ Real-time metrics and dashboards
- ✅ Alerting configuration
- ✅ Troubleshooting procedures
- ✅ Best practices for production
- ✅ Grafana integration templates

Regular monitoring, proactive alerting, and proper connection management ensure high availability and optimal performance for AI agent workloads.

---

**Last Updated:** 2025-10-07  
**Version:** 1.0.0
