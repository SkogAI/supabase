# MCP Server Configuration Templates

## Overview

This document provides ready-to-use configuration templates for MCP servers connecting to Supabase databases. Each template is optimized for specific agent types and deployment scenarios.

## Configuration File Formats

### JSON Configuration

```json
{
  "mcp": {
    "version": "1.0.0",
    "server": {
      "name": "supabase-mcp-server",
      "port": 3000,
      "host": "0.0.0.0"
    },
    "database": {
      "connectionString": "postgresql://user:password@host:5432/database",
      "pool": {
        "min": 2,
        "max": 10,
        "idleTimeoutMillis": 30000,
        "connectionTimeoutMillis": 5000
      }
    },
    "security": {
      "ssl": true,
      "rateLimit": {
        "enabled": true,
        "maxRequests": 100,
        "windowMs": 60000
      }
    }
  }
}
```

### YAML Configuration

```yaml
mcp:
  version: "1.0.0"
  server:
    name: supabase-mcp-server
    port: 3000
    host: 0.0.0.0
  database:
    connectionString: postgresql://user:password@host:5432/database
    pool:
      min: 2
      max: 10
      idleTimeoutMillis: 30000
      connectionTimeoutMillis: 5000
  security:
    ssl: true
    rateLimit:
      enabled: true
      maxRequests: 100
      windowMs: 60000
```

### TOML Configuration

```toml
[mcp]
version = "1.0.0"

[mcp.server]
name = "supabase-mcp-server"
port = 3000
host = "0.0.0.0"

[mcp.database]
connectionString = "postgresql://user:password@host:5432/database"

[mcp.database.pool]
min = 2
max = 10
idleTimeoutMillis = 30000
connectionTimeoutMillis = 5000

[mcp.security]
ssl = true

[mcp.security.rateLimit]
enabled = true
maxRequests = 100
windowMs = 60000
```

## Agent-Specific Templates

### 1. Persistent AI Agent Configuration

**Use Case:** Long-running AI assistants with stable environments

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "persistent",
    "server": {
      "name": "persistent-ai-agent-mcp",
      "port": 3000,
      "host": "0.0.0.0",
      "healthCheck": {
        "enabled": true,
        "interval": 30000,
        "timeout": 5000
      }
    },
    "database": {
      "connectionString": "${DATABASE_URL}",
      "connectionType": "direct_ipv6",
      "ssl": {
        "rejectUnauthorized": true,
        "ca": "${DB_SSL_CERT}"
      },
      "pool": {
        "min": 5,
        "max": 20,
        "idleTimeoutMillis": 300000,
        "connectionTimeoutMillis": 10000,
        "acquireTimeoutMillis": 30000,
        "createTimeoutMillis": 5000,
        "destroyTimeoutMillis": 5000,
        "reapIntervalMillis": 1000,
        "createRetryIntervalMillis": 200
      },
      "query": {
        "statementTimeout": 30000,
        "queryTimeout": 30000,
        "idleInTransactionSessionTimeout": 60000
      }
    },
    "security": {
      "authentication": {
        "method": "service_role",
        "serviceRoleKey": "${SUPABASE_SERVICE_ROLE_KEY}"
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 200,
        "windowMs": 60000,
        "message": "Rate limit exceeded. Please try again later."
      },
      "cors": {
        "enabled": true,
        "origins": ["http://localhost:3000", "https://app.example.com"],
        "methods": ["GET", "POST"],
        "allowedHeaders": ["Content-Type", "Authorization"]
      }
    },
    "monitoring": {
      "enabled": true,
      "metrics": {
        "port": 9090,
        "path": "/metrics"
      },
      "logging": {
        "level": "info",
        "format": "json",
        "auditQueries": true
      }
    }
  }
}
```

### 1.5. Persistent AI Agent with Session Mode (IPv4)

**Use Case:** Long-running AI assistants requiring IPv4 connectivity

**Connection Mode:** Supavisor Session Mode via IPv4 pooler

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "persistent_ipv4",
    "server": {
      "name": "persistent-session-mode-mcp",
      "port": 3000,
      "host": "0.0.0.0",
      "healthCheck": {
        "enabled": true,
        "interval": 30000,
        "timeout": 5000
      }
    },
    "database": {
      "connectionString": "${SUPABASE_SESSION_POOLER}",
      "connectionType": "supavisor_session",
      "pooler": {
        "mode": "session",
        "port": 5432,
        "region": "us-east-1"
      },
      "ssl": {
        "rejectUnauthorized": true
      },
      "pool": {
        "min": 5,
        "max": 20,
        "idleTimeoutMillis": 300000,
        "connectionTimeoutMillis": 10000,
        "acquireTimeoutMillis": 30000,
        "maxLifetimeMillis": 1800000
      },
      "query": {
        "statementTimeout": 30000,
        "queryTimeout": 30000,
        "idleInTransactionSessionTimeout": 60000
      },
      "features": {
        "preparedStatements": true,
        "sessionVariables": true,
        "temporaryTables": true
      }
    },
    "security": {
      "authentication": {
        "method": "service_role",
        "serviceRoleKey": "${SUPABASE_SERVICE_ROLE_KEY}"
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 200,
        "windowMs": 60000
      },
      "cors": {
        "enabled": true,
        "origins": ["http://localhost:3000", "https://app.example.com"],
        "methods": ["GET", "POST"],
        "allowedHeaders": ["Content-Type", "Authorization"]
      }
    },
    "monitoring": {
      "enabled": true,
      "metrics": {
        "port": 9090,
        "path": "/metrics",
        "poolStats": true,
        "queryMetrics": true
      },
      "logging": {
        "level": "info",
        "format": "json",
        "auditQueries": true,
        "logConnections": true
      },
      "alerts": {
        "poolSaturation": {
          "enabled": true,
          "threshold": 0.8
        },
        "connectionErrors": {
          "enabled": true,
          "threshold": 5
        }
      }
    }
  }
}
```

