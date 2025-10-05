-- Cache Hit Ratio and Database Statistics
-- Monitors buffer cache efficiency and overall database health
-- Execute: supabase db execute --file supabase/performance_tests/05_cache_and_stats.sql

\echo ''
\echo '================================================================================'
\echo 'CACHE HIT RATIO AND DATABASE STATISTICS'
\echo '================================================================================'
\echo ''

-- 1. Overall cache hit ratio
\echo '1. Buffer Cache Hit Ratio'
\echo '----------------------------'
\echo 'Target: > 99% (Excellent), > 95% (Good)'
\echo ''
SELECT * FROM public.get_cache_hit_ratio();
\echo ''

-- 2. Detailed cache statistics
\echo '2. Detailed Cache Statistics'
\echo '----------------------------'
SELECT 
    datname as database,
    numbackends as connections,
    xact_commit as transactions_committed,
    xact_rollback as transactions_rolled_back,
    blks_read as disk_blocks_read,
    blks_hit as cache_blocks_hit,
    ROUND(
        100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 
        2
    ) as cache_hit_ratio_percent,
    tup_returned as rows_returned,
    tup_fetched as rows_fetched,
    tup_inserted as rows_inserted,
    tup_updated as rows_updated,
    tup_deleted as rows_deleted,
    temp_files as temp_files_created,
    pg_size_pretty(temp_bytes) as temp_data_size
FROM pg_stat_database
WHERE datname = current_database();
\echo ''

-- 3. Table-level cache statistics
\echo '3. Table-Level Cache Statistics'
\echo '----------------------------'
SELECT 
    schemaname,
    tablename,
    heap_blks_read as table_blocks_from_disk,
    heap_blks_hit as table_blocks_from_cache,
    ROUND(
        100.0 * heap_blks_hit / NULLIF(heap_blks_hit + heap_blks_read, 0),
        2
    ) as table_cache_hit_ratio,
    idx_blks_read as index_blocks_from_disk,
    idx_blks_hit as index_blocks_from_cache,
    ROUND(
        100.0 * idx_blks_hit / NULLIF(idx_blks_hit + idx_blks_read, 0),
        2
    ) as index_cache_hit_ratio
FROM pg_statio_user_tables
WHERE schemaname = 'public'
    AND (heap_blks_read + heap_blks_hit + idx_blks_read + idx_blks_hit) > 0
ORDER BY (heap_blks_read + idx_blks_read) DESC;
\echo ''

-- 4. Index cache performance
\echo '4. Index Cache Performance'
\echo '----------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_blks_read as index_disk_reads,
    idx_blks_hit as index_cache_hits,
    ROUND(
        100.0 * idx_blks_hit / NULLIF(idx_blks_hit + idx_blks_read, 0),
        2
    ) as cache_hit_ratio
FROM pg_statio_user_indexes
WHERE schemaname = 'public'
    AND (idx_blks_read + idx_blks_hit) > 0
ORDER BY idx_blks_read DESC;
\echo ''

-- 5. Shared buffer usage
\echo '5. Shared Buffer Usage'
\echo '----------------------------'
SELECT 
    name,
    setting,
    unit,
    short_desc
FROM pg_settings
WHERE name IN (
    'shared_buffers',
    'effective_cache_size',
    'work_mem',
    'maintenance_work_mem',
    'max_connections'
)
ORDER BY name;
\echo ''

-- 6. Buffer usage by table
\echo '6. Buffer Usage by Table'
\echo '----------------------------'
\echo 'Shows which tables consume the most buffer cache'
\echo ''
SELECT 
    c.relname as table_name,
    pg_size_pretty(pg_relation_size(c.oid)) as table_size,
    count(*) as buffers,
    pg_size_pretty(count(*) * 8192) as buffer_size,
    ROUND(100.0 * count(*) / (SELECT setting::INTEGER FROM pg_settings WHERE name='shared_buffers')::NUMERIC, 2) as percent_of_cache
FROM pg_class c
INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
INNER JOIN pg_database d ON b.reldatabase = d.oid AND d.datname = current_database()
WHERE c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
GROUP BY c.relname, c.oid
ORDER BY count(*) DESC;
\echo ''

-- 7. Database size and growth
\echo '7. Database Size Statistics'
\echo '----------------------------'
SELECT 
    pg_size_pretty(pg_database_size(current_database())) as database_size,
    (SELECT pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))::BIGINT)
     FROM pg_tables WHERE schemaname = 'public') as tables_size,
    (SELECT pg_size_pretty(SUM(pg_relation_size(indexrelid))::BIGINT)
     FROM pg_stat_user_indexes WHERE schemaname = 'public') as indexes_size,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') as table_count,
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public') as index_count;
\echo ''

