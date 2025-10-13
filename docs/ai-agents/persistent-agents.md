# Persistent AI Agents Guide

## Overview

Persistent AI agents are long-running applications that maintain stable connections to Supabase databases. This guide covers setup, configuration, and best practices for persistent agents like Claude Desktop, local AI assistants, and always-on services.

## Characteristics

**Persistent Agents:**
- ✅ Long-running processes (hours/days)
- ✅ Stable network environment
- ✅ Predictable resource availability
- ✅ Can maintain connection pools
- ✅ Support for session state

**Common Examples:**
- Claude Desktop application
- Local AI assistants (ChatGPT Desktop, etc.)
- Development tools (VS Code extensions)
- Long-running data processing scripts
- Admin dashboards and management tools

## Recommended Connection Method

### Primary: Direct Connection (IPv6)

**Why Direct Connection:**
- Lowest latency
- Full PostgreSQL feature support
- Prepared statements supported
- Session state maintained
- No pooler overhead

**Requirements:**
- IPv6 network support
- Stable internet connection
- Local environment (not serverless)

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres
```

### Alternative: Session Mode (IPv4)

**When to use:**
- IPv6 not available
- Network requires IPv4
- Organization firewall restrictions

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres
```

## Setup Guide

### Step 1: Get Connection Details

1. **Navigate to Supabase Dashboard:**
   ```
   https://app.supabase.com/project/[YOUR-PROJECT]/settings/database
   ```

2. **Copy Connection String:**
   - For Direct: Use "Connection string" under "Direct connection"
   - For Session: Use "Connection string" under "Connection pooling" → "Session mode"

3. **Get Database Password:**
   - Settings → Database → Database password
   - Or reset if needed

### Step 2: Configure MCP Server

#### Claude Desktop Configuration

**macOS:**
```bash
# Edit Claude Desktop config
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Windows:**
```powershell
# Edit Claude Desktop config
notepad %APPDATA%\Claude\claude_desktop_config.json
```

**Configuration:**
```json
{
  "mcpServers": {
    "supabase": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres"
      ],
      "env": {
        "PGSSLMODE": "verify-full",
        "PGCONNECT_TIMEOUT": "10",
        "PGAPPNAME": "claude-desktop"
      }
    }
  }
}
```

**With SSL Certificate:**
```json
{
  "mcpServers": {
    "supabase": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres"
      ],
      "env": {
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "/Users/[USERNAME]/.supabase/certs/supabase-ca.crt",
        "PGCONNECT_TIMEOUT": "10",
        "PGAPPNAME": "claude-desktop"
      }
    }
  }
}
```

#### Local AI Assistant (Node.js)

**Installation:**
```bash
npm install pg dotenv
```

**Environment Variables (.env):**
```bash
# Connection Details
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_DB_PASSWORD=your-password

# Direct Connection (IPv6)
DATABASE_URL=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@${SUPABASE_PROJECT_REF}.supabase.co:5432/postgres

# Or Session Mode (IPv4)
# DATABASE_URL=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-us-east-1.pooler.supabase.com:5432/postgres

# SSL Configuration
PGSSLMODE=verify-full
SSL_CERT_PATH=/path/to/supabase-ca.crt

# Pool Configuration
DB_POOL_MIN=5
DB_POOL_MAX=20
DB_IDLE_TIMEOUT_MS=300000
```

**Application Code:**
```javascript
require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync(process.env.SSL_CERT_PATH).toString()
  },
  min: parseInt(process.env.DB_POOL_MIN || '5'),
  max: parseInt(process.env.DB_POOL_MAX || '20'),
  idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT_MS || '300000'),
  connectionTimeoutMillis: 10000,
  application_name: 'persistent-ai-agent'
});

// Health check on startup
async function initialize() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log('✅ Connected to Supabase:', result.rows[0]);
    client.release();
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await pool.end();
  process.exit(0);
});

initialize();

module.exports = pool;
```

#### Python AI Assistant

**Installation:**
```bash
pip install psycopg2-binary python-dotenv
```

**Environment Variables (.env):**
```bash
DATABASE_URL=postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres
PGSSLMODE=verify-full
SSL_CERT_PATH=/path/to/supabase-ca.crt
```

**Application Code:**
```python
import os
from dotenv import load_dotenv
import psycopg2
from psycopg2 import pool

