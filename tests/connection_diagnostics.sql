-- Connection Diagnostics Test Suite
-- Run with: psql "$DATABASE_URL" -f tests/connection_diagnostics.sql
-- Or: supabase db execute --file tests/connection_diagnostics.sql

\echo '=========================================='
\echo 'Connection Diagnostics Test Suite'
\echo '=========================================='
\echo ''

-- Test 1: Basic Connection
\echo '----------------------------------------'
\echo 'Test 1: Basic Connection'
\echo '----------------------------------------'
SELECT 
    CASE 
        WHEN 1 = 1 THEN 'PASS - Database connection successful'
        ELSE 'FAIL - Database connection failed'
    END as result;
\echo ''

-- Test 2: Database Information
\echo '----------------------------------------'
\echo 'Test 2: Database Information'
\echo '----------------------------------------'
SELECT 
    current_database() as database_name,
    current_user as connected_user,
    inet_server_addr() as server_address,
    inet_server_port() as server_port,
    version() as postgresql_version;
\echo ''

-- Test 3: SSL Connection Status
\echo '----------------------------------------'
\echo 'Test 3: SSL Connection Status'
\echo '----------------------------------------'
SELECT 
    pid,
    CASE WHEN ssl THEN 'PASS - SSL Enabled' ELSE 'WARN - SSL Disabled' END as ssl_status,
    version as ssl_version,
    cipher as ssl_cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
\echo ''

