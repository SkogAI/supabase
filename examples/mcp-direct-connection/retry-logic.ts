/**
 * Connection Retry Logic with Exponential Backoff
 * 
 * This module provides retry logic for database operations with
 * exponential backoff, circuit breaker pattern, and error classification.
 * 
 * Usage:
 *   import { withRetry } from './retry-logic';
 *   
 *   const result = await withRetry(
 *     () => pool.query('SELECT * FROM users'),
 *     { maxAttempts: 3 }
 *   );
 */

import pg from 'pg';

export interface RetryConfig {
  maxAttempts: number;
  initialDelayMs: number;
  maxDelayMs: number;
  backoffMultiplier: number;
  jitter: boolean;
}

export const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  initialDelayMs: 1000,
  maxDelayMs: 10000,
  backoffMultiplier: 2,
  jitter: true
};

/**
 * Error classification for retry decisions
 */
export class DatabaseError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly isRetryable: boolean = true
  ) {
    super(message);
    this.name = 'DatabaseError';
  }
}

/**
 * Non-retryable error codes
 */
const NON_RETRYABLE_ERROR_CODES = [
  // Authentication/Authorization
  '28P01', // Invalid password
  '28000', // Invalid authorization specification
  
  // Database/Schema issues
  '3D000', // Database does not exist
  '3F000', // Invalid schema name
  '42P01', // Table does not exist
  '42703', // Column does not exist
  '42883', // Function does not exist
  
  // Data integrity
  '23505', // Unique constraint violation
  '23503', // Foreign key violation
  '23502', // Not null violation
  '23514', // Check constraint violation
  
  // Syntax errors
  '42601', // Syntax error
  '42501', // Insufficient privilege
  
  // Node.js error codes
  'EAUTH', // Authentication error
];

/**
 * Check if error is retryable
 */
export function isRetryableError(error: any): boolean {
  const errorCode = error.code || error.errno;
  
  if (!errorCode) {
    return true; // Unknown errors are retryable by default
  }

  // Check against non-retryable codes
  if (NON_RETRYABLE_ERROR_CODES.includes(errorCode)) {
    return false;
  }

  // Retryable error codes
  const retryableErrors = [
    'ECONNREFUSED',
    'ETIMEDOUT',
    'ENOTFOUND',
    'ENETUNREACH',
    'EPIPE',
    'ECONNRESET',
    '53300', // Too many connections
    '57P01', // Admin shutdown
    '57P02', // Crash shutdown
    '57P03', // Cannot connect now
    '08000', // Connection exception
    '08003', // Connection does not exist
    '08006', // Connection failure
  ];

  return retryableErrors.includes(errorCode);
}

/**
 * Sleep utility with optional jitter
 */
export async function sleep(ms: number, jitter: boolean = false): Promise<void> {
  const delay = jitter ? ms * (0.5 + Math.random() * 0.5) : ms;
  return new Promise(resolve => setTimeout(resolve, delay));
}

/**
 * Retry an operation with exponential backoff
 */
export async function withRetry<T>(
  operation: () => Promise<T>,
  config: Partial<RetryConfig> = {}
): Promise<T> {
  const finalConfig = { ...DEFAULT_RETRY_CONFIG, ...config };
  let lastError: Error;
  let delay = finalConfig.initialDelayMs;

  for (let attempt = 1; attempt <= finalConfig.maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (error: any) {
      lastError = error;

      // Check if error is retryable
      if (!isRetryableError(error)) {
        console.error(`Non-retryable error (${error.code}): ${error.message}`);
        throw error;
      }

      // Don't retry on last attempt
      if (attempt >= finalConfig.maxAttempts) {
        break;
      }

      // Log retry attempt
      console.log(
        `Attempt ${attempt}/${finalConfig.maxAttempts} failed: ${error.message} (${error.code || 'unknown'})`
      );
      console.log(`Retrying in ${Math.round(delay)}ms...`);

      // Wait before retry
      await sleep(delay, finalConfig.jitter);

      // Calculate next delay with exponential backoff
      delay = Math.min(
        delay * finalConfig.backoffMultiplier,
        finalConfig.maxDelayMs
      );
    }
  }

  console.error(`All ${finalConfig.maxAttempts} attempts failed`);
  throw lastError!;
}

/**
 * Circuit breaker state
 */
type CircuitState = 'closed' | 'open' | 'half-open';

/**
 * Circuit breaker configuration
 */
export interface CircuitBreakerConfig {
  failureThreshold: number;
  resetTimeoutMs: number;
  halfOpenMaxAttempts: number;
  monitoringWindowMs: number;
}

export const DEFAULT_CIRCUIT_CONFIG: CircuitBreakerConfig = {
  failureThreshold: 5,
  resetTimeoutMs: 60000, // 1 minute
  halfOpenMaxAttempts: 3,
  monitoringWindowMs: 10000 // 10 seconds
};

/**
 * Circuit breaker for preventing cascading failures
 */
export class CircuitBreaker {
  private state: CircuitState = 'closed';
  private failureCount = 0;
  private successCount = 0;
  private lastFailureTime?: Date;
  private failures: Date[] = [];