load_dotenv()

# Create connection pool
connection_pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=5,
    maxconn=20,
    dsn=os.environ['DATABASE_URL'],
    sslmode=os.environ.get('PGSSLMODE', 'verify-full'),
    sslrootcert=os.environ.get('SSL_CERT_PATH'),
    application_name='persistent-ai-agent'
)

def get_connection():
    """Get connection from pool"""
    return connection_pool.getconn()

def release_connection(conn):
    """Return connection to pool"""
    connection_pool.putconn(conn)

# Test connection
try:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT NOW()')
    result = cursor.fetchone()
    print(f'✅ Connected to Supabase: {result[0]}')
    cursor.close()
    release_connection(conn)
except Exception as e:
    print(f'❌ Connection failed: {e}')
    exit(1)

# Graceful shutdown
import atexit

def cleanup():
    connection_pool.closeall()

atexit.register(cleanup)
```

### Step 3: Verify Connection

**Test with psql:**
```bash
# Direct connection
psql "postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres" \
  -c "SELECT version();"

# Session mode
psql "postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres" \
  -c "SELECT version();"
```

**Test in your application:**
```javascript
// Node.js
async function testConnection() {
  const result = await pool.query('SELECT NOW(), current_user, version()');
  console.log('Connection test:', result.rows[0]);
}

testConnection();
```

```python
# Python
def test_connection():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT NOW(), current_user, version()')
    result = cursor.fetchone()
    print(f'Connection test: {result}')
    cursor.close()
    release_connection(conn)

test_connection()
```

## Connection Pool Configuration

### Optimal Pool Settings

**For Persistent Agents:**
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  
  // Pool size
  min: 5,           // Keep 5 connections always ready
  max: 20,          // Allow up to 20 connections
  
  // Timeouts
  idleTimeoutMillis: 300000,      // 5 minutes - connections idle longer are closed
  connectionTimeoutMillis: 10000,  // 10 seconds - timeout acquiring connection
  
  // Statement timeout (prevent runaway queries)
  statement_timeout: 60000,  // 60 seconds
  
  // Query timeout
  query_timeout: 30000,      // 30 seconds
  
  // Application identification
  application_name: 'persistent-ai-agent',
  
  // Keep-alive
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000
});
```

### Pool Size Calculation

**Formula:**
```
max connections = (expected concurrent operations × 1.5) + buffer

Example:
- 10 concurrent operations expected
- 10 × 1.5 = 15
- Add 5 buffer = 20 max connections
```

**Considerations:**
- Database connection limit (default 100 for Supabase)
- Other services sharing the database
- Memory overhead per connection
- Expected query duration

## Best Practices

### 1. Connection Reuse

```javascript
// ✅ Good - Reuse pool
const pool = new Pool({ /* config */ });

async function queryDatabase(sql, params) {
  return await pool.query(sql, params);
}

// ❌ Bad - Creates new pool every time
async function queryDatabase(sql, params) {
  const pool = new Pool({ /* config */ });  // DON'T DO THIS
  const result = await pool.query(sql, params);
  await pool.end();
  return result;
}
```

### 2. Always Release Connections

```javascript
// ✅ Good - Always release
async function complexQuery() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result1 = await client.query('SELECT ...');
    const result2 = await client.query('INSERT ...');
    await client.query('COMMIT');
    return result1;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();  // Always release
  }
}

// ❌ Bad - Forgets to release on error
async function complexQuery() {
  const client = await pool.connect();
  await client.query('BEGIN');
  const result = await client.query('SELECT ...');
  await client.query('COMMIT');
  client.release();
  return result;  // Leak if query throws error
}
```

### 3. Handle Errors Gracefully

```javascript
pool.on('error', (err, client) => {
  console.error('Unexpected pool error:', err);
  // Log to monitoring service
  // Don't exit process - pool will recover
});

pool.on('connect', (client) => {
  console.log('New client connected');
});

pool.on('remove', (client) => {
  console.log('Client removed from pool');
});
```

### 4. Implement Retry Logic

