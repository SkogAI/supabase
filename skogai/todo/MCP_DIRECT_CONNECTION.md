# Direct Database Connection for Persistent AI Agents (IPv6)

## Overview

Direct database connections provide the lowest latency and full PostgreSQL feature support for long-running, persistent AI agents. This guide covers setup, configuration, and best practices for using direct IPv6 connections with Supabase.

## Table of Contents

- [When to Use Direct Connections](#when-to-use-direct-connections)
- [IPv6 Requirements](#ipv6-requirements)
- [Connection String Format](#connection-string-format)
- [Environment Configuration](#environment-configuration)
- [MCP Server Configuration](#mcp-server-configuration)
- [Connection Health Checks](#connection-health-checks)
- [Connection Retry Logic](#connection-retry-logic)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Comparison with Other Connection Methods](#comparison-with-other-connection-methods)

## When to Use Direct Connections

### ✅ Recommended For:

- **Persistent AI agent servers** running on VMs or containers
- **Long-running processes** with stable execution environments
- **Workloads requiring prepared statements** for performance optimization
- **Applications needing full PostgreSQL features** (LISTEN/NOTIFY, custom types, etc.)
- **Low-latency requirements** where every millisecond counts
- **Single-session workflows** (monitoring agents, data analysis agents)

### ❌ Not Recommended For:

- **Serverless functions** (AWS Lambda, Google Cloud Functions) - Use Transaction Mode instead
- **Edge functions** (Cloudflare Workers, Vercel Edge) - Use Transaction Mode instead
- **Mobile applications** - Use Supabase client libraries instead
- **Environments without IPv6 support** - Use Session Mode instead
- **Applications with unpredictable connection patterns** - Use pooled connections

## IPv6 Requirements

### Network Requirements

Direct connections to Supabase databases use **IPv6 by default**. Ensure your environment supports IPv6:

#### Checking IPv6 Support

**Linux/macOS:**
```bash
# Check if IPv6 is enabled
ip -6 addr show

# Test IPv6 connectivity to Supabase
ping6 -c 4 db.[PROJECT-REF].supabase.co

# Test database connection
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" -c "SELECT version();"
```

**Node.js:**
```javascript
// Test IPv6 support
import { isIPv6 } from 'net';
import dns from 'dns/promises';

async function checkIPv6Support() {
  try {
    const addresses = await dns.resolve6('db.apbkobhfnmcqqzqeeqss.supabase.co');
    console.log('IPv6 addresses found:', addresses);
    console.log('IPv6 is supported ✅');
    return true;
  } catch (error) {
    console.error('IPv6 not available:', error.message);
    return false;
  }
}

checkIPv6Support();
```

**Docker:**
```yaml
# docker-compose.yml
version: '3.8'
services:
  ai-agent:
    image: your-agent:latest
    # Enable IPv6 in Docker
    networks:
      - agent-network

networks:
  agent-network:
    enable_ipv6: true
    ipam:
      config:
        - subnet: 2001:db8::/64
```

### IPv6 Limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Cloud provider doesn't support IPv6 | Cannot use direct connections | Use Supavisor Session Mode (IPv4) |
| Corporate firewall blocks IPv6 | Connection failures | Use Session Mode or configure firewall |
| Docker default network is IPv4-only | Connection timeouts | Enable IPv6 in Docker networks |
| Some hosting providers (Heroku, Railway) | No IPv6 support | Use Transaction Mode instead |

### IPv4 Fallback

If IPv6 is not available, use **Supavisor Session Mode** which provides similar benefits over IPv4:

```bash
# Session Mode (IPv4) - persistent connections
SUPABASE_SESSION_CONNECTION=postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

## Connection String Format

### Direct IPv6 Connection String

```
postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
```

### Components Breakdown

| Component | Description | Example |
|-----------|-------------|---------|
| `postgres` | Database user (default superuser) | `postgres` |
| `[YOUR-PASSWORD]` | Database password from Supabase Dashboard | `your_secure_password_123` |
| `db.[PROJECT-REF].supabase.co` | Direct database host (resolves to IPv6) | `db.apbkobhfnmcqqzqeeqss.supabase.co` |
| `5432` | PostgreSQL default port | `5432` |
| `postgres` | Database name | `postgres` |

### Finding Your Connection String

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Project Settings** → **Database**
4. Find **Connection String** section
5. Select **URI** tab
6. Copy the connection string under **Direct connection**
7. Replace `[YOUR-PASSWORD]` with your actual database password

### Connection String Parameters

Add optional parameters to customize behavior:

```bash
# With SSL mode
postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres?sslmode=require

# With connection timeout
postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres?connect_timeout=10

# With application name (helps with monitoring)
postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres?application_name=ai_agent_v1

# Combined parameters
postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres?sslmode=require&connect_timeout=10&application_name=ai_agent_v1&statement_timeout=30000
```

**Common Parameters:**

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `sslmode` | SSL connection mode | `prefer` | `require`, `verify-full` |
| `connect_timeout` | Connection timeout (seconds) | `0` (no limit) | `10` |
| `application_name` | Identifier in pg_stat_activity | (none) | `my_ai_agent` |
| `statement_timeout` | Max query execution time (ms) | `0` | `30000` |
| `idle_in_transaction_session_timeout` | Max idle time in transaction (ms) | `0` | `60000` |

## Environment Configuration

### Complete .env Setup

```bash
# Direct IPv6 Connection Configuration
SUPABASE_DIRECT_CONNECTION=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Connection Pool Settings
SUPABASE_DIRECT_POOL_MIN=5
SUPABASE_DIRECT_POOL_MAX=20
SUPABASE_DIRECT_POOL_IDLE_TIMEOUT=300000
SUPABASE_DIRECT_POOL_CONNECTION_TIMEOUT=10000

# IPv6 Support
SUPABASE_DIRECT_IPV6_ENABLED=true

# Health Check Configuration
SUPABASE_DIRECT_HEALTH_CHECK_ENABLED=true
SUPABASE_DIRECT_HEALTH_CHECK_INTERVAL=30000
SUPABASE_DIRECT_HEALTH_CHECK_TIMEOUT=5000

# Retry Logic
SUPABASE_DIRECT_RETRY_MAX_ATTEMPTS=3
SUPABASE_DIRECT_RETRY_INITIAL_DELAY=1000
SUPABASE_DIRECT_RETRY_MAX_DELAY=10000
SUPABASE_DIRECT_RETRY_BACKOFF_MULTIPLIER=2

# SSL Settings
SUPABASE_DIRECT_SSL_ENABLED=true
SUPABASE_DIRECT_SSL_REJECT_UNAUTHORIZED=true

# Monitoring
SUPABASE_CONNECTION_MONITORING_ENABLED=true
SUPABASE_CONNECTION_LOG_LEVEL=info
```

### Security Best Practices

**✅ DO:**
- Store connection strings in environment variables
- Use strong, unique database passwords
- Rotate passwords regularly (every 90 days)
- Enable SSL/TLS for all connections
- Set appropriate connection timeouts
- Use least-privilege database users when possible

**❌ DON'T:**
- Hardcode credentials in source code
- Commit `.env` files to version control
- Share credentials across environments
- Use the same password for multiple databases
- Disable SSL verification in production

## MCP Server Configuration

### Basic Configuration

```json
{
  "mcpServers": {
    "supabase-direct": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_DIRECT_CONNECTION}"
      ],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_DIRECT_CONNECTION}",
        "POSTGRES_POOL_MIN": "5",
        "POSTGRES_POOL_MAX": "20",
        "POSTGRES_POOL_IDLE_TIMEOUT": "300000",
        "POSTGRES_SSL_ENABLED": "true"
      }
    }
  }
}
```

### Advanced Configuration with Health Checks

```json
{
  "mcpServers": {
    "supabase-direct-persistent": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_DIRECT_CONNECTION}",
        "--pool-min",
        "5",
        "--pool-max",
        "20",
        "--idle-timeout",
        "300000",
        "--connection-timeout",
        "10000",
        "--health-check-interval",
        "30000"
      ],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_DIRECT_CONNECTION}",
        "POSTGRES_POOL_MIN": "${SUPABASE_DIRECT_POOL_MIN}",
        "POSTGRES_POOL_MAX": "${SUPABASE_DIRECT_POOL_MAX}",
        "POSTGRES_POOL_IDLE_TIMEOUT": "${SUPABASE_DIRECT_POOL_IDLE_TIMEOUT}",
        "POSTGRES_POOL_CONNECTION_TIMEOUT": "${SUPABASE_DIRECT_POOL_CONNECTION_TIMEOUT}",
        "POSTGRES_SSL_ENABLED": "${SUPABASE_DIRECT_SSL_ENABLED}",
        "POSTGRES_SSL_REJECT_UNAUTHORIZED": "${SUPABASE_DIRECT_SSL_REJECT_UNAUTHORIZED}",
        "POSTGRES_HEALTH_CHECK_ENABLED": "${SUPABASE_DIRECT_HEALTH_CHECK_ENABLED}",
        "POSTGRES_HEALTH_CHECK_INTERVAL": "${SUPABASE_DIRECT_HEALTH_CHECK_INTERVAL}",
        "LOG_LEVEL": "${SUPABASE_CONNECTION_LOG_LEVEL}"
      }
    }
  }
}
```

### Node.js Implementation

```typescript
// mcp-server.ts
import pg from 'pg';
const { Pool } = pg;

