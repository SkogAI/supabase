# Edge AI Agents Guide

## Overview

Edge AI agents run on edge computing platforms closer to users, providing ultra-low latency responses. This guide covers setup, configuration, and best practices for edge deployments like Cloudflare Workers, Deno Deploy, and Vercel Edge Functions.

## Characteristics

**Edge Agents:**
- ⚡ Extremely low latency (<50ms)
- 🌍 Globally distributed
- 📦 Small bundle size requirements
- ⏱️ Very short execution time (<10s typically)
- 🔄 High concurrency capabilities

**Common Platforms:**
- Cloudflare Workers
- Deno Deploy
- Vercel Edge Functions
- Fastly Compute@Edge
- AWS CloudFront Functions

## Recommended Connection Method

### Use Transaction Mode (Port 6543)

**Why Transaction Mode:**
- ✅ Optimized for short-lived connections
- ✅ Automatic connection cleanup
- ✅ Minimal cold start impact
- ✅ Efficient connection sharing
- ✅ Works in restricted edge environments

**Connection String:**
```
postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?prepareStatement=false
```

**⚠️ Critical Requirements:**
- Disable prepared statements
- Use SSL/TLS (required)
- Choose pooler region close to edge locations
- Keep queries simple and fast

## Setup Guide

### Cloudflare Workers

#### Step 1: Create Worker Project

```bash
# Create new project
npm create cloudflare@latest supabase-edge-agent

# Or using Wrangler
npm install -g wrangler
wrangler init supabase-edge-agent
```

#### Step 2: Install Dependencies

**Using Neon's Serverless Driver (recommended for Cloudflare):**
```bash
npm install @neondatabase/serverless
```

**Or use pg with polyfills:**
```bash
npm install pg
npm install --save-dev esbuild
```

#### Step 3: Worker Code

**Using Neon Serverless Driver:**
```typescript
import { Pool, neonConfig } from '@neondatabase/serverless';

// Configure for Cloudflare Workers
neonConfig.fetchConnectionCache = true;

export interface Env {
  DATABASE_URL: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Create pool for this request
    const pool = new Pool({ 
      connectionString: env.DATABASE_URL 
    });

    try {
      const client = await pool.connect();
      
      // Your query logic
      const result = await client.query('SELECT NOW()');
      client.release();
      
      return new Response(
        JSON.stringify({
          success: true,
          timestamp: result.rows[0]
        }),
        {
          headers: { 'Content-Type': 'application/json' }
        }
      );
    } catch (error) {
      return new Response(
        JSON.stringify({ 
          error: error instanceof Error ? error.message : 'Unknown error' 
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    } finally {
      await pool.end();
    }
  }
};
```

#### Step 4: Configure wrangler.toml

```toml
name = "supabase-edge-agent"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[env.production]
vars = { }

[env.production.vars]
# Don't put secrets here - use wrangler secret

# Use Cloudflare Workers KV or Secrets
# wrangler secret put DATABASE_URL
```

#### Step 5: Set Secrets

```bash
# Set database URL as secret
wrangler secret put DATABASE_URL

# When prompted, enter:
# postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?prepareStatement=false
```

#### Step 6: Deploy

```bash
# Deploy to Cloudflare
wrangler deploy

# Test locally
wrangler dev
```

### Deno Deploy

#### Step 1: Create Project

```bash
# Initialize Deno project
mkdir supabase-edge-agent
cd supabase-edge-agent
```

#### Step 2: Create Handler

**main.ts:**
```typescript
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { Pool } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

// Create connection pool
const pool = new Pool({
  connectionString: Deno.env.get("DATABASE_URL"),
  tls: {
    enabled: true,
    enforce: true
  },
  lazy: true,  // Connect only when needed
  max: 3       // Small pool for edge
}, 3);

serve(async (req: Request) => {
  // Get client from pool
  const client = await pool.connect();
  
  try {
    const result = await client.queryObject`
      SELECT NOW() as timestamp
    `;
    
    return new Response(
      JSON.stringify(result.rows[0]),
      {
        headers: { "Content-Type": "application/json" }
      }
    );
  } catch (error) {
    console.error("Database error:", error);
    return new Response(
      JSON.stringify({ 
        error: error instanceof Error ? error.message : "Unknown error" 
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" }
      }
    );
  } finally {
    client.release();
  }
});
```