```javascript
async function queryWithRetry(sql, params, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await pool.query(sql, params);
    } catch (err) {
      if (attempt === maxRetries) throw err;
      
      // Retry on transient errors
      if (err.code === 'ECONNRESET' || 
          err.code === 'ETIMEDOUT' ||
          err.message.includes('Connection terminated')) {
        console.warn(`Query failed (attempt ${attempt}), retrying...`);
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      } else {
        throw err;  // Don't retry permanent errors
      }
    }
  }
}
```

### 5. Monitor Connection Health

```javascript
// Health check every minute
setInterval(async () => {
  try {
    await pool.query('SELECT 1');
    console.log('✅ Database healthy', {
      total: pool.totalCount,
      idle: pool.idleCount,
      waiting: pool.waitingCount
    });
  } catch (err) {
    console.error('❌ Database unhealthy:', err.message);
  }
}, 60000);
```

## Advanced Features

### Prepared Statements

**Supported on:**
- ✅ Direct Connection (port 5432)
- ✅ Session Mode (port 5432)

```javascript
// Automatic prepared statements
async function getUser(userId) {
  // pg automatically uses prepared statements
  const result = await pool.query(
    'SELECT * FROM users WHERE id = $1',
    [userId]
  );
  return result.rows[0];
}

// Named prepared statements
async function setupPreparedStatements(client) {
  await client.query({
    name: 'get_user',
    text: 'SELECT * FROM users WHERE id = $1'
  });
  
  // Later use
  const result = await client.query({
    name: 'get_user',
    values: [123]
  });
}
```

### Transaction Management

```javascript
async function transferData() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // Multiple operations in transaction
    await client.query('UPDATE accounts SET balance = balance - 100 WHERE id = $1', [1]);
    await client.query('UPDATE accounts SET balance = balance + 100 WHERE id = $1', [2]);
    
    await client.query('COMMIT');
    console.log('Transaction committed');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Transaction rolled back:', err);
    throw err;
  } finally {
    client.release();
  }
}
```

### Listen/Notify (Real-time)

```javascript
const { Client } = require('pg');

async function setupRealtime() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: true,
      ca: fs.readFileSync(process.env.SSL_CERT_PATH).toString()
    }
  });
  
  await client.connect();
  
  // Listen for notifications
  await client.query('LISTEN data_changes');
  
  client.on('notification', (msg) => {
    console.log('Received notification:', msg.channel, msg.payload);
  });
  
  // Keep connection alive
  setInterval(() => {
    client.query('SELECT 1');
  }, 60000);
}

setupRealtime();
```

## Troubleshooting

### Common Issues

1. **"Connection timeout"**
   - Check network connectivity
   - Verify firewall allows port 5432
   - Increase `connectionTimeoutMillis`

2. **"Too many connections"**
   - Reduce `max` pool size
   - Check for connection leaks
   - Consider using Session Mode

3. **"SSL error"**
   - Download CA certificate
   - Set `PGSSLMODE=verify-full`
   - Verify certificate path

See [Troubleshooting Guide](../mcp-setup/troubleshooting.md) for more details.

## Performance Optimization

### 1. Use Indexes

```sql
-- Create indexes for frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
```

### 2. Use Connection Pooling

```javascript
// ✅ Good - Single pool for application
const pool = new Pool({ /* config */ });

// Export and reuse
module.exports = pool;
```

### 3. Batch Operations

```javascript
// ✅ Good - Batch insert
async function insertMany(records) {
  const values = records.map((r, i) => 
    `($${i*2+1}, $${i*2+2})`
  ).join(',');
  
  const params = records.flatMap(r => [r.name, r.email]);
  
  await pool.query(
    `INSERT INTO users (name, email) VALUES ${values}`,
    params
  );
}

// ❌ Bad - Individual inserts
async function insertMany(records) {
  for (const record of records) {
    await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2)',
      [record.name, record.email]
    );
  }
}
```

## Next Steps

- **Quick Start**: [MCP Quick Start](../mcp-setup/quickstart.md)
- **Configuration**: [Configuration Templates](../mcp-setup/configuration-templates.md)
- **Connection Types**: [Connection Methods](../mcp-setup/connection-types.md)
- **Troubleshooting**: [Common Issues](../mcp-setup/troubleshooting.md)
- **Monitoring**: [Setup Monitoring](../mcp-setup/monitoring.md)

## Related Guides

- [Serverless AI Agents](./serverless-agents.md)
- [Edge AI Agents](./edge-agents.md)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0