**Key Features:**
- IPv4 compatibility for environments without IPv6 support
- Persistent connections with session-level state
- Prepared statement support for query optimization
- Session variable preservation across queries
- Connection pooling with 30 default connections (adjustable)
- Full PostgreSQL feature support

**When to Use:**
- AI agents in IPv4-only networks
- Conversational AI requiring session state
- Agents using prepared statements
- Long-running database operations
- Agents requiring advisory locks or temporary tables

**See Also:** [Session Mode Setup Guide](./MCP_SESSION_MODE_SETUP.md)

### 2. Serverless AI Agent Configuration

**Use Case:** AWS Lambda, Google Cloud Functions, Azure Functions

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "serverless",
    "server": {
      "name": "serverless-ai-agent-mcp",
      "runtime": "lambda",
      "coldStart": {
        "optimized": true,
        "keepWarmInterval": 300000
      }
    },
    "database": {
      "connectionString": "${DATABASE_URL}",
      "connectionType": "supavisor_transaction",
      "pooler": {
        "mode": "transaction",
        "port": 6543
      },
      "ssl": {
        "rejectUnauthorized": true
      },
      "pool": {
        "min": 0,
        "max": 5,
        "idleTimeoutMillis": 5000,
        "connectionTimeoutMillis": 5000,
        "acquireTimeoutMillis": 10000,
        "evictionRunIntervalMillis": 5000,
        "softIdleTimeoutMillis": 3000
      },
      "query": {
        "statementTimeout": 30000,
        "queryTimeout": 25000
      }
    },
    "security": {
      "authentication": {
        "method": "database_credentials",
        "username": "${DB_USERNAME}",
        "password": "${DB_PASSWORD}"
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 50,
        "windowMs": 60000,
        "skipFailedRequests": true
      }
    },
    "monitoring": {
      "enabled": true,
      "logging": {
        "level": "warn",
        "format": "json",
        "cloudwatch": true
      }
    },
    "optimization": {
      "connectionReuse": true,
      "lazyConnection": true,
      "preparedStatements": false
    }
  }
}
```

### 3. Edge AI Agent Configuration

**Use Case:** Cloudflare Workers, Deno Deploy, Vercel Edge

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "edge",
    "server": {
      "name": "edge-ai-agent-mcp",
      "runtime": "edge",
      "region": "auto"
    },
    "database": {
      "connectionString": "${DATABASE_URL}",
      "connectionType": "supavisor_transaction",
      "pooler": {
        "mode": "transaction",
        "port": 6543,
        "region": "auto"
      },
      "ssl": {
        "rejectUnauthorized": true
      },
      "pool": {
        "min": 0,
        "max": 3,
        "idleTimeoutMillis": 1000,
        "connectionTimeoutMillis": 3000,
        "acquireTimeoutMillis": 5000
      },
      "query": {
        "statementTimeout": 10000,
        "queryTimeout": 8000
      }
    },
    "security": {
      "authentication": {
        "method": "jwt",
        "jwtSecret": "${JWT_SECRET}",
        "jwtExpiry": 3600
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 30,
        "windowMs": 60000,
        "headers": true
      }
    },
    "monitoring": {
      "enabled": false,
      "logging": {
        "level": "error",
        "format": "text"
      }
    },
    "optimization": {
      "minimizeLatency": true,
      "connectionReuse": true,
      "lazyConnection": true
    }
  }
}
```

