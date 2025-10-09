/**
 * Connection Health Check Utilities
 *
 * Provides health check functions for AI agent database connections.
 * Can be used in Edge Functions, MCP servers, or standalone monitoring scripts.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface DatabaseHealth {
  healthy: boolean;
  total_connections: number;
  max_connections: number;
  usage_percent: number;
  active_connections: number;
  idle_connections: number;
  idle_in_transaction: number;
  oldest_connection_age: string;
  check_timestamp: string;
}

export interface ConnectionLimits {
  within_limits: boolean;
  total_connections: number;
  max_connections: number;
  usage_percent: number;
  warning_threshold_reached: boolean;
  critical_threshold_reached: boolean;
  recommended_action: string;
}

export interface AIAgentConnection {
  application_name: string;
  user_name: string;
  connection_count: number;
  active_queries: number;
  avg_connection_age: string;
  oldest_connection_age: string;
  newest_connection_age: string;
  ssl_connections: number;
  client_addresses: string[];
}

export interface ConnectionPoolMetric {
  metric_name: string;
  metric_value: number;
  metric_description: string;
}

/**
 * Check database health status
 */
export async function checkDatabaseHealth(
  supabaseUrl: string,
  supabaseKey: string,
): Promise<DatabaseHealth | null> {
  try {
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });

    const { data, error } = await supabase.rpc("check_database_health");

    if (error) {
      console.error("Health check error:", error);
      return null;
    }

    return data?.[0] || null;
  } catch (error) {
    console.error("Failed to check database health:", error);
    return null;
  }
}

/**
 * Check connection limits
 */
export async function checkConnectionLimits(
  supabaseUrl: string,
  supabaseKey: string,
): Promise<ConnectionLimits | null> {
  try {
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });

    const { data, error } = await supabase.rpc("check_connection_limits");

    if (error) {
      console.error("Connection limits check error:", error);
      return null;
    }

    return data?.[0] || null;
  } catch (error) {
    console.error("Failed to check connection limits:", error);
    return null;
  }
}

/**
 * Get AI agent connections
 */
export async function getAIAgentConnections(
  supabaseUrl: string,
  supabaseKey: string,
): Promise<AIAgentConnection[]> {
  try {
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });

    const { data, error } = await supabase.rpc("get_ai_agent_connections");

    if (error) {
      console.error("AI agent connections error:", error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error("Failed to get AI agent connections:", error);
    return [];
  }
}

/**
 * Get connection pool metrics
 */
export async function getConnectionPoolMetrics(
  supabaseUrl: string,
  supabaseKey: string,
): Promise<ConnectionPoolMetric[]> {
  try {
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });

    const { data, error } = await supabase.rpc("get_connection_pool_metrics");

    if (error) {
      console.error("Connection pool metrics error:", error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error("Failed to get connection pool metrics:", error);
    return [];
  }
}

/**
 * Simple health check - returns true if database is accessible
 */
export async function isHealthy(
  supabaseUrl: string,
  supabaseKey: string,
): Promise<boolean> {
  try {
    const health = await checkDatabaseHealth(supabaseUrl, supabaseKey);
    return health?.healthy || false;
  } catch {
    return false;
  }
}

/**
 * Check if connection usage is within safe limits
 */
export async function isWithinLimits(
  supabaseUrl: string,
  supabaseKey: string,
): Promise<boolean> {
  try {
    const limits = await checkConnectionLimits(supabaseUrl, supabaseKey);
    return limits?.within_limits || false;
  } catch {
    return false;
  }
}

/**
 * Get connection usage percentage
 */
export async function getConnectionUsage(
  supabaseUrl: string,
  supabaseKey: string,
): Promise<number> {
  try {
    const health = await checkDatabaseHealth(supabaseUrl, supabaseKey);
    return health?.usage_percent || 0;
  } catch {
    return 0;
  }
}

/**
 * Monitor connection health continuously
 */
export async function* monitorHealth(
  supabaseUrl: string,
  supabaseKey: string,
  intervalMs: number = 60000,
): AsyncGenerator<DatabaseHealth | null> {
  while (true) {
    const health = await checkDatabaseHealth(supabaseUrl, supabaseKey);
    yield health;

    // Wait for next interval
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }
}

/**
 * Alert levels based on connection usage
 */
export enum AlertLevel {
  OK = "ok",
  WARNING = "warning",
  CRITICAL = "critical",
  ERROR = "error",
}

export interface HealthAlert {
  level: AlertLevel;
  message: string;
  usage_percent: number;
  total_connections: number;
  max_connections: number;
  timestamp: Date;
}

/**
 * Get alert level based on health status
 */
export function getAlertLevel(health: DatabaseHealth | null): HealthAlert {
  if (!health) {
    return {
      level: AlertLevel.ERROR,
      message: "Unable to retrieve database health",
      usage_percent: 0,
      total_connections: 0,
      max_connections: 0,
      timestamp: new Date(),
    };
  }

  if (health.usage_percent >= 90) {
    return {
      level: AlertLevel.CRITICAL,
      message:
        `CRITICAL: Connection usage at ${health.usage_percent}% (${health.total_connections}/${health.max_connections})`,
      usage_percent: health.usage_percent,
      total_connections: health.total_connections,
      max_connections: health.max_connections,
      timestamp: new Date(),
    };
  }

  if (health.usage_percent >= 70) {
    return {
      level: AlertLevel.WARNING,
      message:
        `WARNING: Connection usage at ${health.usage_percent}% (${health.total_connections}/${health.max_connections})`,
      usage_percent: health.usage_percent,
      total_connections: health.total_connections,
      max_connections: health.max_connections,
      timestamp: new Date(),
    };
  }

  return {
    level: AlertLevel.OK,
    message:
      `Connection usage normal at ${health.usage_percent}% (${health.total_connections}/${health.max_connections})`,
    usage_percent: health.usage_percent,
    total_connections: health.total_connections,
    max_connections: health.max_connections,
    timestamp: new Date(),
  };
}

/**
 * Format interval string to human-readable format
 */
export function formatInterval(interval: string): string {
  if (!interval) return "0 seconds";

  // Parse PostgreSQL interval format (e.g., "01:23:45" or "1 day 02:30:00")
  const match = interval.match(/(?:(\d+) days? )?(\d+):(\d+):(\d+)/);
  if (!match) return interval;

  const [, days, hours, minutes, seconds] = match;
  const parts: string[] = [];

  if (days && parseInt(days) > 0) parts.push(`${days}d`);
  if (hours && parseInt(hours) > 0) parts.push(`${hours}h`);
  if (minutes && parseInt(minutes) > 0) parts.push(`${minutes}m`);
  if (seconds && parseInt(seconds) > 0) parts.push(`${seconds}s`);

  return parts.length > 0 ? parts.join(" ") : "0s";
}

/**
 * Example usage in an Edge Function
 *
 * ```typescript
 * import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
 * import { checkDatabaseHealth, getAlertLevel } from '../_shared/connection-health.ts';
 *
 * serve(async (req) => {
 *   const health = await checkDatabaseHealth(
 *     Deno.env.get('SUPABASE_URL')!,
 *     Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
 *   );
 *
 *   const alert = getAlertLevel(health);
 *
 *   return new Response(
 *     JSON.stringify({ health, alert }),
 *     { headers: { 'Content-Type': 'application/json' } }
 *   );
 * });
 * ```
 */
