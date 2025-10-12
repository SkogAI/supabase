# Connection Pool Optimization for AI Workloads

## Overview

This document provides comprehensive guidance on configuring and optimizing connection pools specifically for AI agent workloads. AI agents have unique connection patterns that require specialized pool configurations to ensure optimal performance, resource utilization, and cost efficiency.

## AI Agent Connection Patterns

AI agents exhibit distinct connection behaviors that differ from traditional web applications:

### Unique Characteristics

1. **Burst Traffic During Inference**
   - Sudden spikes in database queries during AI model inference
   - Variable query volume based on user interactions
   - Peak loads during business hours or scheduled tasks

2. **Variable Query Complexity**
   - Simple lookups (e.g., retrieving context, user preferences)
   - Complex analytical queries (e.g., embeddings search, aggregations)
   - Mixed read-heavy and write operations
   - Long-running queries for data processing

3. **Mixed Read/Write Operations**
   - High read volumes for context retrieval
   - Moderate writes for storing results, logs, and metrics
   - Transactional requirements for consistency
   - Potential for connection state management

4. **Long-Running Analytical Queries**
   - Vector similarity searches with large datasets
   - Aggregations across multiple tables
   - Complex JOINs for context assembly
   - Potential for query timeouts

5. **Auto-Scaling Requirements**
   - Dynamic scaling based on agent load
   - Rapid scale-up during traffic spikes
   - Gradual scale-down during idle periods
   - Connection pool adaptation to scaling events

## Pool Size Calculation Formulas

### Basic Formula for AI Agents

```
Recommended Pool Size = (Expected Concurrent Agents × Avg Queries per Agent) + Buffer

Where:
  Expected Concurrent Agents = Peak concurrent agent instances
  Avg Queries per Agent = Average queries per agent per time window
  Buffer = 20% of calculated value (minimum 5 connections)
```

### Examples by Workload

#### Low Concurrency (1-10 Agents)
```
Pool Size = (10 agents × 2 queries/agent) + 4 buffer = 24 connections
Recommended: min=5, max=25
```

#### Medium Concurrency (10-50 Agents)
```
Pool Size = (50 agents × 3 queries/agent) + 30 buffer = 180 connections
Recommended: min=20, max=200
```

#### High Concurrency (50-200 Agents)
```
Pool Size = (200 agents × 4 queries/agent) + 160 buffer = 960 connections
Recommended: min=50, max=1000
```

### Advanced Formula (Performance-Based)

```
Optimal Pool Size = ((CPU Cores × 2) + Effective Disk Spindles) × Agent Multiplier

Where:
  CPU Cores = Database server CPU count
  Effective Disk Spindles = Concurrent I/O operations (SSDs = 4-8)
  Agent Multiplier = 2-4 (based on query complexity)
```

For Supabase environments:

| Compute Tier | CPU Cores | Base Pool Size | AI Agent Pool Size |
|--------------|-----------|----------------|-------------------|
| Free         | 2         | 8-12          | 15-20            |
| Small        | 2         | 8-12          | 20-30            |
| Medium       | 4         | 16-24         | 30-50            |
| Large        | 8         | 32-48         | 50-100           |
| XL           | 16        | 64-96         | 100-200          |
| 2XL          | 32        | 128-192       | 200-400          |

## Optimization Strategies by Agent Type

### 1. Persistent AI Agents

**Characteristics:**
- Long-running processes (hours to days)
- Stable execution environment
- Consistent resource needs
- Predictable query patterns

**Optimal Configuration:**
```typescript
{
  connection: {
    mode: "session",
    type: "direct_ipv6" // or supavisor_session
  },
  pool: {
    min: 5,
    max: 20,
    idleTimeoutMillis: 600000,      // 10 minutes
    connectionTimeoutMillis: 10000,  // 10 seconds
    acquireTimeoutMillis: 30000,     // 30 seconds
    maxLifetimeMillis: 1800000,      // 30 minutes
    evictionRunIntervalMillis: 60000 // 1 minute
  },
  query: {
    statementTimeout: 60000,         // 60 seconds
    idleInTransactionTimeout: 120000 // 2 minutes
  }
}
```