#### Step 3: Deploy to Deno Deploy

**Using deployctl:**
```bash
# Install deployctl
deno install --allow-read --allow-write --allow-env --allow-net --allow-run --no-check -r -f https://deno.land/x/deploy/deployctl.ts

# Deploy
deployctl deploy --project=supabase-edge-agent main.ts

# Set environment variable in Deno Deploy dashboard
# DATABASE_URL=postgresql://...
```

**Using GitHub Actions:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Deno Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: denoland/setup-deno@v1
      - uses: denoland/deployctl@v1
        with:
          project: supabase-edge-agent
          entrypoint: main.ts
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Vercel Edge Functions

#### Step 1: Create Next.js Project

```bash
npx create-next-app@latest supabase-edge-agent
cd supabase-edge-agent
```

#### Step 2: Install Dependencies

```bash
npm install @vercel/postgres
# or
npm install pg
```

#### Step 3: Create Edge Function

**app/api/agent/route.ts:**
```typescript
import { sql } from '@vercel/postgres';
import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    // Query using Vercel Postgres
    const result = await sql`
      SELECT * FROM users WHERE email = ${body.email}
    `;
    
    return NextResponse.json({
      success: true,
      users: result.rows
    });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json(
      { 
        error: error instanceof Error ? error.message : 'Unknown error' 
      },
      { status: 500 }
    );
  }
}
```

**Alternative with pg:**
```typescript
import { Pool } from 'pg';
import { NextResponse } from 'next/server';

export const runtime = 'edge';

// Note: pg might have compatibility issues on edge
// Consider using @vercel/postgres instead

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true },
  max: 1
});

export async function GET(request: Request) {
  try {
    const result = await pool.query('SELECT NOW()');
    
    return NextResponse.json({
      success: true,
      timestamp: result.rows[0]
    });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
```

#### Step 4: Configure Environment Variables

**vercel.json or Vercel Dashboard:**
```json
{
  "env": {
    "DATABASE_URL": "@database-url"
  }
}
```

**Set via Vercel CLI:**
```bash
vercel env add DATABASE_URL
# Paste connection string when prompted
```

#### Step 5: Deploy

```bash
# Deploy to Vercel
vercel deploy

# Or push to Git (auto-deploys)
git push origin main
```

## Connection Configuration

### Optimal Settings for Edge

```typescript
// Cloudflare Workers (Neon)
const pool = new Pool({
  connectionString: env.DATABASE_URL,
  // Minimal configuration needed
});

// Deno
const pool = new Pool({
  connectionString: Deno.env.get("DATABASE_URL"),
  tls: { enabled: true, enforce: true },
  lazy: true,
  max: 3,
  connectionTimeoutMillis: 3000
}, 3);

// Vercel (using @vercel/postgres)
// Connection managed automatically
```

### Why These Settings?

| Setting | Value | Reason |
|---------|-------|--------|
| `max: 1-3` | Small pool | Edge functions are distributed |
| `lazy: true` | Lazy connect | Only connect when needed |
| `connectionTimeoutMillis: 3000` | 3 seconds | Fast timeout for edge |
| `tls: enforce` | Required | Edge requires TLS |

## Best Practices

### 1. Keep Bundle Size Small

```typescript
// ✅ Good - Import only what you need
import { Pool } from '@neondatabase/serverless';

// ❌ Bad - Large bundle
import pg from 'pg';  // May not work on edge
```

### 2. Use Edge-Compatible Libraries

**Recommended for Cloudflare:**
- `@neondatabase/serverless` ✅
- `@cloudflare/workers-pg` ✅