interface MCPConfig {
  connectionString: string;
  pool: {
    min: number;
    max: number;
    idleTimeoutMillis: number;
    connectionTimeoutMillis: number;
  };
  ssl: {
    enabled: boolean;
    rejectUnauthorized: boolean;
  };
  healthCheck: {
    enabled: boolean;
    interval: number;
    timeout: number;
  };
}

class DirectConnectionMCPServer {
  private pool: pg.Pool;
  private healthCheckInterval?: NodeJS.Timeout;

  constructor(config: MCPConfig) {
    this.pool = new Pool({
      connectionString: config.connectionString,
      min: config.pool.min,
      max: config.pool.max,
      idleTimeoutMillis: config.pool.idleTimeoutMillis,
      connectionTimeoutMillis: config.pool.connectionTimeoutMillis,
      ssl: config.ssl.enabled ? {
        rejectUnauthorized: config.ssl.rejectUnauthorized
      } : false,
      application_name: 'mcp-server-direct'
    });

    if (config.healthCheck.enabled) {
      this.startHealthCheck(config.healthCheck.interval);
    }

    // Handle pool errors
    this.pool.on('error', (err) => {
      console.error('Unexpected pool error:', err);
    });
  }

  private startHealthCheck(interval: number): void {
    this.healthCheckInterval = setInterval(async () => {
      try {
        const result = await this.pool.query('SELECT 1 as health_check');
        console.log('Health check passed:', result.rows[0]);
      } catch (error) {
        console.error('Health check failed:', error);
      }
    }, interval);
  }

