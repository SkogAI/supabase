-- Index Verification and Usage Analysis
-- Verifies all indexes are properly created and identifies usage patterns
-- Execute: supabase db execute --file supabase/performance_tests/03_index_verification.sql

\echo ''
\echo '================================================================================'
\echo 'INDEX VERIFICATION AND USAGE ANALYSIS'
\echo '================================================================================'
\echo ''

-- 1. List all indexes in public schema
\echo '1. All Indexes in Public Schema'
\echo '----------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
\echo ''

-- 2. Index usage statistics
\echo '2. Index Usage Statistics'
\echo '----------------------------'
SELECT * FROM public.get_index_stats()
ORDER BY table_name, index_scans DESC;
\echo ''

-- 3. Unused indexes (potential candidates for removal)
\echo '3. Unused Indexes (Zero Scans)'
\echo '----------------------------'
\echo 'Note: Primary keys and unique constraints may show 0 scans but are still necessary'
\echo ''
SELECT 
    table_name,
    index_name,
    index_size,
    'Never used - consider dropping if not a primary key or unique constraint' as status
FROM public.get_index_stats()
WHERE index_scans = 0
    AND index_name NOT LIKE '%_pkey'
    AND index_name NOT LIKE '%_key'
ORDER BY index_size DESC;
\echo ''

-- 4. Index efficiency ratio
\echo '4. Index Efficiency (Scans per MB)'
\echo '----------------------------'
SELECT 
    table_name,
    index_name,
    index_scans,
    pg_relation_size(('public.' || index_name)::regclass) / (1024*1024) as size_mb,
    CASE 
        WHEN pg_relation_size(('public.' || index_name)::regclass) > 0 
        THEN ROUND(index_scans::NUMERIC / (pg_relation_size(('public.' || index_name)::regclass) / (1024*1024)), 2)
        ELSE 0
    END as scans_per_mb
FROM public.get_index_stats()
WHERE index_scans > 0
ORDER BY scans_per_mb DESC;
\echo ''

-- 5. Check for duplicate indexes
\echo '5. Duplicate or Overlapping Indexes'
\echo '----------------------------'
SELECT 
    a.schemaname,
    a.tablename,
    a.indexname as index1,
    b.indexname as index2,
    a.indexdef as definition1,
    b.indexdef as definition2
FROM pg_indexes a
JOIN pg_indexes b ON a.tablename = b.tablename 
    AND a.schemaname = b.schemaname 
    AND a.indexname < b.indexname
WHERE a.schemaname = 'public'
    AND a.indexdef = b.indexdef;
\echo 'Note: No output means no exact duplicates found (good!)'
\echo ''

-- 6. Expected indexes checklist
\echo '6. Expected Index Checklist'
\echo '----------------------------'
\echo 'Profiles Table:'
WITH expected_profile_indexes AS (
    SELECT unnest(ARRAY[
        'profiles_pkey',
        'profiles_username_key', 
        'profiles_username_idx',
        'profiles_created_at_idx',
        'profiles_full_name_trgm_idx',
        'profiles_bio_trgm_idx'
    ]) as expected_index
)
SELECT 
    e.expected_index,
    CASE 
        WHEN i.indexname IS NOT NULL THEN '✅ Present'
        ELSE '❌ Missing'
    END as status,
    pg_size_pretty(COALESCE(pg_relation_size(i.indexname::regclass), 0)) as size
FROM expected_profile_indexes e
LEFT JOIN pg_indexes i ON i.indexname = e.expected_index AND i.schemaname = 'public';
\echo ''

\echo 'Posts Table:'
WITH expected_post_indexes AS (
    SELECT unnest(ARRAY[
        'posts_pkey',
        'posts_user_id_idx',
        'posts_created_at_idx',
        'posts_published_idx',
        'posts_user_published_idx',
        'posts_drafts_idx',
        'posts_title_trgm_idx',
        'posts_content_trgm_idx'
    ]) as expected_index
)
SELECT 
    e.expected_index,
    CASE 
        WHEN i.indexname IS NOT NULL THEN '✅ Present'
        ELSE '❌ Missing'
    END as status,
    pg_size_pretty(COALESCE(pg_relation_size(i.indexname::regclass), 0)) as size
FROM expected_post_indexes e
LEFT JOIN pg_indexes i ON i.indexname = e.expected_index AND i.schemaname = 'public';
\echo ''

-- 7. Index types breakdown
\echo '7. Index Types Breakdown'
\echo '----------------------------'
SELECT 
    CASE 
        WHEN indexdef LIKE '%USING btree%' THEN 'B-tree'
        WHEN indexdef LIKE '%USING gin%' THEN 'GIN'
        WHEN indexdef LIKE '%USING gist%' THEN 'GiST'
        WHEN indexdef LIKE '%USING hash%' THEN 'Hash'
        ELSE 'Other'
    END as index_type,
    COUNT(*) as count,
    pg_size_pretty(SUM(pg_relation_size(indexname::regclass))) as total_size
FROM pg_indexes
WHERE schemaname = 'public'
GROUP BY index_type
ORDER BY count DESC;
\echo ''

-- 8. Partial indexes
\echo '8. Partial Indexes (Conditional)'
\echo '----------------------------'
SELECT 
    tablename,
    indexname,
    pg_get_indexdef(indexname::regclass) as index_definition
FROM pg_indexes
WHERE schemaname = 'public'
    AND indexdef LIKE '%WHERE%'
ORDER BY tablename, indexname;
\echo ''

-- 9. Composite (multi-column) indexes
\echo '9. Composite (Multi-Column) Indexes'
\echo '----------------------------'
SELECT 
    i.tablename,
    i.indexname,
    array_length(string_to_array(
        substring(i.indexdef from 'ON.*\((.*)\)'), ','
    ), 1) as column_count,
    pg_size_pretty(pg_relation_size(i.indexname::regclass)) as size
FROM pg_indexes i
WHERE i.schemaname = 'public'
    AND i.indexdef ~ '\(.+,.+\)'  -- Has multiple columns
ORDER BY column_count DESC, tablename;
\echo ''

-- 10. Index bloat estimation
\echo '10. Index Bloat Estimation'
\echo '----------------------------'
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    idx_scan as scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    CASE 
        WHEN idx_scan > 0 THEN ROUND((idx_tup_read::NUMERIC / idx_scan), 2)
        ELSE 0
    END as avg_tuples_per_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
\echo ''

\echo '================================================================================'
\echo 'INDEX VERIFICATION SUMMARY'
\echo '================================================================================'
\echo ''
\echo 'Review checklist:'
\echo '  ✅ All expected indexes are present'
\echo '  ✅ Indexes are being used (scans > 0)'
\echo '  ✅ No duplicate indexes'
\echo '  ⚠️  Check unused indexes - consider dropping if not needed'
\echo '  ⚠️  Review index sizes - large unused indexes waste space'
\echo ''
\echo 'Index maintenance tips:'
\echo '  - Monitor index usage over time'
\echo '  - Rebuild bloated indexes with REINDEX'
\echo '  - Add indexes based on query patterns from get_slow_queries()'
\echo '  - Remove indexes that are never used'
\echo ''
