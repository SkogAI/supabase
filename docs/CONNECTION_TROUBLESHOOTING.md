# Connection Troubleshooting Quick Reference

## Quick Diagnostics

### Check Overall Health
```sql
SELECT * FROM check_database_health();
```

### Check Connection Limits
```sql
SELECT * FROM check_connection_limits();
```

### List All Connections
```sql
SELECT 
    pid,
    usename,
    application_name,
    state,
    NOW() - backend_start as connection_age
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
ORDER BY backend_start;
```

## Common Issues & Solutions

### 1. "Too Many Connections" Error

**Quick Fix:**
```sql
-- Check current usage
SELECT * FROM check_connection_limits();

-- Kill idle connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
  AND NOW() - state_change > INTERVAL '30 minutes'
  AND pid != pg_backend_pid();
```

### 2. Connection Hanging

**Diagnosis:**
```sql
-- Find long-running queries
SELECT * FROM get_long_running_connections(5); -- 5 minutes
```

**Solution:**
```sql
-- Terminate specific connection
SELECT pg_terminate_backend(12345); -- Replace with actual PID
```

### 3. Idle in Transaction

**Find Problem Connections:**
```sql
SELECT 
    pid,
    usename,
    application_name,
    NOW() - state_change as idle_time
FROM pg_stat_activity
WHERE state LIKE '%idle in transaction%'
ORDER BY state_change;
```

**Kill Them:**
```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state LIKE '%idle in transaction%'
  AND NOW() - state_change > INTERVAL '5 minutes'
  AND pid != pg_backend_pid();
```

### 4. Connection Leak Detection

**Find Leaking Agents:**
```sql
SELECT * FROM get_ai_agent_connections()
WHERE connection_count > 20
   OR oldest_connection_age > INTERVAL '4 hours'
ORDER BY connection_count DESC;
```

### 5. Performance Issues

**Check Connection Pool State:**
```sql
SELECT * FROM get_connection_pool_metrics();
```

**Find Slow Queries:**
```sql
SELECT 
    pid,
    NOW() - query_start as duration,
    state,
    LEFT(query, 100) as query_preview
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start IS NOT NULL
  AND NOW() - query_start > INTERVAL '10 seconds'
ORDER BY query_start;
```

## Emergency Procedures

### Kill All User Connections

```sql
-- Kill all connections for a specific user
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'problem_user'
  AND pid != pg_backend_pid();
```

### Kill All Connections from Application

```sql
-- Kill all connections from specific app
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE application_name = 'problem_app'
  AND pid != pg_backend_pid();
```

### Reset Everything (Nuclear Option)

```sql
-- Kill ALL non-superuser connections (BE CAREFUL!)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename != 'postgres'
  AND pid != pg_backend_pid();
```

## Monitoring Commands

### Real-Time Watch

```bash
# Watch connection count (run in terminal)
watch -n 5 "psql -U postgres -h localhost -p 54322 -c 'SELECT * FROM check_database_health();'"
```

### Connection Count by State

```sql
SELECT 
    state,
    COUNT(*) as count
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY state
ORDER BY count DESC;
```

### Top Connection Consumers

```sql
SELECT 
    application_name,
    usename,
    COUNT(*) as connections
FROM pg_stat_activity
WHERE pid != pg_backend_pid()
GROUP BY application_name, usename
ORDER BY COUNT(*) DESC
LIMIT 10;
```

## Prevention

### Set Connection Limits

```sql
-- Limit connections per user
ALTER ROLE ai_agent_user CONNECTION LIMIT 20;

-- Set timeout for idle connections
ALTER DATABASE postgres SET idle_in_transaction_session_timeout = '10min';
```

### Enable Statement Timeout

```sql
-- Prevent runaway queries
ALTER DATABASE postgres SET statement_timeout = '30s';

-- For specific role
ALTER ROLE ai_agent_user SET statement_timeout = '60s';
```

## Contact & Escalation

If issues persist:
1. Check application logs
2. Review connection pool configuration
3. Consider increasing max_connections
4. Enable connection pooling (PgBouncer/Supavisor)
5. Contact database administrator

---

**Quick Reference Card:** Print and keep handy for incidents
