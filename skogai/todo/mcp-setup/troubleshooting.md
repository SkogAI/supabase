# MCP Server Troubleshooting Guide

## Overview

This guide provides solutions to common issues when connecting MCP servers to Supabase databases. Issues are organized by category for quick reference.

## Quick Diagnostic Checklist

Before diving into specific issues, check these common problems:

- [ ] Database password is correct
- [ ] Connection string format is valid
- [ ] Correct port for connection type (5432 vs 6543)
- [ ] SSL mode is configured (`verify-full` or `require`)
- [ ] Prepared statements disabled for transaction mode
- [ ] Network connectivity to Supabase
- [ ] IP allowlist configured (if enabled)
- [ ] Environment variables loaded correctly

## Connection Issues

### Issue: Connection Timeout

**Error Messages:**
```
Error: connect ETIMEDOUT
Error: Connection timeout
Error: timeout expired
```

**Possible Causes:**
- Network connectivity issues
- Firewall blocking connection
- Wrong host/port
- IP not in allowlist

**Solutions:**

1. **Verify network connectivity:**
   ```bash
   # Test DNS resolution
   nslookup [PROJECT-REF].supabase.co
   
   # Test TCP connection
   nc -zv [PROJECT-REF].supabase.co 5432
   # or for transaction mode:
   nc -zv aws-0-[REGION].pooler.supabase.com 6543
   ```

2. **Check firewall rules:**
   ```bash
   # Linux: Check iptables
   sudo iptables -L -n | grep 5432
   
   # macOS: Check application firewall
   /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
   ```

3. **Verify IP allowlist:**
   - Go to Supabase Dashboard → Database → Connection Pooling
   - Check "Restrict access to..." section
   - Add your IP or use `0.0.0.0/0` for testing (not recommended for production)

4. **Increase timeout:**
   ```json
   {
     "env": {
       "PGCONNECT_TIMEOUT": "30",
       "DB_CONNECTION_TIMEOUT_MS": "30000"
     }
   }
   ```

5. **Test with psql:**
   ```bash
   psql "$DATABASE_URL" -c "SELECT 1"
   ```

---

### Issue: Too Many Connections

**Error Messages:**
```
Error: sorry, too many clients already
Error: remaining connection slots are reserved
FATAL: remaining connection slots are reserved for non-replication superuser connections
```

**Possible Causes:**
- Connection pool size too large
- Connections not being released
- Multiple services sharing database
- Using direct connection instead of pooler

**Solutions:**

1. **Switch to Transaction Mode:**
   ```bash
   # Use port 6543 for efficient pooling
   export DATABASE_URL="postgresql://...pooler.supabase.com:6543/postgres"
   ```

2. **Reduce pool size:**
   ```javascript
   const pool = new Pool({
     connectionString: process.env.DATABASE_URL,
     max: 5  // Reduce from default 10 or 20
   });
   ```

3. **Ensure connections are released:**
   ```javascript
   async function query() {
     const client = await pool.connect();
     try {
       const result = await client.query('SELECT NOW()');
       return result;
     } finally {
       client.release();  // ← IMPORTANT
     }
   }
   ```

4. **Check active connections:**
   ```sql
   SELECT count(*) FROM pg_stat_activity
   WHERE datname = 'postgres';
   ```

5. **Find connection leaks:**
   ```sql
   SELECT 
     application_name,
     state,
     count(*)
   FROM pg_stat_activity
   WHERE datname = 'postgres'
   GROUP BY application_name, state
   ORDER BY count DESC;
   ```

6. **Set connection idle timeout:**
   ```javascript
   const pool = new Pool({
     idleTimeoutMillis: 30000,  // 30 seconds
     allowExitOnIdle: true      // For Lambda
   });
   ```

---

### Issue: SSL Connection Error

**Error Messages:**
```
Error: unable to get local issuer certificate
Error: self signed certificate in certificate chain
Error: certificate verify failed
```

**Solutions:**

See detailed [SSL Setup Guide](./ssl-setup.md) for comprehensive solutions.

**Quick Fixes:**

1. **Use system CA bundle:**
   ```bash
   # Linux
   export PGSSLROOTCERT=/etc/ssl/certs/ca-certificates.crt
   
   # macOS
   export PGSSLROOTCERT=/etc/ssl/cert.pem
   ```

