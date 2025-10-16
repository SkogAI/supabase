# MCP Server Quick Start Guide

## Overview

This guide will help you quickly set up an MCP (Model Context Protocol) server to connect your AI agents to Supabase databases. Choose the right connection method based on your agent type and environment.

## Connection Method Decision Tree

Use this decision tree to select the optimal connection method for your AI agent:

```
Start: What type of AI agent are you building?
│
├─ Persistent Agent (long-running, stable environment)
│   │
│   ├─ Do you have IPv6 support? ────► YES ────► Use Direct Connection (Port 5432)
│   │                                            ✅ Best performance, full PostgreSQL features
│   │
│   └─ Do you have IPv6 support? ────► NO ─────► Use Session Mode (Port 5432)
│                                                ✅ IPv4 compatible, persistent connections
│
├─ Serverless Agent (AWS Lambda, Google Cloud Functions, Azure Functions)
│   │
│   └─────────────────────────────────────────► Use Transaction Mode (Port 6543)
│                                                ✅ Efficient resource usage, automatic cleanup
│
├─ Edge Agent (Cloudflare Workers, Deno Deploy, Vercel Edge)
│   │
│   └─────────────────────────────────────────► Use Transaction Mode (Port 6543)
│                                                ✅ Low latency, minimal cold start
│
└─ High-Performance Agent (many concurrent operations, intensive workload)
    │
    └─────────────────────────────────────────► Use Dedicated Pooler (Port 6543)
                                                 ✅ Maximum throughput, isolated resources
```

## Connection Method Comparison Table

| Method | Environment | IPv6 Required | Duration | Port | Best For | Prepared Statements |
|--------|------------|---------------|----------|------|----------|---------------------|
| **Direct Connection** | Persistent VM | ✅ Yes | Long-running | 5432 | Maximum performance, full features | ✅ Supported |
| **Session Mode** | Persistent VM | ❌ No (IPv4/IPv6) | Long-running | 5432 | IPv4 compatibility, stable connections | ✅ Supported |
| **Transaction Mode** | Serverless/Edge | ❌ No (IPv4/IPv6) | Short-lived | 6543 | Auto-cleanup, efficient pooling | ⚠️ Must disable |
| **Dedicated Pooler** | Production | ❌ No (IPv4/IPv6) | Any | 6543 | High concurrency, isolation | ✅ Supported |

## 5-Minute Quick Start

### Step 1: Choose Your Configuration Template

Based on the decision tree above, select one of these quick-start templates:

#### Option A: Direct Connection (IPv6)
```json
{
  "mcpServers": {
    "supabase-direct": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_DIRECT_CONNECTION}"],
      "env": {
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "${SSL_CERT_PATH}"
      }
    }
  }
}
```

**Connection String Format:**
```bash
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres
```

#### Option B: Session Mode (IPv4/IPv6)
```json
{
  "mcpServers": {
    "supabase-session": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_SESSION_POOLER}"],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full"
      }
    }
  }
}
```

**Connection String Format:**
```bash
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres
```

#### Option C: Transaction Mode (Serverless/Edge)
```json
{
  "mcpServers": {
    "supabase-transaction": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string", "${SUPABASE_TRANSACTION_POOLER}",
        "--disable-prepared-statements"
      ],
      "env": {
        "POOL_MODE": "transaction",
        "DISABLE_PREPARED_STATEMENTS": "true",
        "PGSSLMODE": "verify-full"
      }
    }
  }
}
```

**Connection String Format:**
```bash
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
```

#### Option D: Dedicated Pooler (High-Performance)
```json
{
  "mcpServers": {
    "supabase-dedicated": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_DEDICATED_POOLER}"],
      "env": {
        "POOL_MODE": "session",
        "PGSSLMODE": "verify-full",
        "DB_POOL_MIN": "10",
        "DB_POOL_MAX": "100"
      }
    }
  }
}
```

**Connection String Format:**
```bash
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@[DEDICATED-HOST].supabase.com:6543/postgres
```

### Step 2: Get Your Connection Details

1. **Navigate to your Supabase Project**:
   - Go to https://app.supabase.com/project/[YOUR-PROJECT]/settings/database

2. **Find Connection String**:
   - Under "Connection string" section
   - Select connection pooling mode (Session or Transaction)
   - Copy the connection string
   - **Important**: Replace `[YOUR-PASSWORD]` with your actual database password

3. **Get Your Database Password**:
   - Found in Project Settings → Database
   - Or reset it if needed

### Step 3: Set Up Environment Variables

Create a `.env` file (never commit this file):

```bash
# Basic Configuration
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_DB_PASSWORD=your-database-password
SUPABASE_REGION=us-east-1  # Your project region

# Choose ONE connection string based on your method:

# Option A: Direct Connection (IPv6)
SUPABASE_DIRECT_CONNECTION=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@${SUPABASE_PROJECT_REF}.supabase.co:5432/postgres

# Option B: Session Mode (IPv4/IPv6)
SUPABASE_SESSION_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-${SUPABASE_REGION}.pooler.supabase.com:5432/postgres

# Option C: Transaction Mode (Serverless)
SUPABASE_TRANSACTION_POOLER=postgresql://postgres.${SUPABASE_PROJECT_REF}:${SUPABASE_DB_PASSWORD}@aws-0-${SUPABASE_REGION}.pooler.supabase.com:6543/postgres

# SSL Certificate (Optional, for production)
SSL_CERT_PATH=/path/to/supabase-ca.crt
```

