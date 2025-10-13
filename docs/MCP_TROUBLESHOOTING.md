# AI Agent Database Connection Troubleshooting Guide

## Overview

This comprehensive guide helps diagnose and resolve common database connection issues encountered by AI agents connecting to Supabase. Use this guide to quickly identify problems and apply proven solutions.

## Table of Contents

- [Quick Diagnosis Checklist](#quick-diagnosis-checklist)
- [Common Error Messages](#common-error-messages)
- [Connection Issues](#connection-issues)
- [Authentication Issues](#authentication-issues)
- [SSL/TLS Issues](#ssltls-issues)
- [IPv4/IPv6 Compatibility](#ipv4ipv6-compatibility)
- [Pooler and Connection Limits](#pooler-and-connection-limits)
- [Prepared Statement Errors](#prepared-statement-errors)
- [Network Issues](#network-issues)
- [Diagnostic Commands](#diagnostic-commands)
- [Error Code Reference](#error-code-reference)

## Quick Diagnosis Checklist

Run through this checklist systematically to identify issues quickly:

- [ ] **Is the Supabase project running?**
  - Check: https://app.supabase.com/project/[project-ref]
  - Verify: Project shows "Active" status (not "Paused")
  
- [ ] **Is the connection string correct?**
  - Check: Dashboard → Settings → Database → Connection string
  - Verify: Host, port, database name, and credentials match
  
- [ ] **Are credentials valid?**
  - Test: Try connecting with `psql` or database client
  - Verify: Password hasn't been rotated
  
- [ ] **Is SSL configured properly?**
  - Check: Connection string includes `sslmode=require`
  - Verify: SSL certificates are valid
  
- [ ] **Does environment support IPv6?**
  - Test: `ping6 db.[project-ref].supabase.co`
  - Alternative: Use Supavisor session/transaction mode for IPv4
  
- [ ] **Are prepared statements disabled (transaction mode)?**
  - Check: Using transaction mode pooler (port 6543)
  - Verify: Prepared statements disabled in client library
  
- [ ] **Is pool limit reached?**
  - Check: Current connections vs. compute tier limit
  - Verify: No connection leaks in application
  
- [ ] **Are firewall rules correct?**
  - Test: Network connectivity to database host
  - Verify: Outbound connections allowed on port 5432/6543

## Common Error Messages

### Connection Refused

**Error Messages:**
```
Connection refused
ECONNREFUSED
could not connect to server
```

**Causes:**
1. Supabase project is paused (auto-pauses after 1 week of inactivity on free tier)
2. Incorrect host or port in connection string
3. Firewall blocking outbound connections
4. Network connectivity issues

**Solutions:**

```bash
# 1. Check project status in Supabase Dashboard
# If paused, click "Resume" or run any query to wake it up

# 2. Verify connection string format
# Direct IPv6:
postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Supavisor Session (IPv4 compatible):
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[region].pooler.supabase.com:5432/postgres

# Supavisor Transaction (IPv4 compatible):
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[region].pooler.supabase.com:6543/postgres

# 3. Test network connectivity
ping db.[PROJECT-REF].supabase.co
telnet db.[PROJECT-REF].supabase.co 5432

# 4. Check firewall rules (allow outbound on 5432/6543)
# For cloud providers, ensure security groups allow egress
```

### Password Authentication Failed

**Error Messages:**
```
FATAL: password authentication failed for user "postgres"
FATAL: password authentication failed for user "postgres.[PROJECT-REF]"
authentication failed
invalid username/password
```

**Causes:**
1. Incorrect database password
2. Wrong username format for pooler connections
3. Expired or rotated credentials
4. Using wrong password (anon key vs. service role vs. database password)

**Solutions:**

```bash
# 1. Get correct database password
# Dashboard → Settings → Database → Database password (click "Reset Database Password" if needed)

# 2. Verify username format
# Direct connection:
#   Username: postgres
# Supavisor connection:
#   Username: postgres.[PROJECT-REF]

# 3. Test credentials with psql
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 4. Common mistakes to avoid:
# ❌ Using anon key as password
# ❌ Using service_role key as password
# ✅ Use database password from Settings → Database

# 5. Update environment variables
export DATABASE_URL="postgresql://postgres:[NEW-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 6. Rotate credentials if compromised
# Dashboard → Settings → Database → Reset Database Password
```

### SSL Connection Error

**Error Messages:**
```
SSL connection error
SSL SYSCALL error
certificate verify failed
unable to get local issuer certificate
```

**Causes:**
1. SSL certificate verification issues
2. Missing CA certificates
3. SSL mode misconfiguration
4. Self-signed certificate not trusted

**Solutions:**

```bash
# 1. For testing only - disable SSL verification
# WARNING: Not recommended for production
export PGSSLMODE=disable
# Or in connection string:
sslmode=disable

# 2. Enable SSL but skip verification (less secure)
export PGSSLMODE=require
# Or in connection string:
sslmode=require

# 3. Full SSL verification (recommended for production)
export PGSSLMODE=verify-full
# Or in connection string:
sslmode=verify-full

# 4. Download and specify CA certificate
curl https://supabase.com/.well-known/ca-certificate.crt > /tmp/supabase-ca.crt
export PGSSLROOTCERT=/tmp/supabase-ca.crt

# 5. Update system CA certificates (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install ca-certificates
sudo update-ca-certificates

# 6. Test SSL connection
openssl s_client -connect db.[PROJECT-REF].supabase.co:5432 -starttls postgres

# 7. Node.js configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    // ca: fs.readFileSync('/path/to/ca-cert.crt').toString()
  }
});

# 8. Python configuration
conn = await asyncpg.connect(
    dsn=DATABASE_URL,
    ssl='require'  # or 'verify-full' with ca file
)
```

### Too Many Connections

**Error Messages:**
```
FATAL: too many connections for role "postgres"
FATAL: remaining connection slots are reserved
sorry, too many clients already
```

**Causes:**
1. Reached connection limit for compute tier
2. Connection pool not configured properly
3. Connection leaks in application code
4. Too many concurrent AI agents

**Solutions:**

```bash
# 1. Check current connection count
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -c "SELECT count(*) FROM pg_stat_activity;"

# 2. Check connections by state
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -c "SELECT state, count(*) FROM pg_stat_activity GROUP BY state;"

# 3. Check compute tier limits
# Free tier: 60 concurrent connections
# Pro tier: 200 concurrent connections
# Dashboard → Settings → Add-ons → Compute

# 4. Configure connection pooling
# Node.js example:
const pool = new Pool({
  max: 10,  // Reduce from default 20
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000
});

# 5. Use Supavisor pooler for better connection management
# Transaction mode (port 6543) - best for serverless
# Session mode (port 5432) - better for persistent agents

# 6. Fix connection leaks
# Always release connections:
const client = await pool.connect();
try {
  // your query
} finally {
  client.release();  // Always release!
}

# 7. Upgrade compute tier if needed
# Dashboard → Settings → Add-ons → Compute → Upgrade

# 8. Monitor connection lifecycle
# Add logging to track connection acquisition/release
```

### Prepared Statement Does Not Exist

**Error Messages:**
```
prepared statement "..." does not exist
prepared statement "s1" does not exist
server closed the connection unexpectedly
```

**Causes:**
1. Using transaction mode pooler (port 6543) with prepared statements
2. PgBouncer in transaction mode doesn't support prepared statements
3. Client library has prepared statements enabled by default

**Solutions:**

```bash
# 1. Disable prepared statements in your client library

# Node.js (pg library):
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  statement_timeout: 30000,
  // Disable prepared statements for transaction mode
});

// Use direct queries instead of prepared statements:
await client.query('SELECT * FROM users WHERE id = $1', [userId]);
// Not: await client.query({ text: 'SELECT...', name: 'my-query' });

# 2. Python (asyncpg):
conn = await asyncpg.connect(
    dsn=DATABASE_URL,
    server_settings={
        'jit': 'off',  # Disable JIT which uses prepared statements
    }
)

# 3. Python (psycopg2):
import psycopg2.extras
psycopg2.extras.register_default_jsonb(conn_or_curs=cursor, globally=True)
# Use execute() instead of execute() with prepare=True

# 4. Switch to session mode if prepared statements are required
# Use port 5432 instead of 6543:
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[region].pooler.supabase.com:5432/postgres

# 5. Or use direct connection (requires IPv6):
postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
```

## Connection Issues

### Cannot Resolve Hostname

**Problem:** DNS resolution fails for database host

**Symptoms:**
```
could not translate host name "db.xxx.supabase.co" to address
getaddrinfo ENOTFOUND
Name or service not known
```

**Diagnosis:**
```bash
# Test DNS resolution
nslookup db.[PROJECT-REF].supabase.co
dig db.[PROJECT-REF].supabase.co

# Test with different DNS servers
nslookup db.[PROJECT-REF].supabase.co 8.8.8.8
nslookup db.[PROJECT-REF].supabase.co 1.1.1.1
```

**Solutions:**
1. Check network connectivity
2. Verify DNS servers are accessible
3. Try using public DNS (8.8.8.8, 1.1.1.1)
4. Check if domain is blocked by firewall/proxy
5. Use IP address directly (get from DNS lookup)

### Connection Timeout

**Problem:** Connection times out before establishing

**Symptoms:**
```
connection timeout
connect ETIMEDOUT
timeout: timed out
```

**Diagnosis:**
```bash
# Test connectivity with timeout
timeout 5 telnet db.[PROJECT-REF].supabase.co 5432

# Check route and latency
traceroute db.[PROJECT-REF].supabase.co
ping -c 5 db.[PROJECT-REF].supabase.co

# Test from different location
# Some networks block database ports
```

**Solutions:**
```javascript
// 1. Increase connection timeout
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  connectionTimeoutMillis: 30000,  // Increase from default 10000
});

// 2. Add retry logic
async function connectWithRetry(maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await pool.connect();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await sleep(1000 * Math.pow(2, i));  // Exponential backoff
    }
  }
}

// 3. Check network configuration
// - Verify outbound port 5432/6543 is allowed
// - Check for proxy/VPN interference
// - Try from different network/location

// 4. Use transaction mode pooler (shorter connections)
// Switch to port 6543 for faster connection establishment
```

## Authentication Issues

### Permission Denied for Table

**Problem:** User lacks permissions to access table

**Symptoms:**
```
permission denied for table users
permission denied for schema public
```

**Diagnosis:**
```sql
-- Check table permissions
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'your_table';

-- Check current user
SELECT current_user, session_user;

-- Check available roles
\du  -- in psql
```

**Solutions:**
```sql
-- Grant SELECT permission
GRANT SELECT ON TABLE your_table TO postgres;
GRANT SELECT ON TABLE your_table TO authenticated;

-- Grant all permissions
GRANT ALL PRIVILEGES ON TABLE your_table TO postgres;

-- Grant schema access
GRANT USAGE ON SCHEMA public TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO postgres;

-- Verify RLS policies aren't blocking access
SELECT * FROM pg_policies WHERE tablename = 'your_table';
```

### RLS Policy Blocking Access

**Problem:** Row Level Security policies prevent data access

**Symptoms:**
```
-- Query returns 0 rows when data exists
-- No error, but unexpected empty results
```

**Diagnosis:**
```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'your_table';

-- View RLS policies
SELECT * FROM pg_policies WHERE tablename = 'your_table';

-- Test with service role (bypasses RLS)
-- Use service_role key instead of anon key
```

**Solutions:**
```sql
-- Disable RLS for testing (not recommended for production)
ALTER TABLE your_table DISABLE ROW LEVEL SECURITY;

-- Add policy for service role
CREATE POLICY "Service role full access" ON your_table
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Add policy for authenticated users
CREATE POLICY "Authenticated users read all" ON your_table
  FOR SELECT TO authenticated USING (true);

-- Use service role key in your application
const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY  // Bypasses RLS
);
```

## SSL/TLS Issues

### Certificate Verification Failed

**Problem:** SSL certificate cannot be verified

**Diagnosis:**
```bash
# Check certificate details
openssl s_client -connect db.[PROJECT-REF].supabase.co:5432 \
  -starttls postgres \
  -showcerts

# Test with different SSL modes
psql "sslmode=require host=db.[PROJECT-REF].supabase.co ..."
psql "sslmode=verify-ca host=db.[PROJECT-REF].supabase.co ..."
psql "sslmode=verify-full host=db.[PROJECT-REF].supabase.co ..."
```

**Solutions:**
```javascript
// Node.js - Accept self-signed certificates (testing only)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false  // WARNING: Insecure for production
  }
});

// Node.js - Verify with CA certificate (production)
import fs from 'fs';
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/path/to/ca-cert.crt').toString()
  }
});

// Python - Configure SSL
import ssl
context = ssl.create_default_context()
context.check_hostname = True
context.verify_mode = ssl.CERT_REQUIRED

conn = await asyncpg.connect(
    dsn=DATABASE_URL,
    ssl=context
)

// Or use simplified SSL mode
conn = await asyncpg.connect(
    dsn=DATABASE_URL,
    ssl='require'  # Less strict but still encrypted
)
```

## IPv4/IPv6 Compatibility

### IPv6 Connection Required

**Problem:** Direct connections require IPv6, but environment only has IPv4

**Symptoms:**
```
Network is unreachable
Cannot assign requested address
No route to host
```

**Diagnosis:**
```bash
# Test IPv6 connectivity
ping6 db.[PROJECT-REF].supabase.co
curl -6 https://db.[PROJECT-REF].supabase.co

# Test IPv4 connectivity
ping db.[PROJECT-REF].supabase.co
curl -4 https://db.[PROJECT-REF].supabase.co

# Check local IP configuration
ip addr show
ifconfig
```

**Solutions:**

### Solution 1: Use Supavisor Session Mode (IPv4)
```bash
# Switch to session mode pooler (supports IPv4)
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[region].pooler.supabase.com:5432/postgres

# Find your region in Dashboard → Settings → Database → Connection string
# Common regions: us-east-1, eu-west-1, ap-southeast-1
```

### Solution 2: Use Supavisor Transaction Mode (IPv4)
```bash
# Best for serverless/edge environments
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[region].pooler.supabase.com:6543/postgres

# Note: Must disable prepared statements with transaction mode
```

### Solution 3: Enable IPv6 on Your System
```bash
# Ubuntu/Debian
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0

# Verify IPv6 is enabled
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
# Should output: 0

# Test connection
ping6 db.[PROJECT-REF].supabase.co
```

### Solution 4: Use IPv4 Add-on (Paid)
```
Dashboard → Settings → Add-ons → IPv4 Address
This provides a dedicated IPv4 address for direct connections
```

### Connection Type Decision Matrix

| Environment | IPv6 Available? | Recommended Connection | Port | Prepared Statements |
|------------|----------------|----------------------|------|-------------------|
| AWS Lambda | No | Supavisor Transaction | 6543 | No |
| Vercel Edge | No | Supavisor Transaction | 6543 | No |
| Cloudflare Workers | No | Supavisor Transaction | 6543 | No |
| Traditional Server | Yes | Direct IPv6 | 5432 | Yes |
| Traditional Server | No | Supavisor Session | 5432 | Yes |
| Local Development | Varies | Supavisor Session | 5432 | Yes |
| Docker Container | Varies | Supavisor Session | 5432 | Yes |

## Pooler and Connection Limits

### Connection Pool Exhausted

**Problem:** All connections in pool are in use

**Symptoms:**
```
timeout acquiring connection
pool is full
connection pool exhausted
```

**Diagnosis:**
```sql
-- Check active connections
SELECT 
  count(*) as total,
  count(*) FILTER (WHERE state = 'active') as active,
  count(*) FILTER (WHERE state = 'idle') as idle,
  count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity
WHERE usename = 'postgres';

-- Find long-running queries
SELECT 
  pid,
  now() - pg_stat_activity.query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC
LIMIT 10;

-- Check connection by application
SELECT 
  application_name,
  count(*) as connections
FROM pg_stat_activity
GROUP BY application_name
ORDER BY connections DESC;
```

**Solutions:**
```javascript
// 1. Optimize pool configuration
const pool = new Pool({
  max: 20,                    // Maximum pool size
  min: 2,                     // Minimum pool size
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 10000,  // Wait 10s for connection
  acquireTimeoutMillis: 30000,     // Wait 30s to acquire from pool
});

// 2. Always release connections
async function safeQuery(sql, params) {
  const client = await pool.connect();
  try {
    return await client.query(sql, params);
  } finally {
    client.release();  // Critical: Always release!
  }
}

// 3. Use pool.query() instead of pool.connect()
// Automatically handles connection release
await pool.query('SELECT * FROM users WHERE id = $1', [userId]);

// 4. Monitor pool metrics
pool.on('connect', () => {
  console.log('Pool connection established');
});

pool.on('remove', () => {
  console.log('Pool connection removed');
});

pool.on('error', (err) => {
  console.error('Pool error:', err);
});

// 5. Implement connection timeout
const query = pool.query('SELECT * FROM large_table');
const timeout = setTimeout(() => {
  query.cancel();
  console.error('Query timeout');
}, 30000);

query.then(() => clearTimeout(timeout));
```

### Compute Tier Limit Reached

**Problem:** Exceeded maximum connections for compute tier

**Diagnosis:**
```sql
-- Check current vs maximum connections
SELECT 
  (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections,
  (SELECT count(*) FROM pg_stat_activity) as current_connections,
  (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - 
    (SELECT count(*) FROM pg_stat_activity) as available_connections;

-- Check connections by user
SELECT 
  usename,
  count(*) as connections
FROM pg_stat_activity
GROUP BY usename
ORDER BY connections DESC;
```

**Solutions:**
1. **Upgrade compute tier** (Dashboard → Settings → Add-ons → Compute)
   - Free: 60 concurrent connections
   - Small: 90 concurrent connections
   - Medium: 120 concurrent connections
   - Large: 160 concurrent connections
   - XL: 200 concurrent connections
   - 2XL: 280 concurrent connections

2. **Use connection pooling**
   - Switch to Supavisor pooler
   - Reduces active database connections
   - Supports 1000s of client connections

3. **Optimize connection lifecycle**
   - Reduce pool.max in application
   - Decrease idleTimeoutMillis
   - Close connections promptly

4. **Kill idle connections**
```sql
-- Find and kill idle connections (use with caution)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
  AND state_change < now() - interval '5 minutes';
```

## Prepared Statement Errors

### Transaction Mode Limitations

**Problem:** Transaction mode pooler doesn't support prepared statements

**Understanding the Issue:**
- **Session Mode (port 5432):** Maintains session state, supports prepared statements
- **Transaction Mode (port 6543):** New connection per transaction, no session state

**Diagnosis:**
```javascript
// Check which port you're using
console.log(process.env.DATABASE_URL);
// If port is 6543, you're in transaction mode
// If port is 5432, you're in session mode

// Enable debug logging
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  log: (msg) => console.log(msg)
});
```

**Solutions:**

### For Transaction Mode (Port 6543)
```javascript
// Node.js - Disable prepared statements
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Transaction mode automatically disables prepared statements
  // But ensure you're not using named queries
});

// ❌ DON'T: Named prepared statements
await client.query({
  name: 'fetch-user',
  text: 'SELECT * FROM users WHERE id = $1',
  values: [userId]
});

// ✅ DO: Direct parameterized queries
await client.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);
```

```python
# Python asyncpg - Disable statement caching
conn = await asyncpg.connect(
    dsn=DATABASE_URL,
    statement_cache_size=0,  # Disable statement cache
    server_settings={
        'jit': 'off'  # Disable JIT compilation
    }
)

# Or use simple queries
result = await conn.fetch('SELECT * FROM users WHERE id = $1', user_id)
```

### For Session Mode (Port 5432)
```javascript
// Prepared statements work fine in session mode
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Prepared statements enabled by default
});

// Named queries work
await client.query({
  name: 'fetch-user',
  text: 'SELECT * FROM users WHERE id = $1',
  values: [userId]
});
```

## Network Issues

### Firewall Blocking Connection

**Problem:** Network firewall blocks database ports

**Diagnosis:**
```bash
# Test port connectivity
telnet db.[PROJECT-REF].supabase.co 5432
nc -zv db.[PROJECT-REF].supabase.co 5432

# Test with timeout
timeout 5 bash -c "cat < /dev/null > /dev/tcp/db.[PROJECT-REF].supabase.co/5432"
echo $?  # 0 = success, 124 = timeout

# Check from different network
# Try: mobile hotspot, different WiFi, VPN
```

**Solutions:**
1. **Check corporate firewall**
   - Contact network admin
   - Request whitelist for:
     - `*.supabase.co` on port 5432
     - `*.pooler.supabase.com` on ports 5432, 6543

2. **Cloud provider security groups**
```bash
# AWS - Allow outbound on port 5432/6543
aws ec2 authorize-security-group-egress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 5432 \
  --cidr 0.0.0.0/0

# GCP - Allow outbound on port 5432/6543
gcloud compute firewall-rules create allow-postgres \
  --direction=EGRESS \
  --action=ALLOW \
  --rules=tcp:5432,tcp:6543 \
  --destination-ranges=0.0.0.0/0
```

3. **Use HTTP tunneling (last resort)**
```bash
# Use Supabase REST API instead of direct database connection
# Less efficient but works through HTTP/HTTPS
```

### Proxy/VPN Interference

**Problem:** Proxy or VPN interferes with database connection

**Diagnosis:**
```bash
# Check proxy settings
env | grep -i proxy

# Test without proxy
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# Test with VPN disabled
# Disable VPN temporarily and test connection
```

**Solutions:**
```bash
# 1. Configure proxy bypass
export NO_PROXY=".supabase.co,.supabase.com"

# 2. Configure application to bypass proxy
# Node.js
process.env.NO_PROXY = '.supabase.co';

# 3. Use VPN split tunneling
# Configure VPN to exclude Supabase domains

# 4. Contact network administrator
# Request direct access to:
# - *.supabase.co
# - *.pooler.supabase.com
```

## Diagnostic Commands

### Connection Testing

```bash
# Test basic connectivity
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -c "SELECT version();"

# Test with all connection parameters
psql "host=db.[PROJECT-REF].supabase.co port=5432 dbname=postgres user=postgres password=[PASSWORD] sslmode=require" \
  -c "SELECT current_database(), current_user;"

# Test connection timeout
timeout 10 psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -c "SELECT 1;"

# Test query performance
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -c "\timing" \
  -c "SELECT count(*) FROM pg_tables;"
```

### Health Checks

```sql
-- Check database is responding
SELECT 1;

-- Check database version
SELECT version();

-- Check current time (useful for timezone issues)
SELECT now(), current_timestamp, timezone('UTC', now());

-- Check active connections
SELECT 
  count(*) as total_connections,
  count(*) FILTER (WHERE state = 'active') as active,
  count(*) FILTER (WHERE state = 'idle') as idle
FROM pg_stat_activity;

-- Check database size
SELECT 
  pg_size_pretty(pg_database_size(current_database())) as database_size;

-- Check table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

### Performance Diagnostics

```sql
-- Check slow queries
SELECT 
  pid,
  now() - pg_stat_activity.query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE state != 'idle'
  AND now() - pg_stat_activity.query_start > interval '5 seconds'
ORDER BY duration DESC;

-- Check query statistics
SELECT 
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Check index usage
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Check cache hit ratio
SELECT 
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit) as heap_hit,
  sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as cache_hit_ratio
FROM pg_statio_user_tables;
```

### SSL/TLS Diagnostics

```bash
# Test SSL connection
openssl s_client -connect db.[PROJECT-REF].supabase.co:5432 \
  -starttls postgres

# Check certificate details
echo | openssl s_client -connect db.[PROJECT-REF].supabase.co:5432 \
  -starttls postgres 2>/dev/null | openssl x509 -noout -text

# Check certificate expiration
echo | openssl s_client -connect db.[PROJECT-REF].supabase.co:5432 \
  -starttls postgres 2>/dev/null | openssl x509 -noout -dates

# Test specific SSL modes
psql "sslmode=disable host=db.[PROJECT-REF].supabase.co ..." -c "SELECT 1;"
psql "sslmode=require host=db.[PROJECT-REF].supabase.co ..." -c "SELECT 1;"
psql "sslmode=verify-ca host=db.[PROJECT-REF].supabase.co ..." -c "SELECT 1;"
psql "sslmode=verify-full host=db.[PROJECT-REF].supabase.co ..." -c "SELECT 1;"
```

### Network Diagnostics

```bash
# DNS resolution
nslookup db.[PROJECT-REF].supabase.co
dig db.[PROJECT-REF].supabase.co
host db.[PROJECT-REF].supabase.co

# Test IPv4 vs IPv6
ping -4 db.[PROJECT-REF].supabase.co
ping -6 db.[PROJECT-REF].supabase.co

# Traceroute
traceroute db.[PROJECT-REF].supabase.co
mtr -r -c 10 db.[PROJECT-REF].supabase.co

# Port connectivity
nc -zv db.[PROJECT-REF].supabase.co 5432
telnet db.[PROJECT-REF].supabase.co 5432

# Check latency
ping -c 10 db.[PROJECT-REF].supabase.co

# Bandwidth test (rough)
time psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -c "SELECT repeat('x', 1000000);" > /dev/null
```

## Error Code Reference

### PostgreSQL Error Codes

| Error Code | Message | Meaning | Solution |
|-----------|---------|---------|----------|
| 08001 | sqlclient unable to establish sqlconnection | Cannot establish connection | Check network, credentials, SSL |
| 08003 | connection does not exist | Connection was closed | Reconnect, check connection pool |
| 08006 | connection failure | Connection failed | Check network, firewall |
| 08P01 | protocol violation | Invalid protocol | Check PostgreSQL client version |
| 28000 | invalid authorization specification | Authentication failed | Verify credentials |
| 28P01 | invalid password | Wrong password | Reset password in dashboard |
| 3D000 | invalid catalog name | Database doesn't exist | Check database name |
| 42501 | insufficient privilege | Permission denied | Grant required permissions |
| 53300 | too many connections | Connection limit reached | Close connections, upgrade tier |
| 57014 | query canceled | Query was cancelled | Check query timeout settings |
| 57P01 | admin shutdown | Database shutting down | Wait and reconnect |
| 57P02 | crash shutdown | Database crashed | Contact Supabase support |
| 57P03 | cannot connect now | Database starting up | Wait and retry |

### Common Library Error Codes

#### Node.js (pg)
```
ECONNREFUSED - Connection refused (check host/port)
ETIMEDOUT - Connection timeout (increase timeout)
ENOTFOUND - Cannot resolve hostname (check DNS)
ECONNRESET - Connection reset (check network)
DEPTH_ZERO_SELF_SIGNED_CERT - SSL certificate issue
```

#### Python (asyncpg)
```
InvalidPasswordError - Authentication failed
TooManyConnectionsError - Connection limit reached
ConnectionDoesNotExistError - Connection closed
InterfaceError - Interface/protocol error
PostgresError - General database error
```

### HTTP Status Codes (Supabase REST API)

| Status | Meaning | Solution |
|--------|---------|----------|
| 401 | Unauthorized | Check API key |
| 403 | Forbidden | Check RLS policies |
| 404 | Not Found | Check table/resource name |
| 406 | Not Acceptable | Check Accept header |
| 416 | Range Not Satisfiable | Check pagination parameters |
| 500 | Internal Server Error | Check server logs |
| 503 | Service Unavailable | Project paused or maintenance |

## Best Practices

### Connection Management

1. **Always use connection pooling**
   ```javascript
   const pool = new Pool({
     max: 10,
     idleTimeoutMillis: 30000
   });
   ```

2. **Always release connections**
   ```javascript
   const client = await pool.connect();
   try {
     // your code
   } finally {
     client.release();
   }
   ```

3. **Handle connection errors gracefully**
   ```javascript
   pool.on('error', (err) => {
     console.error('Unexpected error on idle client', err);
     // Don't exit, let pool recovery handle it
   });
   ```

4. **Implement retry logic**
   ```javascript
   async function queryWithRetry(fn, maxRetries = 3) {
     for (let i = 0; i < maxRetries; i++) {
       try {
         return await fn();
       } catch (error) {
         if (i === maxRetries - 1) throw error;
         await sleep(1000 * Math.pow(2, i));
       }
     }
   }
   ```

### Monitoring

1. **Log connection events**
   ```javascript
   pool.on('connect', () => console.log('Connection established'));
   pool.on('acquire', () => console.log('Connection acquired'));
   pool.on('remove', () => console.log('Connection removed'));
   ```

2. **Monitor pool metrics**
   ```javascript
   setInterval(() => {
     console.log({
       total: pool.totalCount,
       idle: pool.idleCount,
       waiting: pool.waitingCount
     });
   }, 60000);
   ```

3. **Set up alerts**
   - Connection pool exhaustion
   - Slow queries (> 5 seconds)
   - High connection count (> 80% of limit)
   - Failed authentication attempts

### Security

1. **Never commit credentials**
   - Use environment variables
   - Use secret management services
   - Rotate credentials regularly

2. **Use SSL in production**
   ```javascript
   ssl: {
     rejectUnauthorized: true
   }
   ```

3. **Limit permissions**
   - Use dedicated database users for agents
   - Grant minimal required permissions
   - Enable RLS policies

4. **Monitor for suspicious activity**
   - Failed login attempts
   - Unusual query patterns
   - High connection rates

## Getting Help

### Support Channels

1. **Supabase Documentation**
   - https://supabase.com/docs
   - https://supabase.com/docs/guides/database

2. **Community Support**
   - Discord: https://discord.supabase.com
   - GitHub Discussions: https://github.com/supabase/supabase/discussions

3. **Support Tickets**
   - Dashboard → Support
   - For Pro and Enterprise plans

4. **Status Page**
   - https://status.supabase.com
   - Check for ongoing incidents

### Providing Debug Information

When seeking help, include:

```bash
# 1. PostgreSQL version
psql -c "SELECT version();"

# 2. Client library versions
npm list pg
pip show asyncpg

# 3. Connection string format (without password)
echo $DATABASE_URL | sed 's/:.*@/:***@/'

# 4. Error messages
# Include full error stack trace

# 5. Network diagnostics
ping db.[PROJECT-REF].supabase.co
traceroute db.[PROJECT-REF].supabase.co

# 6. Connection test results
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -c "SELECT 1;"

# 7. Compute tier and limits
# From Dashboard → Settings → Add-ons
```

---

**Last Updated:** 2025-01-07  
**Version:** 1.0  
**Maintainers:** SkogAI Team