**Rationale:**
- **Moderate pool size (5-20):** Balances resource usage with availability
- **Long idle timeout (10 min):** Maintains connections during quiet periods
- **Session mode:** Preserves prepared statements and session state
- **Max lifetime (30 min):** Prevents stale connections

**Application-Side Pooling:**
```typescript
// Node.js with pg-pool
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: 5432,
  database: 'postgres',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  min: 5,
  max: 20,
  idleTimeoutMillis: 600000,
  connectionTimeoutMillis: 10000,
  maxUses: 7500, // Rotate after 7500 queries
  allowExitOnIdle: true
});

// Query with automatic connection management
async function queryWithRetry(sql: string, params: any[] = [], retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await pool.query(sql, params);
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, i)));
    }
  }
}
```

### 2. Serverless AI Agents

**Characteristics:**
- Short-lived execution (seconds to minutes)
- Cold start initialization
- Shared infrastructure
- Variable resource availability

**Optimal Configuration:**
```typescript
{
  connection: {
    mode: "transaction",
    type: "supavisor_transaction"
  },
  pool: {
    min: 0,                              // No idle connections
    max: 10,
    idleTimeoutMillis: 5000,             // 5 seconds
    connectionTimeoutMillis: 5000,       // 5 seconds
    acquireTimeoutMillis: 10000,         // 10 seconds
    reapIntervalMillis: 1000,            // Aggressive cleanup
    softIdleTimeoutMillis: 3000          // 3 seconds
  },
  query: {
    statementTimeout: 30000,             // 30 seconds
    queryTimeout: 25000                  // 25 seconds
  }
}
```

**Rationale:**
- **Zero minimum connections:** Reduce costs during idle periods
- **Higher max pool (10):** Handle burst traffic
- **Aggressive timeouts (5s):** Minimize connection lifetime
- **Transaction mode:** Automatic connection release
- **Fast cleanup:** Rapid resource deallocation

**Serverless Implementation Example:**
```typescript
// AWS Lambda handler
import { createClient } from '@supabase/supabase-js';

let supabaseClient: any = null;

export async function handler(event: any) {
  // Lazy initialization
  if (!supabaseClient) {
    supabaseClient = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!,
      {
        db: {
          schema: 'public'
        },
        auth: {
          persistSession: false,
          autoRefreshToken: false
        },
        global: {
          headers: {
            'x-application-name': 'serverless-ai-agent'
          }
        }
      }
    );
  }

  // Query with automatic cleanup
  try {
    const { data, error } = await supabaseClient
      .from('documents')
      .select('*')
      .limit(10);
    
    if (error) throw error;
    return { statusCode: 200, body: JSON.stringify(data) };
  } catch (error) {
    return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
  }
}
```

### 3. Edge AI Agents

**Characteristics:**
- Global distribution
- Minimal latency requirements
- Limited execution time (< 30 seconds)
- Resource constraints (50-128 MB memory)

**Optimal Configuration:**
```typescript
{
  connection: {
    mode: "transaction",
    type: "supavisor_transaction",
    region: "auto" // Closest region
  },
  pool: {
    min: 0,
    max: 3,                              // Very limited
    idleTimeoutMillis: 1000,             // 1 second
    connectionTimeoutMillis: 3000,       // 3 seconds
    acquireTimeoutMillis: 5000           // 5 seconds
  },
  query: {
    statementTimeout: 10000,             // 10 seconds
    queryTimeout: 8000                   // 8 seconds
  }
}
```

**Rationale:**
- **Minimal pool size (0-3):** Memory constraints
- **Ultra-aggressive timeouts (1-3s):** Fast execution environment
- **Geographic optimization:** Reduce network latency
- **Simple queries only:** Avoid complex operations

**Edge Function Example:**
```typescript
// Deno Edge Function
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    {
      db: { schema: 'public' },
      auth: { persistSession: false }
    }
  );

  try {
    // Simple, fast query
    const { data, error } = await supabase
      .from('cache')
      .select('value')
      .eq('key', 'config')
      .single();
    
    if (error) throw error;
    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
});
```

### 4. High-Performance AI Agents

