# Connection Monitoring and Health Checks

## Quick Start

### 1. Apply Migration

The connection monitoring infrastructure is added via migration:

```bash
# Migration file: supabase/migrations/20251007104008_add_connection_monitoring.sql
npm run db:reset
```

This creates the following SQL functions:
- `check_database_health()` - Overall database health status
- `check_connection_limits()` - Connection usage vs limits
- `get_connection_stats()` - Detailed connection statistics
- `get_ai_agent_connections()` - AI agent connection tracking
- `get_connection_pool_metrics()` - Pool state metrics
- `get_long_running_connections()` - Find long-running connections
- `get_connection_by_client_address()` - Group by client IP

### 2. Run Tests

Verify monitoring is working:

```bash
npm run db:start
supabase db execute --file tests/connection_monitoring_test_suite.sql
```

Expected output: All tests pass ✅

### 3. Use Health Checks

#### In SQL

```sql
-- Quick health check
SELECT * FROM check_database_health();

-- Check if approaching limits
SELECT * FROM check_connection_limits();

-- See AI agent connections
SELECT * FROM get_ai_agent_connections();
```

#### In TypeScript/JavaScript

```typescript
import {
  checkDatabaseHealth,
  checkConnectionLimits,
  getAlertLevel
} from './supabase/functions/_shared/connection-health.ts';

// Check health
const health = await checkDatabaseHealth(supabaseUrl, serviceRoleKey);
console.log(`Healthy: ${health.healthy}`);
console.log(`Usage: ${health.usage_percent}%`);

// Get alert level
const alert = getAlertLevel(health);
if (alert.level === 'critical') {
  console.error('CRITICAL:', alert.message);
}
```

#### Via Edge Function

```bash
# Deploy the health-check function
supabase functions deploy health-check

# Call it
curl https://your-project.supabase.co/functions/v1/health-check

# Simple check
curl https://your-project.supabase.co/functions/v1/health-check?simple=true

# With AI agent details
curl https://your-project.supabase.co/functions/v1/health-check?agents=true
```

## Documentation

Comprehensive guides available:

1. **[MCP_CONNECTION_MONITORING.md](./MCP_CONNECTION_MONITORING.md)**
   - Complete monitoring guide
   - All SQL functions documented
   - Dashboard integration
   - Grafana setup
   - Best practices

2. **[CONNECTION_TROUBLESHOOTING.md](./CONNECTION_TROUBLESHOOTING.md)**
   - Quick reference for incidents
   - Common issues and solutions
   - Emergency procedures
   - Diagnostic queries

## Key Features

### Health Checks
- ✅ Real-time connection monitoring
- ✅ Automatic threshold alerting
- ✅ Connection pool state tracking
- ✅ Long-running connection detection

### AI Agent Tracking
- ✅ Track connections by application_name
- ✅ Monitor connection age and count
- ✅ SSL connection verification
- ✅ Client IP tracking

### Dashboard Integration
- ✅ Supabase Studio queries
- ✅ Grafana dashboard templates
- ✅ Real-time metrics
- ✅ Historical trend analysis

### Alerting
- ✅ 70% usage = WARNING
- ✅ 90% usage = CRITICAL
- ✅ Long-running connections
- ✅ Idle in transaction alerts

## Architecture

```
┌─────────────────────────────────────────┐
│   Monitoring Layer                      │
├─────────────────────────────────────────┤
│  - SQL Functions (7 functions)          │
│  - TypeScript Utilities                 │
│  - Edge Function (health-check)         │
│  - Test Suite                           │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│   PostgreSQL System Views               │
├─────────────────────────────────────────┤
│  - pg_stat_activity                     │
│  - pg_stat_ssl                          │
│  - pg_settings                          │
└─────────────────────────────────────────┘
```

## Files Added

### SQL Migration
- `supabase/migrations/20251007104008_add_connection_monitoring.sql`
  - 7 monitoring functions
  - Comprehensive health checks
  - Connection tracking

### Test Suite
- `tests/connection_monitoring_test_suite.sql`
  - 10 test cases
  - Verifies all functions
  - Tests monitoring queries

### Documentation
- `docs/MCP_CONNECTION_MONITORING.md` - Complete guide (21KB)
- `docs/CONNECTION_TROUBLESHOOTING.md` - Quick reference (4KB)
- `docs/MONITORING_README.md` - This file

### Utilities
- `supabase/functions/_shared/connection-health.ts`
  - TypeScript utilities
  - Health check functions
  - Alert level detection
  - Type definitions

### Edge Function
- `supabase/functions/health-check/index.ts`
  - HTTP health check endpoint
  - Multiple query modes
  - JSON responses

## Integration Examples

### Continuous Monitoring

```typescript
// Monitor health every minute
import { monitorHealth } from './connection-health.ts';

for await (const health of monitorHealth(supabaseUrl, key, 60000)) {
  console.log(`Health: ${health.healthy}, Usage: ${health.usage_percent}%`);
  
  if (!health.healthy) {
    await sendAlert(health);
  }
}
```

### Alerting Integration

```typescript
async function checkAndAlert() {
  const health = await checkDatabaseHealth(url, key);
  const alert = getAlertLevel(health);
  
  if (alert.level === 'critical') {
    await sendSlackAlert(alert.message);
    await sendPagerDuty(alert);
  } else if (alert.level === 'warning') {
    await sendSlackNotification(alert.message);
  }
}

setInterval(checkAndAlert, 60000); // Every minute
```

### Dashboard Query

```sql
-- Add to Supabase Studio or Grafana
SELECT 
    'Database Health' as metric_group,
    'Total Connections' as metric,
    total_connections::TEXT as value,
    'connections' as unit
FROM check_database_health()
UNION ALL
SELECT 
    'Database Health',
    'Usage Percent',
    usage_percent::TEXT,
    '%'
FROM check_database_health()
UNION ALL
SELECT 
    'Database Health',
    'Active Queries',
    active_connections::TEXT,
    'connections'
FROM check_database_health();
```

## Monitoring Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| Connection Usage | 70% | 90% | Scale or optimize |
| Idle in Transaction | 20 | 50 | Kill connections |
| Long-Running (hours) | 2 | 6 | Investigate/kill |
| Query Duration (sec) | 30 | 120 | Optimize query |

## Production Checklist

- [ ] Migration applied to production
- [ ] Tests passing in production
- [ ] Health check function accessible
- [ ] Monitoring dashboard configured
- [ ] Alerting thresholds set
- [ ] Alert destinations configured (Slack, email, etc.)
- [ ] Team trained on troubleshooting procedures
- [ ] Runbooks updated with monitoring queries
- [ ] Grafana dashboards deployed (if using)
- [ ] Connection limits reviewed and adjusted

## Support

For issues or questions:
1. Check [CONNECTION_TROUBLESHOOTING.md](./CONNECTION_TROUBLESHOOTING.md)
2. Review [MCP_CONNECTION_MONITORING.md](./MCP_CONNECTION_MONITORING.md)
3. Run test suite to verify functions
4. Check application logs
5. Review PostgreSQL logs

---

**Version:** 1.0.0  
**Last Updated:** 2025-10-07  
**Related Issues:** #28 (Parent issue)
