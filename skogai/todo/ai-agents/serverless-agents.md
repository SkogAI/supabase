# Serverless AI Agents Guide

## Overview

Serverless AI agents run in ephemeral compute environments like AWS Lambda, Google Cloud Functions, and Azure Functions. This guide covers optimized configuration, connection management, and best practices for serverless deployments.

## Characteristics

**Serverless Agents:**
- ⚡ Short-lived execution (seconds to minutes)
- 📦 Cold starts and warm starts
- 🔄 Auto-scaling based on demand
- 💰 Pay-per-execution pricing
- 🚫 No persistent connections

**Common Platforms:**
- AWS Lambda
- Google Cloud Functions
- Azure Functions
- AWS Fargate (when configured for serverless)
- Google Cloud Run

## Recommended Connection Method

### Use Transaction Mode (Port 6543)

**Why Transaction Mode:**
- ✅ Efficient connection pooling
- ✅ Automatic connection cleanup
- ✅ Optimized for short-lived functions
- ✅ Handles cold starts gracefully
- ✅ Supports auto-scaling

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?prepareStatement=false
```

**⚠️ Critical: Disable Prepared Statements**

Transaction mode REQUIRES prepared statements to be disabled:
```bash
# In connection string
?prepareStatement=false

# Or via environment
DISABLE_PREPARED_STATEMENTS=true
```

## Setup Guide

### AWS Lambda

#### Step 1: Create Lambda Function

**Using AWS Console:**
1. Go to AWS Lambda → Create function
2. Choose runtime (Node.js 20.x, Python 3.12, etc.)
3. Set timeout to 30-60 seconds (default 3s is too short)
4. Increase memory to 512MB+ for better performance

**Using Serverless Framework:**
```yaml
# serverless.yml
service: supabase-ai-agent

provider:
  name: aws
  runtime: nodejs20.x
  memorySize: 512
  timeout: 30
  region: us-east-1
  environment:
    DATABASE_URL: ${env:DATABASE_URL}
    DISABLE_PREPARED_STATEMENTS: 'true'

functions:
  aiAgent:
    handler: handler.main
    events:
      - http:
          path: /agent
          method: post
```

#### Step 2: Configure Environment Variables

**In AWS Console:**
1. Lambda → Configuration → Environment variables
2. Add:
   ```
   DATABASE_URL=postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?prepareStatement=false
   DISABLE_PREPARED_STATEMENTS=true
   PGSSLMODE=require
   ```

**Or use AWS Secrets Manager:**
```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

async function getDatabaseUrl() {
  const secret = await secretsManager.getSecretValue({
    SecretId: 'supabase/database-url'
  }).promise();
  
  return JSON.parse(secret.SecretString).DATABASE_URL;
}
```

#### Step 3: Lambda Handler Code

**Node.js:**
```javascript
const { Pool } = require('pg');

// Create pool OUTSIDE handler for connection reuse
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true },
  // Serverless-optimized settings
  min: 0,  // No minimum connections
  max: 1,  // One connection per Lambda instance
  idleTimeoutMillis: 5000,
  connectionTimeoutMillis: 5000,
  allowExitOnIdle: true,  // Important for Lambda
  // Disable prepared statements
  options: '-c plan_cache_mode=force_custom_plan'
});