### 4. High-Performance AI Agent Configuration

**Use Case:** Intensive workloads with many concurrent operations

```json
{
  "mcp": {
    "version": "1.0.0",
    "agentType": "high_performance",
    "server": {
      "name": "high-perf-ai-agent-mcp",
      "port": 3000,
      "host": "0.0.0.0",
      "workers": 4
    },
    "database": {
      "connectionString": "${DATABASE_URL}",
      "connectionType": "dedicated_pooler",
      "pooler": {
        "mode": "session",
        "port": 5432,
        "dedicated": true
      },
      "ssl": {
        "rejectUnauthorized": true,
        "ca": "${DB_SSL_CERT}"
      },
      "pool": {
        "min": 10,
        "max": 100,
        "idleTimeoutMillis": 600000,
        "connectionTimeoutMillis": 10000,
        "acquireTimeoutMillis": 30000,
        "queueLimit": 1000
      },
      "query": {
        "statementTimeout": 60000,
        "queryTimeout": 60000,
        "idleInTransactionSessionTimeout": 300000
      }
    },
    "security": {
      "authentication": {
        "method": "service_role",
        "serviceRoleKey": "${SUPABASE_SERVICE_ROLE_KEY}"
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 1000,
        "windowMs": 60000,
        "skipSuccessfulRequests": false
      }
    },
    "monitoring": {
      "enabled": true,
      "metrics": {
        "port": 9090,
        "path": "/metrics",
        "detailed": true
      },
      "logging": {
        "level": "debug",
        "format": "json",
        "auditQueries": true,
        "slowQueryThreshold": 1000
      },
      "alerts": {
        "enabled": true,
        "poolSaturation": 0.8,
        "errorRate": 0.05,
        "responseTime": 5000
      }
    },
    "optimization": {
      "connectionReuse": true,
      "preparedStatements": true,
      "queryCache": true,
      "parallelQueries": true
    }
  }
}
```

## Environment-Specific Configurations

### Development Environment

```json
{
  "mcp": {
    "version": "1.0.0",
    "environment": "development",
    "server": {
      "name": "dev-mcp-server",
      "port": 3000,
      "host": "localhost"
    },
    "database": {
      "connectionString": "postgresql://postgres:postgres@localhost:54322/postgres",
      "connectionType": "direct",
      "ssl": false,
      "pool": {
        "min": 2,
        "max": 5,
        "idleTimeoutMillis": 10000
      }
    },
    "security": {
      "authentication": {
        "method": "service_role",
        "serviceRoleKey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      },
      "rateLimit": {
        "enabled": false
      }
    },
    "monitoring": {
      "enabled": true,
      "logging": {
        "level": "debug",
        "format": "pretty",
        "auditQueries": true
      }
    }
  }
}
```

### Staging Environment