  async query(sql: string, params: any[] = []) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(sql, params);
      return result.rows;
    } finally {
      client.release();
    }
  }

  async close(): Promise<void> {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }
    await this.pool.end();
  }
}

// Usage
const config: MCPConfig = {
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION!,
  pool: {
    min: parseInt(process.env.SUPABASE_DIRECT_POOL_MIN || '5'),
    max: parseInt(process.env.SUPABASE_DIRECT_POOL_MAX || '20'),
    idleTimeoutMillis: parseInt(process.env.SUPABASE_DIRECT_POOL_IDLE_TIMEOUT || '300000'),
    connectionTimeoutMillis: parseInt(process.env.SUPABASE_DIRECT_POOL_CONNECTION_TIMEOUT || '10000')
  },
  ssl: {
    enabled: process.env.SUPABASE_DIRECT_SSL_ENABLED === 'true',
    rejectUnauthorized: process.env.SUPABASE_DIRECT_SSL_REJECT_UNAUTHORIZED !== 'false'
  },
  healthCheck: {
    enabled: process.env.SUPABASE_DIRECT_HEALTH_CHECK_ENABLED === 'true',
    interval: parseInt(process.env.SUPABASE_DIRECT_HEALTH_CHECK_INTERVAL || '30000'),
    timeout: parseInt(process.env.SUPABASE_DIRECT_HEALTH_CHECK_TIMEOUT || '5000')
  }
};

