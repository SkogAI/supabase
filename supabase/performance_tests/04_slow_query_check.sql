-- Slow Query Detection and Analysis
-- Identifies and analyzes slow queries using pg_stat_statements
-- Execute: supabase db execute --file supabase/performance_tests/04_slow_query_check.sql

\echo ''
\echo '================================================================================'
\echo 'SLOW QUERY DETECTION AND ANALYSIS'
\echo '================================================================================'
\echo ''

-- 1. Top 20 slowest queries by mean execution time
\echo '1. Top 20 Slowest Queries (by mean execution time)'
\echo '----------------------------'
\echo 'Queries with mean execution time > 1000ms'
\echo ''
SELECT 
    query,
    calls,
    mean_exec_time_ms || ' ms' as mean_time,
    max_exec_time_ms || ' ms' as max_time,
    total_exec_time_seconds || ' s' as total_time,
    rows_affected
FROM public.get_slow_queries(1000, 20)
ORDER BY mean_exec_time_ms DESC;
\echo ''

-- 2. Queries with high total execution time
\echo '2. Queries by Total Execution Time'
\echo '----------------------------'
\echo 'Queries that consume the most cumulative time'
\echo ''
SELECT 
    LEFT(query, 100) as query_sample,
    calls,
    ROUND((mean_exec_time)::NUMERIC, 2) as mean_exec_time_ms,
    ROUND((total_exec_time / 1000)::NUMERIC, 2) as total_exec_time_seconds,
    rows as rows_affected
FROM pg_stat_statements
WHERE userid = (SELECT usesysid FROM pg_user WHERE usename = current_user)
ORDER BY total_exec_time DESC
LIMIT 20;
\echo ''

-- 3. Frequently called queries (potential optimization candidates)
\echo '3. Most Frequently Called Queries'
\echo '----------------------------'
\echo 'High call frequency queries - good candidates for caching or optimization'
\echo ''
SELECT 
    LEFT(query, 100) as query_sample,
    calls,
    ROUND((mean_exec_time)::NUMERIC, 2) as mean_exec_time_ms,
    ROUND((total_exec_time / 1000)::NUMERIC, 2) as total_exec_time_seconds,
    ROUND((calls::NUMERIC / EXTRACT(EPOCH FROM (now() - stats_reset))), 2) as calls_per_second
FROM pg_stat_statements pss
JOIN pg_stat_database psd ON pss.dbid = psd.datid
WHERE psd.datname = current_database()
ORDER BY calls DESC
LIMIT 20;
\echo ''

-- 4. Queries with high variance (inconsistent performance)
\echo '4. Queries with High Performance Variance'
\echo '----------------------------'
\echo 'Queries with high stddev indicate inconsistent performance'
\echo ''
SELECT 
    LEFT(query, 100) as query_sample,
    calls,
    ROUND((mean_exec_time)::NUMERIC, 2) as mean_ms,
    ROUND((stddev_exec_time)::NUMERIC, 2) as stddev_ms,
    ROUND((min_exec_time)::NUMERIC, 2) as min_ms,
    ROUND((max_exec_time)::NUMERIC, 2) as max_ms,
    ROUND((stddev_exec_time / NULLIF(mean_exec_time, 0) * 100)::NUMERIC, 2) as variance_percent
FROM pg_stat_statements
WHERE mean_exec_time > 0
    AND calls > 10
ORDER BY variance_percent DESC
LIMIT 20;
\echo ''

-- 5. Queries causing most I/O
\echo '5. Queries with Highest I/O'
\echo '----------------------------'
\echo 'Queries reading/writing the most data'
\echo ''
SELECT 
    LEFT(query, 100) as query_sample,
    calls,
    shared_blks_read + local_blks_read as total_blks_read,
    shared_blks_written + local_blks_written as total_blks_written,
    shared_blks_hit as cache_hits,
    ROUND(
        100.0 * shared_blks_hit / 
        NULLIF(shared_blks_hit + shared_blks_read, 0), 
        2
    ) as cache_hit_ratio
FROM pg_stat_statements
WHERE shared_blks_read + local_blks_read + shared_blks_written + local_blks_written > 0
ORDER BY (shared_blks_read + local_blks_read + shared_blks_written + local_blks_written) DESC
LIMIT 20;
\echo ''

-- 6. Queries with poor cache hit ratio
\echo '6. Queries with Poor Cache Hit Ratio'
\echo '----------------------------'
\echo 'Queries that may benefit from better indexing or more cache'
\echo ''
SELECT 
    LEFT(query, 100) as query_sample,
    calls,
    shared_blks_read as disk_blocks,
    shared_blks_hit as cache_blocks,
    ROUND(
        100.0 * shared_blks_hit / 
        NULLIF(shared_blks_hit + shared_blks_read, 0), 
        2
    ) as cache_hit_ratio