  constructor(private config: CircuitBreakerConfig = DEFAULT_CIRCUIT_CONFIG) {}

  async execute<T>(operation: () => Promise<T>): Promise<T> {
    // Check circuit state
    if (this.state === 'open') {
      if (this.shouldAttemptReset()) {
        this.transitionTo('half-open');
      } else {
        throw new Error(
          `Circuit breaker is OPEN. Refusing request. ` +
          `Will retry after ${this.getTimeUntilReset()}ms`
        );
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
    if (this.state === 'half-open') {
      this.successCount++;
      console.log(
        `Circuit breaker: Success in HALF-OPEN (${this.successCount}/${this.config.halfOpenMaxAttempts})`
      );
      
      if (this.successCount >= this.config.halfOpenMaxAttempts) {
        this.transitionTo('closed');
        this.reset();
      }
    } else if (this.state === 'closed') {
      // Reset failure count on success
      this.failureCount = 0;
      this.failures = [];
    }
  }

  private onFailure(): void {
    const now = new Date();
    this.failures.push(now);
    this.failureCount++;
    this.lastFailureTime = now;

    // Remove old failures outside monitoring window
    this.failures = this.failures.filter(
      f => now.getTime() - f.getTime() < this.config.monitoringWindowMs
    );

    if (this.state === 'half-open') {
      this.transitionTo('open');
      this.successCount = 0;
    } else if (
      this.state === 'closed' &&
      this.failures.length >= this.config.failureThreshold
    ) {
      this.transitionTo('open');
    }
  }

  private shouldAttemptReset(): boolean {
    if (!this.lastFailureTime) return false;
    
    const timeSinceFailure = Date.now() - this.lastFailureTime.getTime();
    return timeSinceFailure >= this.config.resetTimeoutMs;
  }

  private getTimeUntilReset(): number {
    if (!this.lastFailureTime) return 0;
    
    const timeSinceFailure = Date.now() - this.lastFailureTime.getTime();
    return Math.max(0, this.config.resetTimeoutMs - timeSinceFailure);
  }

  private transitionTo(newState: CircuitState): void {
    console.log(`Circuit breaker: ${this.state.toUpperCase()} → ${newState.toUpperCase()}`);
    this.state = newState;
  }

  private reset(): void {
    this.failureCount = 0;
    this.successCount = 0;
    this.failures = [];
  }

  getState(): CircuitState {
    return this.state;
  }

  getStats() {
    return {
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      recentFailures: this.failures.length,
      timeUntilReset: this.getTimeUntilReset()
    };
  }
}

/**
 * Create connection pool with retry logic
 */
export async function createPoolWithRetry(
  connectionString: string,
  poolConfig?: pg.PoolConfig,
  retryConfig?: Partial<RetryConfig>
): Promise<pg.Pool> {
  return withRetry(async () => {
    const pool = new pg.Pool({
      connectionString,
      ...poolConfig
    });

    // Test the connection
    const client = await pool.connect();
    try {
      await client.query('SELECT 1');
    } finally {
      client.release();
    }

    return pool;
  }, retryConfig);
}

/**
 * Execute query with retry logic
 */
export async function executeQueryWithRetry(
  pool: pg.Pool,
  sql: string,
  params: any[] = [],
  retryConfig?: Partial<RetryConfig>
): Promise<any[]> {
  return withRetry(async () => {
    const result = await pool.query(sql, params);
    return result.rows;
  }, retryConfig);
}

// Example usage
if (import.meta.main) {
  const connectionString = Deno.env.get('SUPABASE_DIRECT_CONNECTION');
  
  if (!connectionString) {
    console.error('SUPABASE_DIRECT_CONNECTION environment variable not set');
    Deno.exit(1);
  }

  console.log('Testing retry logic...\n');

  // Example 1: Create pool with retry
  console.log('1. Creating connection pool with retry...');
  const pool = await createPoolWithRetry(connectionString, {
    max: 10,
    idleTimeoutMillis: 30000
  });
  console.log('✅ Pool created successfully\n');

  // Example 2: Query with retry
  console.log('2. Executing query with retry...');
  const users = await executeQueryWithRetry(
    pool,
    'SELECT id, email FROM auth.users LIMIT 5'
  );
  console.log(`✅ Query succeeded, fetched ${users.length} users\n`);

  // Example 3: Circuit breaker
  console.log('3. Testing circuit breaker...');
  const breaker = new CircuitBreaker({
    failureThreshold: 3,
    resetTimeoutMs: 5000,
    halfOpenMaxAttempts: 2,
    monitoringWindowMs: 10000
  });

  for (let i = 0; i < 5; i++) {
    try {
      await breaker.execute(async () => {
        const result = await pool.query('SELECT 1 as test');
        return result.rows;
      });
      console.log(`   Request ${i + 1}: Success`);
    } catch (error: any) {
      console.error(`   Request ${i + 1}: Failed - ${error.message}`);
    }
    
    const stats = breaker.getStats();
    console.log(`   Circuit state: ${stats.state}, failures: ${stats.recentFailures}`);
  }

  // Cleanup
  await pool.end();
  console.log('\n✅ All tests completed');
}