### Step 4: Test Your Connection

**Using psql:**
```bash
# Direct Connection
psql "$SUPABASE_DIRECT_CONNECTION"

# Session Mode
psql "$SUPABASE_SESSION_POOLER"

# Transaction Mode
psql "$SUPABASE_TRANSACTION_POOLER"
```

**Using Node.js:**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.SUPABASE_TRANSACTION_POOLER,
  ssl: { rejectUnauthorized: true }
});

async function testConnection() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log('Connected successfully:', result.rows[0]);
    client.release();
  } catch (err) {
    console.error('Connection error:', err);
  } finally {
    await pool.end();
  }
}

testConnection();
```

### Step 5: Configure Your MCP Server

Save your configuration to the appropriate location:

- **Claude Desktop**: `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)
- **Claude Desktop**: `%APPDATA%\Claude\claude_desktop_config.json` (Windows)
- **Custom MCP Server**: `./config/mcp-config.json`

### Step 6: Restart and Verify

1. Restart your MCP client (e.g., Claude Desktop)
2. Check MCP server logs for successful connection
3. Test a simple query through your AI agent

## Port and Protocol Reference

| Port | Protocol | Connection Type | Use Case |
|------|----------|-----------------|----------|
| 5432 | PostgreSQL | Direct IPv6 | Full PostgreSQL features, persistent agents |
| 5432 | PostgreSQL via Supavisor | Session Mode | IPv4 compatibility, persistent connections |
| 6543 | PostgreSQL via Supavisor | Transaction Mode | Serverless, automatic cleanup |
| 6543 | PostgreSQL via PgBouncer | Dedicated Pooler | High-performance, isolated resources |

## Important Notes on Prepared Statements

### When to Disable Prepared Statements

**MUST disable** for:
- ✅ Transaction Mode (Port 6543)
- ✅ PgBouncer transaction mode
- ✅ Serverless functions with short lifecycles

**Configuration:**
```bash
# In connection string
?prepareStatement=false

# Or via environment
DISABLE_PREPARED_STATEMENTS=true
```

**Reason:** Transaction pooling doesn't maintain connection state between transactions, causing prepared statement errors.

### When Prepared Statements Are Supported

**Can enable** for:
- ✅ Direct Connection (Port 5432)
- ✅ Session Mode (Port 5432)
- ✅ Dedicated Pooler in session mode
- ✅ Long-running persistent agents

## Common Quick Start Issues

### Issue: "Connection timeout"
**Solution:** 
- Verify your database password is correct
- Check if your IP is allowed (check Supabase Dashboard → Database → Connection Pooling)
- Ensure SSL is properly configured

### Issue: "prepared statement already exists"
**Solution:** 
- Add `--disable-prepared-statements` to your configuration
- Or add `?prepareStatement=false` to connection string

### Issue: "too many connections"
**Solution:**
- Use Transaction Mode instead of Direct Connection
- Reduce connection pool size
- Enable connection pooling

### Issue: "SSL error"
**Solution:**
- Set `PGSSLMODE=verify-full`
- Download CA certificate from Supabase Dashboard
- Or use `PGSSLMODE=require` for testing (less secure)

## Next Steps

Once your basic connection is working:

1. **Secure Your Setup**: See [SSL Setup Guide](./ssl-setup.md)
2. **Optimize Configuration**: See [Configuration Templates](./configuration-templates.md)
3. **Learn Connection Types**: See [Connection Types Guide](./connection-types.md)
4. **Set Up Monitoring**: See [Monitoring Guide](./monitoring.md)
5. **Troubleshooting**: See [Troubleshooting Guide](./troubleshooting.md)

## Agent-Specific Guides

Choose your agent type for detailed setup instructions:

- **[Persistent AI Agents](../ai-agents/persistent-agents.md)** - Long-running assistants (Claude Desktop, local agents)
- **[Serverless AI Agents](../ai-agents/serverless-agents.md)** - AWS Lambda, Google Cloud Functions, Azure Functions
- **[Edge AI Agents](../ai-agents/edge-agents.md)** - Cloudflare Workers, Deno Deploy, Vercel Edge

## Additional Resources

- [MCP Server Architecture](../MCP_SERVER_ARCHITECTURE.md)
- [MCP Authentication Strategies](../MCP_AUTHENTICATION.md)
- [MCP Connection Examples](../MCP_CONNECTION_EXAMPLES.md)
- [Complete Configuration Reference](../MCP_SERVER_CONFIGURATION.md)

---

**Quick Start Checklist:**
- [ ] Identified agent type (Persistent/Serverless/Edge/High-Performance)
- [ ] Selected connection method from decision tree
- [ ] Retrieved connection string from Supabase Dashboard
- [ ] Set up environment variables
- [ ] Tested connection with psql or code
- [ ] Configured MCP server
- [ ] Verified connection in MCP logs
- [ ] Tested query through AI agent

**Need Help?** See [Troubleshooting Guide](./troubleshooting.md) or [GitHub Issues](https://github.com/SkogAI/supabase/issues)