FROM pg_stat_statements
WHERE shared_blks_read > 0
    AND calls > 5
ORDER BY cache_hit_ratio ASC
LIMIT 20;
\echo ''

-- 7. Sequential scans detected in queries
\echo '7. Tables with High Sequential Scan Activity'
\echo '----------------------------'
\echo 'Tables being scanned sequentially - may need indexes'
\echo ''
SELECT 
    schemaname,
    tablename,
    seq_scan as sequential_scans,
    seq_tup_read as rows_read_by_seq_scan,
    idx_scan as index_scans,
    n_live_tup as estimated_rows,
    CASE 
        WHEN seq_scan > 0 AND n_live_tup > 0 
        THEN ROUND((seq_tup_read::NUMERIC / seq_scan), 0)
        ELSE 0
    END as avg_rows_per_seq_scan
FROM pg_stat_user_tables
WHERE schemaname = 'public'
    AND seq_scan > 0
ORDER BY seq_tup_read DESC;
\echo ''

-- 8. Query statistics summary
\echo '8. Query Statistics Summary'
\echo '----------------------------'
SELECT 
    COUNT(*) as total_queries,
    SUM(calls) as total_calls,
    ROUND((SUM(total_exec_time) / 1000)::NUMERIC, 2) as total_exec_time_seconds,
    ROUND((AVG(mean_exec_time))::NUMERIC, 2) as avg_mean_exec_time_ms,
    ROUND((MAX(max_exec_time))::NUMERIC, 2) as max_exec_time_ms,
    pg_size_pretty(SUM(shared_blks_read + local_blks_read) * 8192) as total_data_read,
    ROUND(
        100.0 * SUM(shared_blks_hit) / 
        NULLIF(SUM(shared_blks_hit + shared_blks_read), 0), 
        2
    ) as overall_cache_hit_ratio
FROM pg_stat_statements;
\echo ''

-- 9. Time-based query analysis
\echo '9. Query Performance Over Time'
\echo '----------------------------'
WITH query_stats AS (
    SELECT 
        (SELECT stats_reset FROM pg_stat_database WHERE datname = current_database()) as stats_reset,
        COUNT(*) as query_count,
        SUM(calls) as total_calls,
        ROUND((SUM(total_exec_time) / 1000)::NUMERIC, 2) as total_seconds
    FROM pg_stat_statements
)
SELECT 
    stats_reset,
    EXTRACT(EPOCH FROM (now() - stats_reset))::INTEGER / 3600 as hours_since_reset,
    query_count,
    total_calls,
    total_seconds,
    ROUND((total_calls / NULLIF(EXTRACT(EPOCH FROM (now() - stats_reset)), 0))::NUMERIC, 2) as calls_per_second,
    ROUND((total_seconds / NULLIF(EXTRACT(EPOCH FROM (now() - stats_reset)) / 3600, 0))::NUMERIC, 2) as seconds_per_hour
FROM query_stats;
\echo ''

-- 10. Recommendations
\echo '================================================================================'
\echo 'SLOW QUERY RECOMMENDATIONS'
\echo '================================================================================'
\echo ''
\echo 'Action items based on analysis:'
\echo ''
\echo '  1. For slow queries (> 1000ms):'
\echo '     - Run EXPLAIN ANALYZE on the query'
\echo '     - Check if indexes are being used'
\echo '     - Consider adding appropriate indexes'
\echo '     - Review query logic for optimization opportunities'
\echo ''
\echo '  2. For high-frequency queries:'
\echo '     - Consider caching results if data is not real-time critical'
\echo '     - Ensure queries use indexes'
\echo '     - Consider materializing complex computations'
\echo ''
\echo '  3. For high variance queries:'
\echo '     - May indicate locking or resource contention'
\echo '     - Check for blocking queries during peak times'
\echo '     - Review transaction isolation levels'
\echo ''
\echo '  4. For high I/O queries:'
\echo '     - Check cache hit ratios'
\echo '     - Consider increasing shared_buffers if cache hit < 95%'
\echo '     - Add indexes to reduce data scanning'
\echo ''
\echo '  5. For tables with many sequential scans:'
\echo '     - Run: SELECT * FROM public.get_missing_indexes();'
\echo '     - Add indexes on frequently filtered columns'
\echo '     - Review WHERE clause patterns'
\echo ''
\echo 'To reset statistics and start fresh:'
\echo '  SELECT pg_stat_statements_reset();'
\echo ''
\echo 'To analyze a specific slow query:'
\echo '  EXPLAIN (ANALYZE, BUFFERS, VERBOSE) <your_query>;'
\echo ''