**Recommended for Deno:**
- `https://deno.land/x/postgres` ✅

**Recommended for Vercel:**
- `@vercel/postgres` ✅

### 3. Optimize Query Performance

```typescript
// ✅ Good - Simple, indexed query
const result = await client.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// ❌ Bad - Complex query without indexes
const result = await client.query(`
  SELECT u.*, 
    (SELECT COUNT(*) FROM posts WHERE user_id = u.id) as post_count,
    (SELECT AVG(rating) FROM reviews WHERE user_id = u.id) as avg_rating
  FROM users u
  WHERE u.email LIKE '%@example.com%'
`);
```

### 4. Handle Errors Gracefully

```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const pool = new Pool({ connectionString: env.DATABASE_URL });
      const client = await pool.connect();
      
      try {
        const result = await client.query('SELECT NOW()');
        return new Response(JSON.stringify(result.rows[0]));
      } finally {
        client.release();
        await pool.end();
      }
    } catch (error) {
      // Log error
      console.error('Database error:', error);
      
      // Return user-friendly error
      return new Response(
        JSON.stringify({ error: 'Service temporarily unavailable' }),
        { status: 503 }
      );
    }
  }
};
```

### 5. Use Caching When Possible

```typescript
import { Cache } from '@cloudflare/workers-types';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const cache = caches.default;
    const cacheKey = new Request(request.url, request);
    
    // Try cache first
    let response = await cache.match(cacheKey);
    
    if (!response) {
      // Query database
      const pool = new Pool({ connectionString: env.DATABASE_URL });
      const result = await pool.query('SELECT * FROM public_data');
      await pool.end();
      
      response = new Response(JSON.stringify(result.rows), {
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'max-age=300'  // 5 minutes
        }
      });
      
      // Store in cache
      await cache.put(cacheKey, response.clone());
    }
    
    return response;
  }
};
```

## Performance Optimization

### 1. Choose Closest Pooler Region

**Supabase Regions:**
- `aws-0-us-east-1` - US East Coast
- `aws-0-us-west-2` - US West Coast
- `aws-0-eu-west-1` - Europe (Ireland)
- `aws-0-ap-southeast-1` - Asia Pacific (Singapore)

**Match to your edge locations for lowest latency**

### 2. Use Read Replicas

```typescript
// Write to primary
const writePool = new Pool({
  connectionString: env.DATABASE_URL_PRIMARY
});

// Read from replica
const readPool = new Pool({
  connectionString: env.DATABASE_URL_REPLICA
});

// Route based on operation
if (request.method === 'POST') {
  result = await writePool.query('INSERT ...');
} else {
  result = await readPool.query('SELECT ...');
}
```

### 3. Implement Query Timeouts

```typescript
async function queryWithTimeout(
  client: any, 
  query: string, 
  params: any[], 
  timeoutMs = 2000
) {
  return Promise.race([
    client.query(query, params),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Query timeout')), timeoutMs)
    )
  ]);
}

// Usage
try {
  const result = await queryWithTimeout(
    client,
    'SELECT * FROM users WHERE id = $1',
    [userId],
    2000  // 2 second timeout
  );
} catch (error) {
  if (error.message === 'Query timeout') {
    // Handle timeout specifically
    return new Response('Request timeout', { status: 504 });
  }
  throw error;
}
```

### 4. Batch Requests

```typescript
// Handle multiple items in one edge function call
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { userIds } = await request.json();
    
    const pool = new Pool({ connectionString: env.DATABASE_URL });
    const client = await pool.connect();
    
    try {
      // Single query for all users
      const result = await client.query(
        'SELECT * FROM users WHERE id = ANY($1)',
        [userIds]
      );
      
      return new Response(JSON.stringify(result.rows));
    } finally {
      client.release();
      await pool.end();
    }
  }
};
```

## Monitoring Edge Functions

### Cloudflare Workers Analytics