**Characteristics:**
- Intensive workloads
- Many concurrent operations (100+ qps)
- Predictable resource needs
- SLA requirements (< 100ms p99)

**Optimal Configuration:**
```typescript
{
  connection: {
    mode: "session",
    type: "dedicated_pooler"
  },
  pool: {
    min: 20,
    max: 100,
    idleTimeoutMillis: 600000,           // 10 minutes
    connectionTimeoutMillis: 10000,      // 10 seconds
    acquireTimeoutMillis: 30000,         // 30 seconds
    queueLimit: 1000,                    // Queue up to 1000 requests
    priorityRange: 10                    // Priority queueing
  },
  query: {
    statementTimeout: 60000,             // 60 seconds
    preparedStatementCacheSize: 100,     // Cache prepared statements
    binaryResults: true                  // Binary protocol for performance
  },
  optimization: {
    preparedStatements: true,
    pipelining: true,
    batchQueries: true,
    parallelQueries: 4
  }
}
```

**Rationale:**
- **Large pool size (20-100):** Handle high concurrency
- **Dedicated pooler:** Isolated resources, predictable performance
- **Query optimization:** Prepared statements, batching, pipelining
- **Connection queueing:** Graceful handling of burst traffic

**High-Performance Implementation:**
```typescript
// Node.js with advanced pooling
import { Pool } from 'pg';
import PgBoss from 'pg-boss';

// Primary connection pool
const pool = new Pool({
  host: process.env.POOLER_HOST,
  port: 5432,
  database: 'postgres',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  min: 20,
  max: 100,
  idleTimeoutMillis: 600000,
  connectionTimeoutMillis: 10000,
  statement_timeout: 60000,
  query_timeout: 60000
});

// Enable connection pooling metrics
pool.on('connect', (client) => {
  console.log('Pool: connection established');
});

pool.on('acquire', (client) => {
  console.log('Pool: connection acquired');
});

pool.on('remove', (client) => {
  console.log('Pool: connection removed');
});

// Batch query execution
async function batchQuery(queries: Array<{sql: string, params: any[]}>) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const results = await Promise.all(
      queries.map(q => client.query(q.sql, q.params))
    );
    await client.query('COMMIT');
    return results;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// Parallel query execution
async function parallelQuery(queries: Array<{sql: string, params: any[]}>) {
  return await Promise.all(
    queries.map(q => pool.query(q.sql, q.params))
  );
}
```

## Connection Timeout Strategies

### 1. Connection Establishment Timeouts

**Purpose:** Prevent waiting indefinitely for new connections

**Recommended Values:**
```typescript
{
  connectionTimeoutMillis: {
    persistent: 10000,   // 10 seconds
    serverless: 5000,    // 5 seconds
    edge: 3000,          // 3 seconds
    highPerf: 10000      // 10 seconds
  }
}
```

**Implementation:**
```typescript
// Timeout with fallback
async function connectWithTimeout(timeoutMs: number) {
  return Promise.race([
    pool.connect(),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Connection timeout')), timeoutMs)
    )
  ]);
}
```

### 2. Query Execution Timeouts

**Purpose:** Prevent long-running queries from blocking connections

**Recommended Values:**
```typescript
{
  statementTimeout: {
    simple: 5000,        // 5 seconds for simple queries
    moderate: 30000,     // 30 seconds for moderate complexity
    complex: 60000,      // 60 seconds for complex queries
    analytical: 300000   // 5 minutes for analytical queries
  }
}
```

**Implementation:**
```typescript
// Query-specific timeouts
async function queryWithTimeout(sql: string, params: any[], timeoutMs: number) {
  const client = await pool.connect();
  try {
    await client.query(`SET statement_timeout = ${timeoutMs}`);
    return await client.query(sql, params);
  } finally {
    client.release();
  }
}
```

### 3. Idle Connection Timeouts

**Purpose:** Release unused connections to conserve resources

**Recommended Values:**
```typescript
{
  idleTimeoutMillis: {
    persistent: 600000,  // 10 minutes
    serverless: 5000,    // 5 seconds
    edge: 1000,          // 1 second
    highPerf: 600000     // 10 minutes
  }
}
```

