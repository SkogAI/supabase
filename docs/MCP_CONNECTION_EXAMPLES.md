# MCP Server Connection Examples

## Overview

This document provides practical, ready-to-use connection examples for AI agents connecting to Supabase databases through MCP servers. Each example includes complete code, configuration, and explanations.

## Table of Contents

- [Node.js Examples](#nodejs-examples)
- [Python Examples](#python-examples)
- [Deno Examples](#deno-examples)
- [Edge Function Examples](#edge-function-examples)
- [Language-Specific Libraries](#language-specific-libraries)

## Node.js Examples

### Example 1: Direct Connection (Persistent Agent)

```typescript
// persistent-agent.ts
import pg from 'pg';
const { Pool } = pg;

// Configuration
const config = {
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true
  },
  max: 20,
  idleTimeoutMillis: 300000, // 5 minutes
  connectionTimeoutMillis: 10000
};

// Create connection pool
const pool = new Pool(config);

// Query execution with error handling
async function executeQuery(sql: string, params: any[] = []) {
  const client = await pool.connect();
  try {
    const result = await client.query(sql, params);
    return result.rows;
  } catch (error) {
    console.error('Query error:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Example: Query with connection
async function getUsers() {
  const users = await executeQuery(
    'SELECT id, email, created_at FROM users WHERE active = $1',
    [true]
  );
  return users;
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  await pool.end();
  process.exit(0);
});

// Usage
(async () => {
  try {
    const users = await getUsers();
    console.log('Active users:', users);
  } catch (error) {
    console.error('Failed to fetch users:', error);
  }
})();
```

### Example 2: Supavisor Transaction Mode (Serverless Agent)

```typescript
// serverless-agent.ts
import { createClient } from '@supabase/supabase-js';

// Serverless-optimized configuration
const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(supabaseUrl, supabaseKey, {
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
});

// Lambda handler
export async function handler(event: any) {
  try {
    // Query with automatic connection management
    const { data, error } = await supabase
      .from('documents')
      .select('id, title, content')
      .eq('published', true)
      .limit(10);

    if (error) throw error;

    return {
      statusCode: 200,
      body: JSON.stringify({ documents: data })
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
}
```

### Example 3: Dedicated Pooler (High-Performance Agent - Paid Tier)

```typescript
// dedicated-pooler-agent.ts
import pg from 'pg';
const { Pool } = pg;

// Dedicated pooler configuration for high-performance AI agents
const pool = new Pool({
  connectionString: process.env.SUPABASE_DEDICATED_POOLER,
  ssl: {
    rejectUnauthorized: true
  },
  // CRITICAL: Disable prepared statements for transaction mode
  statement_cache_size: 0,
  // Pool sizing for high-performance workloads
  max: 50,
  min: 10,
  idleTimeoutMillis: 600000, // 10 minutes
  connectionTimeoutMillis: 10000,
  allowExitOnIdle: false
});

// Query execution with latency tracking
async function executeQueryWithMetrics(sql: string, params: any[] = []) {
  const startTime = Date.now();
  const client = await pool.connect();
  const acquireTime = Date.now() - startTime;
  
  try {
    const queryStart = Date.now();
    const result = await client.query(sql, params);
    const queryTime = Date.now() - queryStart;
    const totalTime = Date.now() - startTime;
    
    // Log performance metrics
    console.log({
      acquireMs: acquireTime,
      queryMs: queryTime,
      totalMs: totalTime,
      rows: result.rowCount
    });
    
    return result.rows;
  } catch (error) {
    console.error('Query failed:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Example: AI agent processing request
async function processAIRequest(userId: string, prompt: string) {
  // Get user context
  const userContext = await executeQueryWithMetrics(
    'SELECT * FROM profiles WHERE id = $1',
    [userId]
  );
  
  // Get relevant history
  const history = await executeQueryWithMetrics(
    'SELECT * FROM ai_interactions WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10',
    [userId]
  );
  
  // Store new interaction
  const interaction = await executeQueryWithMetrics(
    'INSERT INTO ai_interactions (user_id, prompt, response) VALUES ($1, $2, $3) RETURNING *',
    [userId, prompt, 'AI response here']
  );
  
  return { userContext, history, interaction };
}

// Health check with pool monitoring
async function healthCheck() {
  return {
    status: 'healthy',
    pool: {
      total: pool.totalCount,
      idle: pool.idleCount,
      waiting: pool.waitingCount,
      utilization: ((pool.totalCount - pool.idleCount) / pool.totalCount * 100).toFixed(2) + '%'
    },
    timestamp: new Date().toISOString()
  };
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await pool.end();
  process.exit(0);
});

// Example usage
(async () => {
  try {
    console.log('Health:', await healthCheck());
    const result = await processAIRequest('user-123', 'Hello AI!');
    console.log('Result:', result);
  } catch (error) {
    console.error('Error:', error);
  }
})();
```

**Key Points:**
- Uses dedicated pooler connection string (port 6543)
- Prepared statements disabled via `statement_cache_size: 0`
- Higher pool size (50 max) for production workloads
- Performance metrics tracking (connection + query time)
- Pool health monitoring
- Requires Pro/Enterprise plan with dedicated pooler enabled
- See [MCP_DEDICATED_POOLER.md](./MCP_DEDICATED_POOLER.md) for complete guide

### Example 4: Connection Pooling with PgBouncer

```typescript
// rls-agent.ts
import { createClient } from '@supabase/supabase-js';
import jwt from 'jsonwebtoken';

// Generate JWT for user context
function generateUserJWT(userId: string) {
  const payload = {
    sub: userId,
    role: 'authenticated',
    iss: 'supabase',
    aud: 'authenticated',
    exp: Math.floor(Date.now() / 1000) + (60 * 60) // 1 hour
  };
  
  return jwt.sign(payload, process.env.JWT_SECRET!);
}

// Create Supabase client with user context
async function createUserContextClient(userId: string) {
  const token = generateUserJWT(userId);
  
  return createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
    {
      global: {
        headers: {
          Authorization: `Bearer ${token}`
        }
      }
    }
  );
}

// Query with RLS enforcement
async function getUserDocuments(userId: string) {
  const supabase = await createUserContextClient(userId);
  
  // RLS policies automatically filter results
  const { data, error } = await supabase
    .from('documents')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) throw error;
  return data;
}

// Usage
(async () => {
  const userId = 'user-123';
  const documents = await getUserDocuments(userId);
  console.log('User documents:', documents);
})();
```

### Example 5: Connection Pooling with PgBouncer

```typescript
// pooled-agent.ts
import { Pool } from 'pg';

// PgBouncer-compatible configuration
const pool = new Pool({
  host: process.env.POOLER_HOST,
  port: parseInt(process.env.POOLER_PORT || '6543'),
  database: 'postgres',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: true
  },
  // PgBouncer optimized settings
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  // Disable prepared statements for PgBouncer
  statement_timeout: 30000
});

// Query function
async function query(sql: string, params: any[] = []) {
  const start = Date.now();
  const client = await pool.connect();
  
  try {
    const result = await client.query(sql, params);
    const duration = Date.now() - start;
    console.log('Query executed in', duration, 'ms');
    return result.rows;
  } finally {
    client.release();
  }
}

// Batch operations
async function batchInsert(records: any[]) {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    for (const record of records) {
      await client.query(
        'INSERT INTO logs (message, level, created_at) VALUES ($1, $2, NOW())',
        [record.message, record.level]
      );
    }
    
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
```

### Example 6: Retry Logic with Exponential Backoff

```typescript
// resilient-agent.ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// Retry configuration
const RETRY_CONFIG = {
  maxRetries: 3,
  initialDelayMs: 1000,
  maxDelayMs: 10000,
  backoffMultiplier: 2
};

// Sleep utility
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Retry wrapper
async function withRetry<T>(
  operation: () => Promise<T>,
  config = RETRY_CONFIG
): Promise<T> {
  let lastError: Error;
  let delay = config.initialDelayMs;
  
  for (let attempt = 0; attempt < config.maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error: any) {
      lastError = error;
      
      // Don't retry on certain errors
      if (error.code === '23505') { // Unique constraint violation
        throw error;
      }
      
      if (attempt < config.maxRetries - 1) {
        console.log(`Attempt ${attempt + 1} failed, retrying in ${delay}ms...`);
        await sleep(delay);
        delay = Math.min(delay * config.backoffMultiplier, config.maxDelayMs);
      }
    }
  }
  
  throw lastError!;
}

// Usage example
async function fetchDataWithRetry() {
  return withRetry(async () => {
    const { data, error } = await supabase
      .from('important_data')
      .select('*')
      .limit(100);
    
    if (error) throw error;
    return data;
  });
}
```

## Python Examples

### Example 1: PostgreSQL Connection (asyncpg)

```python
# persistent_agent.py
import asyncio
import asyncpg
import os
from typing import List, Dict

# Configuration
DATABASE_URL = os.getenv('DATABASE_URL')
POOL_MIN_SIZE = 5
POOL_MAX_SIZE = 20

# Global connection pool
pool: asyncpg.Pool = None

async def init_pool():
    """Initialize database connection pool"""
    global pool
    pool = await asyncpg.create_pool(
        DATABASE_URL,
        min_size=POOL_MIN_SIZE,
        max_size=POOL_MAX_SIZE,
        command_timeout=30,
        server_settings={
            'application_name': 'python-ai-agent'
        }
    )

async def close_pool():
    """Close database connection pool"""
    global pool
    if pool:
        await pool.close()

async def execute_query(sql: str, *args) -> List[Dict]:
    """Execute a query and return results"""
    async with pool.acquire() as connection:
        rows = await connection.fetch(sql, *args)
        return [dict(row) for row in rows]

async def get_active_users() -> List[Dict]:
    """Fetch active users"""
    return await execute_query(
        "SELECT id, email, created_at FROM users WHERE active = $1",
        True
    )

# Main execution
async def main():
    await init_pool()
    
    try:
        users = await get_active_users()
        print(f"Found {len(users)} active users")
    finally:
        await close_pool()

if __name__ == '__main__':
    asyncio.run(main())
```

### Example 2: Supabase Python Client

```python
# supabase_agent.py
import os
from supabase import create_client, Client
from typing import List, Dict, Optional

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

def get_documents(
    limit: int = 10,
    published_only: bool = True
) -> List[Dict]:
    """Fetch documents from Supabase"""
    query = supabase.table('documents').select('*')
    
    if published_only:
        query = query.eq('published', True)
    
    response = query.limit(limit).execute()
    return response.data

def insert_document(title: str, content: str, user_id: str) -> Dict:
    """Insert a new document"""
    data = {
        'title': title,
        'content': content,
        'user_id': user_id,
        'published': False
    }
    
    response = supabase.table('documents').insert(data).execute()
    return response.data[0]

def update_document(doc_id: str, updates: Dict) -> Dict:
    """Update a document"""
    response = (
        supabase.table('documents')
        .update(updates)
        .eq('id', doc_id)
        .execute()
    )
    return response.data[0]

# Usage example
if __name__ == '__main__':
    # Fetch documents
    docs = get_documents(limit=5)
    print(f"Documents: {docs}")
    
    # Insert new document
    new_doc = insert_document(
        title='AI Generated Content',
        content='This was created by an AI agent',
        user_id='user-123'
    )
    print(f"Created document: {new_doc}")
```

### Example 3: Connection with Context Manager

```python
# context_manager_agent.py
import asyncpg
import os
from contextlib import asynccontextmanager
from typing import AsyncIterator

@asynccontextmanager
async def get_db_connection() -> AsyncIterator[asyncpg.Connection]:
    """Context manager for database connections"""
    conn = await asyncpg.connect(os.getenv('DATABASE_URL'))
    try:
        yield conn
    finally:
        await conn.close()

async def query_with_context():
    """Example using context manager"""
    async with get_db_connection() as conn:
        # Execute query
        rows = await conn.fetch(
            "SELECT * FROM users WHERE active = $1",
            True
        )
        
        # Process results
        for row in rows:
            print(f"User: {row['email']}")

# Transaction example
async def transaction_example():
    """Execute multiple queries in a transaction"""
    async with get_db_connection() as conn:
        async with conn.transaction():
            # Insert user
            await conn.execute(
                "INSERT INTO users (email) VALUES ($1)",
                'newuser@example.com'
            )
            
            # Insert profile
            await conn.execute(
                "INSERT INTO profiles (user_id, name) VALUES (currval('users_id_seq'), $1)",
                'New User'
            )
```

## Deno Examples

### Example 1: Deno with PostgreSQL

```typescript
// deno_agent.ts
import { Client } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

// Configuration
const client = new Client({
  hostname: Deno.env.get("DB_HOST"),
  port: 5432,
  user: Deno.env.get("DB_USER"),
  password: Deno.env.get("DB_PASSWORD"),
  database: "postgres",
  tls: {
    enabled: true,
    enforce: true,
  },
});

// Connect to database
await client.connect();

// Execute query
const result = await client.queryObject<{ id: string; email: string }>(
  "SELECT id, email FROM users WHERE active = $1",
  [true]
);

console.log("Users:", result.rows);

// Close connection
await client.end();
```

### Example 2: Supabase Edge Function

```typescript
// supabase/functions/ai-agent/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Create Supabase client
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Parse request
    const { query, table } = await req.json();

    // Execute query
    const { data, error } = await supabase
      .from(table)
      .select(query)
      .limit(10);

    if (error) throw error;

    return new Response(
      JSON.stringify({ data }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
```

### Example 3: Connection Pooling in Deno

```typescript
// deno_pooled_agent.ts
import { Pool } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

// Create connection pool
const pool = new Pool({
  hostname: Deno.env.get("DB_HOST"),
  port: 5432,
  user: Deno.env.get("DB_USER"),
  password: Deno.env.get("DB_PASSWORD"),
  database: "postgres",
  tls: {
    enabled: true,
  },
}, 10); // Pool size of 10

// Query using pool
async function queryUsers() {
  const connection = await pool.connect();
  
  try {
    const result = await connection.queryObject(
      "SELECT * FROM users LIMIT 10"
    );
    return result.rows;
  } finally {
    connection.release();
  }
}

// Usage
const users = await queryUsers();
console.log("Users:", users);

// Cleanup
await pool.end();
```

## Edge Function Examples

### Example 1: Cloudflare Workers

```typescript
// cloudflare-worker.ts
import { createClient } from '@supabase/supabase-js';

export default {
  async fetch(request: Request, env: any): Promise<Response> {
    const supabase = createClient(
      env.SUPABASE_URL,
      env.SUPABASE_SERVICE_ROLE_KEY
    );

    try {
      const { data, error } = await supabase
        .from('documents')
        .select('id, title')
        .limit(10);

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
  }
};
```

### Example 2: Vercel Edge Functions

```typescript
// api/edge-agent.ts
import { createClient } from '@supabase/supabase-js';

export const config = {
  runtime: 'edge',
};

export default async function handler(req: Request) {
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );

  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('published', true)
    .limit(20);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' }
  });
}
```

## Language-Specific Libraries

### PostgreSQL Client Libraries

| Language | Library | Repository |
|----------|---------|------------|
| Node.js | `pg` | https://github.com/brianc/node-postgres |
| Node.js | `@supabase/supabase-js` | https://github.com/supabase/supabase-js |
| Python | `asyncpg` | https://github.com/MagicStack/asyncpg |
| Python | `supabase-py` | https://github.com/supabase/supabase-py |
| Deno | `postgres` | https://deno.land/x/postgres |
| Go | `pgx` | https://github.com/jackc/pgx |
| Rust | `tokio-postgres` | https://github.com/sfackler/rust-postgres |
| Java | `JDBC PostgreSQL` | https://jdbc.postgresql.org/ |
| Ruby | `pg` | https://github.com/ged/ruby-pg |
| PHP | `PDO_PGSQL` | https://www.php.net/manual/en/ref.pdo-pgsql.php |

## Complete Application Examples

### Example: AI Chat Assistant with Database

```typescript
// ai-chat-assistant.ts
import { createClient } from '@supabase/supabase-js';
import OpenAI from 'openai';

// Initialize clients
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Store conversation in database
async function storeMessage(
  conversationId: string,
  role: 'user' | 'assistant',
  content: string
) {
  const { data, error } = await supabase
    .from('messages')
    .insert({
      conversation_id: conversationId,
      role,
      content,
      created_at: new Date().toISOString()
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Retrieve conversation history
async function getConversationHistory(conversationId: string) {
  const { data, error } = await supabase
    .from('messages')
    .select('role, content')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })
    .limit(20);

  if (error) throw error;
  return data;
}

// Main chat function
async function chat(conversationId: string, userMessage: string) {
  // Store user message
  await storeMessage(conversationId, 'user', userMessage);

  // Get conversation history
  const history = await getConversationHistory(conversationId);

  // Get AI response
  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: history.map(msg => ({
      role: msg.role as 'user' | 'assistant',
      content: msg.content
    }))
  });

  const assistantMessage = completion.choices[0].message.content;

  // Store assistant response
  await storeMessage(conversationId, 'assistant', assistantMessage!);

  return assistantMessage;
}

// Usage
(async () => {
  const conversationId = 'conv-123';
  const response = await chat(conversationId, 'What is the weather today?');
  console.log('Assistant:', response);
})();
```

## Performance Optimization Tips

### 1. Connection Reuse

```typescript
// ❌ BAD: Creating new connection for each request
async function badExample() {
  const client = new Client(/* config */);
  await client.connect();
  await client.query(/* ... */);
  await client.end();
}

// ✅ GOOD: Reusing connection pool
const pool = new Pool(/* config */);
async function goodExample() {
  const client = await pool.connect();
  try {
    await client.query(/* ... */);
  } finally {
    client.release();
  }
}
```

### 2. Batch Operations

```typescript
// ❌ BAD: Multiple individual inserts
for (const record of records) {
  await supabase.from('logs').insert(record);
}

// ✅ GOOD: Single batch insert
await supabase.from('logs').insert(records);
```

### 3. Query Optimization

```typescript
// ❌ BAD: Fetching all columns
const { data } = await supabase.from('users').select('*');

// ✅ GOOD: Select only needed columns
const { data } = await supabase
  .from('users')
  .select('id, email, name');
```

## Related Documentation

- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Server Configuration](./MCP_SERVER_CONFIGURATION.md)
- [MCP Authentication Strategies](./MCP_AUTHENTICATION.md)
- [SSL/TLS Security Guide](./MCP_SSL_TLS_SECURITY.md) - **Critical for Production**

---

**Last Updated**: 2025-10-05  
**Version**: 1.0.0  
**Status**: ✅ Initial Release