const mcpServer = new DirectConnectionMCPServer(config);

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Received SIGTERM, closing connections...');
  await mcpServer.close();
  process.exit(0);
});
```

## Connection Health Checks

### Simple Health Check

```typescript
// health-check.ts
import pg from 'pg';

async function healthCheck(connectionString: string): Promise<boolean> {
  const client = new pg.Client({ connectionString });
  
  try {
    await client.connect();
    const result = await client.query('SELECT 1 as health');
    await client.end();
    return result.rows[0].health === 1;
  } catch (error) {
    console.error('Health check failed:', error);
    return false;
  }
}

// Usage
const isHealthy = await healthCheck(process.env.SUPABASE_DIRECT_CONNECTION!);
console.log('Database connection healthy:', isHealthy);
```

### Advanced Health Check with Metrics

```typescript
// advanced-health-check.ts
import pg from 'pg';
const { Pool } = pg;

interface HealthCheckResult {
  status: 'healthy' | 'degraded' | 'unhealthy';
  latency: number;
  poolStats: {
    total: number;
    idle: number;
    waiting: number;
  };
  databaseStats: {
    version: string;
    connections: number;
    maxConnections: number;
  };
  timestamp: Date;
}

class HealthChecker {
  constructor(private pool: Pool) {}

  async check(): Promise<HealthCheckResult> {
    const startTime = Date.now();
    
    try {
      // Test basic connectivity
      const healthQuery = await this.pool.query('SELECT 1 as health');
      
      // Get database version and connection info
      const versionResult = await this.pool.query('SELECT version()');
      const connectionStats = await this.pool.query(`
        SELECT 
          count(*) as current_connections,
          (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections
        FROM pg_stat_activity
      `);

      const latency = Date.now() - startTime;
      
      // Get pool statistics
      const poolStats = {
        total: this.pool.totalCount,
        idle: this.pool.idleCount,
        waiting: this.pool.waitingCount
      };

      const dbStats = connectionStats.rows[0];
      const connectionUsage = dbStats.current_connections / dbStats.max_connections;
      
      // Determine status
      let status: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
      if (latency > 100 || connectionUsage > 0.8) {
        status = 'degraded';
      }
      if (latency > 1000 || connectionUsage > 0.95) {
        status = 'unhealthy';
      }

      return {
        status,
        latency,
        poolStats,
        databaseStats: {
          version: versionResult.rows[0].version,
          connections: parseInt(dbStats.current_connections),
          maxConnections: parseInt(dbStats.max_connections)
        },
        timestamp: new Date()
      };
    } catch (error) {
      console.error('Health check error:', error);
      return {
        status: 'unhealthy',
        latency: Date.now() - startTime,
        poolStats: {
          total: this.pool.totalCount,
          idle: this.pool.idleCount,
          waiting: this.pool.waitingCount
        },
        databaseStats: {
          version: 'unknown',
          connections: 0,
          maxConnections: 0
        },
        timestamp: new Date()
      };
    }
  }

