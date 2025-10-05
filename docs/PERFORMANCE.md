# Database Performance Monitoring and Optimization Guide

Complete guide for monitoring and optimizing database performance in your Supabase project.

## Table of Contents

- [Overview](#overview)
- [Performance Monitoring](#performance-monitoring)
- [Query Optimization](#query-optimization)
- [Index Management](#index-management)
- [Slow Query Detection](#slow-query-detection)
- [Performance Baselines](#performance-baselines)
- [Best Practices](#best-practices)

---

## Overview

This project includes comprehensive performance monitoring utilities through the `20251005053024_performance_monitoring.sql` migration. These tools help you:

- Track slow queries
- Monitor index usage
- Identify missing indexes
- Measure cache hit ratios
- Analyze query execution plans

---

## Performance Monitoring

### Available Monitoring Functions

All monitoring functions are available in the `public` schema:

#### 1. Get Slow Queries

```sql
-- Get queries with mean execution time > 1000ms (default)
SELECT * FROM public.get_slow_queries();

-- Custom threshold (500ms) and limit (10 results)
SELECT * FROM public.get_slow_queries(500, 10);
```

**Returns:**
- `query`: The SQL query text (truncated to 500 chars)
- `calls`: Number of times the query was executed
- `total_exec_time_seconds`: Total time spent executing this query
- `mean_exec_time_ms`: Average execution time
- `max_exec_time_ms`: Maximum execution time observed
- `rows_affected`: Total rows processed

#### 2. Get Table Statistics

```sql
-- Get size and statistics for all tables
SELECT * FROM public.get_table_stats();
```

**Returns:**
- `schema_name`: Schema name (public)
- `table_name`: Table name
- `total_size`: Total size including indexes
- `table_size`: Size of table data only
- `indexes_size`: Size of all indexes
- `row_count`: Estimated row count
- `live_rows`: Number of live rows
- `dead_rows`: Number of dead rows (may need VACUUM)

#### 3. Get Index Usage Statistics

```sql
-- Check which indexes are being used
SELECT * FROM public.get_index_stats();
```

**Returns:**
- `schema_name`: Schema name
- `table_name`: Table name
- `index_name`: Index name
- `index_size`: Size of the index
- `index_scans`: Number of times index was used
- `rows_read`: Total rows read via index
- `rows_fetched`: Total rows fetched via index

**Identifying Unused Indexes:**
```sql
-- Find indexes with zero scans (never used)
SELECT * FROM public.get_index_stats()
WHERE index_scans = 0
ORDER BY index_size DESC;
```

#### 4. Identify Missing Indexes

```sql
-- Find tables that might benefit from additional indexes
SELECT * FROM public.get_missing_indexes();
```

**Returns:**
- `schema_name`: Schema name
- `table_name`: Table name
- `seq_scans`: Number of sequential scans
- `seq_rows_read`: Total rows read via sequential scan
- `index_scans`: Number of index scans
- `row_estimate`: Estimated number of rows in table
- `recommendation`: Suggested action

#### 5. Check Cache Hit Ratio

```sql
-- Check database buffer cache efficiency
SELECT * FROM public.get_cache_hit_ratio();
```

**Target:** > 99% for optimal performance
- **> 99%**: Excellent - most data served from cache
- **95-99%**: Good - acceptable performance
- **< 95%**: Needs improvement - consider increasing `shared_buffers`

#### 6. Performance Overview

```sql
-- Quick dashboard of key metrics
SELECT * FROM public.performance_overview;
```

---

## Query Optimization

### Using EXPLAIN ANALYZE

The `EXPLAIN ANALYZE` command shows the actual execution plan and performance:

```sql
-- Basic EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT * FROM posts 
WHERE published = true 
ORDER BY created_at DESC 
LIMIT 10;
```

### Using the Helper Function

```sql
-- Analyze query with detailed output
SELECT * FROM public.analyze_query_performance(
    'SELECT * FROM posts WHERE published = true ORDER BY created_at DESC LIMIT 10'
);
```

### Common EXPLAIN Output Patterns

#### Sequential Scan (Bad for large tables)
```
Seq Scan on posts  (cost=0.00..1234.56 rows=1000 width=200)
```
**Fix:** Add an index on the filtered column

#### Index Scan (Good)
```
Index Scan using posts_published_idx on posts  (cost=0.42..8.44 rows=1 width=200)
```

#### Bitmap Index Scan (Good for multiple matches)
```
Bitmap Index Scan on posts_user_id_idx  (cost=0.00..4.43 rows=50 width=0)
```

### EXPLAIN Options

```sql
-- Detailed analysis with buffer statistics
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT * FROM posts WHERE user_id = '...';
```

**Options:**
- `ANALYZE`: Actually run the query and show real timing
- `BUFFERS`: Show buffer cache statistics
- `VERBOSE`: Include additional details
- `FORMAT`: Output format (TEXT, JSON, YAML, XML)

---

## Index Management

### Current Indexes

The project has these indexes defined:

#### Profiles Table
```sql
-- B-tree indexes
profiles_pkey              -- Primary key (id)
profiles_username_key      -- Unique constraint (username)
profiles_username_idx      -- B-tree index (username)
profiles_created_at_idx    -- B-tree index (created_at DESC)

-- GIN indexes for text search
profiles_full_name_trgm_idx -- Trigram search (full_name)
profiles_bio_trgm_idx       -- Trigram search (bio)
```

#### Posts Table
```sql
-- B-tree indexes
posts_pkey                    -- Primary key (id)
posts_user_id_idx            -- Foreign key (user_id)
posts_created_at_idx         -- Timestamp (created_at DESC)
posts_published_idx          -- Partial index (WHERE published = true)
posts_user_published_idx     -- Composite (user_id, published, created_at DESC)
posts_drafts_idx             -- Partial index (WHERE published = false)

-- GIN indexes for text search
posts_title_trgm_idx         -- Trigram search (title)
posts_content_trgm_idx       -- Trigram search (content)
```

### When to Add Indexes

✅ **Do add indexes when:**
- Filtering on a column frequently (WHERE clause)
- Joining on a column
- Ordering by a column (ORDER BY)
- Checking uniqueness constraints
- Using GROUP BY on a column
- Foreign key relationships

❌ **Don't add indexes when:**
- Table is very small (< 1000 rows)
- Column has low cardinality (few distinct values)
- High write frequency with few reads
- Column is rarely queried

### Index Types

#### 1. B-tree (Default)
```sql
CREATE INDEX idx_name ON table_name(column_name);
```
Best for: Equality, range queries, sorting

#### 2. GIN (Generalized Inverted Index)
```sql
CREATE INDEX idx_name ON table_name USING gin(column_name gin_trgm_ops);
```
Best for: Full-text search, JSONB, arrays

#### 3. Partial Index
```sql
CREATE INDEX idx_name ON table_name(column_name) WHERE condition;
```
Best for: Filtering on a subset of rows

#### 4. Composite Index
```sql
CREATE INDEX idx_name ON table_name(col1, col2, col3);
```
Best for: Queries filtering on multiple columns

**Column order matters!** Left-most columns should be in WHERE/ORDER BY clauses.

### Text Search with pg_trgm

```sql
-- Fast ILIKE queries with trigram indexes
SELECT * FROM profiles 
WHERE full_name ILIKE '%alice%';

-- Similarity search
SELECT *, similarity(full_name, 'alice') as score
FROM profiles 
WHERE full_name % 'alice'
ORDER BY score DESC;
```

---

## Slow Query Detection

### Monitor Slow Queries

```sql
-- Check for queries taking > 1 second
SELECT 
    query,
    calls,
    mean_exec_time_ms,
    total_exec_time_seconds
FROM public.get_slow_queries(1000, 20)
ORDER BY mean_exec_time_ms DESC;
```

### Log Slow Queries

Add to your Supabase project settings or `postgresql.conf`:

```conf
log_min_duration_statement = 1000  # Log queries > 1 second
log_statement = 'all'              # Log all statements (development only)
log_duration = on                  # Log query duration
```

### Reset Statistics

```sql
-- Clear pg_stat_statements data
SELECT pg_stat_statements_reset();
```

---

## Performance Baselines

### Establishing Baselines

Run these queries regularly to establish performance baselines:

```sql
-- 1. Overall database health
SELECT * FROM public.performance_overview;

-- 2. Cache hit ratio (target: > 99%)
SELECT * FROM public.get_cache_hit_ratio();

-- 3. Table sizes and growth
SELECT 
    table_name,
    total_size,
    row_count,
    live_rows,
    dead_rows
FROM public.get_table_stats()
ORDER BY total_size DESC;

-- 4. Index efficiency
SELECT 
    table_name,
    index_name,
    index_scans,
    index_size
FROM public.get_index_stats()
WHERE index_scans > 0
ORDER BY index_scans DESC;

-- 5. Potential issues
SELECT * FROM public.get_missing_indexes();
```

### Performance Testing Queries

See `supabase/performance_tests/` directory for ready-to-use test queries.

---

## Best Practices

### 1. Index Strategy

✅ **Do:**
- Index foreign keys
- Index columns used in WHERE clauses
- Use partial indexes for subset queries
- Use composite indexes for multi-column queries
- Monitor index usage regularly

❌ **Don't:**
- Over-index (each index adds write overhead)
- Index low-cardinality columns (e.g., boolean)
- Index columns that are rarely queried
- Create duplicate indexes

### 2. Query Optimization

✅ **Do:**
- Use LIMIT for pagination
- Filter early (WHERE before JOIN)
- Use appropriate data types
- Avoid SELECT * (select only needed columns)
- Use prepared statements

❌ **Don't:**
- Use OFFSET for large offsets (use cursor-based pagination)
- Use functions in WHERE clauses (prevents index usage)
- Compare different data types
- Use OR extensively (consider UNION)

### 3. RLS Performance

Row Level Security can impact performance:

```sql
-- ✅ Good: Index on RLS filter column
CREATE INDEX posts_user_id_idx ON posts(user_id);

-- Policy using indexed column
CREATE POLICY "users_own_posts" ON posts
    USING (auth.uid() = user_id);
```

```sql
-- ❌ Bad: Complex RLS with joins
CREATE POLICY "complex_policy" ON posts
    USING (
        EXISTS (
            SELECT 1 FROM other_table 
            WHERE other_table.id = posts.id
        )
    );
```

### 4. Maintenance

```sql
-- Regular VACUUM to reclaim space
VACUUM ANALYZE;

-- Check for bloat
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    n_dead_tup,
    ROUND(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### 5. Connection Pooling

For production, use Supabase's built-in connection pooling:

- **Transaction mode**: Best for short transactions
- **Session mode**: For long-lived connections
- **Statement mode**: For single queries

### 6. Monitoring Schedule

**Daily:**
- Check slow queries: `SELECT * FROM get_slow_queries(1000, 10);`
- Monitor cache hit ratio: `SELECT * FROM get_cache_hit_ratio();`

**Weekly:**
- Review index usage: `SELECT * FROM get_index_stats();`
- Check for missing indexes: `SELECT * FROM get_missing_indexes();`
- Review table sizes: `SELECT * FROM get_table_stats();`

**Monthly:**
- Run VACUUM ANALYZE
- Review and remove unused indexes
- Update performance baselines
- Review query patterns and optimize

---

## Performance Testing

### Example Test Suite

```sql
-- Test 1: Profile lookup by username (should use index)
EXPLAIN ANALYZE
SELECT * FROM profiles WHERE username = 'alice';

-- Test 2: Published posts with pagination (should use index)
EXPLAIN ANALYZE
SELECT * FROM posts 
WHERE published = true 
ORDER BY created_at DESC 
LIMIT 10;

-- Test 3: User's posts with composite index
EXPLAIN ANALYZE
SELECT * FROM posts 
WHERE user_id = '00000000-0000-0000-0000-000000000001'
    AND published = true
ORDER BY created_at DESC;

-- Test 4: Text search with trigram
EXPLAIN ANALYZE
SELECT * FROM posts 
WHERE title ILIKE '%supabase%'
LIMIT 10;

-- Test 5: Drafts for user (partial index)
EXPLAIN ANALYZE
SELECT * FROM posts 
WHERE user_id = '00000000-0000-0000-0000-000000000001'
    AND published = false
ORDER BY updated_at DESC;
```

---

## Troubleshooting

### Slow Queries

1. **Identify:** `SELECT * FROM get_slow_queries(500, 20);`
2. **Analyze:** `EXPLAIN ANALYZE <your_query>;`
3. **Add Index:** Based on WHERE/JOIN/ORDER BY clauses
4. **Verify:** Re-run EXPLAIN ANALYZE

### High Dead Rows

```sql
-- Check for tables needing VACUUM
SELECT tablename, n_dead_tup, n_live_tup
FROM pg_stat_user_tables
WHERE n_dead_tup > n_live_tup * 0.1
ORDER BY n_dead_tup DESC;

-- Solution: Run VACUUM
VACUUM ANALYZE table_name;
```

### Low Cache Hit Ratio

```sql
-- If cache hit ratio < 95%
SELECT * FROM get_cache_hit_ratio();

-- Possible solutions:
-- 1. Increase shared_buffers (Supabase dashboard)
-- 2. Optimize queries to reduce data scanned
-- 3. Add appropriate indexes
```

### Unused Indexes

```sql
-- Find indexes never used
SELECT * FROM get_index_stats()
WHERE index_scans = 0
    AND index_name NOT LIKE '%_pkey'
    AND index_name NOT LIKE '%_key';

-- Drop unused indexes (carefully!)
DROP INDEX IF EXISTS index_name;
```

---

## Additional Resources

- [PostgreSQL EXPLAIN Documentation](https://www.postgresql.org/docs/current/sql-explain.html)
- [Supabase Performance Tips](https://supabase.com/docs/guides/platform/performance)
- [pg_stat_statements Documentation](https://www.postgresql.org/docs/current/pgstatstatements.html)
- [Index Types in PostgreSQL](https://www.postgresql.org/docs/current/indexes-types.html)

---

**Last Updated**: 2025-10-05  
**Migration Version**: 20251005053024_performance_monitoring.sql