### 4. Transaction Timeouts

**Purpose:** Prevent abandoned transactions from holding locks

**Recommended Values:**
```typescript
{
  idleInTransactionSessionTimeout: {
    default: 60000,      // 1 minute
    longRunning: 300000  // 5 minutes
  }
}
```

**Implementation:**
```sql
-- Set at connection level
SET idle_in_transaction_session_timeout = '60s';

-- Set at role level
ALTER ROLE ai_agent SET idle_in_transaction_session_timeout = '60s';
```

## Max Client Connections Configuration

### Database-Level Settings

```sql
-- Check current max connections
SHOW max_connections;

-- View current connections
SELECT count(*) FROM pg_stat_activity;

-- View connections by application
SELECT 
  application_name,
  count(*) as connections,
  max(state) as states
FROM pg_stat_activity
WHERE application_name LIKE '%ai%'
GROUP BY application_name;
```

### Supabase Compute Tier Limits

| Tier | Max Connections | Reserved | Available for Pooling |
|------|----------------|----------|---------------------|
| Free | 60 | 10 | 50 |
| Small | 90 | 10 | 80 |
| Medium | 150 | 15 | 135 |
| Large | 200 | 20 | 180 |
| XL | 300 | 30 | 270 |
| 2XL | 500 | 50 | 450 |

### Connection Allocation Strategy

```
Total Available = Database Max Connections - Reserved Connections

Allocation:
- Application Pools: 60%
- Admin/Maintenance: 10%
- Monitoring: 5%
- Buffer: 25%

Example for Medium Tier (135 available):
- Application Pools: 81 connections
- Admin/Maintenance: 14 connections
- Monitoring: 7 connections
- Buffer: 33 connections
```

### Configuration Example

```typescript
// Calculate pool size based on compute tier
function calculatePoolSize(tier: string) {
  const limits = {
    free: { max: 50, recommended: 10 },
    small: { max: 80, recommended: 20 },
    medium: { max: 135, recommended: 40 },
    large: { max: 180, recommended: 60 },
    xl: { max: 270, recommended: 100 },
    '2xl': { max: 450, recommended: 150 }
  };

  const config = limits[tier.toLowerCase()] || limits.small;
  
  return {
    min: Math.floor(config.recommended * 0.25),
    max: config.recommended,
    hard_limit: config.max
  };
}
```

## Connection Queue Management

### Queue Configuration

```typescript
{
  queue: {
    enabled: true,
    maxSize: 1000,              // Max queued requests
    timeout: 30000,             // 30 second wait time
    priorityLevels: 3,          // High, medium, low
    fifo: false,                // Priority-based
    rejectOnFull: false         // Queue or reject
  }
}
```

### Priority-Based Queueing

```typescript
// Priority levels
enum QueryPriority {
  HIGH = 1,    // Interactive queries, < 100ms expected
  MEDIUM = 2,  // Standard queries, < 1s expected
  LOW = 3      // Background/analytical queries, > 1s expected
}

// Queue manager
class ConnectionQueueManager {
  private queues: Map<QueryPriority, Array<QueuedRequest>>;
  
  async acquire(priority: QueryPriority = QueryPriority.MEDIUM): Promise<Client> {
    // Try immediate acquisition
    if (pool.availableCount > 0) {
      return await pool.connect();
    }
    
    // Queue with priority
    return new Promise((resolve, reject) => {
      const request = { priority, resolve, reject, timestamp: Date.now() };
      this.enqueue(request);
      
      // Set timeout
      setTimeout(() => {
        this.remove(request);
        reject(new Error('Queue timeout'));
      }, 30000);
    });
  }
  
  private enqueue(request: QueuedRequest) {
    const queue = this.queues.get(request.priority) || [];
    queue.push(request);
    this.queues.set(request.priority, queue);
  }
  
  async processQueue() {
    // Process high priority first
    for (const priority of [QueryPriority.HIGH, QueryPriority.MEDIUM, QueryPriority.LOW]) {
      const queue = this.queues.get(priority);
      if (queue && queue.length > 0 && pool.availableCount > 0) {
        const request = queue.shift()!;
        const client = await pool.connect();
        request.resolve(client);
      }
    }
  }
}
```