  startPeriodicCheck(intervalMs: number = 30000): NodeJS.Timeout {
    return setInterval(async () => {
      const result = await this.check();
      console.log('Health check result:', JSON.stringify(result, null, 2));
      
      if (result.status === 'unhealthy') {
        console.error('❌ Database connection is unhealthy!');
      } else if (result.status === 'degraded') {
        console.warn('⚠️  Database connection is degraded');
      } else {
        console.log('✅ Database connection is healthy');
      }
    }, intervalMs);
  }
}

// Usage
const pool = new Pool({
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION
});

const healthChecker = new HealthChecker(pool);
const interval = healthChecker.startPeriodicCheck(30000);

// Stop health checks on shutdown
process.on('SIGTERM', () => {
  clearInterval(interval);
});
```

## Connection Retry Logic

### Exponential Backoff Retry

```typescript
// retry-logic.ts
interface RetryConfig {
  maxAttempts: number;
  initialDelayMs: number;
  maxDelayMs: number;
  backoffMultiplier: number;
}

const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  initialDelayMs: 1000,
  maxDelayMs: 10000,
  backoffMultiplier: 2
};

class ConnectionError extends Error {
  constructor(message: string, public readonly isRetryable: boolean = true) {
    super(message);
    this.name = 'ConnectionError';
  }
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function withRetry<T>(
  operation: () => Promise<T>,
  config: RetryConfig = DEFAULT_RETRY_CONFIG
): Promise<T> {
  let lastError: Error;
  let delay = config.initialDelayMs;

  for (let attempt = 1; attempt <= config.maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (error: any) {
      lastError = error;

      // Don't retry on certain errors
      const nonRetryableErrors = [
        'EAUTH', // Authentication failed
        '28P01', // Invalid password
        '3D000', // Database does not exist
        '23505', // Unique constraint violation
        '42P01', // Table does not exist
      ];

      const isNonRetryable = nonRetryableErrors.some(code => 
        error.code === code || error.message?.includes(code)
      );

      if (isNonRetryable) {
        console.error(`Non-retryable error: ${error.message}`);
        throw error;
      }

      if (attempt < config.maxAttempts) {
        console.log(
          `Attempt ${attempt}/${config.maxAttempts} failed: ${error.message}`
        );
        console.log(`Retrying in ${delay}ms...`);
        await sleep(delay);
        delay = Math.min(delay * config.backoffMultiplier, config.maxDelayMs);
      }
    }
  }

  console.error(`All ${config.maxAttempts} attempts failed`);
  throw lastError!;
}

// Usage with database connection
import pg from 'pg';
const { Pool } = pg;

async function createConnectionWithRetry(): Promise<Pool> {
  const config = {
    maxAttempts: parseInt(process.env.SUPABASE_DIRECT_RETRY_MAX_ATTEMPTS || '3'),
    initialDelayMs: parseInt(process.env.SUPABASE_DIRECT_RETRY_INITIAL_DELAY || '1000'),
    maxDelayMs: parseInt(process.env.SUPABASE_DIRECT_RETRY_MAX_DELAY || '10000'),
    backoffMultiplier: parseFloat(process.env.SUPABASE_DIRECT_RETRY_BACKOFF_MULTIPLIER || '2')
  };

  return withRetry(async () => {
    const pool = new Pool({
      connectionString: process.env.SUPABASE_DIRECT_CONNECTION
    });

    // Test the connection
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();

    return pool;
  }, config);
}

// Usage with queries
async function executeQueryWithRetry(
  pool: Pool,
  sql: string,
  params: any[] = []
): Promise<any[]> {
  return withRetry(async () => {
    const result = await pool.query(sql, params);
    return result.rows;
  });
}

// Example
(async () => {
  try {
    const pool = await createConnectionWithRetry();
    const users = await executeQueryWithRetry(
      pool,
      'SELECT * FROM profiles LIMIT 10'
    );
    console.log('Fetched users:', users);
  } catch (error) {
    console.error('Failed after all retries:', error);
  }
})();
```

### Circuit Breaker Pattern

```typescript
// circuit-breaker.ts
type CircuitState = 'closed' | 'open' | 'half-open';

interface CircuitBreakerConfig {
  failureThreshold: number;
  resetTimeout: number;
  halfOpenMaxAttempts: number;
}

class CircuitBreaker {
  private state: CircuitState = 'closed';
  private failureCount = 0;
  private lastFailureTime?: Date;
  private successCount = 0;