-- Test 4: Connection Limits
\echo '----------------------------------------'
\echo 'Test 4: Connection Limits'
\echo '----------------------------------------'
SELECT 
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections,
    (SELECT count(*) FROM pg_stat_activity) as current_connections,
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - 
        (SELECT count(*) FROM pg_stat_activity) as available_connections,
    CASE 
        WHEN (SELECT count(*) FROM pg_stat_activity) * 100 / 
             (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') < 60
        THEN 'PASS - Connection usage is healthy'
        WHEN (SELECT count(*) FROM pg_stat_activity) * 100 / 
             (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') < 80
        THEN 'WARN - Connection usage is moderate'
        ELSE 'FAIL - Connection usage is critical'
    END as status;
\echo ''

-- Test 5: Active Connections Breakdown
\echo '----------------------------------------'
\echo 'Test 5: Active Connections Breakdown'
\echo '----------------------------------------'
SELECT 
    state,
    count(*) as connection_count,
    round(100.0 * count(*) / (SELECT count(*) FROM pg_stat_activity), 2) as percentage
FROM pg_stat_activity
GROUP BY state
ORDER BY connection_count DESC;
\echo ''

-- Test 6: Long-Running Queries
\echo '----------------------------------------'
\echo 'Test 6: Long-Running Queries'
\echo '----------------------------------------'
DO $$
DECLARE
    long_query_count int;
BEGIN
    SELECT count(*) INTO long_query_count
    FROM pg_stat_activity
    WHERE state = 'active'
      AND now() - query_start > interval '30 seconds'
      AND query NOT LIKE '%pg_stat_activity%';
    
    IF long_query_count > 0 THEN
        RAISE WARNING 'WARN - Found % long-running queries (>30s)', long_query_count;
    ELSE
        RAISE NOTICE 'PASS - No long-running queries detected';
    END IF;
END $$;

SELECT 
    pid,
    usename,
    application_name,
    now() - query_start as duration,
    left(query, 100) as query
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - query_start > interval '30 seconds'
  AND query NOT LIKE '%pg_stat_activity%'
ORDER BY query_start
LIMIT 5;
\echo ''

-- Test 7: Idle in Transaction
\echo '----------------------------------------'
\echo 'Test 7: Idle in Transaction Connections'
\echo '----------------------------------------'
DO $$
DECLARE
    idle_trans_count int;
BEGIN
    SELECT count(*) INTO idle_trans_count
    FROM pg_stat_activity
    WHERE state = 'idle in transaction';
    
    IF idle_trans_count > 0 THEN
        RAISE WARNING 'WARN - Found % connections idle in transaction', idle_trans_count;
    ELSE
        RAISE NOTICE 'PASS - No idle in transaction connections';
    END IF;
END $$;

SELECT 
    pid,
    usename,
    application_name,
    now() - state_change as idle_duration,
    left(query, 100) as last_query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
ORDER BY state_change
LIMIT 5;
\echo ''

-- Test 8: Database Locks
\echo '----------------------------------------'
\echo 'Test 8: Database Locks'
\echo '----------------------------------------'
DO $$
DECLARE
    blocked_count int;
BEGIN
    SELECT count(*) INTO blocked_count
    FROM pg_locks
    WHERE granted = false;
    
    IF blocked_count > 0 THEN
        RAISE WARNING 'WARN - Found % blocked queries waiting for locks', blocked_count;
    ELSE
        RAISE NOTICE 'PASS - No blocked queries';
    END IF;
END $$;

SELECT 
    locktype,
    database,
    relation::regclass as table_name,
    mode,
    granted,
    count(*) as lock_count
FROM pg_locks
WHERE NOT granted
GROUP BY locktype, database, relation, mode, granted
LIMIT 10;
\echo ''

-- Test 9: RLS Configuration
\echo '----------------------------------------'
\echo 'Test 9: Row Level Security (RLS) Status'
\echo '----------------------------------------'
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN 'Enabled'
        ELSE 'Disabled'
    END as rls_status,
    (SELECT count(*) 
     FROM pg_policies 
     WHERE schemaname = pt.schemaname 
       AND tablename = pt.tablename) as policy_count
FROM pg_tables pt
WHERE schemaname = 'public'
ORDER BY tablename
LIMIT 10;
\echo ''

-- Test 10: Table Permissions
\echo '----------------------------------------'
\echo 'Test 10: Table Permissions (Current User)'
\echo '----------------------------------------'
SELECT 
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee = current_user
  AND table_schema = 'public'
ORDER BY table_name, privilege_type
LIMIT 20;
\echo ''

-- Test 11: Database Size
\echo '----------------------------------------'
\echo 'Test 11: Database Size'
\echo '----------------------------------------'
SELECT 
    current_database() as database,
    pg_size_pretty(pg_database_size(current_database())) as size,
    CASE 
        WHEN pg_database_size(current_database()) < 500 * 1024 * 1024 
        THEN 'PASS - Database size is small'
        WHEN pg_database_size(current_database()) < 8 * 1024 * 1024 * 1024 
        THEN 'PASS - Database size is moderate'
        ELSE 'WARN - Database size is large'
    END as status;
\echo ''

-- Test 12: Cache Hit Ratio
\echo '----------------------------------------'
\echo 'Test 12: Cache Performance'
\echo '----------------------------------------'
SELECT 
    'Buffer Cache' as cache_type,
    round(100.0 * sum(heap_blks_hit) / 
        NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) as hit_ratio_percent,
    CASE 
        WHEN round(100.0 * sum(heap_blks_hit) / 
            NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) >= 95 
        THEN 'PASS - Excellent cache performance'
        WHEN round(100.0 * sum(heap_blks_hit) / 
            NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) >= 90 
        THEN 'PASS - Good cache performance'
        WHEN round(100.0 * sum(heap_blks_hit) / 
            NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) >= 80 
        THEN 'WARN - Moderate cache performance'
        ELSE 'FAIL - Poor cache performance'
    END as status
FROM pg_statio_user_tables
UNION ALL
SELECT 
    'Index Cache' as cache_type,
    round(100.0 * sum(idx_blks_hit) / 
        NULLIF(sum(idx_blks_hit) + sum(idx_blks_read), 0), 2) as hit_ratio_percent,
    CASE 
        WHEN round(100.0 * sum(idx_blks_hit) / 
            NULLIF(sum(idx_blks_hit) + sum(idx_blks_read), 0), 2) >= 95 
        THEN 'PASS - Excellent cache performance'
        WHEN round(100.0 * sum(idx_blks_hit) / 
            NULLIF(sum(idx_blks_hit) + sum(idx_blks_read), 0), 2) >= 90 
        THEN 'PASS - Good cache performance'
        ELSE 'WARN - Consider optimizing indexes'
    END as status
FROM pg_statio_user_indexes;
\echo ''

-- Test 13: Replication Status (if applicable)
\echo '----------------------------------------'
\echo 'Test 13: Replication Status'
\echo '----------------------------------------'
SELECT 
    CASE 
        WHEN count(*) > 0 THEN 'INFO - Replication is configured'
        ELSE 'INFO - No replication configured'
    END as status,
    count(*) as replica_count
FROM pg_stat_replication;

SELECT 
    application_name,
    client_addr,
    state,
    sync_state,
    replay_lag
FROM pg_stat_replication
LIMIT 5;
\echo ''

-- Test 14: Prepared Statements Support
\echo '----------------------------------------'
\echo 'Test 14: Prepared Statements Support'
\echo '----------------------------------------'
DO $$
DECLARE
    test_result text;
BEGIN
    -- Try to create a prepared statement
    BEGIN
        PREPARE diagnostic_test AS SELECT 1;
        EXECUTE diagnostic_test;
        DEALLOCATE diagnostic_test;
        RAISE NOTICE 'PASS - Prepared statements are supported (Session mode)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'WARN - Prepared statements not supported (Transaction mode)';
    END;
END $$;
\echo ''

-- Test 15: Extension Availability
\echo '----------------------------------------'
\echo 'Test 15: Available Extensions'
\echo '----------------------------------------'
SELECT 
    name,
    default_version,
    installed_version,
    CASE 
        WHEN installed_version IS NOT NULL THEN 'Installed'
        ELSE 'Available'
    END as status
FROM pg_available_extensions
WHERE name IN ('pg_stat_statements', 'pgcrypto', 'uuid-ossp', 'pg_trgm', 'btree_gin', 'btree_gist')
ORDER BY name;
\echo ''

-- Summary
\echo '=========================================='
\echo 'Diagnostic Summary'
\echo '=========================================='
\echo ''

DO $$
DECLARE
    conn_usage_pct int;
    long_queries int;
    idle_trans int;
    locks_blocked int;
BEGIN
    -- Calculate metrics
    SELECT (SELECT count(*) FROM pg_stat_activity) * 100 / 
           (SELECT setting::int FROM pg_settings WHERE name = 'max_connections')
    INTO conn_usage_pct;
    
    SELECT count(*) INTO long_queries
    FROM pg_stat_activity
    WHERE state = 'active'
      AND now() - query_start > interval '30 seconds'
      AND query NOT LIKE '%pg_stat_activity%';
    
    SELECT count(*) INTO idle_trans
    FROM pg_stat_activity
    WHERE state = 'idle in transaction';
    
    SELECT count(*) INTO locks_blocked
    FROM pg_locks
    WHERE NOT granted;
    
    -- Print summary
    RAISE NOTICE '';
    RAISE NOTICE 'Connection Usage: %% (%)', 
        conn_usage_pct,
        CASE 
            WHEN conn_usage_pct < 60 THEN 'Healthy'
            WHEN conn_usage_pct < 80 THEN 'Moderate'
            ELSE 'Critical'
        END;
    
    RAISE NOTICE 'Long-Running Queries: % (%)',
        long_queries,
        CASE WHEN long_queries = 0 THEN 'None' ELSE 'Review needed' END;
    
    RAISE NOTICE 'Idle in Transaction: % (%)',
        idle_trans,
        CASE WHEN idle_trans = 0 THEN 'None' ELSE 'Review needed' END;
    
    RAISE NOTICE 'Blocked Locks: % (%)',
        locks_blocked,
        CASE WHEN locks_blocked = 0 THEN 'None' ELSE 'Review needed' END;
    
    RAISE NOTICE '';
    
    IF conn_usage_pct < 80 AND long_queries = 0 AND idle_trans = 0 AND locks_blocked = 0 THEN
        RAISE NOTICE '✓ Overall Status: HEALTHY';
    ELSIF conn_usage_pct >= 80 OR long_queries > 0 OR idle_trans > 0 OR locks_blocked > 0 THEN
        RAISE NOTICE '⚠ Overall Status: NEEDS ATTENTION';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'For troubleshooting guidance, see: docs/MCP_TROUBLESHOOTING.md';
END $$;

\echo ''
\echo 'Diagnostics Complete!'
\echo ''
