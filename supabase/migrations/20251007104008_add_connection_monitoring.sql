-- ============================================================================
-- CONNECTION MONITORING AND HEALTH CHECKS
-- ============================================================================
-- This migration adds comprehensive connection monitoring, health checks,
-- and diagnostic functions for AI agent database connections.
--
-- Features:
-- - Database health check utilities
-- - Connection statistics and metrics
-- - AI agent connection tracking
-- - Connection pool monitoring
-- - Connection limit alerting
-- ============================================================================

-- ============================================================================
-- Function: check_database_health
-- Description: Comprehensive database health check
-- Returns: Health status, connection counts, and metrics
-- ============================================================================
CREATE OR REPLACE FUNCTION check_database_health()
RETURNS TABLE (
    healthy BOOLEAN,
    total_connections INTEGER,
    max_connections INTEGER,
    usage_percent NUMERIC,
    active_connections INTEGER,
    idle_connections INTEGER,
    idle_in_transaction INTEGER,
    oldest_connection_age INTERVAL,
    check_timestamp TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    WITH connection_stats AS (
        SELECT 
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE state = 'active') as active,
            COUNT(*) FILTER (WHERE state = 'idle') as idle,
            COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_tx,
            GREATEST(MAX(NOW() - backend_start), INTERVAL '0') as oldest_age
        FROM pg_stat_activity
        WHERE pid != pg_backend_pid()
    ),
    limits AS (
        SELECT setting::INTEGER as max_conn
        FROM pg_settings
        WHERE name = 'max_connections'
    )
    SELECT 
        (cs.total::NUMERIC / l.max_conn < 0.9) as healthy,
        cs.total::INTEGER,
        l.max_conn,
        ROUND((cs.total::NUMERIC / l.max_conn * 100), 2),
        cs.active::INTEGER,
        cs.idle::INTEGER,
        cs.idle_tx::INTEGER,
        cs.oldest_age,
        NOW()
    FROM connection_stats cs, limits l;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_database_health() IS 'Performs a comprehensive health check of database connections and returns key metrics';