```json
{
  "mcp": {
    "version": "1.0.0",
    "environment": "staging",
    "server": {
      "name": "staging-mcp-server",
      "port": 3000,
      "host": "0.0.0.0"
    },
    "database": {
      "connectionString": "${STAGING_DATABASE_URL}",
      "connectionType": "supavisor_session",
      "ssl": {
        "rejectUnauthorized": true
      },
      "pool": {
        "min": 5,
        "max": 15,
        "idleTimeoutMillis": 60000
      }
    },
    "security": {
      "authentication": {
        "method": "service_role",
        "serviceRoleKey": "${STAGING_SERVICE_ROLE_KEY}"
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 500,
        "windowMs": 60000
      }
    },
    "monitoring": {
      "enabled": true,
      "logging": {
        "level": "info",
        "format": "json"
      }
    }
  }
}
```

### Production Environment

```json
{
  "mcp": {
    "version": "1.0.0",
    "environment": "production",
    "server": {
      "name": "prod-mcp-server",
      "port": 3000,
      "host": "0.0.0.0"
    },
    "database": {
      "connectionString": "${PRODUCTION_DATABASE_URL}",
      "connectionType": "supavisor_transaction",
      "ssl": {
        "rejectUnauthorized": true,
        "ca": "${PRODUCTION_DB_SSL_CERT}"
      },
      "pool": {
        "min": 10,
        "max": 50,
        "idleTimeoutMillis": 300000
      },
      "query": {
        "statementTimeout": 30000
      }
    },
    "security": {
      "authentication": {
        "method": "service_role",
        "serviceRoleKey": "${PRODUCTION_SERVICE_ROLE_KEY}"
      },
      "rateLimit": {
        "enabled": true,
        "maxRequests": 200,
        "windowMs": 60000
      },
      "cors": {
        "enabled": true,
        "origins": ["https://app.example.com"],
        "credentials": true
      }
    },
    "monitoring": {
      "enabled": true,
      "metrics": {
        "port": 9090,
        "path": "/metrics"
      },
      "logging": {
        "level": "warn",
        "format": "json",
        "auditQueries": true
      },
      "alerts": {
        "enabled": true,
        "endpoint": "${ALERT_WEBHOOK_URL}"
      }
    }
  }
}
```

## Connection String Examples

### Local Development

```bash
# Direct connection to local Supabase
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres

# With explicit schema
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres?schema=public

# With connection timeout
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres?connect_timeout=10
```

### Supabase Cloud (Direct IPv6)

```bash
# Direct IPv6 connection
DATABASE_URL=postgresql://postgres.project-ref:[password]@db.project-ref.supabase.co:5432/postgres

# With SSL mode
DATABASE_URL=postgresql://postgres.project-ref:[password]@db.project-ref.supabase.co:5432/postgres?sslmode=require
```

### Supabase Cloud (Session Mode)

```bash
# Session pooler (port 5432)
DATABASE_URL=postgresql://postgres.project-ref:[password]@aws-0-us-east-1.pooler.supabase.com:5432/postgres

# With pool size hint
DATABASE_URL=postgresql://postgres.project-ref:[password]@aws-0-us-east-1.pooler.supabase.com:5432/postgres?pool_size=10
```

### Supabase Cloud (Transaction Mode)

```bash
# Transaction pooler (port 6543)
DATABASE_URL=postgresql://postgres.project-ref:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres

# With statement timeout
DATABASE_URL=postgresql://postgres.project-ref:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?statement_timeout=30000
```

### Supabase Cloud (Dedicated Pooler - Paid Tier)

```bash
# Dedicated pooler co-located with database (port 6543)
SUPABASE_DEDICATED_POOLER=postgresql://postgres.project-ref:[password]@db.project-ref.supabase.co:6543/postgres

# With prepared statements disabled (required)
SUPABASE_DEDICATED_POOLER=postgresql://postgres.project-ref:[password]@db.project-ref.supabase.co:6543/postgres?prepared_statements=false

# With statement timeout
SUPABASE_DEDICATED_POOLER=postgresql://postgres.project-ref:[password]@db.project-ref.supabase.co:6543/postgres?statement_timeout=30000

# Note: Requires Pro/Enterprise plan with dedicated pooler enabled
# See: docs/MCP_DEDICATED_POOLER.md for complete guide
```