-- 8. Checkpoint and background writer stats
\echo '8. Background Writer and Checkpoint Statistics'
\echo '----------------------------'
SELECT 
    checkpoints_timed as scheduled_checkpoints,
    checkpoints_req as requested_checkpoints,
    checkpoint_write_time as checkpoint_write_time_ms,
    checkpoint_sync_time as checkpoint_sync_time_ms,
    buffers_checkpoint,
    buffers_clean,
    maxwritten_clean as bgwriter_halts,
    buffers_backend,
    buffers_backend_fsync,
    buffers_alloc,
    stats_reset
FROM pg_stat_bgwriter;
\echo ''

-- 9. Transaction statistics
\echo '9. Transaction Statistics'
\echo '----------------------------'
SELECT 
    datname,
    xact_commit as commits,
    xact_rollback as rollbacks,
    ROUND(100.0 * xact_commit / NULLIF(xact_commit + xact_rollback, 0), 2) as commit_ratio_percent,
    deadlocks,
    conflicts,
    temp_files,
    pg_size_pretty(temp_bytes) as temp_bytes
FROM pg_stat_database
WHERE datname = current_database();
\echo ''

-- 10. Active queries and connections
\echo '10. Current Database Activity'
\echo '----------------------------'
SELECT 
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active,
    COUNT(*) FILTER (WHERE state = 'idle') as idle,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
    COUNT(*) FILTER (WHERE wait_event IS NOT NULL) as waiting
FROM pg_stat_activity
WHERE datname = current_database();
\echo ''

-- 11. Long-running queries
\echo '11. Long-Running Queries (> 1 minute)'
\echo '----------------------------'
SELECT 
    pid,
    usename,
    application_name,
    state,
    now() - query_start as duration,
    wait_event_type,
    wait_event,
    LEFT(query, 100) as query_sample
FROM pg_stat_activity
WHERE datname = current_database()
    AND state != 'idle'
    AND query_start < now() - interval '1 minute'
ORDER BY duration DESC;
\echo ''

-- 12. Lock information
\echo '12. Current Locks'
\echo '----------------------------'
SELECT 
    locktype,
    relation::regclass as relation,
    mode,
    granted,
    COUNT(*) as count
FROM pg_locks
WHERE database = (SELECT oid FROM pg_database WHERE datname = current_database())
GROUP BY locktype, relation, mode, granted
ORDER BY count DESC;
\echo ''

-- 13. Vacuum and analyze statistics
\echo '13. Last Vacuum/Analyze Times'
\echo '----------------------------'
SELECT 
    schemaname,
    tablename,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    n_tup_ins as inserts_since_analyze,
    n_tup_upd as updates_since_analyze,
    n_tup_del as deletes_since_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY tablename;
\echo ''

-- 14. Cache efficiency recommendations
\echo '================================================================================'
\echo 'CACHE EFFICIENCY RECOMMENDATIONS'
\echo '================================================================================'
\echo ''

WITH cache_stats AS (
    SELECT 
        ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) as hit_ratio
    FROM pg_stat_database
    WHERE datname = current_database()
)
SELECT 
    CASE 
        WHEN hit_ratio >= 99 THEN '✅ Excellent cache performance!'
        WHEN hit_ratio >= 95 THEN '✓ Good cache performance'
        WHEN hit_ratio >= 90 THEN '⚠️  Cache performance could be improved'
        ELSE '❌ Poor cache performance - action required'
    END as status,
    hit_ratio || '%' as current_hit_ratio,
    CASE 
        WHEN hit_ratio >= 99 THEN 'No action needed. Cache is performing optimally.'
        WHEN hit_ratio >= 95 THEN 'Monitor cache usage. Consider tuning if it degrades.'
        WHEN hit_ratio >= 90 THEN 
            'Consider: 1) Increasing shared_buffers, 2) Adding indexes, 3) Optimizing queries'
        ELSE 
            'Action required: 1) Review query performance, 2) Add missing indexes, ' ||
            '3) Increase shared_buffers, 4) Check for sequential scans'
    END as recommendation
FROM cache_stats;
\echo ''

\echo 'Buffer Cache Tips:'
\echo '  - shared_buffers: Typically 25% of available RAM'
\echo '  - effective_cache_size: Typically 50-75% of available RAM'
\echo '  - Review buffer usage by table to identify hot tables'
\echo '  - Monitor checkpoint frequency - too frequent indicates undersized buffers'
\echo ''
\echo 'Next steps:'
\echo '  1. Check slow queries: SELECT * FROM get_slow_queries(1000, 20);'
\echo '  2. Review missing indexes: SELECT * FROM get_missing_indexes();'
\echo '  3. Monitor over time to identify trends'
\echo ''
