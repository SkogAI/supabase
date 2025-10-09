-- Connection Pool Monitoring Queries
-- Run with: psql "$DATABASE_URL" -f tests/pool_monitoring.sql
-- Or: supabase db execute --file tests/pool_monitoring.sql

\echo '=========================================='
\echo 'Connection Pool Monitoring'
\echo '=========================================='
\echo ''

-- Current Connection Summary
\echo '----------------------------------------'
\echo '1. Connection Summary'
\echo '----------------------------------------'
SELECT 
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections,
    count(*) as total_connections,
    count(*) FILTER (WHERE state = 'active') as active,
    count(*) FILTER (WHERE state = 'idle') as idle,
    count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
    count(*) FILTER (WHERE state = 'idle in transaction (aborted)') as idle_in_transaction_aborted,
    count(*) FILTER (WHERE state = 'fastpath function call') as fastpath,
    count(*) FILTER (WHERE state = 'disabled') as disabled,
    round(100.0 * count(*) / (SELECT setting::int FROM pg_settings WHERE name = 'max_connections'), 2) as usage_percent
FROM pg_stat_activity;
\echo ''

-- Connections by User
\echo '----------------------------------------'
\echo '2. Connections by User'
\echo '----------------------------------------'
SELECT 
    usename as username,
    count(*) as connection_count,
    count(*) FILTER (WHERE state = 'active') as active,
    count(*) FILTER (WHERE state = 'idle') as idle,
    max(now() - query_start) FILTER (WHERE state = 'active') as longest_active_query
FROM pg_stat_activity
WHERE usename IS NOT NULL
GROUP BY usename
ORDER BY connection_count DESC;
\echo ''

-- Connections by Application
\echo '----------------------------------------'
\echo '3. Connections by Application'
\echo '----------------------------------------'
SELECT 
    COALESCE(application_name, 'unknown') as application,
    count(*) as connection_count,
    count(*) FILTER (WHERE state = 'active') as active,
    count(*) FILTER (WHERE state = 'idle') as idle
FROM pg_stat_activity
GROUP BY application_name
ORDER BY connection_count DESC
LIMIT 10;
\echo ''

-- Connections by Client Address
\echo '----------------------------------------'
\echo '4. Connections by Client Address'
\echo '----------------------------------------'
SELECT 
    COALESCE(client_addr::text, 'local') as client_address,
    count(*) as connection_count,
    count(*) FILTER (WHERE state = 'active') as active,
    count(*) FILTER (WHERE state = 'idle') as idle
FROM pg_stat_activity
GROUP BY client_addr
ORDER BY connection_count DESC
LIMIT 10;
\echo ''

-- Connection Age Distribution
\echo '----------------------------------------'
\echo '5. Connection Age Distribution'
\echo '----------------------------------------'
SELECT 
    CASE 
        WHEN now() - backend_start < interval '1 minute' THEN '< 1 min'
        WHEN now() - backend_start < interval '5 minutes' THEN '1-5 min'
        WHEN now() - backend_start < interval '15 minutes' THEN '5-15 min'
        WHEN now() - backend_start < interval '1 hour' THEN '15-60 min'
        WHEN now() - backend_start < interval '6 hours' THEN '1-6 hours'
        ELSE '> 6 hours'
    END as age_range,
    count(*) as connection_count
FROM pg_stat_activity
GROUP BY age_range
ORDER BY 
    CASE age_range
        WHEN '< 1 min' THEN 1
        WHEN '1-5 min' THEN 2
        WHEN '5-15 min' THEN 3
        WHEN '15-60 min' THEN 4
        WHEN '1-6 hours' THEN 5
        ELSE 6
    END;
\echo ''

-- Active Query Duration
\echo '----------------------------------------'
\echo '6. Active Query Duration'
\echo '----------------------------------------'
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    now() - query_start as duration,
    state,
    left(query, 100) as query
FROM pg_stat_activity
WHERE state = 'active'
  AND query NOT LIKE '%pg_stat_activity%'
ORDER BY query_start
LIMIT 15;
\echo ''

-- Idle Connections
\echo '----------------------------------------'
\echo '7. Long Idle Connections'
\echo '----------------------------------------'
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    now() - state_change as idle_duration,
    left(query, 80) as last_query
FROM pg_stat_activity
WHERE state = 'idle'
  AND now() - state_change > interval '5 minutes'
ORDER BY state_change
LIMIT 15;
\echo ''