## Environment Variable Templates

### .env Template for MCP Server

```bash
# MCP Server Configuration
MCP_SERVER_NAME=supabase-mcp-server
MCP_SERVER_PORT=3000
MCP_SERVER_HOST=0.0.0.0

# Database Connection
DATABASE_URL=postgresql://user:password@host:5432/database
DB_CONNECTION_TYPE=supavisor_transaction
DB_SSL_ENABLED=true
DB_SSL_CERT_PATH=/path/to/cert.pem

# Connection Pool
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_POOL_IDLE_TIMEOUT=30000
DB_POOL_CONNECTION_TIMEOUT=5000

# Supabase Credentials
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Security
JWT_SECRET=your-jwt-secret
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_WINDOW_MS=60000

# Monitoring
ENABLE_MONITORING=true
ENABLE_METRICS=true
METRICS_PORT=9090
LOG_LEVEL=info
LOG_FORMAT=json

# Environment
NODE_ENV=production
ENVIRONMENT=production
```

### .env.example Template

```bash
# MCP Server Configuration
# Copy this file to .env and fill in your actual values

# Server Settings
MCP_SERVER_NAME=supabase-mcp-server
MCP_SERVER_PORT=3000
MCP_SERVER_HOST=0.0.0.0

# Database Connection
# Get this from your Supabase project settings
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.project-ref.supabase.co:5432/postgres

# Connection Type: direct_ipv6, direct_ipv4, supavisor_session, supavisor_transaction, dedicated_pooler
DB_CONNECTION_TYPE=supavisor_transaction

# Dedicated Pooler (Paid Tier Only - uncomment if using)
# SUPABASE_DEDICATED_POOLER=postgresql://postgres.[project-ref]:[YOUR-PASSWORD]@db.[project-ref].supabase.co:6543/postgres
# DB_CONNECTION_TYPE=dedicated_pooler
# DISABLE_PREPARED_STATEMENTS=true

# SSL Configuration
DB_SSL_ENABLED=true
DB_SSL_REJECT_UNAUTHORIZED=true

# Connection Pool Settings
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_POOL_IDLE_TIMEOUT=30000
DB_POOL_CONNECTION_TIMEOUT=5000

# Supabase Project Credentials
# Get these from: https://app.supabase.com/project/[project-ref]/settings/api
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Security Settings
JWT_SECRET=your-jwt-secret-here
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_WINDOW_MS=60000

# Monitoring Settings
ENABLE_MONITORING=true
ENABLE_METRICS=true
METRICS_PORT=9090
LOG_LEVEL=info
LOG_FORMAT=json

# Environment
NODE_ENV=production
ENVIRONMENT=production
```

## Configuration Validation