### Queue Monitoring

```typescript
// Monitor queue depth
setInterval(() => {
  const stats = {
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount,
    queued: queueManager.size()
  };
  
  // Alert on queue buildup
  if (stats.queued > 100) {
    console.warn('Queue depth exceeds threshold:', stats);
  }
  
  // Alert on pool saturation
  if (stats.idle === 0 && stats.waiting > 10) {
    console.error('Pool saturation detected:', stats);
  }
}, 10000); // Every 10 seconds
```

## Auto-Scaling Guidelines

### Horizontal Scaling (Agent Instances)

**When to Scale Up:**
- Queue depth > 50 for > 2 minutes
- Average response time > 2x baseline
- Connection pool utilization > 80%
- Error rate > 5%

**When to Scale Down:**
- Queue depth = 0 for > 10 minutes
- Average response time < baseline
- Connection pool utilization < 30%
- Error rate < 1%

**Scaling Configuration:**
```yaml
# Kubernetes HPA example
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ai-agent-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-agent
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: database_connection_pool_utilization
      target:
        type: AverageValue
        averageValue: "75"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

### Vertical Scaling (Pool Size)

**Dynamic Pool Sizing:**
```typescript
class DynamicPoolManager {
  private currentMin: number;
  private currentMax: number;
  private readonly absoluteMax: number;
  
  constructor(absoluteMax: number) {
    this.absoluteMax = absoluteMax;
    this.currentMin = Math.floor(absoluteMax * 0.1);
    this.currentMax = Math.floor(absoluteMax * 0.5);
  }
  
  async adjustPoolSize() {
    const metrics = await this.getMetrics();
    
    // Scale up conditions
    if (metrics.utilization > 0.8 && this.currentMax < this.absoluteMax) {
      this.currentMax = Math.min(
        Math.floor(this.currentMax * 1.5),
        this.absoluteMax
      );
      this.currentMin = Math.floor(this.currentMax * 0.2);
      await pool.resize(this.currentMin, this.currentMax);
      console.log(`Scaled up pool: min=${this.currentMin}, max=${this.currentMax}`);
    }
    
    // Scale down conditions
    if (metrics.utilization < 0.3 && metrics.idle > 10) {
      this.currentMax = Math.max(
        Math.floor(this.currentMax * 0.7),
        Math.floor(this.absoluteMax * 0.3)
      );
      this.currentMin = Math.floor(this.currentMax * 0.2);
      await pool.resize(this.currentMin, this.currentMax);
      console.log(`Scaled down pool: min=${this.currentMin}, max=${this.currentMax}`);
    }
  }
  
  private async getMetrics() {
    return {
      total: pool.totalCount,
      idle: pool.idleCount,
      active: pool.totalCount - pool.idleCount,
      utilization: (pool.totalCount - pool.idleCount) / pool.totalCount,
      waiting: pool.waitingCount
    };
  }
}

// Run every minute
setInterval(() => poolManager.adjustPoolSize(), 60000);
```

### Database Compute Tier Scaling

**Upgrade Triggers:**
- Sustained CPU > 80% for > 10 minutes
- Connection pool consistently at max capacity
- Query response times degraded > 3x
- Frequent connection timeouts

**Downgrade Triggers:**
- Average CPU < 40% for > 24 hours
- Connection pool utilization < 30%
- No performance issues for > 7 days

## Pool Monitoring and Alerts

### Key Metrics to Track

```typescript
interface PoolMetrics {
  // Connection metrics
  totalConnections: number;
  idleConnections: number;
  activeConnections: number;
  waitingClients: number;
  
  // Performance metrics
  avgConnectionTime: number;
  avgQueryTime: number;
  slowQueries: number;
  
  // Health metrics
  connectionErrors: number;
  queryErrors: number;
  timeouts: number;
  
  // Resource metrics
  poolUtilization: number;
  queueDepth: number;
}
```

### Monitoring Implementation

```typescript
import * as prometheus from 'prom-client';

// Create metrics
const poolGauge = new prometheus.Gauge({
  name: 'db_pool_connections',
  help: 'Database connection pool connections',
  labelNames: ['state']
});

