/**
 * Connection Pool Configuration Examples for AI Agents
 * 
 * This file demonstrates optimal connection pool configurations
 * for different AI agent types and workload patterns.
 * 
 * See docs/MCP_CONNECTION_POOLING.md for detailed documentation.
 */

import { Pool, PoolConfig } from 'pg';

// ============================================================================
// 1. PERSISTENT AI AGENT CONFIGURATION
// ============================================================================

/**
 * For long-running AI agents with stable environments
 * - Session mode connection
 * - Moderate pool size (5-20)
 * - Long idle timeout (10 minutes)
 */
export const persistentAgentPool: PoolConfig = {
  // Connection
  host: process.env.DB_HOST,
  port: 5432,
  database: 'postgres',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  
  // SSL
  ssl: {
    rejectUnauthorized: true
  },
  
  // Pool settings
  min: 5,
  max: 20,
  idleTimeoutMillis: 600000,      // 10 minutes
  connectionTimeoutMillis: 10000,  // 10 seconds
  
  // Query timeouts
  statement_timeout: 60000,        // 60 seconds
  query_timeout: 60000,            // 60 seconds
  
  // Connection lifecycle
  maxUses: 7500,                   // Recycle after 7500 queries
  allowExitOnIdle: true,
  
  // Application name for monitoring
  application_name: 'persistent-ai-agent'
};

// ============================================================================
// 2. SERVERLESS AI AGENT CONFIGURATION
// ============================================================================

/**
 * For AWS Lambda, Google Cloud Functions, Azure Functions
 * - Transaction mode connection
 * - Zero minimum connections
 * - Aggressive timeouts (5 seconds)
 */
export const serverlessAgentPool: PoolConfig = {
  // Connection (use transaction pooler)
  host: process.env.POOLER_HOST,
  port: 6543, // Transaction mode port
  database: 'postgres',
  user: `${process.env.DB_USER}.${process.env.PROJECT_REF}`,
  password: process.env.DB_PASSWORD,
  
  // SSL
  ssl: {
    rejectUnauthorized: true
  },
  
  // Pool settings - minimal for serverless
  min: 0,                          // No idle connections
  max: 10,
  idleTimeoutMillis: 5000,         // 5 seconds
  connectionTimeoutMillis: 5000,   // 5 seconds
  
  // Query timeouts - aggressive for serverless
  statement_timeout: 30000,        // 30 seconds
  query_timeout: 25000,            // 25 seconds
  
  // Disable prepared statements for PgBouncer
  // @ts-ignore
  preparedStatements: false,
  
  // Application name
  application_name: 'serverless-ai-agent'
};

// ============================================================================
// 3. EDGE AI AGENT CONFIGURATION
// ============================================================================

/**
 * For Cloudflare Workers, Vercel Edge, Deno Deploy
 * - Transaction mode connection
 * - Very limited pool (0-3)
 * - Ultra-aggressive timeouts (1-3 seconds)
 */
export const edgeAgentPool: PoolConfig = {
  // Connection (use transaction pooler)
  host: process.env.POOLER_HOST,
  port: 6543,
  database: 'postgres',
  user: `${process.env.DB_USER}.${process.env.PROJECT_REF}`,
  password: process.env.DB_PASSWORD,
  
  // SSL
  ssl: {
    rejectUnauthorized: true
  },
  
  // Pool settings - minimal for edge
  min: 0,
  max: 3,
  idleTimeoutMillis: 1000,         // 1 second
  connectionTimeoutMillis: 3000,   // 3 seconds
  
  // Query timeouts - very aggressive
  statement_timeout: 10000,        // 10 seconds
  query_timeout: 8000,             // 8 seconds
  
  // Disable prepared statements
  // @ts-ignore
  preparedStatements: false,
  
  // Application name
  application_name: 'edge-ai-agent'
};

// ============================================================================
// 4. HIGH-PERFORMANCE AI AGENT CONFIGURATION
// ============================================================================

/**
 * For intensive workloads with many concurrent operations
 * - Session mode connection
 * - Large pool size (20-100)
 * - Dedicated pooler
 */
export const highPerfAgentPool: PoolConfig = {
  // Connection (dedicated pooler)
  host: process.env.DEDICATED_POOLER_HOST,
  port: 5432,
  database: 'postgres',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  
  // SSL
  ssl: {
    rejectUnauthorized: true,
    ca: process.env.DB_SSL_CERT
  },
  
  // Pool settings - large for high performance
  min: 20,
  max: 100,
  idleTimeoutMillis: 600000,       // 10 minutes
  connectionTimeoutMillis: 10000,  // 10 seconds
  
  // Query timeouts
  statement_timeout: 60000,        // 60 seconds
  query_timeout: 60000,            // 60 seconds
  
  // Enable prepared statements for performance
  // @ts-ignore
  preparedStatements: true,
  
  // Connection lifecycle
  maxUses: 10000,
  allowExitOnIdle: false,          // Keep connections alive
  
  // Application name
  application_name: 'high-perf-ai-agent'
};

