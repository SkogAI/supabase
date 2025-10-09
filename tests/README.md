# Database Test Suites

Automated tests for database security, RLS policies, and AI agent authentication.

## Overview

This directory contains SQL test scripts to validate database functionality:
# Database Test and Diagnostic Suite

Automated tests and diagnostic tools for database configuration, RLS policies, connection health, and performance monitoring.

## Overview

This directory contains SQL test scripts and diagnostic tools to validate database configuration and troubleshoot issues. These tools verify that:

### RLS Policy Test Suite (`rls_test_suite.sql`)
- RLS is enabled on all public tables
- Service role has full access
- Authenticated users can only access/modify their own data
- Anonymous users have read-only access to published content
- No accidental data exposure occurs

### AI Agent Authentication Test Suite (`ai_agent_authentication_test.sql`)
- AI agent roles are created correctly
- Audit logging infrastructure is functional
- RLS policies protect audit tables
- API key generation and validation works
- Authentication and query logging is operational
## Available Test Suites

### 1. Profiles Basic Tests (`profiles_basic_test_suite.sql`) ⭐ NEW

Small, incremental unit tests to verify profiles functionality is working.

**What it tests:**
- Profiles table exists with expected columns
- RLS is enabled
- Required constraints (unique username, foreign key)
- Trigger for auto-creating profiles exists
- Seed data loaded correctly
- Basic query operations work

**Run with:**
```bash
supabase db execute --file tests/profiles_basic_test_suite.sql
```

### 2. RLS Policy Tests (`rls_test_suite.sql`)

Tests Row Level Security policies to ensure proper access control.

### 3. Storage Tests (`storage_test_suite.sql`)

Tests storage bucket policies and file access permissions.

### 4. Connection Diagnostics (`connection_diagnostics.sql`)

Comprehensive diagnostic tests for database connectivity and configuration.

### 5. Pool Monitoring (`pool_monitoring.sql`)

Real-time monitoring of connection pool usage and health.

## Running Tests

### Using npm Scripts (Recommended)

```bash
# Start Supabase (if not already running)
npm run db:start

# Reset database with migrations and seed data
npm run db:reset

# Run the RLS test suite
npm run test:rls
# or: supabase db execute --file tests/rls_test_suite.sql

# Run the AI Agent Authentication test suite
supabase db execute --file tests/ai_agent_authentication_test.sql

# Run all tests
supabase db execute --file tests/rls_test_suite.sql
supabase db execute --file tests/ai_agent_authentication_test.sql
# Run RLS tests
npm run test:rls

# Run storage tests
npm run test:storage

# Run connection diagnostics
npm run diagnose:connection

# Run pool monitoring
npm run diagnose:pool
```

### Using Shell Scripts

```bash
# Test database connection (with detailed diagnostics)
npm run test:connection
# Or with custom connection string:
bash scripts/test-connection.sh "postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"

# Check database health
npm run test:db-health
# Or with custom connection string:
bash scripts/check-db-health.sh "postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
```

### Using Supabase CLI Directly

```bash
# Run any test suite
supabase db execute --file tests/rls_test_suite.sql
supabase db execute --file tests/storage_test_suite.sql
supabase db execute --file tests/connection_diagnostics.sql
supabase db execute --file tests/pool_monitoring.sql
```

### Option 2: Using Supabase Studio

1. Start Supabase: `npm run db:start`
2. Open Supabase Studio: http://localhost:8000
3. Navigate to **SQL Editor**
4. Open `tests/rls_test_suite.sql` or `tests/ai_agent_authentication_test.sql`
5. Copy and paste the entire file
6. Click **Run** to execute all tests

### Option 3: Using psql

```bash
# Connect to local database
psql postgresql://postgres:postgres@localhost:54322/postgres

# Run RLS tests
\i tests/rls_test_suite.sql

# Run AI Agent Authentication tests
\i tests/ai_agent_authentication_test.sql
```

## Test Coverage

### RLS Test Suite

The test suite includes:
### RLS Policy Tests

1. **RLS Status Check** - Verifies RLS is enabled on all tables
2. **Policy Inventory** - Lists all policies by table
3. **Service Role Tests** - Verifies admin access
4. **Authenticated User Tests** - Tests logged-in user permissions
5. **Anonymous User Tests** - Tests unauthenticated access
6. **Write Operation Tests** - Verifies anonymous users cannot modify data
7. **Cross-User Access** - Ensures users can't access other users' private data
8. **Service Role Bypass** - Confirms admins can perform any operation

### Storage Tests

1. **Bucket Configuration** - Verifies bucket settings
2. **Upload Permissions** - Tests file upload access
3. **Download Permissions** - Tests file download access
4. **Public vs Private** - Validates access controls
5. **File Size Limits** - Tests size restrictions

### Connection Diagnostics

