# MCP Configuration Templates

## Overview

Ready-to-use configuration templates for MCP servers connecting to Supabase. Copy and customize these templates for your specific use case.

## Template Format Reference

MCP server configurations can be provided in multiple formats:

- **JSON**: Most common, used by Claude Desktop and many MCP clients
- **YAML**: Alternative format, more readable for complex configurations
- **TOML**: Used by some Rust-based MCP servers
- **Environment Variables**: For cloud deployments

## Quick Reference Table

| Template | Agent Type | Connection | Port | Prepared Statements | Use Case |
|----------|-----------|------------|------|---------------------|----------|
| [T1](#template-1-persistent-agent-direct-connection) | Persistent | Direct IPv6 | 5432 | ✅ Yes | Local development, Claude Desktop |
| [T2](#template-2-persistent-agent-session-mode) | Persistent | Session | 5432 | ✅ Yes | IPv4 persistent agents |
| [T3](#template-3-serverless-agent) | Serverless | Transaction | 6543 | ❌ No | AWS Lambda, Cloud Functions |
| [T4](#template-4-edge-agent) | Edge | Transaction | 6543 | ❌ No | Cloudflare Workers, Edge Runtime |
| [T5](#template-5-high-performance-agent) | High-Perf | Dedicated | 6543 | ✅ Yes | Production, high traffic |

---

## Template 1: Persistent Agent (Direct Connection)

**Best for:** Claude Desktop, local AI assistants, development environments

### JSON Configuration

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
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "${SSL_CERT_PATH}",
        "PGCONNECT_TIMEOUT": "10",
        "PGAPPNAME": "mcp-persistent-agent",
        "DB_POOL_MIN": "5",
        "DB_POOL_MAX": "20",
        "DB_IDLE_TIMEOUT_MS": "300000"
      }
    }
  }
}
```

### Environment Variables (.env)

```bash
# Connection Details
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_DB_PASSWORD=your-password

# Direct Connection (IPv6)
SUPABASE_DIRECT_CONNECTION=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@${SUPABASE_PROJECT_REF}.supabase.co:5432/postgres

# SSL Configuration
SSL_CERT_PATH=/path/to/supabase-ca.crt

# Pool Configuration
DB_POOL_MIN=5
DB_POOL_MAX=20
DB_IDLE_TIMEOUT_MS=300000
DB_CONNECTION_TIMEOUT_MS=10000
```

### Node.js Implementation

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.SUPABASE_DIRECT_CONNECTION,
  ssl: {
    rejectUnauthorized: true,
    ca: require('fs').readFileSync(process.env.SSL_CERT_PATH).toString()
  },
  min: 5,
  max: 20,
  idleTimeoutMillis: 300000,
  connectionTimeoutMillis: 10000,
  application_name: 'mcp-persistent-agent'
});

module.exports = pool;
```

---

## Template 2: Persistent Agent (Session Mode)

**Best for:** IPv4-only environments, persistent agents without IPv6

### JSON Configuration

```json
{
  "mcpServers": {
    "supabase-session": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_SESSION_POOLER}"
      ],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full",
        "PGCONNECT_TIMEOUT": "10",
        "PGAPPNAME": "mcp-session-agent",
        "DB_POOL_MIN": "2",
        "DB_POOL_MAX": "10"
      }
    }
  }
}
```

### Environment Variables (.env)

```bash
# Connection Details
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_DB_PASSWORD=your-password
SUPABASE_REGION=us-east-1

# Session Mode Pooler
SUPABASE_SESSION_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-${SUPABASE_REGION}.pooler.supabase.com:5432/postgres

# Pool Configuration
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_IDLE_TIMEOUT_MS=300000
DB_CONNECTION_TIMEOUT_MS=10000
```

### Python Implementation

```python
import os
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    os.environ['SUPABASE_SESSION_POOLER'],
    poolclass=QueuePool,
    pool_size=5,
    max_overflow=5,
    pool_timeout=30,
    pool_recycle=3600,
    connect_args={
        'application_name': 'mcp-session-agent',
        'sslmode': 'verify-full'
    }
)
```

---

## Template 3: Serverless Agent

**Best for:** AWS Lambda, Google Cloud Functions, Azure Functions

### JSON Configuration

```json
{
  "mcpServers": {
    "supabase-serverless": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_TRANSACTION_POOLER}",
        "--disable-prepared-statements"
      ],
      "env": {
        "POOL_MODE": "transaction",
        "DISABLE_PREPARED_STATEMENTS": "true",
        "PGSSLMODE": "verify-full",
        "PGCONNECT_TIMEOUT": "5",
        "PGAPPNAME": "mcp-serverless-agent",
        "DB_POOL_MIN": "0",
        "DB_POOL_MAX": "5",
        "DB_IDLE_TIMEOUT_MS": "5000"
      }
    }
  }
}
```

### Environment Variables (.env)

```bash
# Connection Details
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_DB_PASSWORD=your-password
SUPABASE_REGION=us-east-1

# Transaction Mode Pooler (Port 6543)
SUPABASE_TRANSACTION_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-${SUPABASE_REGION}.pooler.supabase.com:6543/postgres?prepareStatement=false

# Pool Configuration (Serverless Optimized)
DB_POOL_MIN=0
DB_POOL_MAX=5
DB_IDLE_TIMEOUT_MS=5000
DB_CONNECTION_TIMEOUT_MS=5000
DB_ACQUIRE_TIMEOUT_MS=10000
```

### AWS Lambda (Node.js) Implementation

```javascript
const { Pool } = require('pg');

// Create pool outside handler for connection reuse
const pool = new Pool({
  connectionString: process.env.SUPABASE_TRANSACTION_POOLER,
  ssl: { rejectUnauthorized: true },
  min: 0,
  max: 5,
  idleTimeoutMillis: 5000,
  connectionTimeoutMillis: 5000,
  allowExitOnIdle: true,  // Important for Lambda
  application_name: 'mcp-serverless-agent',
  // Disable prepared statements for transaction mode
  options: '-c plan_cache_mode=force_custom_plan'
});

exports.handler = async (event) => {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT NOW()');
    return {
      statusCode: 200,
      body: JSON.stringify(result.rows[0])
    };
  } finally {
    client.release();
  }
};
```

### Google Cloud Functions Implementation

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.SUPABASE_TRANSACTION_POOLER,
  ssl: { rejectUnauthorized: true },
  min: 0,
  max: 1,  // Cloud Functions: 1 connection per instance
  idleTimeoutMillis: 5000,
  options: '-c plan_cache_mode=force_custom_plan'
});

