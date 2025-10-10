#!/bin/bash

# Session Pool Monitoring Script for Supabase MCP Server
# This script monitors connection pool health for session mode connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Supabase Session Pool Monitor${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo

# Check if connection string is set
if [ -z "$SUPABASE_SESSION_POOLER" ]; then
    echo -e "${YELLOW}⚠️  SUPABASE_SESSION_POOLER not set in .env file${NC}"
    echo -e "${YELLOW}   Using local connection instead${NC}"
    CONNECTION_STRING="postgresql://postgres:postgres@localhost:54322/postgres"
else
    CONNECTION_STRING="$SUPABASE_SESSION_POOLER"
fi

# Function to run SQL query
run_query() {
    local query="$1"
    psql "$CONNECTION_STRING" -t -c "$query" 2>/dev/null || echo "Error"
}

# Check connection
echo -e "${BLUE}📡 Testing connection...${NC}"
RESULT=$(run_query "SELECT 1;" | xargs)
if [ "$RESULT" = "1" ]; then
    echo -e "${GREEN}✅ Connection successful${NC}"
    echo
else
    echo -e "${RED}❌ Connection failed${NC}"
    echo -e "${YELLOW}   Check your connection string in .env${NC}"
    exit 1
fi

# Get current timestamp
echo -e "${BLUE}🕐 Current time: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo

# Monitor active connections
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Connection Pool Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

QUERY="
SELECT 
    count(*) as total,
    count(*) FILTER (WHERE state = 'active') as active,
    count(*) FILTER (WHERE state = 'idle') as idle,
    count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
    count(*) FILTER (WHERE state = 'disabled') as disabled
FROM pg_stat_activity
WHERE datname = 'postgres';
"

RESULT=$(run_query "$QUERY")
echo "$RESULT" | while read -r total active idle idle_tx disabled; do
    echo -e "  Total connections:           ${GREEN}$total${NC}"
    echo -e "  Active:                      ${GREEN}$active${NC}"
    echo -e "  Idle:                        ${YELLOW}$idle${NC}"
    if [ "$idle_tx" -gt 0 ]; then
        echo -e "  Idle in transaction:         ${RED}$idle_tx${NC} ⚠️"
    else
        echo -e "  Idle in transaction:         ${GREEN}$idle_tx${NC}"
    fi
    echo -e "  Disabled:                    $disabled"
done
echo

# MCP-specific connections
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🤖 MCP Agent Connections${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

QUERY="
SELECT 
    count(*) as mcp_connections,
    count(*) FILTER (WHERE state = 'active') as mcp_active
FROM pg_stat_activity
WHERE datname = 'postgres' 
    AND application_name LIKE '%mcp%';
"

RESULT=$(run_query "$QUERY")
echo "$RESULT" | while read -r mcp_total mcp_active; do
    if [ "$mcp_total" -gt 0 ]; then
        echo -e "  MCP connections:             ${GREEN}$mcp_total${NC}"
        echo -e "  MCP active:                  ${GREEN}$mcp_active${NC}"
    else
        echo -e "  ${YELLOW}No MCP connections found${NC}"
        echo -e "  ${YELLOW}Set application_name='*-mcp-*' in your client${NC}"
    fi
done
echo

# Connection age
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⏱️  Connection Duration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

QUERY="
SELECT 
    EXTRACT(EPOCH FROM max(now() - backend_start))::integer as max_age_seconds,
    EXTRACT(EPOCH FROM avg(now() - backend_start))::integer as avg_age_seconds,
    EXTRACT(EPOCH FROM max(now() - state_change))::integer as max_idle_seconds
FROM pg_stat_activity
WHERE datname = 'postgres' AND state != 'disabled';
"

RESULT=$(run_query "$QUERY")
echo "$RESULT" | while read -r max_age avg_age max_idle; do
    echo -e "  Oldest connection:           ${YELLOW}$max_age seconds${NC}"
    echo -e "  Average connection age:      $avg_age seconds"
    if [ "$max_idle" -gt 300 ]; then
        echo -e "  Max idle time:               ${RED}$max_idle seconds${NC} ⚠️"
        echo -e "  ${YELLOW}Consider reducing idle timeout${NC}"
    else
        echo -e "  Max idle time:               ${GREEN}$max_idle seconds${NC}"
    fi
done
echo

# Long-running queries
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🐌 Long-Running Queries${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

QUERY="
SELECT 
    count(*) as long_queries,
    EXTRACT(EPOCH FROM max(now() - query_start))::integer as max_duration
FROM pg_stat_activity
WHERE datname = 'postgres' 
    AND state = 'active'
    AND now() - query_start > interval '30 seconds';
"

RESULT=$(run_query "$QUERY")
echo "$RESULT" | while read -r count duration; do
    if [ "$count" -gt 0 ]; then
        echo -e "  ${RED}⚠️  Found $count queries running > 30 seconds${NC}"
        echo -e "  Longest query:               ${RED}$duration seconds${NC}"
        echo -e "  ${YELLOW}Consider optimizing or adding indexes${NC}"
    else
        echo -e "  ${GREEN}✅ No long-running queries${NC}"
    fi
done
echo

# Database size and connections limit
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💾 Database Metrics${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get max connections
MAX_CONN=$(run_query "SHOW max_connections;" | xargs)
echo -e "  Max connections:             $MAX_CONN"

# Get current connections
CURRENT_CONN=$(run_query "SELECT count(*) FROM pg_stat_activity;" | xargs)
echo -e "  Current connections:         $CURRENT_CONN"

# Calculate utilization
if [ -n "$MAX_CONN" ] && [ "$MAX_CONN" != "Error" ]; then
    UTIL=$((100 * CURRENT_CONN / MAX_CONN))
    if [ "$UTIL" -gt 80 ]; then
        echo -e "  Utilization:                 ${RED}$UTIL%${NC} ⚠️"
        echo -e "  ${YELLOW}Consider increasing max_connections or pool size${NC}"
    elif [ "$UTIL" -gt 60 ]; then
        echo -e "  Utilization:                 ${YELLOW}$UTIL%${NC}"
    else
        echo -e "  Utilization:                 ${GREEN}$UTIL%${NC}"
    fi
fi
echo

# Recommendations
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💡 Recommendations${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check idle in transaction
IDLE_TX=$(run_query "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction';" | xargs)
if [ "$IDLE_TX" -gt 0 ]; then
    echo -e "  ${RED}⚠️  $IDLE_TX idle transactions detected${NC}"
    echo -e "     Set idle_in_transaction_session_timeout"
    echo
fi

# Check long idle connections
LONG_IDLE=$(run_query "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle' AND now() - state_change > interval '10 minutes';" | xargs)
if [ "$LONG_IDLE" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠️  $LONG_IDLE connections idle > 10 minutes${NC}"
    echo -e "     Consider reducing DB_POOL_IDLE_TIMEOUT"
    echo
fi

# General recommendations
if [ "$UTIL" -gt 70 ]; then
    echo -e "  ${YELLOW}High connection utilization:${NC}"
    echo -e "     • Increase compute tier for more connections"
    echo -e "     • Optimize queries to reduce duration"
    echo -e "     • Consider connection pooling strategies"
    echo
fi

echo -e "${GREEN}✅ Monitoring complete${NC}"
echo
echo -e "${BLUE}For continuous monitoring, run:${NC}"
echo -e "  watch -n 30 './scripts/monitor-session-pool.sh'"
echo