1. **Basic Connection** - Verifies database connectivity
2. **Database Information** - Shows version, uptime, configuration
3. **SSL Status** - Checks SSL/TLS encryption
4. **Connection Limits** - Shows usage vs. capacity
5. **Active Connections** - Breakdown by state
6. **Long-Running Queries** - Identifies slow queries
7. **Idle in Transaction** - Detects connection leaks
8. **Database Locks** - Shows blocking queries
9. **RLS Configuration** - Lists tables with RLS enabled
10. **Table Permissions** - Shows current user permissions
11. **Database Size** - Shows storage usage
12. **Cache Performance** - Shows buffer/index cache hit ratios
13. **Replication Status** - Shows replica information (if configured)
14. **Prepared Statements** - Tests session vs. transaction mode
15. **Extensions** - Lists installed extensions

### Pool Monitoring

1. **Connection Summary** - Total, active, idle connections
2. **Connections by User** - Breakdown by database user
3. **Connections by Application** - Breakdown by app name
4. **Connections by Client** - Breakdown by IP address
5. **Connection Age** - How long connections have been open
6. **Active Query Duration** - Currently running queries
7. **Idle Connections** - Long idle connections
8. **Idle in Transaction** - Potential connection leaks
9. **Pool Health Metrics** - Overall health assessment
10. **Connection Settings** - Current configuration
11. **Recent Activity** - Connection establishment rate
12. **Database Statistics** - Transaction and cache stats

## Expected Output

When all tests pass, you'll see output like:

```
================================================================================
RLS POLICY TEST SUITE
================================================================================

TEST 1: Verifying RLS is enabled on all public tables...
NOTICE:  PASS: All public tables have RLS enabled

TEST 2: Listing all RLS policies...
 tablename | policy_count
-----------+--------------
 posts     |            8
 profiles  |            7

TEST 3: Testing service role access...
NOTICE:  PASS: Service role can view all profiles (3 found)
NOTICE:  PASS: Service role can view all posts (7 found)

TEST 4: Testing authenticated user access (Alice)...
NOTICE:  PASS: Authenticated user can view all profiles (3 found)
NOTICE:  PASS: Authenticated user can view posts (7 found)
NOTICE:  PASS: Authenticated user can view own drafts (1 found)
NOTICE:  PASS: Authenticated user can update own profile
NOTICE:  PASS: Authenticated user cannot update other profiles

TEST 5: Testing anonymous user access...
NOTICE:  PASS: Anonymous user can view all profiles (3 found)
NOTICE:  PASS: Anonymous user can only view published posts (6 found)

TEST 6: Testing anonymous user cannot modify data...
NOTICE:  PASS: Anonymous user cannot insert posts
NOTICE:  PASS: Anonymous user cannot update posts
NOTICE:  PASS: Anonymous user cannot delete posts

TEST 7: Testing cross-user access restrictions...
NOTICE:  PASS: User cannot see other users' drafts

TEST 8: Testing service role can bypass all restrictions...
NOTICE:  PASS: Service role can update any post

================================================================================
TEST SUITE COMPLETE
================================================================================
All tests passed! RLS policies are working correctly.

Summary:
  ✅ RLS enabled on all public tables
  ✅ Service role has full access
  ✅ Authenticated users can view all public data
  ✅ Authenticated users can only modify own data
  ✅ Anonymous users have read-only access to published content
  ✅ Anonymous users cannot modify any data
  ✅ Cross-user access is properly restricted

================================================================================
```

## Diagnostic Scripts

### test-connection.sh

Comprehensive connection test script that validates:
- Network connectivity (DNS, ping, port reachability)
- SSL/TLS configuration
- Database authentication
- Query execution
- Prepared statement support
- RLS policy configuration
- IPv6 vs IPv4 detection

**Usage:**
```bash
# Using DATABASE_URL environment variable
export DATABASE_URL="postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
npm run test:connection

# Or with direct connection string
bash scripts/test-connection.sh "postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
```

**Example Output:**
```
========================================
AI Agent Database Connection Test
========================================
Host: db.xxx.supabase.co
Port: 5432
Timestamp: 2025-01-07 10:30:00

========================================
Checking Requirements
========================================
✓ psql is installed: psql (PostgreSQL) 14.9
✓ openssl is installed: OpenSSL 1.1.1
✓ netcat is installed

========================================
Testing Network Connectivity
========================================
✓ DNS resolution successful
✓ Port 5432 is reachable
✓ Host is responding to ping
  rtt min/avg/max = 10.5/12.3/15.1 ms

========================================
Testing SSL/TLS Connection
========================================
✓ SSL connection successful with valid certificate
  subject: CN=*.supabase.co
  issuer: CN=Let's Encrypt Authority
  notAfter: 2025-04-01

========================================
Testing Database Connection
========================================
✓ Connection successful
✓ Query executed successfully
  PostgreSQL version: PostgreSQL 15.1
  Database: postgres, User: postgres, SSL: Yes
  Total: 5, Active: 1, Idle: 4
```

### check-db-health.sh

Real-time database health monitoring that checks:
- Connection pool usage and capacity
- Active queries and performance
- Long-running queries
- Idle in transaction connections
- Database locks and blocking queries
- Database size and table statistics
- Cache hit ratios
- SSL status

**Usage:**
```bash
# Using DATABASE_URL environment variable
export DATABASE_URL="postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
npm run test:db-health

# Or with direct connection string
bash scripts/check-db-health.sh "postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
```