exports.myFunction = async (req, res) => {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT $1::text as message', ['Hello']);
    res.json(result.rows[0]);
  } finally {
    client.release();
  }
};
```

---

## Template 4: Edge Agent

**Best for:** Cloudflare Workers, Deno Deploy, Vercel Edge Functions

### JSON Configuration

```json
{
  "mcpServers": {
    "supabase-edge": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_TRANSACTION_POOLER}",
        "--disable-prepared-statements"
      ],
      "env": {
        "POOL_MODE": "transaction",
        "DISABLE_PREPARED_STATEMENTS": "true",
        "PGSSLMODE": "require",
        "PGCONNECT_TIMEOUT": "3",
        "PGAPPNAME": "mcp-edge-agent",
        "DB_POOL_MAX": "3"
      }
    }
  }
}
```

### Cloudflare Workers Implementation

```typescript
import { Pool } from '@neondatabase/serverless';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const pool = new Pool({
      connectionString: env.SUPABASE_TRANSACTION_POOLER,
    });

    try {
      const client = await pool.connect();
      const result = await client.query('SELECT NOW()');
      client.release();
      
      return new Response(JSON.stringify(result.rows[0]), {
        headers: { 'Content-Type': 'application/json' }
      });
    } finally {
      await pool.end();
    }
  }
};
```

### Deno Deploy Implementation

```typescript
import { Pool } from "https://deno.land/x/postgres/mod.ts";