-- Idle in Transaction
\echo '----------------------------------------'
\echo '8. Idle in Transaction (Connection Leaks)'
\echo '----------------------------------------'
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    now() - state_change as idle_duration,
    now() - xact_start as transaction_duration,
    left(query, 100) as last_query
FROM pg_stat_activity
WHERE state IN ('idle in transaction', 'idle in transaction (aborted)')
ORDER BY state_change
LIMIT 15;
\echo ''

-- Connection Pool Health Metrics
\echo '----------------------------------------'
\echo '9. Pool Health Metrics'
\echo '----------------------------------------'
DO $$
DECLARE
    v_max_conn int;
    v_total_conn int;
    v_active_conn int;
    v_idle_conn int;
    v_idle_in_trans int;
    v_long_queries int;
    v_usage_pct numeric;
    v_health_status text;
BEGIN
    SELECT setting::int INTO v_max_conn 
    FROM pg_settings WHERE name = 'max_connections';
    
    SELECT count(*) INTO v_total_conn FROM pg_stat_activity;
    
    SELECT count(*) INTO v_active_conn 
    FROM pg_stat_activity WHERE state = 'active';
    
    SELECT count(*) INTO v_idle_conn 
    FROM pg_stat_activity WHERE state = 'idle';
    
    SELECT count(*) INTO v_idle_in_trans 
    FROM pg_stat_activity WHERE state LIKE 'idle in transaction%';
    
    SELECT count(*) INTO v_long_queries 
    FROM pg_stat_activity 
    WHERE state = 'active' 
      AND now() - query_start > interval '30 seconds';
    
    v_usage_pct := round(100.0 * v_total_conn / v_max_conn, 2);
    
    -- Determine health status
    IF v_usage_pct < 60 AND v_idle_in_trans = 0 AND v_long_queries = 0 THEN
        v_health_status := 'HEALTHY';
    ELSIF v_usage_pct < 80 AND v_idle_in_trans < 5 AND v_long_queries < 3 THEN
        v_health_status := 'MODERATE';
    ELSE
        v_health_status := 'CRITICAL';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Pool Health Status: %', v_health_status;
    RAISE NOTICE '-----------------------------------';
    RAISE NOTICE 'Max Connections: %', v_max_conn;
    RAISE NOTICE 'Total Connections: % (%.2f%% used)', v_total_conn, v_usage_pct;
    RAISE NOTICE 'Active: %', v_active_conn;
    RAISE NOTICE 'Idle: %', v_idle_conn;
    RAISE NOTICE 'Idle in Transaction: %', v_idle_in_trans;
    RAISE NOTICE 'Long-Running Queries (>30s): %', v_long_queries;
    RAISE NOTICE '';
    
    IF v_health_status = 'CRITICAL' THEN
        RAISE NOTICE 'ALERTS:';
        IF v_usage_pct >= 80 THEN
            RAISE NOTICE '  ⚠ Connection pool usage is high (%.2f%%)', v_usage_pct;
            RAISE NOTICE '    Consider: Closing idle connections, upgrading compute tier';
        END IF;
        IF v_idle_in_trans > 0 THEN
            RAISE NOTICE '  ⚠ Found % connections idle in transaction', v_idle_in_trans;
            RAISE NOTICE '    Consider: Reviewing application connection handling';
        END IF;
        IF v_long_queries > 0 THEN
            RAISE NOTICE '  ⚠ Found % long-running queries', v_long_queries;
            RAISE NOTICE '    Consider: Optimizing queries or setting timeouts';
        END IF;
    ELSIF v_health_status = 'MODERATE' THEN
        RAISE NOTICE 'WARNINGS:';
        RAISE NOTICE '  Pool usage is moderate, monitor closely';
    ELSE
        RAISE NOTICE '✓ Pool health is good';
    END IF;
END $$;
\echo ''

-- Connection Settings
\echo '----------------------------------------'
\echo '10. Connection-Related Settings'
\echo '----------------------------------------'
SELECT 
    name,
    setting,
    unit,
    short_desc
FROM pg_settings
WHERE name IN (
    'max_connections',
    'superuser_reserved_connections',
    'idle_in_transaction_session_timeout',
    'statement_timeout',
    'lock_timeout',
    'max_locks_per_transaction',
    'max_prepared_transactions'
)
ORDER BY name;
\echo ''