// ============================================================================
// POOL CALCULATION HELPER FUNCTIONS
// ============================================================================

/**
 * Calculate optimal pool size based on expected load
 */
export function calculatePoolSize(params: {
  expectedConcurrentAgents: number;
  avgQueriesPerAgent: number;
  bufferPercentage?: number;
}): { min: number; max: number } {
  const { 
    expectedConcurrentAgents, 
    avgQueriesPerAgent,
    bufferPercentage = 0.20 
  } = params;
  
  const baseSize = expectedConcurrentAgents * avgQueriesPerAgent;
  const buffer = Math.max(Math.floor(baseSize * bufferPercentage), 5);
  const maxSize = baseSize + buffer;
  const minSize = Math.floor(maxSize * 0.25);
  
  return {
    min: minSize,
    max: maxSize
  };
}

/**
 * Calculate pool size based on compute tier
 */
export function calculatePoolSizeByTier(tier: string): { min: number; max: number } {
  const limits: Record<string, { max: number; recommended: number }> = {
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
    max: config.recommended
  };
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/**
 * Example: Create persistent agent pool
 */
export async function createPersistentPool() {
  const pool = new Pool(persistentAgentPool);
  
  // Monitor pool events
  pool.on('connect', () => {
    console.log('Pool: connection established');
  });
  
  pool.on('error', (error) => {
    console.error('Pool: connection error', error);
  });
  
  return pool;
}

/**
 * Example: Create serverless agent pool with calculated size
 */
export async function createServerlessPool(expectedAgents: number) {
  const poolSize = calculatePoolSize({
    expectedConcurrentAgents: expectedAgents,
    avgQueriesPerAgent: 3,
    bufferPercentage: 0.20
  });
  
  const config = {
    ...serverlessAgentPool,
    min: 0, // Serverless always starts at 0
    max: Math.min(poolSize.max, 10) // Cap at 10 for serverless
  };
  
  return new Pool(config);
}

/**
 * Example: Create high-performance pool based on compute tier
 */
export async function createHighPerfPool(tier: string) {
  const poolSize = calculatePoolSizeByTier(tier);
  
  const config = {
    ...highPerfAgentPool,
    min: poolSize.min,
    max: poolSize.max
  };
  
  return new Pool(config);
}

/**
 * Example: Query with automatic retry
 */
export async function queryWithRetry(
  pool: Pool,
  sql: string,
  params: any[] = [],
  maxRetries = 3
) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await pool.query(sql, params);
    } catch (error: any) {
      if (attempt === maxRetries - 1) {
        throw error;
      }
      
      // Exponential backoff
      const delay = 1000 * Math.pow(2, attempt);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

/**
 * Example: Graceful shutdown
 */
export async function shutdownPool(pool: Pool) {
  console.log('Shutting down connection pool...');
  
  // Wait for active queries to complete
  await pool.end();
  
  console.log('Connection pool closed');
}

// ============================================================================
// MONITORING HELPERS
// ============================================================================

/**
 * Get current pool statistics
 */
export function getPoolStats(pool: Pool) {
  return {
    total: pool.totalCount,
    idle: pool.idleCount,
    active: pool.totalCount - pool.idleCount,
    waiting: pool.waitingCount,
    utilization: ((pool.totalCount - pool.idleCount) / pool.totalCount * 100).toFixed(2) + '%'
  };
}

/**
 * Monitor pool health
 */
export function monitorPoolHealth(pool: Pool, intervalMs = 30000) {
  const interval = setInterval(() => {
    const stats = getPoolStats(pool);
    console.log('Pool Health:', stats);
    
    // Alert on high utilization
    if (pool.idleCount === 0 && pool.waitingCount > 10) {
      console.warn('Pool saturation detected! Consider increasing pool size.');
    }
    
    // Alert on connection errors
    if (stats.total === 0) {
      console.error('No active connections in pool!');
    }
  }, intervalMs);
  
  return () => clearInterval(interval);
}

// ============================================================================
// EXPORT ALL CONFIGURATIONS
// ============================================================================

export const poolConfigs = {
  persistent: persistentAgentPool,
  serverless: serverlessAgentPool,
  edge: edgeAgentPool,
  highPerf: highPerfAgentPool
};

export const poolHelpers = {
  calculatePoolSize,
  calculatePoolSizeByTier,
  createPersistentPool,
  createServerlessPool,
  createHighPerfPool,
  queryWithRetry,
  shutdownPool,
  getPoolStats,
  monitorPoolHealth
};