```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const start = Date.now();
    
    try {
      // Your logic
      const result = await queryDatabase();
      
      // Log metrics (visible in Cloudflare dashboard)
      console.log(JSON.stringify({
        success: true,
        duration: Date.now() - start,
        timestamp: new Date().toISOString()
      }));
      
      return new Response(JSON.stringify(result));
    } catch (error) {
      console.error(JSON.stringify({
        error: error.message,
        duration: Date.now() - start,
        timestamp: new Date().toISOString()
      }));
      
      throw error;
    }
  }
};
```

### Deno Deploy Logs

```typescript
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";

serve(async (req: Request) => {
  const requestId = crypto.randomUUID();
  const start = Date.now();
  
  // Structured logging
  console.log(JSON.stringify({
    requestId,
    event: 'request_start',
    url: req.url,
    method: req.method
  }));
  
  try {
    const result = await handleRequest(req);
    
    console.log(JSON.stringify({
      requestId,
      event: 'request_complete',
      duration: Date.now() - start,
      status: 200
    }));
    
    return result;
  } catch (error) {
    console.error(JSON.stringify({
      requestId,
      event: 'request_error',
      error: error.message,
      duration: Date.now() - start
    }));
    
    throw error;
  }
});
```

### Vercel Edge Analytics

**Automatic in Vercel:**
- Response times tracked automatically
- Error rates monitored
- View in Vercel Dashboard → Analytics

**Custom Metrics:**
```typescript
import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET(request: Request) {
  const start = Date.now();
  
  try {
    const result = await queryDatabase();
    
    // Custom header for metrics
    return NextResponse.json(result, {
      headers: {
        'X-Query-Duration': `${Date.now() - start}ms`
      }
    });
  } catch (error) {
    return NextResponse.json(
      { error: error.message },
      { 
        status: 500,
        headers: {
          'X-Query-Duration': `${Date.now() - start}ms`,
          'X-Query-Error': 'true'
        }
      }
    );
  }
}
```

## Troubleshooting

### Issue: "Module not found" or "Can't resolve 'pg'"

**Solution:** Use edge-compatible libraries
```bash
# Cloudflare
npm install @neondatabase/serverless

# Vercel
npm install @vercel/postgres

# Deno
# Use: https://deno.land/x/postgres
```

### Issue: "Connection timeout"

**Solutions:**
1. Use closest pooler region
2. Reduce connection timeout
3. Optimize queries
4. Add indexes

### Issue: "Bundle size too large"

**Solutions:**
1. Use tree-shaking
2. Import only what you need
3. Use edge-optimized libraries
4. Minimize dependencies

See [Troubleshooting Guide](../mcp-setup/troubleshooting.md) for more details.

## Security Considerations

### 1. Protect Secrets

**Cloudflare:**
```bash
# Use Wrangler secrets
wrangler secret put DATABASE_URL
```

**Deno Deploy:**
```bash
# Use environment variables in dashboard
```

**Vercel:**
```bash
# Use Vercel environment variables
vercel env add DATABASE_URL
```

### 2. Validate Input

```typescript
function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { email } = await request.json();
    
    if (!validateEmail(email)) {
      return new Response(
        JSON.stringify({ error: 'Invalid email' }),
        { status: 400 }
      );
    }
    
    // Proceed with query
  }
};
```

### 3. Use Parameterized Queries

```typescript
// ✅ Good - Parameterized
const result = await client.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// ❌ Bad - SQL injection risk
const result = await client.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

## Next Steps

- **Quick Start**: [MCP Quick Start](../mcp-setup/quickstart.md)
- **Configuration**: [Configuration Templates](../mcp-setup/configuration-templates.md)
- **Troubleshooting**: [Common Issues](../mcp-setup/troubleshooting.md)
- **Monitoring**: [Setup Monitoring](../mcp-setup/monitoring.md)

## Related Guides

- [Persistent AI Agents](./persistent-agents.md)
- [Serverless AI Agents](./serverless-agents.md)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0
