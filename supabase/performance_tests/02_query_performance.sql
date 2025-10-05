-- Query Performance Testing with EXPLAIN ANALYZE
-- Tests common query patterns to verify index usage and performance
-- Execute: supabase db execute --file supabase/performance_tests/02_query_performance.sql

\echo ''
\echo '================================================================================'
\echo 'QUERY PERFORMANCE TESTS'
\echo '================================================================================'
\echo ''

-- Test 1: Profile lookup by username (should use index)
\echo 'Test 1: Profile Lookup by Username'
\echo '----------------------------'
\echo 'Expected: Index Scan using profiles_username_idx'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM profiles WHERE username = 'alice';
\echo ''

-- Test 2: Profile search with ILIKE (should use trigram index)
\echo 'Test 2: Profile Full Name Search (ILIKE)'
\echo '----------------------------'
\echo 'Expected: Bitmap Index Scan using profiles_full_name_trgm_idx'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM profiles WHERE full_name ILIKE '%alice%';
\echo ''

-- Test 3: Published posts with pagination (should use partial index)
\echo 'Test 3: Published Posts with Pagination'
\echo '----------------------------'
\echo 'Expected: Index Scan using posts_published_idx'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, user_id, created_at 
FROM posts 
WHERE published = true 
ORDER BY created_at DESC 
LIMIT 10;
\echo ''

-- Test 4: User's published posts (should use composite index)
\echo 'Test 4: User Published Posts'
\echo '----------------------------'
\echo 'Expected: Index Scan using posts_user_published_idx'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, created_at 
FROM posts 
WHERE user_id = '00000000-0000-0000-0000-000000000001'
    AND published = true
ORDER BY created_at DESC;
\echo ''

-- Test 5: User's drafts (should use partial index)
\echo 'Test 5: User Draft Posts'
\echo '----------------------------'
\echo 'Expected: Index Scan using posts_drafts_idx'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, updated_at 
FROM posts 
WHERE user_id = '00000000-0000-0000-0000-000000000001'
    AND published = false
ORDER BY updated_at DESC;
\echo ''

-- Test 6: Text search on post titles (should use trigram index)
\echo 'Test 6: Post Title Text Search'
\echo '----------------------------'
\echo 'Expected: Bitmap Index Scan using posts_title_trgm_idx'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, created_at 
FROM posts 
WHERE title ILIKE '%supabase%'
ORDER BY created_at DESC
LIMIT 10;
\echo ''

-- Test 7: Recent profiles (should use index on created_at)
\echo 'Test 7: Recent Profiles'
\echo '----------------------------'
\echo 'Expected: Index Scan using profiles_created_at_idx'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, username, full_name, created_at 
FROM profiles 
ORDER BY created_at DESC 
LIMIT 10;
\echo ''

-- Test 8: Join query - posts with profile info
\echo 'Test 8: Posts with Profile Join'
\echo '----------------------------'
\echo 'Expected: Index scans on both tables'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    p.id,
    p.title,
    p.created_at,
    pr.username,
    pr.full_name
FROM posts p
JOIN profiles pr ON p.user_id = pr.id
WHERE p.published = true
ORDER BY p.created_at DESC
LIMIT 10;
\echo ''

-- Test 9: Count queries
\echo 'Test 9: Count Published Posts'
\echo '----------------------------'
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM posts WHERE published = true;
\echo ''

-- Test 10: Aggregation query
\echo 'Test 10: Posts Per User'
\echo '----------------------------'
\echo 'Expected: Index usage for grouping'
\echo ''
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    user_id,
    COUNT(*) as post_count,
    COUNT(*) FILTER (WHERE published = true) as published_count
FROM posts
GROUP BY user_id
ORDER BY post_count DESC;
\echo ''

-- Performance timing tests
\echo '================================================================================'
\echo 'QUERY TIMING TESTS'
\echo '================================================================================'
\echo ''

-- Enable timing
\timing on

\echo 'Timing Test 1: Username lookup'
SELECT * FROM profiles WHERE username = 'alice';

\echo 'Timing Test 2: Published posts'
SELECT * FROM posts WHERE published = true ORDER BY created_at DESC LIMIT 10;

\echo 'Timing Test 3: Text search'
SELECT * FROM posts WHERE title ILIKE '%post%' LIMIT 5;

\echo 'Timing Test 4: Join query'
SELECT p.title, pr.username 
FROM posts p 
JOIN profiles pr ON p.user_id = pr.id 
WHERE p.published = true 
LIMIT 10;

\timing off

\echo ''
\echo '================================================================================'
\echo 'PERFORMANCE TEST SUMMARY'
\echo '================================================================================'
\echo ''
\echo 'Review the EXPLAIN ANALYZE output above:'
\echo '  ✅ Check that all queries use indexes (Index Scan, Bitmap Index Scan)'
\echo '  ⚠️  Watch for Seq Scan on large tables'
\echo '  📊 Review actual time vs estimated rows'
\echo '  💾 Check buffer hits vs reads (high hits = good cache usage)'
\echo ''
\echo 'Performance Targets:'
\echo '  - Simple lookups: < 10ms'
\echo '  - List queries: < 50ms'
\echo '  - Joins: < 200ms'
\echo '  - Text search: < 100ms'
\echo ''
