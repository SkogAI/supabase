#!/bin/bash
# AI Agent Database Connection Test Script
# Tests various connection scenarios and provides diagnostic information

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

# Check if required tools are installed
check_requirements() {
    print_header "Checking Requirements"
    
    local all_good=true
    
    if command -v psql &> /dev/null; then
        print_success "psql is installed: $(psql --version | head -n1)"
    else
        print_error "psql is not installed. Install with: apt-get install postgresql-client"
        all_good=false
    fi
    
    if command -v openssl &> /dev/null; then
        print_success "openssl is installed: $(openssl version)"
    else
        print_warning "openssl is not installed. SSL tests will be skipped."
    fi
    
    if command -v nc &> /dev/null; then
        print_success "netcat is installed"
    elif command -v telnet &> /dev/null; then
        print_success "telnet is installed"
    else
        print_warning "Neither netcat nor telnet found. Network tests will be limited."
    fi
    
    if [ "$all_good" = false ]; then
        print_error "Required tools are missing. Please install them first."
        exit 1
    fi
}

# Test basic connectivity
test_connectivity() {
    print_header "Testing Network Connectivity"
    
    local host=$1
    local port=$2
    
    print_info "Testing connection to $host:$port..."
    
    # Test DNS resolution
    if host "$host" &> /dev/null; then
        print_success "DNS resolution successful"
        host "$host" | grep "has address" | head -n2
    else
        print_error "DNS resolution failed"
        return 1
    fi
    
    # Test port connectivity
    if command -v nc &> /dev/null; then
        if timeout 5 nc -zv "$host" "$port" 2>&1 | grep -q "succeeded\|open"; then
            print_success "Port $port is reachable"
        else
            print_error "Port $port is not reachable"
            return 1
        fi
    elif command -v telnet &> /dev/null; then
        if timeout 5 telnet "$host" "$port" 2>&1 | grep -q "Connected\|Escape"; then
            print_success "Port $port is reachable"
        else
            print_error "Port $port is not reachable"
            return 1
        fi
    fi
    
    # Test latency
    print_info "Testing latency..."
    if command -v ping &> /dev/null; then
        if ping -c 3 "$host" 2>&1 | grep -q "3 received\|3 packets received"; then
            print_success "Host is responding to ping"
            ping -c 3 "$host" 2>&1 | grep "rtt\|round-trip" || true
        else
            print_warning "Host is not responding to ping (may be blocked)"
        fi
    fi
}

# Test SSL/TLS connection
test_ssl() {
    print_header "Testing SSL/TLS Connection"
    
    local host=$1
    local port=$2
    
    if ! command -v openssl &> /dev/null; then
        print_warning "openssl not available, skipping SSL tests"
        return 0
    fi
    
    print_info "Testing SSL connection to $host:$port..."
    
    # Test SSL connection
    if timeout 10 echo | openssl s_client -connect "$host:$port" -starttls postgres 2>&1 | grep -q "Verify return code: 0"; then
        print_success "SSL connection successful with valid certificate"
    elif timeout 10 echo | openssl s_client -connect "$host:$port" -starttls postgres 2>&1 | grep -q "SSL-Session"; then
        print_warning "SSL connection established but certificate verification may have issues"
    else
        print_error "SSL connection failed"
        return 1
    fi
    
    # Show certificate details
    print_info "Certificate details:"
    timeout 10 echo | openssl s_client -connect "$host:$port" -starttls postgres 2>&1 | \
        grep -A2 "subject\|issuer\|notAfter" | head -n6 || true
}

# Test database connection
test_database_connection() {
    print_header "Testing Database Connection"
    
    local conn_string=$1
    local description=$2
    
    print_info "Testing: $description"
    print_info "Connection string: $(echo $conn_string | sed 's/:.*@/:***@/')"
    
    # Test basic connection
    if psql "$conn_string" -c "SELECT 1;" &> /dev/null; then
        print_success "Connection successful"
    else
        print_error "Connection failed"
        psql "$conn_string" -c "SELECT 1;" 2>&1 | tail -n5
        return 1
    fi
    
    # Test query execution
    print_info "Testing query execution..."
    if result=$(psql "$conn_string" -t -c "SELECT version();" 2>&1); then
        print_success "Query executed successfully"
        echo "  PostgreSQL version: $(echo $result | grep -oP 'PostgreSQL \d+\.\d+' || echo 'Unknown')"
    else
        print_error "Query execution failed"
        return 1
    fi
    
    # Test connection info
    print_info "Connection information:"
    psql "$conn_string" -t -c "
        SELECT 
            'Database: ' || current_database() || ', ' ||
            'User: ' || current_user || ', ' ||
            'SSL: ' || CASE WHEN ssl IS TRUE THEN 'Yes' ELSE 'No' END
        FROM pg_stat_ssl
        WHERE pid = pg_backend_pid();
    " 2>&1 | sed 's/^/  /' || true
    
    # Check active connections
    print_info "Active connections:"
    psql "$conn_string" -t -c "
        SELECT 
            'Total: ' || count(*) || ', ' ||
            'Active: ' || count(*) FILTER (WHERE state = 'active') || ', ' ||
            'Idle: ' || count(*) FILTER (WHERE state = 'idle')
        FROM pg_stat_activity;
    " 2>&1 | sed 's/^/  /' || true
}