**Example Output:**
```
========================================
Database Health Check
========================================
Timestamp: 2025-01-07 10:35:00

========================================
1. Basic Connectivity
========================================
✓ Database is reachable

========================================
3. Connection Statistics
========================================
 max_connections | current_connections | available_connections | usage_percent
-----------------+---------------------+----------------------+---------------
              60 |                  12 |                   48 |         20.00

✓ Connection usage is healthy: 20% (12/60)

========================================
5. Active Queries
========================================
✓ No active queries (database is idle)

========================================
7. Idle in Transaction
========================================
✓ No connections idle in transaction

========================================
Health Check Summary
========================================
✓ Database health is good! No issues detected.
```

## Troubleshooting

### Test Failures

If tests fail:

1. **Check database state**: Ensure you've run `npm run db:reset` to apply migrations and seed data
2. **Check migration order**: Migrations must be applied in order
3. **Check seed data**: The test suite expects specific test users (Alice, Bob, Charlie)
4. **Check Supabase version**: Ensure you're using a recent version of Supabase CLI

### Connection Issues

If connection tests fail:

1. **Check project status**: Verify project is not paused in Supabase dashboard
2. **Verify credentials**: Get correct database password from Settings → Database
3. **Test network**: Ensure outbound connections on port 5432/6543 are allowed
4. **Check SSL**: Try with different SSL modes (disable, require, verify-full)
5. **IPv4/IPv6**: If IPv6 fails, switch to Supavisor session mode

See the comprehensive troubleshooting guide: `docs/MCP_TROUBLESHOOTING.md`

### Common Issues

**"Table or view not found"**
- Solution: Run `npm run db:reset` to create tables

**"Test user not found"**
- Solution: Verify seed data was loaded (`supabase/seed.sql`)

**"Permission denied"**
- Solution: Check if RLS is enabled: `SELECT rowsecurity FROM pg_tables WHERE tablename = 'your_table'`

**"Connection refused"**
- Solution: Check if project is paused, verify connection string, test network connectivity

**"Password authentication failed"**
- Solution: Verify database password in Settings → Database, not anon key or service role key

**"SSL connection error"**
- Solution: Try `sslmode=require` instead of `sslmode=verify-full`, update CA certificates

**"Too many connections"**
- Solution: Close idle connections, reduce pool size, or upgrade compute tier

**"Prepared statement does not exist"**
- Solution: Disable prepared statements if using transaction mode (port 6543)

## CI/CD Integration

These tests can be integrated into your CI/CD pipeline:

```yaml
# In .github/workflows/migrations-validation.yml
- name: Run RLS tests
  run: |
    supabase start
    supabase db reset
    supabase db execute --file tests/rls_test_suite.sql
```

## Writing Custom Tests

To add new tests:

1. Follow the existing test structure
2. Use DO blocks with proper error handling
3. Test both positive (should work) and negative (should fail) cases
4. Always clean up after tests (revert changes)
5. Document expected behavior

Example:

```sql
-- Test: New feature
DO $$
BEGIN
    -- Your test logic here
    IF condition THEN
        RAISE NOTICE 'PASS: Test description';
    ELSE
        RAISE EXCEPTION 'FAIL: Test description';
    END IF;
END $$;
```

## CI/CD Integration

These diagnostic tools can be integrated into your CI/CD pipeline:

```yaml
# In .github/workflows/database-tests.yml
- name: Run RLS tests
  run: npm run test:rls

- name: Run connection diagnostics
  run: npm run diagnose:connection

- name: Run pool monitoring
  run: npm run diagnose:pool

- name: Check database health
  run: npm run test:db-health
```

## Documentation

For more information:

- [AI Agent Troubleshooting Guide](../docs/MCP_TROUBLESHOOTING.md) - **Comprehensive troubleshooting for connection issues**
- [MCP Connection Examples](../docs/MCP_CONNECTION_EXAMPLES.md) - Code examples for various connection scenarios
- [MCP Server Configuration](../docs/MCP_SERVER_CONFIGURATION.md) - Configuration templates
- [MCP Authentication](../docs/MCP_AUTHENTICATION.md) - Authentication strategies
- [RLS Policy Documentation](../docs/RLS_POLICIES.md) - RLS best practices
- [RLS Testing Guidelines](../docs/RLS_TESTING.md) - RLS testing guide
- [Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)

## Quick Reference

### Common Commands

```bash
# Start local development
npm run db:start

# Run all tests
npm run test:rls
npm run test:storage
npm run diagnose:connection
npm run diagnose:pool

# Check health
npm run test:connection
npm run test:db-health

# Monitor in real-time (run periodically)
watch -n 5 'npm run test:db-health'
```

### Environment Variables

```bash
# Set for all commands
export DATABASE_URL="postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"

# Or use different connection types
export DATABASE_URL="postgresql://postgres.xxx:[password]@aws-0-us-east-1.pooler.supabase.com:5432/postgres"  # Session mode
export DATABASE_URL="postgresql://postgres.xxx:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres"  # Transaction mode
```

---

**Last Updated**: 2025-01-07
**Version**: 2.0.0