  constructor(private config: CircuitBreakerConfig) {}

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (this.shouldAttemptReset()) {
        this.state = 'half-open';
        this.successCount = 0;
      } else {
        throw new Error('Circuit breaker is OPEN - refusing request');
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;

    if (this.state === 'half-open') {
      this.successCount++;
      if (this.successCount >= this.config.halfOpenMaxAttempts) {
        this.state = 'closed';
        console.log('Circuit breaker: HALF-OPEN → CLOSED');
      }
    }
  }

  private onFailure(): void {
    this.failureCount++;
    this.lastFailureTime = new Date();

    if (this.state === 'half-open') {
      this.state = 'open';
      console.log('Circuit breaker: HALF-OPEN → OPEN');
    } else if (this.failureCount >= this.config.failureThreshold) {
      this.state = 'open';
      console.log('Circuit breaker: CLOSED → OPEN');
    }
  }

  private shouldAttemptReset(): boolean {
    if (!this.lastFailureTime) return false;
    
    const timeSinceFailure = Date.now() - this.lastFailureTime.getTime();
    return timeSinceFailure >= this.config.resetTimeout;
  }

  getState(): CircuitState {
    return this.state;
  }
}

// Usage
const breaker = new CircuitBreaker({
  failureThreshold: 5,
  resetTimeout: 60000, // 1 minute
  halfOpenMaxAttempts: 3
});

async function queryWithCircuitBreaker(pool: Pool, sql: string) {
  return breaker.execute(async () => {
    const result = await pool.query(sql);
    return result.rows;
  });
}
```

## Error Handling

### Common Connection Errors

| Error Code | Description | Solution |
|------------|-------------|----------|
| `ECONNREFUSED` | Connection refused | Check if database is running, verify host/port |
| `ETIMEDOUT` | Connection timeout | Increase timeout, check network/firewall |
| `ENOTFOUND` | Host not found | Verify connection string, check DNS |
| `ENETUNREACH` | Network unreachable | Check IPv6 support, try Session Mode |
| `28P01` | Invalid password | Verify password, check for special characters |
| `3D000` | Database does not exist | Verify database name in connection string |
| `53300` | Too many connections | Reduce pool size, close unused connections |

### Error Handling Example

```typescript
// error-handling.ts
import pg from 'pg';

async function handleDatabaseError(error: any): Promise<void> {
  console.error('Database error occurred:', error);

  // Connection errors
  if (error.code === 'ECONNREFUSED') {
    console.error('❌ Connection refused - database may be down or unreachable');
    console.log('💡 Check: Database status, firewall rules, connection string');
  } else if (error.code === 'ETIMEDOUT') {
    console.error('❌ Connection timeout - network or performance issue');
    console.log('💡 Try: Increase timeout, check network latency');
  } else if (error.code === 'ENOTFOUND') {
    console.error('❌ Host not found - DNS issue or invalid connection string');
    console.log('💡 Check: Connection string format, DNS resolution');
  } else if (error.code === 'ENETUNREACH') {
    console.error('❌ Network unreachable - IPv6 not supported');
    console.log('💡 Try: Use Supavisor Session Mode (IPv4) instead');
  }

  // PostgreSQL errors
  else if (error.code === '28P01') {
    console.error('❌ Authentication failed - invalid password');
    console.log('💡 Check: Password in connection string, special characters');
  } else if (error.code === '3D000') {
    console.error('❌ Database does not exist');
    console.log('💡 Check: Database name in connection string');
  } else if (error.code === '53300') {
    console.error('❌ Too many connections to database');
    console.log('💡 Try: Reduce pool size, close idle connections');
  }

  // Query errors
  else if (error.code === '42P01') {
    console.error('❌ Table does not exist');
    console.log('💡 Check: Table name, schema, migrations');
  } else if (error.code === '23505') {
    console.error('❌ Unique constraint violation');
    console.log('💡 Check: Duplicate data, unique constraints');
  }

  // Generic errors
  else {
    console.error('❌ Unexpected error:', error.message);
    console.log('Error details:', {
      code: error.code,
      message: error.message,
      detail: error.detail,
      hint: error.hint
    });
  }
}

// Usage
try {
  const pool = new Pool({
    connectionString: process.env.SUPABASE_DIRECT_CONNECTION
  });
  await pool.query('SELECT * FROM profiles');
} catch (error) {
  await handleDatabaseError(error);
}
```

## Troubleshooting

### Connection Refused Errors

**Symptom:** `ECONNREFUSED` error when trying to connect

**Common Causes:**
1. Database is not running
2. Incorrect host or port
3. Firewall blocking connection
4. IPv6 not supported

**Solutions:**

```bash
# 1. Verify database is accessible
ping db.[PROJECT-REF].supabase.co

# 2. Test connection with psql
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 3. Check if port is open
nc -zv db.[PROJECT-REF].supabase.co 5432

# 4. Test IPv6 connectivity
ping6 db.[PROJECT-REF].supabase.co

# 5. Try IPv4 fallback (Session Mode)
# Update connection string to use Supavisor Session Mode
SUPABASE_SESSION_CONNECTION=postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

### Timeout Errors

**Symptom:** `ETIMEDOUT` or slow connections

**Solutions:**

```typescript
// Increase timeouts
const pool = new Pool({
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION,
  connectionTimeoutMillis: 30000, // 30 seconds
  idleTimeoutMillis: 600000, // 10 minutes
  statement_timeout: 60000 // 60 seconds for queries
});
```

### IPv6 Not Supported

**Symptom:** `ENETUNREACH` or connection hangs

**Solution:** Switch to Session Mode (IPv4)

```bash
# Before (Direct IPv6)
SUPABASE_DIRECT_CONNECTION=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# After (Session Mode IPv4)
SUPABASE_SESSION_CONNECTION=postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

### Too Many Connections

**Symptom:** `53300` error - too many connections

**Solutions:**

```typescript
// 1. Reduce pool size
const pool = new Pool({
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION,
  max: 10, // Reduce from 20
  min: 2   // Reduce from 5
});

// 2. Ensure connections are released
const client = await pool.connect();
try {
  await client.query('SELECT * FROM profiles');
} finally {
  client.release(); // Always release!
}

// 3. Monitor connection usage
const stats = await pool.query(`
  SELECT count(*) as connections 
  FROM pg_stat_activity 
  WHERE usename = current_user
`);
console.log('Active connections:', stats.rows[0].connections);
```

### Authentication Failures

**Symptom:** `28P01` - password authentication failed

**Solutions:**

1. **Check password format:**
```bash
# If password contains special characters, URL-encode them
# Before: password: p@ssw0rd!
# After:  password: p%40ssw0rd%21
```

2. **Verify in Supabase Dashboard:**
   - Project Settings → Database → Reset Database Password
   - Copy new password and update `.env` file

3. **Test with psql:**
```bash
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" -c "SELECT current_user;"
```

## Best Practices

### 1. Connection Pool Management

```typescript
// ✅ Good: Single pool instance
const pool = new Pool({
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION,
  max: 20,
  min: 5
});

// ❌ Bad: Creating new pool for each request
function badExample() {
  const pool = new Pool({ /* ... */ }); // Don't do this!
  return pool.query('SELECT * FROM users');
}
```

### 2. Always Release Connections

```typescript
// ✅ Good: Use try/finally
const client = await pool.connect();
try {
  await client.query('SELECT * FROM profiles');
} finally {
  client.release(); // Always called
}

// ❌ Bad: Connection might not be released
const client = await pool.connect();
await client.query('SELECT * FROM profiles');
client.release(); // May not be called if query fails
```

### 3. Set Appropriate Timeouts

```typescript
// ✅ Good: Reasonable timeouts
const pool = new Pool({
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION,
  connectionTimeoutMillis: 10000, // 10 seconds
  idleTimeoutMillis: 300000, // 5 minutes
  statement_timeout: 30000 // 30 seconds
});

// ❌ Bad: No timeouts (can cause hangs)
const pool = new Pool({
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION
  // Uses defaults which may be too long
});
```

### 4. Implement Health Checks

```typescript
// ✅ Good: Regular health checks
setInterval(async () => {
  try {
    await pool.query('SELECT 1');
  } catch (error) {
    console.error('Health check failed:', error);
    // Alert monitoring system
  }
}, 30000);
```

### 5. Use Prepared Statements

```typescript
// ✅ Good: Prevents SQL injection, better performance
const result = await pool.query(
  'SELECT * FROM profiles WHERE id = $1',
  [userId]
);

// ❌ Bad: SQL injection risk
const result = await pool.query(
  `SELECT * FROM profiles WHERE id = ${userId}` // Dangerous!
);
```

### 6. Graceful Shutdown

```typescript
// ✅ Good: Clean shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await pool.end();
  process.exit(0);
});