const queryDuration = new prometheus.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Database query duration',
  buckets: [0.001, 0.01, 0.1, 0.5, 1, 2, 5, 10]
});

const connectionErrors = new prometheus.Counter({
  name: 'db_connection_errors_total',
  help: 'Total database connection errors',
  labelNames: ['type']
});

// Collect metrics
function collectPoolMetrics() {
  poolGauge.labels('total').set(pool.totalCount);
  poolGauge.labels('idle').set(pool.idleCount);
  poolGauge.labels('active').set(pool.totalCount - pool.idleCount);
  poolGauge.labels('waiting').set(pool.waitingCount);
}

setInterval(collectPoolMetrics, 5000);

// Query wrapper with metrics
async function monitoredQuery(sql: string, params: any[]) {
  const start = Date.now();
  try {
    const result = await pool.query(sql, params);
    queryDuration.observe((Date.now() - start) / 1000);
    return result;
  } catch (error) {
    connectionErrors.inc({ type: error.code || 'unknown' });
    throw error;
  }
}
```

### Alert Configuration

```yaml
# Prometheus alerting rules
groups:
- name: database_pool_alerts
  interval: 30s
  rules:
  
  # Pool saturation
  - alert: DatabasePoolSaturated
    expr: db_pool_connections{state="idle"} < 2
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Database pool nearly saturated"
      description: "Idle connections: {{ $value }}"
  
  # High wait times
  - alert: DatabasePoolHighWaitTime
    expr: db_pool_connections{state="waiting"} > 10
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High number of waiting clients"
      description: "Waiting clients: {{ $value }}"
  
  # Connection errors
  - alert: DatabaseConnectionErrors
    expr: rate(db_connection_errors_total[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High database connection error rate"
      description: "Error rate: {{ $value }}/s"
  
  # Slow queries
  - alert: DatabaseSlowQueries
    expr: histogram_quantile(0.95, db_query_duration_seconds) > 5
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "95th percentile query time high"
      description: "P95 query time: {{ $value }}s"
```

### Dashboard Example (Grafana)

```json
{
  "dashboard": {
    "title": "AI Agent Database Pool Monitoring",
    "panels": [
      {
        "title": "Connection Pool Status",
        "targets": [
          {
            "expr": "db_pool_connections{state='total'}",
            "legendFormat": "Total"
          },
          {
            "expr": "db_pool_connections{state='active'}",
            "legendFormat": "Active"
          },
          {
            "expr": "db_pool_connections{state='idle'}",
            "legendFormat": "Idle"
          },
          {
            "expr": "db_pool_connections{state='waiting'}",
            "legendFormat": "Waiting"
          }
        ]
      },
      {
        "title": "Query Performance",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, db_query_duration_seconds)",
            "legendFormat": "P50"
          },
          {
            "expr": "histogram_quantile(0.95, db_query_duration_seconds)",
            "legendFormat": "P95"
          },
          {
            "expr": "histogram_quantile(0.99, db_query_duration_seconds)",
            "legendFormat": "P99"
          }
        ]
      },
      {
        "title": "Pool Utilization",
        "targets": [
          {
            "expr": "db_pool_connections{state='active'} / db_pool_connections{state='total'} * 100",
            "legendFormat": "Utilization %"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(db_connection_errors_total[5m])",
            "legendFormat": "Errors/sec"
          }
        ]
      }
    ]
  }
}
```

### Logging Best Practices

```typescript
// Structured logging
import winston from 'winston';

const logger = winston.createLogger({
  format: winston.format.json(),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'pool.log' })
  ]
});

// Log pool events
pool.on('connect', (client) => {
  logger.info('Pool: connection established', {
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount
  });
});

pool.on('acquire', (client) => {
  logger.debug('Pool: connection acquired', {
    total: pool.totalCount,
    idle: pool.idleCount
  });
});

pool.on('error', (error, client) => {
  logger.error('Pool: connection error', {
    error: error.message,
    stack: error.stack,
    total: pool.totalCount
  });
});

