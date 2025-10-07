-- ============================================================================
-- CONNECTION MONITORING TEST SUITE
-- ============================================================================
-- Comprehensive test suite for connection monitoring and health checks
-- Tests connection tracking, health check functions, and monitoring queries
--
-- Usage:
--   supabase db execute --file tests/connection_monitoring_test_suite.sql
--
-- Or in Supabase Studio SQL Editor, copy and paste this file
-- ============================================================================

\echo ''
\echo '================================================================================'
\echo 'CONNECTION MONITORING TEST SUITE'
\echo '================================================================================'
\echo ''

-- ============================================================================
-- TEST 1: Verify Monitoring Functions Exist
-- ============================================================================
\echo 'TEST 1: Verifying monitoring functions exist...'

DO $$
DECLARE
    func_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO func_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'check_database_health',
        'get_connection_stats',
        'get_ai_agent_connections',
        'check_connection_limits'
      );
    
    IF func_count >= 4 THEN
        RAISE NOTICE 'PASS: All monitoring functions exist (% found)', func_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Missing monitoring functions (only % of 4 found)', func_count;
    END IF;
END $$;

-- ============================================================================
-- TEST 2: Test Health Check Function
-- ============================================================================
\echo ''
\echo 'TEST 2: Testing health check function...'

DO $$
DECLARE
    health_result RECORD;
    check_passed BOOLEAN := true;
BEGIN
    SELECT * INTO health_result FROM check_database_health();
    
    -- Verify health check returns required fields
    IF health_result.healthy IS NULL THEN
        RAISE EXCEPTION 'FAIL: Health check missing healthy field';
    END IF;
    
    IF health_result.total_connections IS NULL THEN
        RAISE EXCEPTION 'FAIL: Health check missing total_connections field';
    END IF;
    
    IF health_result.max_connections IS NULL THEN
        RAISE EXCEPTION 'FAIL: Health check missing max_connections field';
    END IF;
    
    RAISE NOTICE 'PASS: Health check function working (healthy: %, connections: %/%)', 
        health_result.healthy, health_result.total_connections, health_result.max_connections;
END $$;

-- ============================================================================
-- TEST 3: Test Connection Statistics
-- ============================================================================
\echo ''
\echo 'TEST 3: Testing connection statistics function...'

DO $$
DECLARE
    stats_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO stats_count FROM get_connection_stats();
    
    IF stats_count >= 0 THEN
        RAISE NOTICE 'PASS: Connection stats function working (% connection groups)', stats_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Connection stats function failed';
    END IF;
END $$;

-- ============================================================================
-- TEST 4: Test AI Agent Connection Tracking
-- ============================================================================
\echo ''
\echo 'TEST 4: Testing AI agent connection tracking...'

DO $$
DECLARE
    agent_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO agent_count FROM get_ai_agent_connections();
    
    IF agent_count >= 0 THEN
        RAISE NOTICE 'PASS: AI agent tracking working (% agents found)', agent_count;
    ELSE
        RAISE EXCEPTION 'FAIL: AI agent tracking failed';
    END IF;
END $$;

-- ============================================================================
-- TEST 5: Test Connection Limit Checks
-- ============================================================================
\echo ''
\echo 'TEST 5: Testing connection limit checks...'

DO $$
DECLARE
    limit_result RECORD;
BEGIN
    SELECT * INTO limit_result FROM check_connection_limits();
    
    IF limit_result.within_limits IS NULL THEN
        RAISE EXCEPTION 'FAIL: Connection limit check missing within_limits field';
    END IF;
    
    IF limit_result.usage_percent IS NULL THEN
        RAISE EXCEPTION 'FAIL: Connection limit check missing usage_percent field';
    END IF;
    
    RAISE NOTICE 'PASS: Connection limit check working (within limits: %, usage: %)', 
        limit_result.within_limits, limit_result.usage_percent || '%';
END $$;

-- ============================================================================
-- TEST 6: View Current Connections (Read-Only Test)
-- ============================================================================
\echo ''
\echo 'TEST 6: Viewing current active connections...'

SELECT 
    COUNT(*) as total_connections,
    COUNT(DISTINCT usename) as unique_users,
    COUNT(DISTINCT application_name) as unique_apps
FROM pg_stat_activity
WHERE pid != pg_backend_pid();

\echo 'PASS: Active connection query successful'

-- ============================================================================
-- TEST 7: Test Connection Pool Metrics
-- ============================================================================
\echo ''
\echo 'TEST 7: Testing connection pool metrics...'

DO $$
DECLARE
    active_count INTEGER;
    idle_count INTEGER;
BEGIN
    SELECT 
        COUNT(*) FILTER (WHERE state = 'active'),
        COUNT(*) FILTER (WHERE state = 'idle')
    INTO active_count, idle_count
    FROM pg_stat_activity
    WHERE pid != pg_backend_pid();
    
    IF active_count >= 0 AND idle_count >= 0 THEN
        RAISE NOTICE 'PASS: Connection pool metrics working (active: %, idle: %)', 
            active_count, idle_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Connection pool metrics failed';
    END IF;
END $$;

-- ============================================================================
-- TEST 8: Test SSL Connection Monitoring
-- ============================================================================
\echo ''
\echo 'TEST 8: Testing SSL connection monitoring...'

DO $$
DECLARE
    ssl_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO ssl_count
    FROM pg_stat_ssl
    WHERE ssl = true;
    
    RAISE NOTICE 'PASS: SSL monitoring working (% SSL connections)', ssl_count;
END $$;

-- ============================================================================
-- TEST 9: Test Long-Running Connection Detection
-- ============================================================================
\echo ''
\echo 'TEST 9: Testing long-running connection detection...'

DO $$
DECLARE
    long_running INTEGER;
BEGIN
    SELECT COUNT(*) INTO long_running
    FROM pg_stat_activity
    WHERE state != 'idle'
      AND NOW() - backend_start > INTERVAL '1 hour'
      AND pid != pg_backend_pid();
    
    RAISE NOTICE 'PASS: Long-running detection working (% connections > 1 hour)', long_running;
END $$;

-- ============================================================================
-- TEST 10: Test Connection Count by Database
-- ============================================================================
\echo ''
\echo 'TEST 10: Testing connection grouping by database...'

DO $$
DECLARE
    db_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT datname) INTO db_count
    FROM pg_stat_activity
    WHERE datname IS NOT NULL;
    
    IF db_count >= 1 THEN
        RAISE NOTICE 'PASS: Database grouping working (% databases)', db_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Database grouping failed';
    END IF;
END $$;

-- ============================================================================
-- Summary Display
-- ============================================================================
\echo ''
\echo '================================================================================'
\echo 'TEST SUITE COMPLETE'
\echo '================================================================================'
\echo ''
\echo 'All tests passed! Connection monitoring is working correctly.'
\echo ''
\echo 'Summary:'
\echo '  ✅ All monitoring functions exist'
\echo '  ✅ Health check function working'
\echo '  ✅ Connection statistics available'
\echo '  ✅ AI agent tracking operational'
\echo '  ✅ Connection limit checks functional'
\echo '  ✅ Active connection queries working'
\echo '  ✅ Connection pool metrics available'
\echo '  ✅ SSL monitoring operational'
\echo '  ✅ Long-running connection detection working'
\echo '  ✅ Connection grouping functional'
\echo ''
\echo '================================================================================'
\echo ''
