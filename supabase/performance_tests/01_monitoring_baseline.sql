-- Performance Monitoring Baseline
-- Run this to establish baseline metrics for your database
-- Execute: supabase db execute --file supabase/performance_tests/01_monitoring_baseline.sql

\echo ''
\echo '================================================================================'
\echo 'PERFORMANCE MONITORING BASELINE'
\echo '================================================================================'
\echo ''

-- 1. Database Overview
\echo '1. Database Overview'
\echo '----------------------------'
SELECT * FROM public.performance_overview;
\echo ''

-- 2. Cache Hit Ratio (Target: > 99%)
\echo '2. Cache Hit Ratio'
\echo '----------------------------'
SELECT 
    metric,
    ratio || '%' as ratio_percentage,
    status
FROM public.get_cache_hit_ratio();
\echo ''

-- 3. Table Statistics
\echo '3. Table Statistics (Size and Row Counts)'
\echo '----------------------------'
SELECT 
    table_name,
    total_size,
    table_size,
    indexes_size,
    row_count,
    live_rows,
    dead_rows,
    CASE 
        WHEN live_rows > 0 
        THEN ROUND(100.0 * dead_rows / live_rows, 2) 
        ELSE 0 
    END as dead_ratio_percent
FROM public.get_table_stats()
ORDER BY pg_total_relation_size('public.' || table_name) DESC;
\echo ''

-- 4. Index Usage Statistics
\echo '4. Index Usage Statistics'
\echo '----------------------------'
SELECT 
    table_name,
    index_name,
    index_size,
    index_scans,
    rows_read,
    rows_fetched,
    CASE 
        WHEN index_scans = 0 THEN '⚠️  Never used'
        WHEN index_scans < 100 THEN '⚡ Low usage'
        ELSE '✅ Active'
    END as usage_status
FROM public.get_index_stats()
ORDER BY index_scans DESC;
\echo ''

-- 5. Potential Missing Indexes
\echo '5. Potential Missing Indexes'
\echo '----------------------------'
SELECT 
    table_name,
    seq_scans,
    seq_rows_read,
    index_scans,
    row_estimate,
    recommendation
FROM public.get_missing_indexes()
ORDER BY seq_rows_read DESC;
\echo ''

-- 6. Connection Statistics
\echo '6. Active Connections'
\echo '----------------------------'
SELECT 
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active,
    COUNT(*) FILTER (WHERE state = 'idle') as idle,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity
WHERE datname = current_database();
\echo ''

-- 7. Transaction Statistics
\echo '7. Transaction Statistics'
\echo '----------------------------'
SELECT 
    xact_commit as commits,
    xact_rollback as rollbacks,
    ROUND(100.0 * xact_commit / NULLIF(xact_commit + xact_rollback, 0), 2) as commit_ratio_percent,
    blks_read as disk_blocks_read,
    blks_hit as cache_blocks_hit,
    tup_returned as rows_returned,
    tup_fetched as rows_fetched,
    tup_inserted as rows_inserted,
    tup_updated as rows_updated,
    tup_deleted as rows_deleted
FROM pg_stat_database
WHERE datname = current_database();
\echo ''

-- 8. Table Bloat Check
\echo '8. Table Bloat Check (Dead Rows)'
\echo '----------------------------'
SELECT 
    schemaname,
    tablename,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    ROUND(100 * n_dead_tup::NUMERIC / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_ratio_percent,
    last_vacuum,
    last_autovacuum,
    CASE 
        WHEN n_dead_tup::NUMERIC / NULLIF(n_live_tup, 0) > 0.2 
        THEN '⚠️  High - Consider VACUUM'
        WHEN n_dead_tup::NUMERIC / NULLIF(n_live_tup, 0) > 0.1 
        THEN '⚡ Moderate - Monitor'
        ELSE '✅ OK'
    END as bloat_status
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;
\echo ''

-- 9. Checkpoint Activity
\echo '9. Background Writer Stats'
\echo '----------------------------'
SELECT 
    checkpoints_timed as scheduled_checkpoints,
    checkpoints_req as requested_checkpoints,
    buffers_checkpoint as buffers_written_checkpoint,
    buffers_clean as buffers_written_bgwriter,
    maxwritten_clean as bgwriter_stops,
    buffers_backend as buffers_written_backend
FROM pg_stat_bgwriter;
\echo ''

-- 10. Summary
\echo '================================================================================'
\echo 'BASELINE SUMMARY'
\echo '================================================================================'
\echo ''
\echo 'Next Steps:'
\echo '  1. Review cache hit ratio - should be > 99%'
\echo '  2. Check for tables with high dead row ratios - may need VACUUM'
\echo '  3. Review indexes with 0 scans - consider dropping unused indexes'
\echo '  4. Check for missing indexes on frequently scanned tables'
\echo '  5. Run 02_query_performance.sql to test specific queries'
\echo ''
\echo 'Save these baseline metrics for comparison over time!'
\echo '================================================================================'