### JSON Schema for MCP Configuration

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MCP Server Configuration",
  "type": "object",
  "required": ["mcp"],
  "properties": {
    "mcp": {
      "type": "object",
      "required": ["version", "server", "database"],
      "properties": {
        "version": {
          "type": "string",
          "pattern": "^\\d+\\.\\d+\\.\\d+$"
        },
        "agentType": {
          "type": "string",
          "enum": ["persistent", "serverless", "edge", "high_performance"]
        },
        "environment": {
          "type": "string",
          "enum": ["development", "staging", "production"]
        },
        "server": {
          "type": "object",
          "required": ["name", "port"],
          "properties": {
            "name": { "type": "string" },
            "port": { "type": "integer", "minimum": 1, "maximum": 65535 },
            "host": { "type": "string" }
          }
        },
        "database": {
          "type": "object",
          "required": ["connectionString"],
          "properties": {
            "connectionString": { "type": "string" },
            "connectionType": {
              "type": "string",
              "enum": ["direct_ipv6", "direct_ipv4", "supavisor_session", "supavisor_transaction", "dedicated_pooler"]
            },
            "pool": {
              "type": "object",
              "properties": {
                "min": { "type": "integer", "minimum": 0 },
                "max": { "type": "integer", "minimum": 1 },
                "idleTimeoutMillis": { "type": "integer", "minimum": 0 },
                "connectionTimeoutMillis": { "type": "integer", "minimum": 0 }
              }
            }
          }
        },
        "security": {
          "type": "object",
          "properties": {
            "authentication": {
              "type": "object",
              "required": ["method"],
              "properties": {
                "method": {
                  "type": "string",
                  "enum": ["service_role", "database_credentials", "jwt", "api_key"]
                }
              }
            },
            "rateLimit": {
              "type": "object",
              "properties": {
                "enabled": { "type": "boolean" },
                "maxRequests": { "type": "integer", "minimum": 1 },
                "windowMs": { "type": "integer", "minimum": 1000 }
              }
            }
          }
        }
      }
    }
  }
}
```

## Best Practices

### 1. Use Environment Variables

Always use environment variables for sensitive configuration:

```typescript
// Good ✅
const config = {
  database: {
    connectionString: process.env.DATABASE_URL
  }
};

// Bad ❌
const config = {
  database: {
    connectionString: "postgresql://user:password@host:5432/db"
  }
};
```

### 2. Separate Configurations by Environment

Maintain separate configuration files for each environment:

```
config/
├── mcp.development.json
├── mcp.staging.json
├── mcp.production.json
└── mcp.schema.json
```

### 3. Validate Configuration on Startup

```typescript
import Ajv from 'ajv';
import schema from './config/mcp.schema.json';
import config from './config/mcp.production.json';

const ajv = new Ajv();
const validate = ajv.compile(schema);

if (!validate(config)) {
  console.error('Invalid configuration:', validate.errors);
  process.exit(1);
}
```

### 4. Document Configuration Changes

Keep a changelog of configuration updates:

```markdown
# Configuration Changelog

## [1.1.0] - 2025-10-15
- Added support for dedicated pooler
- Increased max connections from 10 to 20
- Enabled query audit logging

## [1.0.0] - 2025-10-05
- Initial MCP server configuration
```

### 5. Version Control Configuration Templates

Store configuration templates (without secrets) in version control:

```bash
# Commit templates
git add config/*.example.json
git add config/*.schema.json

# Never commit actual secrets
echo "config/*.json" >> .gitignore
echo "!config/*.example.json" >> .gitignore
echo "!config/*.schema.json" >> .gitignore
```

## Troubleshooting

### Connection Issues

1. **"Connection timeout"**
   - Increase `connectionTimeoutMillis`
   - Check network connectivity
   - Verify firewall rules

2. **"Too many connections"**
   - Reduce `pool.max`
   - Check for connection leaks
   - Enable connection monitoring

3. **"SSL connection error"**
   - **Production**: Always use `ssl.rejectUnauthorized: true` with valid certificate
   - Verify SSL certificate path (use absolute path)
   - Download certificate from Supabase Dashboard → Settings → Database
   - See [SSL/TLS Security Guide](./MCP_SSL_TLS_SECURITY.md) for complete troubleshooting
   - For testing only: Set `ssl.rejectUnauthorized: false` (never in production)

### Performance Issues

1. **Slow query performance**
   - Lower `statementTimeout`
   - Enable prepared statements
   - Add query caching

2. **High connection churn**
   - Increase `idleTimeoutMillis`
   - Enable connection reuse
   - Use session mode for persistent agents

3. **Memory issues**
   - Reduce `pool.max`
   - Enable pool eviction
   - Monitor connection lifecycle

## Related Documentation

- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Dedicated Pooler Guide](./MCP_DEDICATED_POOLER.md) - High-performance pooler for paid tiers
- [MCP Authentication Strategies](./MCP_AUTHENTICATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [SSL/TLS Security Guide](./MCP_SSL_TLS_SECURITY.md) - **Critical for Production**

---

**Last Updated**: 2025-10-05  
**Version**: 1.0.0  
**Status**: ✅ Initial Release