const pool = new Pool({
  connectionString: Deno.env.get("SUPABASE_TRANSACTION_POOLER"),
  tls: { enabled: true },
  lazy: true,
  max: 3
}, 3);

Deno.serve(async (req: Request) => {
  const client = await pool.connect();
  try {
    const result = await client.queryObject`SELECT NOW()`;
    return new Response(JSON.stringify(result.rows[0]));
  } finally {
    client.release();
  }
});
```

### Vercel Edge Functions Implementation

```typescript
import { Pool } from '@vercel/postgres';

export const config = {
  runtime: 'edge',
};

export default async function handler(request: Request) {
  const pool = new Pool({
    connectionString: process.env.SUPABASE_TRANSACTION_POOLER,
  });

  const client = await pool.connect();
  try {
    const { rows } = await client.query('SELECT NOW()');
    return new Response(JSON.stringify(rows[0]));
  } finally {
    client.release();
  }
}
```

---

## Template 5: High-Performance Agent

**Best for:** Production applications with high concurrent traffic

### JSON Configuration

```json
{
  "mcpServers": {
    "supabase-dedicated": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_DEDICATED_POOLER}"
      ],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "${SSL_CERT_PATH}",
        "PGCONNECT_TIMEOUT": "10",
        "PGAPPNAME": "mcp-high-perf-agent",
        "DB_POOL_MIN": "10",
        "DB_POOL_MAX": "100",
        "DB_IDLE_TIMEOUT_MS": "600000",
        "DB_QUEUE_LIMIT": "1000"
      }
    }
  }
}
```

### Environment Variables (.env)

```bash
# Connection Details
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_DB_PASSWORD=your-password
SUPABASE_DEDICATED_ID=your-dedicated-pooler-id

# Dedicated Pooler Connection
SUPABASE_DEDICATED_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@${SUPABASE_DEDICATED_ID}.pooler.supabase.com:6543/postgres

# SSL Configuration
SSL_CERT_PATH=/path/to/supabase-ca.crt

# High-Performance Pool Configuration
DB_POOL_MIN=10
DB_POOL_MAX=100
DB_IDLE_TIMEOUT_MS=600000
DB_CONNECTION_TIMEOUT_MS=10000
DB_ACQUIRE_TIMEOUT_MS=30000
DB_QUEUE_LIMIT=1000
```

### Node.js Production Implementation

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.SUPABASE_DEDICATED_POOLER,
  ssl: {
    rejectUnauthorized: true,
    ca: require('fs').readFileSync(process.env.SSL_CERT_PATH).toString()
  },
  min: 10,
  max: 100,
  idleTimeoutMillis: 600000,
  connectionTimeoutMillis: 10000,
  application_name: 'mcp-high-perf-agent',
  // Performance optimizations
  statement_timeout: 60000,
  query_timeout: 60000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000
});

// Health check
pool.on('error', (err, client) => {
  console.error('Unexpected pool error:', err);
});

// Monitoring
pool.on('connect', (client) => {
  console.log('New client connected to pool');
});

pool.on('acquire', (client) => {
  console.log('Client acquired from pool');
});

pool.on('remove', (client) => {
  console.log('Client removed from pool');
});

module.exports = pool;
```

---

## Configuration by Environment

### Development Environment

```json
{
  "mcpServers": {
    "supabase-dev": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_DIRECT_CONNECTION}"],
      "env": {
        "PGSSLMODE": "require",
        "PGCONNECT_TIMEOUT": "10",
        "DB_POOL_MIN": "1",
        "DB_POOL_MAX": "5",
        "LOG_LEVEL": "debug"
      }
    }
  }
}
```

### Staging Environment