# Test prepared statements
test_prepared_statements() {
    print_header "Testing Prepared Statements"
    
    local conn_string=$1
    
    print_info "Testing if prepared statements are supported..."
    
    # Try to use a prepared statement
    if psql "$conn_string" -c "PREPARE test_stmt AS SELECT 1; EXECUTE test_stmt; DEALLOCATE test_stmt;" &> /dev/null; then
        print_success "Prepared statements are supported (Session mode)"
    else
        print_warning "Prepared statements are NOT supported (Transaction mode)"
        print_info "This is expected for Supavisor transaction mode (port 6543)"
        print_info "Use session mode (port 5432) if prepared statements are required"
    fi
}

# Test RLS policies
test_rls_policies() {
    print_header "Testing RLS Policies"
    
    local conn_string=$1
    
    print_info "Checking RLS configuration..."
    
    # Check if any tables have RLS enabled
    local rls_tables=$(psql "$conn_string" -t -c "
        SELECT count(*) 
        FROM pg_tables 
        WHERE schemaname = 'public' 
          AND tablename IN (
              SELECT tablename 
              FROM pg_tables 
              WHERE rowsecurity = true
          );
    " 2>&1)
    
    if [ "$rls_tables" -gt 0 ] 2>/dev/null; then
        print_success "Found $rls_tables table(s) with RLS enabled"
        print_info "Listing tables with RLS:"
        psql "$conn_string" -c "
            SELECT tablename, rowsecurity 
            FROM pg_tables 
            WHERE schemaname = 'public' 
              AND rowsecurity = true
            LIMIT 5;
        " 2>&1 | sed 's/^/  /' || true
    else
        print_info "No tables with RLS enabled found (or connection has limited permissions)"
    fi
}

# Main test function
run_connection_test() {
    local conn_string=$1
    
    if [ -z "$conn_string" ]; then
        print_error "No connection string provided"
        echo ""
        echo "Usage: $0 <connection_string>"
        echo ""
        echo "Example:"
        echo "  $0 'postgresql://postgres:password@db.xxx.supabase.co:5432/postgres'"
        echo ""
        echo "Or set DATABASE_URL environment variable:"
        echo "  export DATABASE_URL='postgresql://postgres:password@db.xxx.supabase.co:5432/postgres'"
        echo "  $0"
        exit 1
    fi
    
    # Parse connection string to extract host and port
    local host=$(echo "$conn_string" | grep -oP '(?<=@)[^:]+' || echo "")
    local port=$(echo "$conn_string" | grep -oP '(?<=:)\d+(?=/|$)' || echo "5432")
    
    if [ -z "$host" ]; then
        print_error "Could not parse host from connection string"
        exit 1
    fi
    
    print_header "AI Agent Database Connection Test"
    print_info "Host: $host"
    print_info "Port: $port"
    print_info "Timestamp: $(date)"
    
    # Run tests
    check_requirements
    
    if test_connectivity "$host" "$port"; then
        test_ssl "$host" "$port"
        test_database_connection "$conn_string" "Main connection"
        test_prepared_statements "$conn_string"
        test_rls_policies "$conn_string"
    else
        print_error "Network connectivity test failed. Cannot proceed with database tests."
        exit 1
    fi
    
    # Summary
    print_header "Test Summary"
    print_success "All tests completed!"
    print_info "Check the output above for any warnings or errors."
    echo ""
    print_info "For more troubleshooting information, see:"
    print_info "  docs/MCP_TROUBLESHOOTING.md"
}

# IPv6 detection
detect_ipv6() {
    print_header "IPv4/IPv6 Detection"
    
    local host=$1
    
    print_info "Detecting IP version support..."
    
    # Test IPv4
    if ping -4 -c 1 -W 2 "$host" &> /dev/null; then
        print_success "IPv4 is supported"
    else
        print_warning "IPv4 is not supported or host doesn't respond to ping"
    fi
    
    # Test IPv6
    if command -v ping6 &> /dev/null; then
        if ping6 -c 1 -W 2 "$host" &> /dev/null; then
            print_success "IPv6 is supported"
        else
            print_warning "IPv6 is not supported"
            print_info "Consider using Supavisor session mode for IPv4 compatibility"
        fi
    elif ping -6 -c 1 -W 2 "$host" &> /dev/null; then
        print_success "IPv6 is supported"
    else
        print_warning "Cannot test IPv6 (ping6 not available or not supported)"
        print_info "If direct connections fail, try Supavisor session mode"
    fi
    
    # Show IP addresses
    print_info "Resolved IP addresses:"
    host "$host" | grep "has address\|has IPv6" | sed 's/^/  /' || true
}

# Parse arguments
if [ $# -eq 0 ]; then
    # Use DATABASE_URL from environment
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

# Extract host for IPv6 detection
HOST=$(echo "$CONN_STRING" | grep -oP '(?<=@)[^:]+' || echo "")
if [ -n "$HOST" ]; then
    detect_ipv6 "$HOST"
fi

# Run main tests
run_connection_test "$CONN_STRING"
