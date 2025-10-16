# MCP Server Configuration for AI Agents

## Overview

This document provides practical configuration examples for setting up MCP servers with AI agent authentication and authorization. These configurations implement the security best practices outlined in [AI_AGENT_SECURITY.md](AI_AGENT_SECURITY.md).

## Table of Contents

- [Configuration Templates](#configuration-templates)
- [Authentication Patterns](#authentication-patterns)
- [Environment Setup](#environment-setup)
- [Deployment Examples](#deployment-examples)
- [Monitoring Configuration](#monitoring-configuration)

## Configuration Templates

### Read-Only AI Agent Configuration

For AI agents that only need to query data (chatbots, analytics viewers, search assistants).

```json
{
  "mcpServers": {
    "ai-agent-readonly": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_AI_AGENT_READONLY_CONNECTION}"
      ],
      "env": {
        "AGENT_ROLE": "readonly",
        "AGENT_ID": "chatbot_001",
        "AGENT_TYPE": "chatbot",
        "AUDIT_LOG": "true",
        "MAX_QUERY_TIME": "30000",
        "RATE_LIMIT": "100"
      },
      "metadata": {
        "description": "Read-only MCP server for AI chatbot",
        "permissions": ["SELECT"],
        "tables": ["profiles", "posts", "categories"]
      }
    }
  }
}
```

### Read-Write AI Agent Configuration

For AI agents that need to create and modify data (content generators, data processors).

```json
{
  "mcpServers": {
    "ai-agent-readwrite": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_AI_AGENT_READWRITE_CONNECTION}"
      ],
      "env": {
        "AGENT_ROLE": "readwrite",
        "AGENT_ID": "content_generator_001",
        "AGENT_TYPE": "content_generator",
        "AUDIT_LOG": "true",
        "MAX_QUERY_TIME": "45000",
        "RATE_LIMIT": "50"
      },
      "metadata": {
        "description": "Read-write MCP server for content generation",
        "permissions": ["SELECT", "INSERT", "UPDATE"],
        "tables": ["posts", "drafts", "media"]
      }
    }
  }
}
```

### Analytics AI Agent Configuration

For AI agents performing analytics and reporting.

```json
{
  "mcpServers": {
    "ai-agent-analytics": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "${SUPABASE_AI_AGENT_ANALYTICS_CONNECTION}"
      ],
      "env": {
        "AGENT_ROLE": "analytics",
        "AGENT_ID": "analytics_engine_001",
        "AGENT_TYPE": "analytics",
        "AUDIT_LOG": "true",
        "MAX_QUERY_TIME": "120000",
        "RATE_LIMIT": "30"
      },
      "metadata": {
        "description": "Analytics MCP server for business intelligence",
        "permissions": ["SELECT", "CREATE MATERIALIZED VIEW"],
        "tables": ["*"]
      }
    }
  }
}
```

## Authentication Patterns

### Pattern 1: Database Credentials Authentication

**Use Case:** Production AI agents with dedicated database users.

```typescript
// MCP Server Configuration
import { createMCPServer } from 'mcp-server-postgres';

const server = createMCPServer({
  authentication: {
    method: 'database_credentials',
    connectionString: process.env.SUPABASE_AI_AGENT_READONLY_CONNECTION,
    ssl: {
      rejectUnauthorized: true
    }
  },
  agent: {
    id: process.env.AGENT_ID || 'chatbot_001',
    role: process.env.AGENT_ROLE || 'readonly',
    type: process.env.AGENT_TYPE || 'chatbot'
  },
  audit: {
    enabled: process.env.AUDIT_LOG === 'true',
    logAuthentication: true,
    logQueries: true,
    logFunction: async (logEntry) => {
      // Log to database using audit functions
      await db.query(
        'SELECT public.log_mcp_query($1, $2, $3, $4, $5, $6)',
        [
          logEntry.agentId,
          logEntry.agentRole,
          logEntry.operation,
          logEntry.query,
          logEntry.executionTime,
          logEntry.rows
        ]
      );
    }
  },
  limits: {
    maxQueryTime: parseInt(process.env.MAX_QUERY_TIME || '30000'),
    maxConnections: 10,
    rateLimit: parseInt(process.env.RATE_LIMIT || '100')
  }
});

server.start();
```

### Pattern 2: API Key Authentication

**Use Case:** External AI agents with rate limiting and tracking.

```typescript
// MCP Server Configuration with API Key
import { createMCPServer } from 'mcp-server-postgres';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const server = createMCPServer({
  authentication: {
    method: 'api_key',
    validateFunction: async (apiKey: string) => {
      // Validate API key against database
      const { data, error } = await supabase
        .rpc('validate_api_key', { api_key_input: apiKey });
      
      if (error || !data?.[0]?.valid) {
        // Log failed authentication
        await supabase.rpc('log_auth_attempt', {
          agent_id: 'unknown',
          method: 'api_key',
          success: false,
          error: error?.message || 'Invalid API key'
        });
        
        throw new Error('Invalid API key');
      }
      
      // Log successful authentication
      await supabase.rpc('log_auth_attempt', {
        agent_id: data[0].agent_name,
        method: 'api_key',
        success: true
      });
      
      return {
        agentName: data[0].agent_name,
        agentType: data[0].agent_type,
        agentRole: data[0].agent_role,
        permissions: data[0].permissions,
        rateLimit: data[0].rate_limit
      };
    }
  },
  agent: {
    id: process.env.AGENT_ID,
    role: process.env.AGENT_ROLE,
    type: process.env.AGENT_TYPE
  },
  audit: {
    enabled: true,
    logAuthentication: true,
    logQueries: true
  }
});

server.start();
```

### Pattern 3: JWT Token Authentication

**Use Case:** User-context aware AI agents with RLS enforcement.

```typescript
// MCP Server Configuration with JWT
import { createMCPServer } from 'mcp-server-postgres';
import jwt from 'jsonwebtoken';

const server = createMCPServer({
  authentication: {
    method: 'jwt',
    jwtSecret: process.env.JWT_SECRET!,
    jwtIssuer: 'supabase',
    jwtAudience: 'authenticated',
    generateToken: (userId: string, agentType: string) => {
      const payload = {
        sub: userId,
        role: 'authenticated',
        agent_type: agentType,
        iss: 'supabase',
        aud: 'authenticated',
        exp: Math.floor(Date.now() / 1000) + (60 * 60) // 1 hour
      };
      return jwt.sign(payload, process.env.JWT_SECRET!);
    }
  },
  agent: {
    id: process.env.AGENT_ID,
    role: process.env.AGENT_ROLE,
    type: process.env.AGENT_TYPE
  },
  audit: {
    enabled: true,
    logAuthentication: true,
    logQueries: true
  }
});

server.start();
```

## Environment Setup

### Development Environment

```bash
# .env.development
# Database connections for AI agents
SUPABASE_AI_AGENT_READONLY_CONNECTION=postgresql://ai_readonly_user:dev_password@localhost:54322/postgres?sslmode=disable
SUPABASE_AI_AGENT_READWRITE_CONNECTION=postgresql://ai_readwrite_user:dev_password@localhost:54322/postgres?sslmode=disable
SUPABASE_AI_AGENT_ANALYTICS_CONNECTION=postgresql://ai_analytics_user:dev_password@localhost:54322/postgres?sslmode=disable

# Agent configuration
AGENT_ID=chatbot_dev_001
AGENT_ROLE=readonly
AGENT_TYPE=chatbot

# Audit configuration
AUDIT_LOG=true

# Limits
MAX_QUERY_TIME=30000
RATE_LIMIT=1000

# MCP Server
MCP_SERVER_PORT=3000
MCP_CONNECTION_TYPE=direct
```

### Staging Environment

```bash
# .env.staging
# Database connections (use Supavisor transaction mode)
SUPABASE_AI_AGENT_READONLY_CONNECTION=postgresql://ai_readonly_user:staging_password@db.staging-project.supabase.co:6543/postgres?sslmode=require
SUPABASE_AI_AGENT_READWRITE_CONNECTION=postgresql://ai_readwrite_user:staging_password@db.staging-project.supabase.co:6543/postgres?sslmode=require
SUPABASE_AI_AGENT_ANALYTICS_CONNECTION=postgresql://ai_analytics_user:staging_password@db.staging-project.supabase.co:6543/postgres?sslmode=require

# Agent configuration
AGENT_ID=chatbot_staging_001
AGENT_ROLE=readonly
AGENT_TYPE=chatbot

# Audit configuration
AUDIT_LOG=true

# Limits
MAX_QUERY_TIME=30000
RATE_LIMIT=200

# MCP Server
MCP_SERVER_PORT=3000
MCP_CONNECTION_TYPE=supavisor_transaction
```

### Production Environment

```bash
# .env.production
# ⚠️ DO NOT store production credentials in .env files
# Use secret management systems (AWS Secrets Manager, HashiCorp Vault, etc.)

# Database connections (use Supavisor session mode for persistent agents)
SUPABASE_AI_AGENT_READONLY_CONNECTION=postgresql://ai_readonly_user:SECURE_PASSWORD@db.project-ref.supabase.co:5432/postgres?sslmode=require
SUPABASE_AI_AGENT_READWRITE_CONNECTION=postgresql://ai_readwrite_user:SECURE_PASSWORD@db.project-ref.supabase.co:5432/postgres?sslmode=require
SUPABASE_AI_AGENT_ANALYTICS_CONNECTION=postgresql://ai_analytics_user:SECURE_PASSWORD@db.project-ref.supabase.co:5432/postgres?sslmode=require

# API Key authentication
SUPABASE_AI_AGENT_API_KEY=sk_ai_GENERATED_KEY_HERE

# Agent configuration
AGENT_ID=chatbot_prod_001
AGENT_ROLE=readonly
AGENT_TYPE=chatbot

# Audit configuration
AUDIT_LOG=true

# Limits
MAX_QUERY_TIME=30000
RATE_LIMIT=100

# MCP Server
MCP_SERVER_PORT=3000
MCP_CONNECTION_TYPE=supavisor_session

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090
```

## Deployment Examples

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  mcp-server-readonly:
    image: mcp-server-postgres:latest
    environment:
      SUPABASE_AI_AGENT_READONLY_CONNECTION: ${SUPABASE_AI_AGENT_READONLY_CONNECTION}
      AGENT_ID: chatbot_001
      AGENT_ROLE: readonly
      AGENT_TYPE: chatbot
      AUDIT_LOG: "true"
      MAX_QUERY_TIME: "30000"
      RATE_LIMIT: "100"
    ports:
      - "3001:3000"
    restart: unless-stopped
    networks:
      - mcp-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  mcp-server-readwrite:
    image: mcp-server-postgres:latest
    environment:
      SUPABASE_AI_AGENT_READWRITE_CONNECTION: ${SUPABASE_AI_AGENT_READWRITE_CONNECTION}
      AGENT_ID: content_generator_001
      AGENT_ROLE: readwrite
      AGENT_TYPE: content_generator
      AUDIT_LOG: "true"
      MAX_QUERY_TIME: "45000"
      RATE_LIMIT: "50"
    ports:
      - "3002:3000"
    restart: unless-stopped
    networks:
      - mcp-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  mcp-server-analytics:
    image: mcp-server-postgres:latest
    environment:
      SUPABASE_AI_AGENT_ANALYTICS_CONNECTION: ${SUPABASE_AI_AGENT_ANALYTICS_CONNECTION}
      AGENT_ID: analytics_engine_001
      AGENT_ROLE: analytics
      AGENT_TYPE: analytics
      AUDIT_LOG: "true"
      MAX_QUERY_TIME: "120000"
      RATE_LIMIT: "30"
    ports:
      - "3003:3000"
    restart: unless-stopped
    networks:
      - mcp-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  mcp-network:
    driver: bridge
```

### Kubernetes

```yaml
# kubernetes/mcp-readonly-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-server-readonly
  labels:
    app: mcp-server
    role: readonly
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mcp-server
      role: readonly
  template:
    metadata:
      labels:
        app: mcp-server
        role: readonly
    spec:
      containers:
      - name: mcp-server
        image: mcp-server-postgres:latest
        ports:
        - containerPort: 3000
        env:
        - name: SUPABASE_AI_AGENT_READONLY_CONNECTION
          valueFrom:
            secretKeyRef:
              name: ai-agent-credentials
              key: readonly-connection
        - name: AGENT_ID
          value: "chatbot_k8s_001"
        - name: AGENT_ROLE
          value: "readonly"
        - name: AGENT_TYPE
          value: "chatbot"
        - name: AUDIT_LOG
          value: "true"
        - name: MAX_QUERY_TIME
          value: "30000"
        - name: RATE_LIMIT
          value: "100"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: mcp-server-readonly
spec:
  selector:
    app: mcp-server
    role: readonly
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP

---
apiVersion: v1
kind: Secret
metadata:
  name: ai-agent-credentials
type: Opaque
stringData:
  readonly-connection: "postgresql://ai_readonly_user:SECURE_PASSWORD@db.project-ref.supabase.co:5432/postgres?sslmode=require"
  readwrite-connection: "postgresql://ai_readwrite_user:SECURE_PASSWORD@db.project-ref.supabase.co:5432/postgres?sslmode=require"
  analytics-connection: "postgresql://ai_analytics_user:SECURE_PASSWORD@db.project-ref.supabase.co:5432/postgres?sslmode=require"
```

### Systemd Service

```ini
# /etc/systemd/system/mcp-server-readonly.service
[Unit]
Description=MCP Server - Read-Only AI Agent
After=network.target

[Service]
Type=simple
User=mcp
Group=mcp
WorkingDirectory=/opt/mcp-server
EnvironmentFile=/opt/mcp-server/.env
ExecStart=/usr/local/bin/mcp-server-postgres
Restart=always
RestartSec=10

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/mcp-server

[Install]
WantedBy=multi-user.target
```

## Monitoring Configuration

### Prometheus Metrics

```typescript
// Expose metrics for Prometheus
import { createMCPServer } from 'mcp-server-postgres';
import promClient from 'prom-client';

// Create metrics
const authAttemptsCounter = new promClient.Counter({
  name: 'mcp_auth_attempts_total',
  help: 'Total number of authentication attempts',
  labelNames: ['agent_id', 'agent_role', 'success']
});

const queryDurationHistogram = new promClient.Histogram({
  name: 'mcp_query_duration_ms',
  help: 'Query execution duration in milliseconds',
  labelNames: ['agent_id', 'agent_role', 'operation'],
  buckets: [10, 50, 100, 500, 1000, 5000, 10000]
});

const activeConnectionsGauge = new promClient.Gauge({
  name: 'mcp_active_connections',
  help: 'Number of active database connections',
  labelNames: ['agent_id', 'agent_role']
});

const server = createMCPServer({
  // ... authentication config ...
  monitoring: {
    enabled: true,
    metricsPort: 9090,
    onAuthentication: (agentId, agentRole, success) => {
      authAttemptsCounter.inc({ agent_id: agentId, agent_role: agentRole, success });
    },
    onQuery: (agentId, agentRole, operation, duration) => {
      queryDurationHistogram.observe({ agent_id: agentId, agent_role: agentRole, operation }, duration);
    },
    onConnectionChange: (agentId, agentRole, count) => {
      activeConnectionsGauge.set({ agent_id: agentId, agent_role: agentRole }, count);
    }
  }
});
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "MCP Server - AI Agent Monitoring",
    "panels": [
      {
        "title": "Authentication Success Rate",
        "targets": [
          {
            "expr": "rate(mcp_auth_attempts_total{success=\"true\"}[5m]) / rate(mcp_auth_attempts_total[5m])"
          }
        ]
      },
      {
        "title": "Query Duration (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(mcp_query_duration_ms_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Active Connections by Agent",
        "targets": [
          {
            "expr": "mcp_active_connections"
          }
        ]
      }
    ]
  }
}
```

## Related Documentation

- [AI Agent Security](AI_AGENT_SECURITY.md) - Security best practices
- [Credential Rotation](CREDENTIAL_ROTATION.md) - Rotation procedures
- [MCP Authentication](MCP_AUTHENTICATION.md) - Authentication methods
- [MCP Server Configuration](MCP_SERVER_CONFIGURATION.md) - General configuration

## References

- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [PostgreSQL Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
- [Supabase Database Settings](https://supabase.com/docs/guides/database/connecting-to-postgres)