exports.handler = async (event) => {
  const client = await pool.connect();
  
  try {
    // Your database logic here
    const result = await client.query(
      'SELECT * FROM users WHERE email = $1',
      [event.email]
    );
    
    return {
      statusCode: 200,
      body: JSON.stringify(result.rows)
    };
  } catch (error) {
    console.error('Database error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  } finally {
    client.release();
  }
};
```

**Python:**
```python
import os
import json
import psycopg2
from psycopg2 import pool

# Create pool outside handler
connection_pool = None

def get_pool():
    global connection_pool
    if connection_pool is None:
        connection_pool = psycopg2.pool.SimpleConnectionPool(
            minconn=1,
            maxconn=1,
            dsn=os.environ['DATABASE_URL'],
            sslmode='require',
            options='-c plan_cache_mode=force_custom_plan'
        )
    return connection_pool

def lambda_handler(event, context):
    pool = get_pool()
    conn = pool.getconn()
    
    try:
        cursor = conn.cursor()
        cursor.execute(
            'SELECT * FROM users WHERE email = %s',
            (event['email'],)
        )
        results = cursor.fetchall()
        cursor.close()
        
        return {
            'statusCode': 200,
            'body': json.dumps({'users': results})
        }
    except Exception as e:
        print(f'Database error: {e}')
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        pool.putconn(conn)
```

#### Step 4: Deploy

**Using Serverless Framework:**
```bash
# Install dependencies
npm install

# Deploy
serverless deploy

# Test
serverless invoke -f aiAgent --data '{"email": "test@example.com"}'
```

**Using AWS SAM:**
```bash
sam build
sam deploy --guided
```

### Google Cloud Functions

#### Step 1: Create Function

**Using gcloud CLI:**
```bash
gcloud functions deploy supabase-ai-agent \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point main \
  --memory 512MB \
  --timeout 60s \
  --set-env-vars DATABASE_URL="postgresql://..." \
  --set-env-vars DISABLE_PREPARED_STATEMENTS=true
```

#### Step 2: Function Code

**Node.js (index.js):**
```javascript
const { Pool } = require('pg');

// Create pool outside function for reuse
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true },
  min: 0,
  max: 1,
  idleTimeoutMillis: 5000,
  options: '-c plan_cache_mode=force_custom_plan'
});