pool.on('remove', (client) => {
  logger.info('Pool: connection removed', {
    total: pool.totalCount,
    reason: 'idle_timeout'
  });
});
```

## Best Practices Summary

### Do's ✅

1. **Match pool size to workload patterns**
   - Start conservative, scale based on metrics
   - Leave 25% buffer capacity

2. **Use appropriate connection mode**
   - Session for persistent agents
   - Transaction for serverless/edge agents

3. **Implement aggressive timeouts for serverless**
   - Connection: 5 seconds
   - Query: 30 seconds
   - Idle: 5 seconds

4. **Monitor pool metrics continuously**
   - Track utilization, wait times, errors
   - Set up alerts for anomalies

5. **Implement connection retry logic**
   - Exponential backoff
   - Circuit breaker pattern

6. **Use prepared statements for repeated queries**
   - Improves performance
   - Reduces parsing overhead

7. **Implement graceful degradation**
   - Queue requests during spikes
   - Return cached data when possible

### Don'ts ❌

1. **Don't use excessive pool sizes**
   - Wastes memory and connections
   - Can overload database

2. **Don't ignore idle timeout settings**
   - Can leak connections
   - Increases costs

3. **Don't use session mode for serverless**
   - Connection lifetime exceeds function execution
   - Poor resource utilization

4. **Don't skip monitoring**
   - Can't optimize without data
   - Miss critical issues

5. **Don't hardcode pool sizes**
   - Different environments need different sizes
   - Use environment-based configuration

6. **Don't forget connection cleanup**
   - Always release connections
   - Use try-finally blocks

7. **Don't run long queries in small pools**
   - Blocks other operations
   - Use dedicated pools or queues

## Troubleshooting Guide

### Issue: Connection Pool Exhausted

**Symptoms:**
- "Too many clients already" errors
- High wait times for connections
- Timeouts acquiring connections

**Solutions:**
```typescript
// 1. Increase pool size
pool.max = Math.min(pool.max * 1.5, databaseMaxConnections);

// 2. Reduce idle timeout
pool.idleTimeoutMillis = 30000; // 30 seconds

// 3. Implement connection queueing
const queuedRequest = await queueManager.acquire();

// 4. Check for connection leaks
pool.on('acquire', () => {
  if (pool.totalCount > pool.max * 0.9) {
    console.warn('Pool near capacity, check for leaks');
  }
});
```

### Issue: Slow Query Performance

**Symptoms:**
- High P95/P99 query times
- Timeouts on complex queries
- Database CPU spikes

**Solutions:**
```typescript
// 1. Set appropriate query timeouts
await client.query('SET statement_timeout = 30000');

// 2. Use query result caching
const cached = await cache.get(queryKey);
if (cached) return cached;

// 3. Implement query prioritization
const result = await pool.query(sql, params, { priority: 'high' });

// 4. Break up large queries
const results = await Promise.all([
  pool.query(query1),
  pool.query(query2),
  pool.query(query3)
]);
```

### Issue: Memory Leaks

**Symptoms:**
- Gradual memory increase
- Out of memory errors
- Slow connection establishment

**Solutions:**
```typescript
// 1. Enforce connection max lifetime
pool.maxUses = 7500; // Recycle after 7500 queries

// 2. Monitor connection age
setInterval(() => {
  const oldConnections = pool.getConnections()
    .filter(c => Date.now() - c.createdAt > 3600000);
  if (oldConnections.length > 0) {
    console.warn('Old connections detected:', oldConnections.length);
  }
}, 60000);

// 3. Force connection recycling
setInterval(async () => {
  await pool.drain();
  await pool.clear();
}, 3600000); // Every hour
```

## Related Documentation

- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Server Configuration Templates](./MCP_SERVER_CONFIGURATION.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [MCP Authentication Strategies](./MCP_AUTHENTICATION.md)

## References

- [PostgreSQL Connection Pooling](https://www.postgresql.org/docs/current/runtime-config-connection.html)
- [Supabase Connection Pooling Guide](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)
- [PgBouncer Documentation](https://www.pgbouncer.org/usage.html)
- [Node.js pg-pool Documentation](https://node-postgres.com/apis/pool)

---

**Last Updated**: 2025-01-09  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