-- ============================================================================
-- Function: get_connection_stats
-- Description: Get detailed connection statistics grouped by various attributes
-- Returns: Connection counts by database, user, application, and state
-- ============================================================================
CREATE OR REPLACE FUNCTION get_connection_stats()
RETURNS TABLE (
    database_name TEXT,
    user_name TEXT,
    application_name TEXT,
    state TEXT,
    connection_count BIGINT,
    avg_query_duration INTERVAL,
    ssl_enabled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(sa.datname, 'unknown')::TEXT,
        COALESCE(sa.usename, 'unknown')::TEXT,
        COALESCE(sa.application_name, 'unknown')::TEXT,
        COALESCE(sa.state, 'unknown')::TEXT,
        COUNT(*)::BIGINT,
        AVG(NOW() - sa.query_start) FILTER (WHERE sa.query_start IS NOT NULL),
        BOOL_OR(COALESCE(ssl.ssl, false))
    FROM pg_stat_activity sa
    LEFT JOIN pg_stat_ssl ssl ON sa.pid = ssl.pid
    WHERE sa.pid != pg_backend_pid()
    GROUP BY sa.datname, sa.usename, sa.application_name, sa.state
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_connection_stats() IS 'Returns detailed connection statistics grouped by database, user, application, and state';

-- ============================================================================
-- Function: get_ai_agent_connections
-- Description: Track connections by AI agent (identified by application_name)
-- Returns: AI agent connection details with metrics
-- ============================================================================
CREATE OR REPLACE FUNCTION get_ai_agent_connections()
RETURNS TABLE (
    application_name TEXT,
    user_name TEXT,
    connection_count BIGINT,
    active_queries BIGINT,
    avg_connection_age INTERVAL,
    oldest_connection_age INTERVAL,
    newest_connection_age INTERVAL,
    ssl_connections BIGINT,
    client_addresses TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(sa.application_name, 'unknown')::TEXT,
        COALESCE(sa.usename, 'unknown')::TEXT,
        COUNT(*)::BIGINT,
        COUNT(*) FILTER (WHERE sa.state = 'active')::BIGINT,
        AVG(NOW() - sa.backend_start),
        MAX(NOW() - sa.backend_start),
        MIN(NOW() - sa.backend_start),
        COUNT(*) FILTER (WHERE ssl.ssl = true)::BIGINT,
        ARRAY_AGG(DISTINCT sa.client_addr::TEXT) FILTER (WHERE sa.client_addr IS NOT NULL)
    FROM pg_stat_activity sa
    LEFT JOIN pg_stat_ssl ssl ON sa.pid = ssl.pid
    WHERE sa.pid != pg_backend_pid()
      AND sa.application_name IS NOT NULL
      AND sa.application_name != ''
    GROUP BY sa.application_name, sa.usename
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_ai_agent_connections() IS 'Returns connection details for AI agents identified by application_name';

-- ============================================================================
-- Function: check_connection_limits
-- Description: Check if connection usage is within safe limits
-- Returns: Boolean indicating if within limits and usage metrics
-- ============================================================================
CREATE OR REPLACE FUNCTION check_connection_limits()
RETURNS TABLE (
    within_limits BOOLEAN,
    total_connections INTEGER,
    max_connections INTEGER,
    usage_percent NUMERIC,
    warning_threshold_reached BOOLEAN,
    critical_threshold_reached BOOLEAN,
    recommended_action TEXT
) AS $$
DECLARE
    v_total INTEGER;
    v_max INTEGER;
    v_percent NUMERIC;
BEGIN
    SELECT 
        COUNT(*)::INTEGER,
        (SELECT setting::INTEGER FROM pg_settings WHERE name = 'max_connections')
    INTO v_total, v_max
    FROM pg_stat_activity
    WHERE pid != pg_backend_pid();
    
    v_percent := ROUND((v_total::NUMERIC / v_max * 100), 2);
    
    RETURN QUERY
    SELECT 
        (v_percent < 90),
        v_total,
        v_max,
        v_percent,
        (v_percent >= 70),
        (v_percent >= 90),
        CASE 
            WHEN v_percent >= 90 THEN 'CRITICAL: Reduce connections immediately or increase max_connections'
            WHEN v_percent >= 70 THEN 'WARNING: Monitor closely and consider increasing max_connections'
            ELSE 'OK: Connection usage is within safe limits'
        END::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_connection_limits() IS 'Checks connection usage against limits and provides recommendations';

-- ============================================================================
-- Function: get_connection_pool_metrics
-- Description: Get connection pool metrics including active, idle, waiting
-- Returns: Detailed pool metrics
-- ============================================================================
CREATE OR REPLACE FUNCTION get_connection_pool_metrics()
RETURNS TABLE (
    metric_name TEXT,
    metric_value BIGINT,
    metric_description TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT 
            COUNT(*) FILTER (WHERE state = 'active') as active,
            COUNT(*) FILTER (WHERE state = 'idle') as idle,
            COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_tx,
            COUNT(*) FILTER (WHERE state = 'idle in transaction (aborted)') as idle_in_tx_aborted,
            COUNT(*) FILTER (WHERE state = 'fastpath function call') as fastpath,
            COUNT(*) FILTER (WHERE state = 'disabled') as disabled,
            COUNT(*) FILTER (WHERE wait_event_type IS NOT NULL) as waiting,
            COUNT(*) as total
        FROM pg_stat_activity
        WHERE pid != pg_backend_pid()
    )
    SELECT 'total_connections'::TEXT, stats.total, 'Total number of connections'::TEXT FROM stats
    UNION ALL
    SELECT 'active_connections'::TEXT, stats.active, 'Connections currently executing queries'::TEXT FROM stats
    UNION ALL
    SELECT 'idle_connections'::TEXT, stats.idle, 'Idle connections in the pool'::TEXT FROM stats
    UNION ALL
    SELECT 'idle_in_transaction'::TEXT, stats.idle_in_tx, 'Connections idle within a transaction'::TEXT FROM stats
    UNION ALL
    SELECT 'idle_in_transaction_aborted'::TEXT, stats.idle_in_tx_aborted, 'Connections idle in aborted transaction'::TEXT FROM stats
    UNION ALL
    SELECT 'waiting_connections'::TEXT, stats.waiting, 'Connections waiting for resources'::TEXT FROM stats
    UNION ALL
    SELECT 'fastpath_calls'::TEXT, stats.fastpath, 'Connections in fastpath function call'::TEXT FROM stats
    UNION ALL
    SELECT 'disabled_connections'::TEXT, stats.disabled, 'Disabled connections'::TEXT FROM stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_connection_pool_metrics() IS 'Returns detailed connection pool metrics including state breakdown';

-- ============================================================================
-- Function: get_long_running_connections
-- Description: Find connections that have been open longer than specified duration
-- Returns: Long-running connection details
-- ============================================================================
CREATE OR REPLACE FUNCTION get_long_running_connections(threshold_minutes INTEGER DEFAULT 60)
RETURNS TABLE (
    pid INTEGER,
    user_name TEXT,
    database_name TEXT,
    application_name TEXT,
    client_addr INET,
    backend_start TIMESTAMPTZ,
    connection_age INTERVAL,
    state TEXT,
    current_query TEXT,
    query_start TIMESTAMPTZ,
    query_duration INTERVAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sa.pid,
        sa.usename::TEXT,
        sa.datname::TEXT,
        COALESCE(sa.application_name, 'unknown')::TEXT,
        sa.client_addr,
        sa.backend_start,
        NOW() - sa.backend_start,
        sa.state::TEXT,
        LEFT(sa.query, 200)::TEXT,
        sa.query_start,
        CASE 
            WHEN sa.query_start IS NOT NULL THEN NOW() - sa.query_start
            ELSE NULL
        END
    FROM pg_stat_activity sa
    WHERE sa.pid != pg_backend_pid()
      AND NOW() - sa.backend_start > (threshold_minutes || ' minutes')::INTERVAL
    ORDER BY sa.backend_start;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_long_running_connections(INTEGER) IS 'Returns connections older than the specified threshold in minutes';

-- ============================================================================
-- Function: get_connection_by_client_address
-- Description: Get connections grouped by client IP address
-- Returns: Connection details by client address
-- ============================================================================
CREATE OR REPLACE FUNCTION get_connection_by_client_address()
RETURNS TABLE (
    client_addr TEXT,
    connection_count BIGINT,
    user_names TEXT[],
    application_names TEXT[],
    databases TEXT[],
    states TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(sa.client_addr::TEXT, 'local'),
        COUNT(*)::BIGINT,
        ARRAY_AGG(DISTINCT sa.usename) FILTER (WHERE sa.usename IS NOT NULL),
        ARRAY_AGG(DISTINCT sa.application_name) FILTER (WHERE sa.application_name IS NOT NULL AND sa.application_name != ''),
        ARRAY_AGG(DISTINCT sa.datname) FILTER (WHERE sa.datname IS NOT NULL),
        ARRAY_AGG(DISTINCT sa.state) FILTER (WHERE sa.state IS NOT NULL)
    FROM pg_stat_activity sa
    WHERE sa.pid != pg_backend_pid()
    GROUP BY sa.client_addr
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_connection_by_client_address() IS 'Returns connection statistics grouped by client IP address';

-- ============================================================================
-- Grant execute permissions to authenticated users
-- ============================================================================
GRANT EXECUTE ON FUNCTION check_database_health() TO authenticated;
GRANT EXECUTE ON FUNCTION get_connection_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_ai_agent_connections() TO authenticated;
GRANT EXECUTE ON FUNCTION check_connection_limits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_connection_pool_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_long_running_connections(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_connection_by_client_address() TO authenticated;

-- ============================================================================
-- Create indexes for better performance (if not already present)
-- ============================================================================
-- Note: pg_stat_activity is a system view, no custom indexes needed
-- The monitoring functions use efficient queries against system catalogs

-- ============================================================================
-- End of migration
-- ============================================================================
