#!/bin/bash

# ============================================================================
# SAML Docker Logs Check Script
# ============================================================================
# Checks Docker logs for SAML-related entries and errors
#
# Usage:
#   ./scripts/check_saml_logs.sh
#
# Options:
#   -f, --follow    Follow logs in real-time
#   -t, --tail N    Show last N lines (default: 100)
#   -s, --service   Specific service (auth, kong, all)
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
FOLLOW=false
TAIL_LINES=100
SERVICE="all"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -t|--tail)
            TAIL_LINES="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-f] [-t N] [-s service]"
            echo ""
            echo "Options:"
            echo "  -f, --follow      Follow logs in real-time"
            echo "  -t, --tail N      Show last N lines (default: 100)"
            echo "  -s, --service S   Specific service: auth, kong, or all (default: all)"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

# Helper functions
print_header() {
    echo ""
    echo "================================================================================"
    echo "$1"
    echo "================================================================================"
    echo ""
}

print_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_fail() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if docker-compose is available
check_docker() {
    if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
        print_fail "Docker not found"
        echo "Please ensure Docker is installed and running"
        exit 1
    fi
    
    # Check if containers are running
    if command -v docker-compose &> /dev/null; then
        RUNNING=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    else
        RUNNING=$(docker compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    fi
    
    if [ "$RUNNING" -eq 0 ]; then
        print_warning "No Docker containers running"
        print_info "Start Supabase: npm run db:start"
        exit 1
    fi
}

# Get logs for a service
get_service_logs() {
    local service=$1
    local keyword=$2
    
    if command -v docker-compose &> /dev/null; then
        DOCKER_CMD="docker-compose"
    else
        DOCKER_CMD="docker compose"
    fi
    
    if [ "$FOLLOW" = true ]; then
        $DOCKER_CMD logs -f "$service" | grep -i "$keyword" --color=always
    else
        $DOCKER_CMD logs --tail="$TAIL_LINES" "$service" | grep -i "$keyword" --color=always
    fi
}

# Check auth service logs
check_auth_logs() {
    print_header "Auth Service Logs (GoTrue)"
    
    print_info "Filtering for SAML-related entries..."
    echo ""
    
    # Get SAML-related logs
    SAML_LOGS=$(get_service_logs "auth" "saml" 2>&1 || echo "")
    
    if [ -z "$SAML_LOGS" ]; then
        print_warning "No SAML entries found in auth logs"
        print_info "This is normal if no SAML authentication has occurred yet"
    else
        echo "$SAML_LOGS"
        echo ""
        
        # Count different log levels
        ERROR_COUNT=$(echo "$SAML_LOGS" | grep -ci "error" || echo "0")
        WARN_COUNT=$(echo "$SAML_LOGS" | grep -ci "warn" || echo "0")
        INFO_COUNT=$(echo "$SAML_LOGS" | grep -ci "info" || echo "0")
        
        echo "Summary:"
        if [ "$ERROR_COUNT" -gt 0 ]; then
            print_fail "${ERROR_COUNT} error(s) found"
        else
            print_pass "No errors found"
        fi
        
        if [ "$WARN_COUNT" -gt 0 ]; then
            print_warning "${WARN_COUNT} warning(s) found"
        fi
        
        print_info "${INFO_COUNT} info message(s) found"
    fi
}

# Check Kong logs
check_kong_logs() {
    print_header "Kong Gateway Logs"
    
    print_info "Filtering for SAML endpoint requests..."
    echo ""
    
    # Get SAML endpoint logs
    KONG_LOGS=$(get_service_logs "kong" "saml" 2>&1 || echo "")
    
    if [ -z "$KONG_LOGS" ]; then
        print_warning "No SAML entries found in Kong logs"
        print_info "This is normal if no SAML requests have been made yet"
    else
        echo "$KONG_LOGS"
        echo ""
        
        # Check for specific endpoints
        METADATA_COUNT=$(echo "$KONG_LOGS" | grep -c "/sso/saml/metadata" || echo "0")
        ACS_COUNT=$(echo "$KONG_LOGS" | grep -c "/sso/saml/acs" || echo "0")
        SSO_COUNT=$(echo "$KONG_LOGS" | grep -c "/sso?" || echo "0")
        
        echo "Endpoint Access Summary:"
        print_info "Metadata endpoint: ${METADATA_COUNT} request(s)"
        print_info "ACS endpoint: ${ACS_COUNT} request(s)"
        print_info "SSO initiation: ${SSO_COUNT} request(s)"
        
        # Check for errors
        ERROR_COUNT=$(echo "$KONG_LOGS" | grep -ci "error\|500\|502\|503" || echo "0")
        if [ "$ERROR_COUNT" -gt 0 ]; then
            print_fail "${ERROR_COUNT} error(s) found"
        else
            print_pass "No errors found"
        fi
    fi
}

# Check all service health
check_service_health() {
    print_header "Service Health Status"
    
    if command -v docker-compose &> /dev/null; then
        DOCKER_CMD="docker-compose"
    else
        DOCKER_CMD="docker compose"
    fi
    
    # Get service status
    $DOCKER_CMD ps
    echo ""
    
    # Check if services are healthy
    UNHEALTHY=$($DOCKER_CMD ps | grep -c "unhealthy" || echo "0")
    
    if [ "$UNHEALTHY" -gt 0 ]; then
        print_fail "${UNHEALTHY} unhealthy service(s) found"
    else
        print_pass "All services healthy"
    fi
}

# Follow logs in real-time
follow_logs() {
    print_header "Following SAML Logs (Ctrl+C to stop)"
    
    print_info "Watching for SAML-related entries..."
    echo ""
    
    if command -v docker-compose &> /dev/null; then
        DOCKER_CMD="docker-compose"
    else
        DOCKER_CMD="docker compose"
    fi
    
    if [ "$SERVICE" = "auth" ]; then
        $DOCKER_CMD logs -f auth | grep -i "saml" --color=always
    elif [ "$SERVICE" = "kong" ]; then
        $DOCKER_CMD logs -f kong | grep -i "saml" --color=always
    else
        $DOCKER_CMD logs -f auth kong | grep -i "saml" --color=always
    fi
}

# Main execution
main() {
    print_header "SAML Docker Logs Analysis"
    
    check_docker
    
    if [ "$FOLLOW" = true ]; then
        follow_logs
    else
        if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "auth" ]; then
            check_auth_logs
        fi
        
        if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "kong" ]; then
            check_kong_logs
        fi
        
        check_service_health
        
        print_header "Summary"
        print_info "Logs analyzed for SAML-related entries"
        print_info "Use -f to follow logs in real-time"
        print_info "Use -s auth or -s kong to check specific service"
        echo ""
        print_info "To view all logs: docker-compose logs"
        print_info "To follow all logs: docker-compose logs -f"
    fi
}

# Run main function
main
