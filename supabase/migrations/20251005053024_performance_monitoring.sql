-- Performance Monitoring and Optimization Setup
-- Created: 2025-10-05
-- Description: Adds performance monitoring utilities, indexes, and helper functions

-- ============================================================================
-- ENABLE PERFORMANCE EXTENSIONS
-- ============================================================================
-- Enable pg_stat_statements for query performance tracking
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Enable pg_trgm for trigram-based text search performance
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================================
-- ADDITIONAL INDEXES FOR PERFORMANCE
-- ============================================================================

-- Add text search indexes for common search patterns
CREATE INDEX IF NOT EXISTS profiles_full_name_trgm_idx ON public.profiles 
    USING gin (full_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS profiles_bio_trgm_idx ON public.profiles 
    USING gin (bio gin_trgm_ops);

CREATE INDEX IF NOT EXISTS posts_title_trgm_idx ON public.posts 
    USING gin (title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS posts_content_trgm_idx ON public.posts 
    USING gin (content gin_trgm_ops);

-- Add composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS posts_user_published_idx ON public.posts(user_id, published, created_at DESC);

-- Add partial index for unpublished drafts
CREATE INDEX IF NOT EXISTS posts_drafts_idx ON public.posts(user_id, updated_at DESC) 
    WHERE published = false;

-- ============================================================================
-- PERFORMANCE MONITORING FUNCTIONS
-- ============================================================================

-- Function to get slow queries from pg_stat_statements
CREATE OR REPLACE FUNCTION public.get_slow_queries(
    min_exec_time_ms INTEGER DEFAULT 1000,
    result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    query TEXT,
    calls BIGINT,
    total_exec_time_seconds NUMERIC,
    mean_exec_time_ms NUMERIC,
    max_exec_time_ms NUMERIC,
    rows_affected BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        LEFT(pss.query, 500) as query,
        pss.calls,
        ROUND((pss.total_exec_time / 1000)::NUMERIC, 2) as total_exec_time_seconds,
        ROUND((pss.mean_exec_time)::NUMERIC, 2) as mean_exec_time_ms,
        ROUND((pss.max_exec_time)::NUMERIC, 2) as max_exec_time_ms,
        pss.rows
    FROM pg_stat_statements pss
    WHERE pss.mean_exec_time > min_exec_time_ms
    ORDER BY pss.mean_exec_time DESC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get table sizes and index usage
CREATE OR REPLACE FUNCTION public.get_table_stats()
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    total_size TEXT,
    table_size TEXT,
    indexes_size TEXT,
    row_count BIGINT,
    live_rows BIGINT,
    dead_rows BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname::TEXT,
        tablename::TEXT,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
        pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                      pg_relation_size(schemaname||'.'||tablename)) as indexes_size,
        (SELECT reltuples::BIGINT FROM pg_class WHERE oid = (schemaname||'.'||tablename)::regclass) as row_count,
        n_live_tup as live_rows,
        n_dead_tup as dead_rows
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get index usage statistics
CREATE OR REPLACE FUNCTION public.get_index_stats()
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    index_name TEXT,
    index_size TEXT,
    index_scans BIGINT,
    rows_read BIGINT,
    rows_fetched BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname::TEXT,
        tablename::TEXT,
        indexrelname::TEXT,
        pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
        idx_scan as index_scans,
        idx_tup_read as rows_read,
        idx_tup_fetch as rows_fetched
    FROM pg_stat_user_indexes
    WHERE schemaname = 'public'
    ORDER BY idx_scan DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to identify missing indexes
CREATE OR REPLACE FUNCTION public.get_missing_indexes()
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    seq_scans BIGINT,
    seq_rows_read BIGINT,
    index_scans BIGINT,
    row_estimate BIGINT,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname::TEXT,
        tablename::TEXT,
        seq_scan as seq_scans,
        seq_tup_read as seq_rows_read,
        idx_scan as index_scans,
        n_live_tup as row_estimate,
        CASE 
            WHEN seq_scan > 0 AND seq_tup_read / seq_scan > 10000 THEN 
                'High sequential scan cost - consider adding indexes'
            WHEN idx_scan = 0 AND n_live_tup > 1000 THEN 
                'No index usage detected - may need indexes'
            ELSE 'Monitor for query patterns'
        END as recommendation
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
        AND (seq_scan > idx_scan OR idx_scan = 0)
        AND n_live_tup > 100
    ORDER BY seq_tup_read DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get cache hit ratio
CREATE OR REPLACE FUNCTION public.get_cache_hit_ratio()
RETURNS TABLE (
    metric TEXT,
    ratio NUMERIC,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Buffer Cache Hit Ratio'::TEXT as metric,
        ROUND(
            (sum(blks_hit) * 100.0 / NULLIF(sum(blks_hit) + sum(blks_read), 0))::NUMERIC, 
            2
        ) as ratio,
        CASE 
            WHEN sum(blks_hit) * 100.0 / NULLIF(sum(blks_hit) + sum(blks_read), 0) > 99 
                THEN '✅ Excellent'
            WHEN sum(blks_hit) * 100.0 / NULLIF(sum(blks_hit) + sum(blks_read), 0) > 95 
                THEN '✓ Good'
            ELSE '⚠️ Needs Improvement'
        END as status
    FROM pg_stat_database
    WHERE datname = current_database();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to analyze query performance
CREATE OR REPLACE FUNCTION public.analyze_query_performance(query_text TEXT)
RETURNS TABLE (
    plan_line TEXT
) AS $$
BEGIN
    RETURN QUERY EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT) ' || query_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PERFORMANCE MONITORING VIEWS
-- ============================================================================

-- View for quick performance overview
CREATE OR REPLACE VIEW public.performance_overview AS
SELECT 
    'Database Size' as metric,
    pg_size_pretty(pg_database_size(current_database())) as value,
    'Total database size including all tables and indexes' as description
UNION ALL
SELECT 
    'Active Connections' as metric,
    count(*)::TEXT as value,
    'Number of currently active database connections' as description
FROM pg_stat_activity
WHERE state = 'active'
UNION ALL
SELECT 
    'Table Count' as metric,
    count(*)::TEXT as value,
    'Number of tables in public schema' as description
FROM pg_tables
WHERE schemaname = 'public';

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON FUNCTION public.get_slow_queries IS 
    'Returns queries with mean execution time above threshold. Default: 1000ms';
COMMENT ON FUNCTION public.get_table_stats IS 
    'Returns size and statistics for all tables in public schema';
COMMENT ON FUNCTION public.get_index_stats IS 
    'Returns index usage statistics to identify unused indexes';
COMMENT ON FUNCTION public.get_missing_indexes IS 
    'Identifies tables that might benefit from additional indexes';
COMMENT ON FUNCTION public.get_cache_hit_ratio IS 
    'Returns database buffer cache hit ratio (higher is better)';
COMMENT ON FUNCTION public.analyze_query_performance IS 
    'Runs EXPLAIN ANALYZE on a query to show execution plan and performance';
COMMENT ON VIEW public.performance_overview IS 
    'Quick overview of key database performance metrics';

-- ============================================================================
-- PERFORMANCE BASELINE QUERIES
-- ============================================================================
-- These comments serve as documentation for baseline performance queries

-- Example: Check current slow queries
-- SELECT * FROM public.get_slow_queries(1000, 10);

-- Example: Check table sizes and statistics
-- SELECT * FROM public.get_table_stats();

-- Example: Check index usage
-- SELECT * FROM public.get_index_stats();

-- Example: Identify potential missing indexes
-- SELECT * FROM public.get_missing_indexes();

-- Example: Check cache hit ratio
-- SELECT * FROM public.get_cache_hit_ratio();

-- Example: Analyze a specific query
-- SELECT * FROM public.analyze_query_performance('SELECT * FROM posts WHERE published = true LIMIT 10');

-- Example: Reset pg_stat_statements statistics
-- SELECT pg_stat_statements_reset();
