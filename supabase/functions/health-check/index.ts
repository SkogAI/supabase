/**
 * Health Check Edge Function
 * 
 * Provides comprehensive database health checks and connection monitoring
 * for AI agents and monitoring systems.
 * 
 * Endpoints:
 * - GET /health-check - Full health report
 * - GET /health-check?simple=true - Simple health status
 * - GET /health-check?agents=true - AI agent connection details
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import {
  checkDatabaseHealth,
  checkConnectionLimits,
  getAIAgentConnections,
  getConnectionPoolMetrics,
  getAlertLevel,
  formatInterval,
  AlertLevel
} from '../_shared/connection-health.ts';

interface HealthCheckResponse {
  status: 'healthy' | 'degraded' | 'unhealthy' | 'error';
  timestamp: string;
  health?: any;
  limits?: any;
  alert?: any;
  agents?: any[];
  pool_metrics?: any[];
  uptime?: string;
}

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const simple = url.searchParams.get('simple') === 'true';
    const includeAgents = url.searchParams.get('agents') === 'true';
    const includeMetrics = url.searchParams.get('metrics') === 'true';

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseKey) {
      return new Response(
        JSON.stringify({
          status: 'error',
          message: 'Missing configuration',
          timestamp: new Date().toISOString()
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Check database health
    const health = await checkDatabaseHealth(supabaseUrl, supabaseKey);
    
    if (!health) {
      return new Response(
        JSON.stringify({
          status: 'error',
          message: 'Unable to check database health',
          timestamp: new Date().toISOString()
        }),
        {
          status: 503,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Simple health check - just return status
    if (simple) {
      return new Response(
        JSON.stringify({
          status: health.healthy ? 'healthy' : 'unhealthy',
          timestamp: new Date().toISOString(),
          usage_percent: health.usage_percent,
          connections: `${health.total_connections}/${health.max_connections}`
        }),
        {
          status: health.healthy ? 200 : 503,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Full health check
    const limits = await checkConnectionLimits(supabaseUrl, supabaseKey);
    const alert = getAlertLevel(health);

    const response: HealthCheckResponse = {
      status: health.healthy ? 'healthy' : limits?.critical_threshold_reached ? 'unhealthy' : 'degraded',
      timestamp: new Date().toISOString(),
      health: {
        ...health,
        oldest_connection_age_formatted: formatInterval(health.oldest_connection_age)
      },
      limits,
      alert
    };

    // Include AI agent details if requested
    if (includeAgents) {
      const agents = await getAIAgentConnections(supabaseUrl, supabaseKey);
      response.agents = agents.map(agent => ({
        ...agent,
        avg_connection_age_formatted: formatInterval(agent.avg_connection_age),
        oldest_connection_age_formatted: formatInterval(agent.oldest_connection_age),
        newest_connection_age_formatted: formatInterval(agent.newest_connection_age)
      }));
    }

    // Include pool metrics if requested
    if (includeMetrics) {
      response.pool_metrics = await getConnectionPoolMetrics(supabaseUrl, supabaseKey);
    }

    // Determine HTTP status based on health
    let httpStatus = 200;
    if (alert.level === AlertLevel.CRITICAL) {
      httpStatus = 503;
    } else if (alert.level === AlertLevel.WARNING) {
      httpStatus = 200; // Still operational, but warn in response
    }

    return new Response(
      JSON.stringify(response, null, 2),
      {
        status: httpStatus,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('Health check error:', error);
    
    return new Response(
      JSON.stringify({
        status: 'error',
        message: error.message || 'Internal server error',
        timestamp: new Date().toISOString()
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});

/**
 * Usage Examples:
 * 
 * Simple health check:
 * curl https://your-project.supabase.co/functions/v1/health-check?simple=true
 * 
 * Full health report:
 * curl https://your-project.supabase.co/functions/v1/health-check
 * 
 * Include AI agent details:
 * curl https://your-project.supabase.co/functions/v1/health-check?agents=true
 * 
 * Include pool metrics:
 * curl https://your-project.supabase.co/functions/v1/health-check?metrics=true
 * 
 * Full report with all details:
 * curl https://your-project.supabase.co/functions/v1/health-check?agents=true&metrics=true
 */