exports.main = async (req, res) => {
  const client = await pool.connect();
  
  try {
    const result = await client.query(
      'SELECT NOW()'
    );
    
    res.json({
      success: true,
      timestamp: result.rows[0]
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
};
```

**package.json:**
```json
{
  "name": "supabase-ai-agent",
  "version": "1.0.0",
  "dependencies": {
    "pg": "^8.11.0"
  }
}
```

#### Step 3: Deploy

```bash
# Deploy function
gcloud functions deploy supabase-ai-agent \
  --runtime nodejs20 \
  --trigger-http \
  --entry-point main \
  --source .

# Test function
gcloud functions call supabase-ai-agent \
  --data '{"email":"test@example.com"}'
```

### Azure Functions

#### Step 1: Create Function App

**Using Azure CLI:**
```bash
# Create resource group
az group create --name supabase-functions --location eastus

# Create storage account
az storage account create \
  --name supabasefunctionsstorage \
  --resource-group supabase-functions \
  --sku Standard_LRS

# Create function app
az functionapp create \
  --name supabase-ai-agent \
  --resource-group supabase-functions \
  --consumption-plan-location eastus \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4 \
  --storage-account supabasefunctionsstorage
```

#### Step 2: Configure App Settings

```bash
# Set environment variables
az functionapp config appsettings set \
  --name supabase-ai-agent \
  --resource-group supabase-functions \
  --settings \
    DATABASE_URL="postgresql://..." \
    DISABLE_PREPARED_STATEMENTS=true \
    PGSSLMODE=require
```

#### Step 3: Function Code

**index.js:**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true },
  min: 0,
  max: 1,
  idleTimeoutMillis: 5000,
  options: '-c plan_cache_mode=force_custom_plan'
});

module.exports = async function (context, req) {
  const client = await pool.connect();
  
  try {
    const result = await client.query('SELECT NOW()');
    
    context.res = {
      status: 200,
      body: {
        success: true,
        timestamp: result.rows[0]
      }
    };
  } catch (error) {
    context.log.error('Database error:', error);
    context.res = {
      status: 500,
      body: { error: error.message }
    };
  } finally {
    client.release();
  }
};
```

**function.json:**
```json
{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
```

#### Step 4: Deploy

```bash
# Initialize project
func init --worker-runtime node

# Create function
func new --template "HTTP trigger" --name supabase-ai-agent

# Deploy
func azure functionapp publish supabase-ai-agent
```

## Connection Pool Configuration

### Optimal Settings for Serverless

```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true },
  
  // Serverless-specific settings
  min: 0,                          // No minimum (save resources)
  max: 1,                          // One connection per instance
  idleTimeoutMillis: 5000,         // Quick cleanup (5 seconds)
  connectionTimeoutMillis: 5000,   // Quick timeout
  allowExitOnIdle: true,           // Exit when idle (Lambda)
  
  // CRITICAL: Disable prepared statements
  options: '-c plan_cache_mode=force_custom_plan',
  
  // Identification
  application_name: 'serverless-ai-agent'
});
```

### Why These Settings?

| Setting | Value | Reason |
|---------|-------|--------|
| `min: 0` | No minimum | Saves resources when idle |
| `max: 1` | One connection | One function instance = one connection |
| `idleTimeoutMillis: 5000` | 5 seconds | Quick cleanup after execution |
| `allowExitOnIdle: true` | Enabled | Allows Lambda to freeze properly |
| `options: -c plan_cache_mode=force_custom_plan` | Force custom | Disables prepared statements |

## Best Practices

### 1. Create Pool Outside Handler

```javascript
// ✅ Good - Pool created once per container
const pool = new Pool({ /* config */ });

exports.handler = async (event) => {
  // Handler code
};

// ❌ Bad - New pool per invocation
exports.handler = async (event) => {
  const pool = new Pool({ /* config */ });  // DON'T DO THIS
  // ...
};
```

### 2. Always Release Connections

```javascript
// ✅ Good - Always release
exports.handler = async (event) => {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT ...');
    return result.rows;
  } finally {
    client.release();  // Always release
  }
};

// ❌ Bad - Forgets to release on error
exports.handler = async (event) => {
  const client = await pool.connect();
  const result = await client.query('SELECT ...');
  client.release();
  return result.rows;  // Leaks if query throws
};
```

### 3. Handle Cold Starts

```javascript
// Pre-warm connection
let connectionReady = null;

exports.handler = async (event) => {
  // Establish connection on first invocation
  if (!connectionReady) {
    connectionReady = pool.connect().then(client => {
      client.release();
      return true;
    }).catch(err => {
      console.error('Pre-warm failed:', err);
      connectionReady = null;
      return false;
    });
  }
  
  await connectionReady;
  
  // Now execute actual query
  const result = await pool.query('SELECT ...');
  return result.rows;
};
```

### 4. Use Timeouts

```javascript
async function queryWithTimeout(query, params, timeoutMs = 5000) {
  return Promise.race([
    pool.query(query, params),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Query timeout')), timeoutMs)
    )
  ]);
}

exports.handler = async (event) => {
  try {
    const result = await queryWithTimeout(
      'SELECT * FROM users WHERE id = $1',
      [event.userId],
      5000  // 5 second timeout
    );
    return { statusCode: 200, body: JSON.stringify(result.rows) };
  } catch (error) {
    console.error('Query failed:', error);
    return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
  }
};
```

### 5. Implement Retry Logic

```javascript
async function queryWithRetry(query, params, maxRetries = 2) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await pool.query(query, params);
    } catch (error) {
      if (attempt === maxRetries) throw error;
      
      // Only retry transient errors
      if (error.code === 'ECONNRESET' || 
          error.code === 'ETIMEDOUT') {
        console.warn(`Attempt ${attempt} failed, retrying...`);
        await new Promise(resolve => setTimeout(resolve, 100 * attempt));
      } else {
        throw error;  // Don't retry permanent errors
      }
    }
  }
}
```

## Performance Optimization

### 1. Keep Lambda Warm

**EventBridge Rule:**
```yaml
# serverless.yml
functions:
  aiAgent:
    handler: handler.main
    events:
      - schedule: rate(5 minutes)  # Ping every 5 minutes
```

**Or use Lambda Provisioned Concurrency:**
```yaml
functions:
  aiAgent:
    handler: handler.main
    provisionedConcurrency: 2  # Keep 2 instances warm
```

### 2. Use Connection Caching

```javascript
// Cache connection status
let isConnected = false;

exports.handler = async (event) => {
  if (!isConnected) {
    // First invocation or reconnection needed
    await pool.query('SELECT 1');
    isConnected = true;
  }
  
  // Use cached connection
  const result = await pool.query('SELECT ...');
  return result.rows;
};
```

### 3. Batch Operations

```javascript
// ✅ Good - Single query for multiple records
async function getUsers(userIds) {
  const result = await pool.query(
    'SELECT * FROM users WHERE id = ANY($1)',
    [userIds]
  );
  return result.rows;
}

// ❌ Bad - Multiple queries
async function getUsers(userIds) {
  const users = [];
  for (const id of userIds) {
    const result = await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    users.push(result.rows[0]);
  }
  return users;
}
```

### 4. Use Indexes

```sql
-- Create indexes for frequently queried columns
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY idx_posts_user_id ON posts(user_id);
```

## Monitoring Serverless Functions

### AWS Lambda Monitoring

```javascript
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

// Custom metrics
async function recordMetric(metricName, value) {
  await cloudwatch.putMetricData({
    Namespace: 'Supabase/AI-Agent',
    MetricData: [{
      MetricName: metricName,
      Value: value,
      Unit: 'Count',
      Timestamp: new Date()
    }]
  }).promise();
}

exports.handler = async (event) => {
  const start = Date.now();
  
  try {
    const result = await pool.query('SELECT ...');
    
    // Record success metric
    await recordMetric('QuerySuccess', 1);
    await recordMetric('QueryDuration', Date.now() - start);
    
    return { statusCode: 200, body: JSON.stringify(result.rows) };
  } catch (error) {
    // Record error metric
    await recordMetric('QueryError', 1);
    throw error;
  }
};
```

### Structured Logging

```javascript
function log(level, message, data = {}) {
  console.log(JSON.stringify({
    level,
    message,
    timestamp: new Date().toISOString(),
    requestId: context.awsRequestId,
    ...data
  }));
}

exports.handler = async (event, context) => {
  log('info', 'Function invoked', { event });
  
  try {
    const result = await pool.query('SELECT ...');
    log('info', 'Query successful', { rowCount: result.rowCount });
    return result.rows;
  } catch (error) {
    log('error', 'Query failed', { error: error.message });
    throw error;
  }
};
```

## Troubleshooting

### Issue: "Prepared statement does not exist"

**Solution:**
```javascript
// Add to connection string
?prepareStatement=false

// Or in pool config
options: '-c plan_cache_mode=force_custom_plan'
```

### Issue: Function timeout

**Solutions:**
1. Increase Lambda timeout (30-60 seconds)
2. Optimize queries (add indexes)
3. Reduce connection timeout
4. Use connection caching

### Issue: "Too many connections"

**Solutions:**
1. Verify using Transaction Mode (port 6543)
2. Set `max: 1` in pool config
3. Always release connections
4. Check for connection leaks

See [Troubleshooting Guide](../mcp-setup/troubleshooting.md) for more details.

## Cost Optimization

### 1. Use Transaction Mode
- More efficient than Direct Connection
- Shares database connections across functions
- Reduces database connection costs

### 2. Keep Functions Warm
- Pre-warmed functions have faster response times
- Reduces cold start overhead
- Balance between cost and performance

### 3. Optimize Memory Allocation
- Start with 512MB
- Monitor and adjust based on usage
- More memory = faster execution = lower cost

### 4. Batch Processing
- Process multiple items per invocation
- Reduces total invocations
- Lower overall cost

## Next Steps

- **Quick Start**: [MCP Quick Start](../mcp-setup/quickstart.md)
- **Configuration**: [Configuration Templates](../mcp-setup/configuration-templates.md)
- **Troubleshooting**: [Common Issues](../mcp-setup/troubleshooting.md)
- **Monitoring**: [Setup Monitoring](../mcp-setup/monitoring.md)

## Related Guides

- [Persistent AI Agents](./persistent-agents.md)
- [Edge AI Agents](./edge-agents.md)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0