2. **Download Supabase certificate:**
   ```bash
   mkdir -p ~/.supabase/certs
   curl -o ~/.supabase/certs/supabase-ca.crt \
     https://supabase.com/docs/guides/platform/ssl-certificates/supabase-ca.crt
   chmod 600 ~/.supabase/certs/supabase-ca.crt
   ```

3. **For development only (NOT production):**
   ```bash
   export PGSSLMODE=require  # Less strict than verify-full
   ```

---

### Issue: Authentication Failed

**Error Messages:**
```
Error: password authentication failed
FATAL: password authentication failed for user "postgres"
Error: role "postgres" does not exist
```

**Solutions:**

1. **Verify password:**
   - Go to Supabase Dashboard → Settings → Database
   - Reset password if needed
   - Update `.env` file

2. **Check connection string format:**
   ```bash
   # Correct format:
   postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[HOST]:5432/postgres
   
   # NOT:
   postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres  # ❌ Missing project ref
   ```

3. **URL-encode password if it contains special characters:**
   ```javascript
   const password = encodeURIComponent('p@ssw0rd!');
   const connectionString = `postgresql://postgres.${projectRef}:${password}@...`;
   ```

4. **Test authentication:**
   ```bash
   # Test with psql
   PGPASSWORD='your-password' psql -h [HOST] -U postgres.[PROJECT-REF] -d postgres
   ```

---

## Prepared Statement Issues

### Issue: Prepared Statement Does Not Exist

**Error Messages:**
```
Error: prepared statement "stmtcache_1" does not exist
Error: prepared statement "S_1" already exists
ERROR: prepared statement "..." does not exist
```

**Cause:**
Using prepared statements with Transaction Mode (port 6543) or PgBouncer in transaction mode.

**Solutions:**

1. **Disable prepared statements (REQUIRED for transaction mode):**

   **Connection String:**
   ```bash
   postgresql://...pooler.supabase.com:6543/postgres?prepareStatement=false
   ```

   **Environment Variable:**
   ```bash
   export DISABLE_PREPARED_STATEMENTS=true
   ```

   **MCP Config:**
   ```json
   {
     "mcpServers": {
       "supabase": {
         "args": [
           "--connection-string", "${DATABASE_URL}",
           "--disable-prepared-statements"
         ]
       }
     }
   }
   ```

2. **Node.js (pg):**
   ```javascript
   const pool = new Pool({
     connectionString: process.env.DATABASE_URL,
     options: '-c plan_cache_mode=force_custom_plan'
   });
   ```

3. **Prisma:**
   ```
   DATABASE_URL="postgresql://...?pgbouncer=true"
   ```

4. **Python (psycopg2):**
   ```python
   conn = psycopg2.connect(
       dsn,
       options='-c plan_cache_mode=force_custom_plan'
   )
   ```

5. **Switch to Session Mode (port 5432) if prepared statements are required:**
   ```bash
   # Session mode supports prepared statements
   postgresql://...pooler.supabase.com:5432/postgres
   ```

---

## Performance Issues

### Issue: Slow Query Performance

**Symptoms:**
- Queries taking longer than expected
- Timeouts occurring
- High latency

**Solutions:**

1. **Check query execution time:**
   ```sql
   EXPLAIN ANALYZE
   SELECT * FROM your_table WHERE condition;
   ```

2. **Add indexes:**
   ```sql
   -- Check missing indexes
   SELECT schemaname, tablename, attname
   FROM pg_stats
   WHERE schemaname = 'public'
   AND n_distinct > 100
   AND correlation < 0.1;
   
   -- Create index
   CREATE INDEX idx_table_column ON your_table(column);
   ```

3. **Enable query logging:**
   ```sql
   -- Check slow queries
   SELECT
     query,
     mean_exec_time,
     calls
   FROM pg_stat_statements
   WHERE mean_exec_time > 1000  -- queries > 1 second
   ORDER BY mean_exec_time DESC
   LIMIT 10;
   ```

4. **Set statement timeout:**
   ```javascript
   const pool = new Pool({
     connectionString: process.env.DATABASE_URL,
     statement_timeout: 30000,  // 30 seconds
     query_timeout: 30000
   });
   ```

5. **Use connection pooling:**
   ```bash
   # Switch to transaction mode for better pooling
   postgresql://...pooler.supabase.com:6543/postgres
   ```

---

### Issue: High Connection Churn

**Symptoms:**
- Frequent connection/disconnection
- "Too many connections" errors
- High database CPU usage

**Solutions:**

1. **Use connection pooling:**
   ```javascript
   // Create pool once, reuse connections
   const pool = new Pool({
     min: 2,
     max: 10,
     idleTimeoutMillis: 300000  // 5 minutes
   });
   ```

2. **Enable connection reuse in serverless:**
   ```javascript
   // AWS Lambda - create pool outside handler
   const pool = new Pool({
     connectionString: process.env.DATABASE_URL,
     allowExitOnIdle: true
   });
   
   exports.handler = async (event) => {
     // Use pool.query() - don't create new pool each time
     const result = await pool.query('SELECT NOW()');
     return result.rows[0];
   };
   ```

3. **Use Transaction Mode (port 6543):**
   ```bash
   # Better for serverless
   postgresql://...pooler.supabase.com:6543/postgres
   ```

4. **Increase idle timeout:**
   ```javascript
   const pool = new Pool({
     idleTimeoutMillis: 600000  // 10 minutes
   });
   ```

---

## Environment-Specific Issues

### Issue: Works Locally, Fails in Production

**Solutions:**

1. **Check environment variables:**
   ```bash
   # Verify variables are set
   printenv | grep DATABASE_URL
   printenv | grep PGSSLMODE
   ```

2. **Verify network access:**
   ```bash
   # Test from production environment
   curl -v telnet://[PROJECT-REF].supabase.co:5432
   ```

3. **Check SSL configuration:**
   ```bash
   # Production should use verify-full
   export PGSSLMODE=verify-full
   export PGSSLROOTCERT=/path/to/ca.crt
   ```

4. **Verify connection string:**
   ```bash
   # Ensure no development URLs in production
   echo $DATABASE_URL | grep -i localhost && echo "WRONG URL!"
   ```

---

### Issue: Lambda/Serverless Function Timeout

**Error Messages:**
```
Error: Task timed out after 30.00 seconds
Error: Execution time exceeded
```

**Solutions:**

1. **Use Transaction Mode (port 6543):**
   ```bash
   export DATABASE_URL="postgresql://...pooler.supabase.com:6543/postgres"
   ```

2. **Optimize pool configuration:**
   ```javascript
   const pool = new Pool({
     connectionString: process.env.DATABASE_URL,
     min: 0,  // No minimum
     max: 1,  // One connection per Lambda
     connectionTimeoutMillis: 3000,
     idleTimeoutMillis: 3000,
     allowExitOnIdle: true
   });
   ```

3. **Keep Lambda warm:**
   ```javascript
   // EventBridge rule to ping every 5 minutes
   // Prevents cold starts
   ```

4. **Increase Lambda timeout:**
   ```yaml
   # serverless.yml
   functions:
     myFunction:
       timeout: 30  # Increase from default 6 seconds
   ```

5. **Use connection pre-warming:**
   ```javascript
   // Pre-establish connection
   let poolReady = pool.connect().then(client => {
     client.release();
     return true;
   });
   
   exports.handler = async (event) => {
     await poolReady;
     // Now execute query
   };
   ```

---

## Monitoring and Debugging

### Enable Debug Logging

**Node.js (pg):**
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Enable debugging
  log: (msg) => console.log('PG:', msg)
});

// Or use DEBUG environment variable
// DEBUG=pg:* node app.js
```

