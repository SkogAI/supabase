/**
 * Health Check Utility for Direct Database Connections
 * 
 * This module provides health checking functionality for monitoring
 * direct IPv6 database connections to Supabase.
 * 
 * Usage:
 *   import { HealthChecker } from './health-check';
 *   
 *   const checker = new HealthChecker(pool);
 *   const result = await checker.check();
 *   console.log('Health status:', result.status);
 */

import pg from 'pg';
const { Pool } = pg;

export interface HealthCheckResult {
  status: 'healthy' | 'degraded' | 'unhealthy';
  latency: number;
  poolStats: {
    total: number;
    idle: number;
    waiting: number;
  };
  databaseStats: {
    version: string;
    connections: number;
    maxConnections: number;
    uptime?: string;
  };
  timestamp: Date;
  error?: string;
}

export interface HealthCheckConfig {
  enabled: boolean;
  interval: number;
  timeout: number;
  latencyThresholds: {
    warning: number;
    critical: number;
  };
  connectionThresholds: {
    warning: number;
    critical: number;
  };
}

export class HealthChecker {
  private intervalId?: NodeJS.Timeout;
  
  constructor(
    private pool: Pool,
    private config: HealthCheckConfig = {
      enabled: true,
      interval: 30000,
      timeout: 5000,
      latencyThresholds: {
        warning: 100,
        critical: 1000
      },
      connectionThresholds: {
        warning: 0.8,
        critical: 0.95
      }
    }
  ) {}

  /**
   * Perform a single health check
   */
  async check(): Promise<HealthCheckResult> {
    const startTime = Date.now();
    
    try {
      // Test basic connectivity with timeout
      const healthQuery = await this.queryWithTimeout(
        'SELECT 1 as health',
        this.config.timeout
      );
      
      if (!healthQuery || healthQuery.rows[0]?.health !== 1) {
        throw new Error('Health check query failed');
      }

      // Get database version and connection info
      const [versionResult, connectionStats, uptime] = await Promise.all([
        this.pool.query('SELECT version()'),
        this.pool.query(`
          SELECT 
            count(*) as current_connections,
            (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections
          FROM pg_stat_activity
        `),
        this.pool.query(`
          SELECT 
            date_trunc('second', current_timestamp - pg_postmaster_start_time()) as uptime
        `).catch(() => null)
      ]);

      const latency = Date.now() - startTime;
      
      // Get pool statistics
      const poolStats = {
        total: this.pool.totalCount,
        idle: this.pool.idleCount,
        waiting: this.pool.waitingCount
      };

      const dbStats = connectionStats.rows[0];
      const connectionUsage = dbStats.current_connections / dbStats.max_connections;
      
      // Determine status based on thresholds
      let status: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
      
      if (
        latency > this.config.latencyThresholds.warning ||
        connectionUsage > this.config.connectionThresholds.warning
      ) {
        status = 'degraded';
      }
      
      if (
        latency > this.config.latencyThresholds.critical ||
        connectionUsage > this.config.connectionThresholds.critical
      ) {
        status = 'unhealthy';
      }

      return {
        status,
        latency,
        poolStats,
        databaseStats: {
          version: versionResult.rows[0].version.split(' ')[0], // Just PostgreSQL version
          connections: parseInt(dbStats.current_connections),
          maxConnections: parseInt(dbStats.max_connections),
          uptime: uptime?.rows[0]?.uptime
        },
        timestamp: new Date()
      };
    } catch (error: any) {
      console.error('Health check error:', error);
      return {
        status: 'unhealthy',
        latency: Date.now() - startTime,
        poolStats: {
          total: this.pool.totalCount,
          idle: this.pool.idleCount,
          waiting: this.pool.waitingCount
        },
        databaseStats: {
          version: 'unknown',
          connections: 0,
          maxConnections: 0
        },
        timestamp: new Date(),
        error: error.message
      };
    }
  }

  /**
   * Query with timeout
   */
  private async queryWithTimeout(
    sql: string,
    timeoutMs: number
  ): Promise<pg.QueryResult | null> {
    return Promise.race([
      this.pool.query(sql),
      new Promise<null>((_, reject) => 
        setTimeout(() => reject(new Error('Query timeout')), timeoutMs)
      )
    ]);
  }

  /**
   * Start periodic health checks
   */
  startPeriodicCheck(callback?: (result: HealthCheckResult) => void): void {
    if (!this.config.enabled) {
      console.log('Health checks are disabled');
      return;
    }

    if (this.intervalId) {
      console.warn('Health checks already running');
      return;
    }

    console.log(`Starting health checks every ${this.config.interval}ms`);
    
    this.intervalId = setInterval(async () => {
      const result = await this.check();
      
      // Default logging
      this.logHealthCheck(result);
      
      // Custom callback
      if (callback) {
        callback(result);
      }
    }, this.config.interval);
  }

  /**
   * Stop periodic health checks
   */
  stopPeriodicCheck(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
      console.log('Health checks stopped');
    }
  }

  /**
   * Log health check result
   */
  private logHealthCheck(result: HealthCheckResult): void {
    const emoji = result.status === 'healthy' ? '✅' :
                  result.status === 'degraded' ? '⚠️' : '❌';
    
    console.log(`${emoji} Health Check: ${result.status.toUpperCase()}`);
    console.log(`   Latency: ${result.latency}ms`);
    console.log(`   Pool: ${result.poolStats.idle}/${result.poolStats.total} idle`);
    console.log(`   Connections: ${result.databaseStats.connections}/${result.databaseStats.maxConnections}`);
    
    if (result.error) {
      console.error(`   Error: ${result.error}`);
    }
  }
}

/**
 * Simple health check function
 */
export async function simpleHealthCheck(
  connectionString: string
): Promise<boolean> {
  const client = new pg.Client({ connectionString });
  
  try {
    await client.connect();
    const result = await client.query('SELECT 1 as health');
    await client.end();
    return result.rows[0].health === 1;
  } catch (error) {
    console.error('Health check failed:', error);
    return false;
  }
}

// Example usage
if (import.meta.main) {
  const connectionString = Deno.env.get('SUPABASE_DIRECT_CONNECTION');
  
  if (!connectionString) {
    console.error('SUPABASE_DIRECT_CONNECTION environment variable not set');
    Deno.exit(1);
  }

  const pool = new Pool({ connectionString });
  const checker = new HealthChecker(pool);

  // Run single check
  console.log('Running health check...');
  const result = await checker.check();
  console.log(JSON.stringify(result, null, 2));

  // Start periodic checks
  checker.startPeriodicCheck((result) => {
    if (result.status === 'unhealthy') {
      // Alert monitoring system
      console.error('⚠️  ALERT: Database is unhealthy!');
    }
  });

  // Graceful shutdown
  Deno.addSignalListener('SIGTERM', async () => {
    checker.stopPeriodicCheck();
    await pool.end();
    Deno.exit(0);
  });
}