```json
{
  "mcpServers": {
    "supabase-staging": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_SESSION_POOLER}"],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full",
        "DB_POOL_MIN": "5",
        "DB_POOL_MAX": "20",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

### Production Environment

```json
{
  "mcpServers": {
    "supabase-prod": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_DEDICATED_POOLER}"],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "${SSL_CERT_PATH}",
        "DB_POOL_MIN": "10",
        "DB_POOL_MAX": "50",
        "LOG_LEVEL": "warn",
        "ENABLE_MONITORING": "true"
      }
    }
  }
}
```

---

## Complete .env.example Template

```bash
# ==============================================================================
# MCP Server Configuration - Environment Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# Project Details
# ------------------------------------------------------------------------------
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_DB_PASSWORD=your-database-password
SUPABASE_REGION=us-east-1

# ------------------------------------------------------------------------------
# Connection Strings (Choose ONE based on your needs)
# ------------------------------------------------------------------------------

# Direct Connection (IPv6) - Port 5432
# Best for: Local development, persistent agents with IPv6
SUPABASE_DIRECT_CONNECTION=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@${SUPABASE_PROJECT_REF}.supabase.co:5432/postgres

# Session Mode (IPv4/IPv6) - Port 5432
# Best for: Persistent agents without IPv6
SUPABASE_SESSION_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-${SUPABASE_REGION}.pooler.supabase.com:5432/postgres

# Transaction Mode (IPv4/IPv6) - Port 6543
# Best for: Serverless functions, edge functions
SUPABASE_TRANSACTION_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-${SUPABASE_REGION}.pooler.supabase.com:6543/postgres?prepareStatement=false

# Dedicated Pooler - Port 6543
# Best for: High-performance production workloads
SUPABASE_DEDICATED_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@your-dedicated-id.pooler.supabase.com:6543/postgres

# ------------------------------------------------------------------------------
# SSL Configuration
# ------------------------------------------------------------------------------
SSL_CERT_PATH=/path/to/supabase-ca.crt
PGSSLMODE=verify-full
# Options: disable, require, verify-ca, verify-full

# ------------------------------------------------------------------------------
# Connection Pool Configuration
# ------------------------------------------------------------------------------
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_IDLE_TIMEOUT_MS=30000
DB_CONNECTION_TIMEOUT_MS=5000
DB_ACQUIRE_TIMEOUT_MS=10000

# ------------------------------------------------------------------------------
# Query Configuration
# ------------------------------------------------------------------------------
DB_STATEMENT_TIMEOUT=30000
DB_QUERY_TIMEOUT=25000
DISABLE_PREPARED_STATEMENTS=false  # Set to true for transaction mode

# ------------------------------------------------------------------------------
# Application Configuration
# ------------------------------------------------------------------------------
PGAPPNAME=mcp-server
NODE_ENV=development
LOG_LEVEL=info

# ------------------------------------------------------------------------------
# Monitoring (Optional)
# ------------------------------------------------------------------------------
ENABLE_MONITORING=false
ENABLE_METRICS=false
METRICS_PORT=9090

# ------------------------------------------------------------------------------
# Rate Limiting (Optional)
# ------------------------------------------------------------------------------
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_WINDOW_MS=60000
```

---

## Configuration Validation

### Validation Script (Node.js)

```javascript
const Ajv = require('ajv');

const schema = {
  type: 'object',
  required: ['connectionString'],
  properties: {
    connectionString: { type: 'string', pattern: '^postgresql://' },
    ssl: {
      type: 'object',
      properties: {
        rejectUnauthorized: { type: 'boolean' }
      }
    },
    pool: {
      type: 'object',
      properties: {
        min: { type: 'number', minimum: 0 },
        max: { type: 'number', minimum: 1 }
      }
    }
  }
};

function validateConfig(config) {
  const ajv = new Ajv();
  const validate = ajv.compile(schema);
  const valid = validate(config);
  
  if (!valid) {
    console.error('Configuration errors:', validate.errors);
    return false;
  }
  
  console.log('Configuration is valid ✅');
  return true;
}

module.exports = validateConfig;
```

---

## Next Steps

- **Connection Types**: [Detailed Connection Guide](./connection-types.md)
- **SSL Setup**: [SSL Configuration Guide](./ssl-setup.md)
- **Troubleshooting**: [Common Issues](./troubleshooting.md)
- **Monitoring**: [Setup Monitoring](./monitoring.md)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0