**Python:**
```python
import logging

# Enable psycopg2 logging
logging.basicConfig(level=logging.DEBUG)
logging.getLogger('psycopg2').setLevel(logging.DEBUG)
```

**Environment Variable:**
```bash
export DEBUG=*
export LOG_LEVEL=debug
```

### Check Database Logs

**In Supabase Dashboard:**
1. Go to Database → Logs
2. Filter by time range
3. Search for errors or slow queries

**Via SQL:**
```sql
-- Recent errors
SELECT * FROM postgres_logs
WHERE level = 'ERROR'
ORDER BY timestamp DESC
LIMIT 10;

-- Slow queries
SELECT 
  query,
  mean_exec_time,
  calls
FROM pg_stat_statements
WHERE mean_exec_time > 1000
ORDER BY mean_exec_time DESC;
```

### Monitor Connections

```sql
-- Active connections
SELECT 
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  state_change
FROM pg_stat_activity
WHERE datname = 'postgres'
ORDER BY query_start DESC;

-- Connection count by state
SELECT 
  state,
  count(*)
FROM pg_stat_activity
WHERE datname = 'postgres'
GROUP BY state;

-- Long-running queries
SELECT 
  pid,
  now() - query_start AS duration,
  query
FROM pg_stat_activity
WHERE state = 'active'
AND now() - query_start > interval '30 seconds';
```

