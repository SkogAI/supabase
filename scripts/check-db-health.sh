#!/bin/bash
# Database Health Check Script for AI Agents
# Monitors connection pools, active queries, and performance metrics

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if connection string is provided
if [ $# -eq 0 ]; then
    if [ -z "$DATABASE_URL" ]; then
        print_error "No connection string provided and DATABASE_URL not set"
        echo ""
        echo "Usage: $0 <connection_string>"
        echo "   or: export DATABASE_URL='<connection_string>' && $0"
        exit 1
    fi
    CONN_STRING="$DATABASE_URL"
else
    CONN_STRING="$1"
fi

# Check if psql is available
if ! command -v psql &> /dev/null; then
    print_error "psql is not installed. Install with: apt-get install postgresql-client"
    exit 1
fi

print_header "Database Health Check"
print_info "Timestamp: $(date)"
print_info "Connection: $(echo $CONN_STRING | sed 's/:.*@/:***@/')"

# Test basic connectivity
print_header "1. Basic Connectivity"
if psql "$CONN_STRING" -c "SELECT 1;" &> /dev/null; then
    print_success "Database is reachable"
else
    print_error "Cannot connect to database"
    psql "$CONN_STRING" -c "SELECT 1;" 2>&1 | tail -n5
    exit 1
fi

# Database version and uptime
print_header "2. Database Information"
psql "$CONN_STRING" -c "
    SELECT 
        version() as version,
        pg_postmaster_start_time() as started_at,
        now() - pg_postmaster_start_time() as uptime;
"

# Connection statistics
print_header "3. Connection Statistics"
psql "$CONN_STRING" -c "
    SELECT 
        (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections,
        (SELECT count(*) FROM pg_stat_activity) as current_connections,
        (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - 
            (SELECT count(*) FROM pg_stat_activity) as available_connections,
        round(100.0 * (SELECT count(*) FROM pg_stat_activity) / 
            (SELECT setting::int FROM pg_settings WHERE name = 'max_connections'), 2) as usage_percent;
"

# Connection breakdown by state
print_header "4. Connection Breakdown"
psql "$CONN_STRING" -c "
    SELECT 
        state,
        count(*) as connections,
        round(100.0 * count(*) / (SELECT count(*) FROM pg_stat_activity), 2) as percentage
    FROM pg_stat_activity
    GROUP BY state
    ORDER BY connections DESC;
"

# Check for connection warnings
TOTAL_CONN=$(psql "$CONN_STRING" -t -c "SELECT count(*) FROM pg_stat_activity;" | xargs)
MAX_CONN=$(psql "$CONN_STRING" -t -c "SELECT setting::int FROM pg_settings WHERE name = 'max_connections';" | xargs)
USAGE_PERCENT=$((100 * TOTAL_CONN / MAX_CONN))

if [ "$USAGE_PERCENT" -gt 80 ]; then
    print_error "Connection usage is at ${USAGE_PERCENT}% (${TOTAL_CONN}/${MAX_CONN})"
    print_warning "Consider closing idle connections or upgrading compute tier"
elif [ "$USAGE_PERCENT" -gt 60 ]; then
    print_warning "Connection usage is at ${USAGE_PERCENT}% (${TOTAL_CONN}/${MAX_CONN})"
else
    print_success "Connection usage is healthy: ${USAGE_PERCENT}% (${TOTAL_CONN}/${MAX_CONN})"
fi

# Active queries
print_header "5. Active Queries"
ACTIVE_QUERIES=$(psql "$CONN_STRING" -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND query NOT LIKE '%pg_stat_activity%';" | xargs)
if [ "$ACTIVE_QUERIES" -gt 0 ]; then
    print_info "Found $ACTIVE_QUERIES active queries"
    psql "$CONN_STRING" -c "
        SELECT 
            pid,
            usename,
            application_name,
            now() - query_start as duration,
            left(query, 80) as query
        FROM pg_stat_activity
        WHERE state = 'active'
          AND query NOT LIKE '%pg_stat_activity%'
        ORDER BY query_start
        LIMIT 10;
    "
else
    print_success "No active queries (database is idle)"
fi

# Long-running queries
print_header "6. Long-Running Queries"
LONG_QUERIES=$(psql "$CONN_STRING" -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '30 seconds' AND query NOT LIKE '%pg_stat_activity%';" | xargs)
if [ "$LONG_QUERIES" -gt 0 ]; then
    print_warning "Found $LONG_QUERIES queries running longer than 30 seconds"
    psql "$CONN_STRING" -c "
        SELECT 
            pid,
            usename,
            now() - query_start as duration,
            left(query, 100) as query
        FROM pg_stat_activity
        WHERE state = 'active'
          AND now() - query_start > interval '30 seconds'
          AND query NOT LIKE '%pg_stat_activity%'
        ORDER BY query_start
        LIMIT 5;
    "
else
    print_success "No long-running queries detected"
fi

# Idle in transaction
print_header "7. Idle in Transaction"
IDLE_IN_TRANS=$(psql "$CONN_STRING" -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction';" | xargs)
if [ "$IDLE_IN_TRANS" -gt 0 ]; then
    print_warning "Found $IDLE_IN_TRANS connections idle in transaction"
    print_info "These connections may be holding locks and should be investigated"
    psql "$CONN_STRING" -c "
        SELECT 
            pid,
            usename,
            application_name,
            now() - state_change as idle_duration,
            left(query, 80) as last_query
        FROM pg_stat_activity
        WHERE state = 'idle in transaction'
        ORDER BY state_change
        LIMIT 5;
    "
else
    print_success "No connections idle in transaction"
fi

# Database locks
print_header "8. Database Locks"
LOCKS=$(psql "$CONN_STRING" -t -c "SELECT count(*) FROM pg_locks WHERE granted = false;" | xargs)
if [ "$LOCKS" -gt 0 ]; then
    print_warning "Found $LOCKS blocked queries waiting for locks"
    psql "$CONN_STRING" -c "
        SELECT 
            blocked_locks.pid AS blocked_pid,
            blocked_activity.usename AS blocked_user,
            blocking_locks.pid AS blocking_pid,
            blocking_activity.usename AS blocking_user,
            blocked_activity.query AS blocked_statement
        FROM pg_catalog.pg_locks blocked_locks
        JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
        JOIN pg_catalog.pg_locks blocking_locks 
            ON blocking_locks.locktype = blocked_locks.locktype
            AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
            AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
            AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
            AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
            AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
            AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
            AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
            AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
            AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
            AND blocking_locks.pid != blocked_locks.pid
        JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
        WHERE NOT blocked_locks.granted
        LIMIT 5;
    " 2>/dev/null || print_info "No detailed lock information available"
else
    print_success "No blocked queries"
fi

# Database size
print_header "9. Database Size"
psql "$CONN_STRING" -c "
    SELECT 
        current_database() as database,
        pg_size_pretty(pg_database_size(current_database())) as size;
"

# Top tables by size
print_header "10. Largest Tables"
psql "$CONN_STRING" -c "
    SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
        pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                      pg_relation_size(schemaname||'.'||tablename)) as indexes_size
    FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
    LIMIT 5;
" 2>/dev/null || print_info "Cannot access table size information"

# Cache hit ratio
print_header "11. Cache Performance"
psql "$CONN_STRING" -c "
    SELECT 
        'Buffer Cache Hit Ratio' as metric,
        round(100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) || '%' as value
    FROM pg_statio_user_tables
    UNION ALL
    SELECT 
        'Index Cache Hit Ratio' as metric,
        round(100.0 * sum(idx_blks_hit) / NULLIF(sum(idx_blks_hit) + sum(idx_blks_read), 0), 2) || '%' as value
    FROM pg_statio_user_indexes;
" 2>/dev/null || print_info "Cache statistics not available"

# Check if statistics are enabled
STATS_ENABLED=$(psql "$CONN_STRING" -t -c "SELECT setting FROM pg_settings WHERE name = 'track_activities';" | xargs)
if [ "$STATS_ENABLED" = "on" ]; then
    print_success "Activity tracking is enabled"
else
    print_warning "Activity tracking is disabled. Some metrics may not be available."
fi

# Recent errors (if available)
print_header "12. Recent Errors"
ERROR_COUNT=$(psql "$CONN_STRING" -t -c "
    SELECT count(*) 
    FROM pg_stat_database_conflicts 
    WHERE datname = current_database();
" 2>/dev/null | xargs || echo "0")

if [ "$ERROR_COUNT" != "0" ] && [ "$ERROR_COUNT" -gt 0 ] 2>/dev/null; then
    print_warning "Found database conflicts"
    psql "$CONN_STRING" -c "
        SELECT * FROM pg_stat_database_conflicts 
        WHERE datname = current_database();
    " 2>/dev/null || print_info "Cannot access conflict information"
else
    print_success "No recent conflicts detected"
fi

# SSL information
print_header "13. SSL Status"
psql "$CONN_STRING" -c "
    SELECT 
        'SSL Enabled' as metric,
        CASE WHEN ssl IS TRUE THEN 'Yes' ELSE 'No' END as value
    FROM pg_stat_ssl
    WHERE pid = pg_backend_pid();
" 2>/dev/null || print_info "SSL information not available"

# Summary
print_header "Health Check Summary"

ISSUES=0

if [ "$USAGE_PERCENT" -gt 80 ]; then
    print_error "Connection pool usage is critical (${USAGE_PERCENT}%)"
    ISSUES=$((ISSUES + 1))
fi

if [ "$LONG_QUERIES" -gt 0 ]; then
    print_warning "Long-running queries detected ($LONG_QUERIES)"
    ISSUES=$((ISSUES + 1))
fi

if [ "$IDLE_IN_TRANS" -gt 0 ]; then
    print_warning "Idle in transaction connections detected ($IDLE_IN_TRANS)"
    ISSUES=$((ISSUES + 1))
fi

if [ "$LOCKS" -gt 0 ]; then
    print_warning "Blocked queries detected ($LOCKS)"
    ISSUES=$((ISSUES + 1))
fi

if [ "$ISSUES" -eq 0 ]; then
    print_success "Database health is good! No issues detected."
else
    print_warning "Found $ISSUES potential issue(s). Review the details above."
fi

echo ""
print_info "For troubleshooting guidance, see: docs/MCP_TROUBLESHOOTING.md"
