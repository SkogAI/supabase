# Performance Testing Queries

This directory contains SQL query files for testing database performance and establishing baselines.

## Running Tests

### Using Supabase CLI

```bash
# Execute all tests
supabase db execute --file supabase/performance_tests/01_monitoring_baseline.sql

# Or execute individual test files
supabase db execute --file supabase/performance_tests/02_query_performance.sql
```

### Using psql

```bash
# Connect to local Supabase
psql postgresql://postgres:postgres@localhost:54322/postgres

# Run a test file
\i supabase/performance_tests/01_monitoring_baseline.sql
```

## Test Files

1. **01_monitoring_baseline.sql** - Establish baseline metrics for monitoring
2. **02_query_performance.sql** - Test common query patterns with EXPLAIN ANALYZE
3. **03_index_verification.sql** - Verify all indexes are being used effectively
4. **04_slow_query_check.sql** - Identify and analyze slow queries
5. **05_cache_and_stats.sql** - Check cache hit ratios and database statistics

## Performance Targets

### Response Times
- **Simple lookups**: < 10ms
- **List queries with pagination**: < 50ms
- **Complex joins**: < 200ms
- **Text search**: < 100ms

### Cache Hit Ratio
- **Target**: > 99%
- **Acceptable**: > 95%
- **Needs attention**: < 95%

### Index Usage
- All foreign keys should have indexes
- Indexes should show > 0 scans in production
- Sequential scans should be minimal on large tables

## Interpreting Results

### EXPLAIN ANALYZE Output

```
Index Scan using posts_published_idx on posts
  (cost=0.42..8.44 rows=1 width=200)
  (actual time=0.015..0.025 rows=10 loops=1)
```

- **cost**: Estimated cost (startup..total)
- **rows**: Estimated rows returned
- **width**: Average row size in bytes
- **actual time**: Real execution time (ms)
- **loops**: Number of times the node was executed

### Key Metrics

- **Seq Scan**: Sequential scan (full table scan) - bad for large tables
- **Index Scan**: Using an index - good
- **Bitmap Heap Scan**: Using index for multiple matches - good
- **Buffers**: Shows cache hits vs reads from disk

## Baseline Checklist

- [ ] Cache hit ratio > 99%
- [ ] All critical queries use indexes
- [ ] No slow queries > 1000ms
- [ ] Table sizes documented
- [ ] Index usage verified
- [ ] Dead row count < 10% of live rows

## Regular Testing Schedule

- **Before deployment**: Run all performance tests
- **After migration**: Verify indexes are created
- **Weekly**: Check for slow queries and index usage
- **Monthly**: Review and update baselines

---

For detailed documentation, see [docs/PERFORMANCE.md](../../docs/PERFORMANCE.md)