// ❌ Bad: Abrupt shutdown leaves connections open
process.on('SIGTERM', () => {
  process.exit(0); // Connections not closed!
});
```

## Comparison with Other Connection Methods

| Feature | Direct IPv6 | Session Mode (IPv4) | Transaction Mode | Dedicated Pooler |
|---------|-------------|---------------------|------------------|------------------|
| **Latency** | Lowest | Low | Medium | Lowest |
| **IPv6 Required** | Yes | No | No | Depends |
| **Connection Persistence** | Yes | Yes | No | Yes |
| **Best For** | Persistent agents | IPv4 agents | Serverless | High-performance |
| **Port** | 5432 | 5432 | 6543 | Custom |
| **PostgreSQL Features** | Full | Full | Limited | Full |
| **Auto Cleanup** | No | No | Yes | No |
| **Connection String** | `postgres@db.*.supabase.co` | `postgres.*@pooler.supabase.com` | `postgres.*@pooler.supabase.com:6543` | Custom |

### When to Use Each Method

**Direct IPv6 Connection:**
- ✅ Long-running processes (VMs, containers)
- ✅ Need full PostgreSQL features (LISTEN/NOTIFY, etc.)
- ✅ IPv6 network support available
- ✅ Low-latency requirements

**Session Mode (IPv4):**
- ✅ IPv6 not available
- ✅ Need persistent connections
- ✅ Similar to Direct but over IPv4

**Transaction Mode:**
- ✅ Serverless functions (Lambda, Cloud Functions)
- ✅ Edge functions (Cloudflare Workers)
- ✅ Unpredictable connection patterns
- ✅ Need automatic connection cleanup

**Dedicated Pooler:**
- ✅ Very high throughput requirements
- ✅ Need isolated resources
- ✅ Can justify additional cost
- ✅ Predictable workload patterns

## Related Documentation

- [MCP Server Configuration](./MCP_SERVER_CONFIGURATION.md)
- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [MCP Authentication Strategies](./MCP_AUTHENTICATION.md)

## Additional Resources

- [Supabase Database Settings](https://supabase.com/docs/guides/database/connecting-to-postgres)
- [PostgreSQL Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
- [Node.js pg Library](https://node-postgres.com/)
- [IPv6 Troubleshooting](https://www.internetsociety.org/deploy360/ipv6/)

---

**Last Updated:** 2025-01-08  
**Version:** 1.0.0  
**Status:** ✅ Complete