---

## Error Code Reference

### PostgreSQL Error Codes

| Code | Error | Cause | Solution |
|------|-------|-------|----------|
| 53300 | too_many_connections | Connection limit reached | Use transaction mode or reduce pool size |
| 28P01 | invalid_password | Wrong password | Check credentials in Supabase Dashboard |
| 08001 | sqlclient_unable_to_establish_sqlconnection | Network issue | Check firewall, DNS, IP allowlist |
| 08006 | connection_failure | Connection lost | Check network stability, increase timeout |
| 42P05 | duplicate_prepared_statement | Prepared statement conflict | Disable prepared statements for transaction mode |
| 57014 | query_canceled | Query timeout | Increase statement_timeout |

### Node.js (pg) Error Codes

| Code | Error | Solution |
|------|-------|----------|
| ECONNREFUSED | Connection refused | Check host/port, verify database is running |
| ETIMEDOUT | Timeout | Increase connectionTimeoutMillis |
| ENOTFOUND | DNS lookup failed | Check hostname, DNS settings |
| ECONNRESET | Connection reset | Check network stability, firewall |

---

## Common Configuration Mistakes

### ❌ Wrong: Using Direct Connection for Serverless

```javascript
// BAD - High connection overhead
const pool = new Pool({
  connectionString: 'postgresql://...supabase.co:5432/postgres'
});
```

### ✅ Correct: Use Transaction Mode

```javascript
// GOOD - Efficient for serverless
const pool = new Pool({
  connectionString: 'postgresql://...pooler.supabase.com:6543/postgres',
  options: '-c plan_cache_mode=force_custom_plan'
});
```

---

### ❌ Wrong: Not Releasing Connections

```javascript
// BAD - Connection leak
async function query() {
  const client = await pool.connect();
  const result = await client.query('SELECT NOW()');
  return result;  // ❌ Never released!
}
```

### ✅ Correct: Always Release

```javascript
// GOOD - Proper cleanup
async function query() {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT NOW()');
    return result;
  } finally {
    client.release();  // ✅ Always released
  }
}
```

---

### ❌ Wrong: Hardcoded Credentials

```javascript
// BAD - Security risk
const pool = new Pool({
  connectionString: 'postgresql://postgres:password123@...'
});
```

### ✅ Correct: Use Environment Variables

```javascript
// GOOD - Secure
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});
```

---

## Getting Help

If you're still experiencing issues:

1. **Check Supabase Status**: https://status.supabase.com
2. **Search GitHub Issues**: https://github.com/supabase/supabase/issues
3. **Supabase Discord**: https://discord.supabase.com
4. **Supabase Support**: support@supabase.com

### Information to Include

When asking for help, provide:

- Error message (full stack trace)
- Connection string format (without password)
- Connection type (Direct/Session/Transaction/Dedicated)
- Environment (Local/Lambda/Edge/Production)
- Client library and version
- Node.js/Python/Deno version
- Code snippet (sanitized)
- Steps to reproduce

### Diagnostic Script

Run this script to collect diagnostic information:

```bash
#!/bin/bash
echo "=== MCP Diagnostic Info ==="
echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"
echo ""
echo "=== Environment Variables ==="
echo "DATABASE_URL is set: $([ -n "$DATABASE_URL" ] && echo 'YES' || echo 'NO')"
echo "PGSSLMODE: $PGSSLMODE"
echo ""
echo "=== Network Test ==="
timeout 5 nc -zv aws-0-us-east-1.pooler.supabase.com 6543
echo ""
echo "=== DNS Resolution ==="
nslookup aws-0-us-east-1.pooler.supabase.com
```

---

## Next Steps

- **Quick Start**: [Getting Started Guide](./quickstart.md)
- **Connection Types**: [Detailed Connection Guide](./connection-types.md)
- **SSL Setup**: [SSL Configuration](./ssl-setup.md)
- **Monitoring**: [Setup Monitoring](./monitoring.md)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0