-- Connection Rate (approximation)
\echo '----------------------------------------'
\echo '11. Recent Connection Activity'
\echo '----------------------------------------'
SELECT 
    CASE 
        WHEN now() - backend_start < interval '1 minute' THEN 'Last 1 minute'
        WHEN now() - backend_start < interval '5 minutes' THEN 'Last 5 minutes'
        WHEN now() - backend_start < interval '15 minutes' THEN 'Last 15 minutes'
        WHEN now() - backend_start < interval '1 hour' THEN 'Last hour'
        ELSE 'Older'
    END as period,
    count(*) as new_connections
FROM pg_stat_activity
GROUP BY period
ORDER BY 
    CASE period
        WHEN 'Last 1 minute' THEN 1
        WHEN 'Last 5 minutes' THEN 2
        WHEN 'Last 15 minutes' THEN 3
        WHEN 'Last hour' THEN 4
        ELSE 5
    END;
\echo ''

-- Database Statistics
\echo '----------------------------------------'
\echo '12. Database Connection Statistics'
\echo '----------------------------------------'
SELECT 
    datname as database,
    numbackends as active_connections,
    xact_commit as transactions_committed,
    xact_rollback as transactions_rolled_back,
    round(100.0 * xact_rollback / NULLIF(xact_commit + xact_rollback, 0), 2) as rollback_rate_percent,
    blks_read as blocks_read,
    blks_hit as blocks_hit,
    round(100.0 * blks_hit / NULLIF(blks_read + blks_hit, 0), 2) as cache_hit_rate_percent
FROM pg_stat_database
WHERE datname = current_database();
\echo ''

-- Recommendations
\echo '=========================================='
\echo 'Recommendations'
\echo '=========================================='
\echo ''

DO $$
DECLARE
    v_usage_pct numeric;
    v_idle_in_trans int;
    v_long_idle int;
    v_cache_hit numeric;
BEGIN
    -- Calculate metrics
    SELECT round(100.0 * count(*) / (SELECT setting::int FROM pg_settings WHERE name = 'max_connections'), 2)
    INTO v_usage_pct
    FROM pg_stat_activity;
    
    SELECT count(*) INTO v_idle_in_trans
    FROM pg_stat_activity
    WHERE state LIKE 'idle in transaction%';
    
    SELECT count(*) INTO v_long_idle
    FROM pg_stat_activity
    WHERE state = 'idle'
      AND now() - state_change > interval '5 minutes';
    
    SELECT round(100.0 * sum(blks_hit) / NULLIF(sum(blks_read + blks_hit), 0), 2)
    INTO v_cache_hit
    FROM pg_stat_database
    WHERE datname = current_database();
    
    RAISE NOTICE '';
    
    -- Generate recommendations
    IF v_usage_pct >= 80 THEN
        RAISE NOTICE '⚠ High connection usage (%.2f%%)', v_usage_pct;
        RAISE NOTICE '  → Reduce connection pool size in applications';
        RAISE NOTICE '  → Use connection pooler (Supavisor)';
        RAISE NOTICE '  → Upgrade compute tier';
        RAISE NOTICE '';
    END IF;
    
    IF v_idle_in_trans > 0 THEN
        RAISE NOTICE '⚠ Found % idle in transaction connections', v_idle_in_trans;
        RAISE NOTICE '  → Review application transaction handling';
        RAISE NOTICE '  → Ensure connections are released after use';
        RAISE NOTICE '  → Set idle_in_transaction_session_timeout';
        RAISE NOTICE '';
    END IF;
    
    IF v_long_idle >= 10 THEN
        RAISE NOTICE '⚠ Found % long idle connections', v_long_idle;
        RAISE NOTICE '  → Reduce connection pool idle timeout';
        RAISE NOTICE '  → Close idle connections after 30 seconds';
        RAISE NOTICE '  → Use transaction mode pooler for serverless';
        RAISE NOTICE '';
    END IF;
    
    IF v_cache_hit < 90 THEN
        RAISE NOTICE '⚠ Low cache hit rate (%.2f%%)', v_cache_hit;
        RAISE NOTICE '  → Consider increasing shared_buffers';
        RAISE NOTICE '  → Review query performance';
        RAISE NOTICE '  → Add appropriate indexes';
        RAISE NOTICE '';
    END IF;
    
    IF v_usage_pct < 60 AND v_idle_in_trans = 0 AND v_long_idle < 5 THEN
        RAISE NOTICE '✓ Connection pool is healthy - no issues detected';
        RAISE NOTICE '';
    END IF;
    
    RAISE NOTICE 'For more troubleshooting help, see: docs/MCP_TROUBLESHOOTING.md';
END $$;

\echo ''
\echo 'Pool Monitoring Complete!'
\echo ''
