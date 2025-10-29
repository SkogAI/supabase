#!/bin/bash

##############################################################################
# SAML SSO Complete Validation Script
# 
# This script performs a comprehensive validation of the SAML SSO setup,
# checking all components from configuration to endpoints.
#
# Usage: ./validate-saml-complete.sh [options]
# Options:
#   --skip-services    Skip service startup checks
#   --skip-endpoints   Skip endpoint validation
#   --verbose          Show detailed output
#   -h, --help         Show help message
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Options
SKIP_SERVICES=false
SKIP_ENDPOINTS=false
VERBOSE=false

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}ℹ${NC} $1"
    fi
}

increment_total() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

show_help() {
    cat << EOF
SAML SSO Complete Validation Script

This script validates all aspects of the SAML SSO configuration including:
- Configuration files (docker-compose.yml, .env, config.toml)
- SAML certificates and keys
- Docker services (if running)
- SAML endpoints (if services are running)
- Database configuration

Usage: $0 [options]

Options:
    --skip-services    Skip Docker service checks
    --skip-endpoints   Skip SAML endpoint validation
    --verbose          Show detailed output
    -h, --help         Show this help message

Examples:
    # Full validation
    $0

    # Validate configuration only (no services)
    $0 --skip-services --skip-endpoints

    # Verbose output
    $0 --verbose

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-services)
                SKIP_SERVICES=true
                shift
                ;;
            --skip-endpoints)
                SKIP_ENDPOINTS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

##############################################################################
# Validation Functions
##############################################################################

validate_prerequisites() {
    print_section "Checking Prerequisites"

    # Check if we're in the right directory
    increment_total
    if [ -f "supabase/config.toml" ] && [ -f "supabase/docker/docker-compose.yml" ]; then
        print_success "Running from project root directory"
    else
        print_error "Not in project root directory"
        echo "  Please run this script from the repository root"
        return 1
    fi

    # Check required commands
    for cmd in docker openssl curl jq; do
        increment_total
        if command -v $cmd &> /dev/null; then
            print_success "$cmd is installed"
            print_info "$($cmd --version 2>&1 | head -1)"
        else
            print_error "$cmd is not installed"
        fi
    done
}

validate_docker_compose() {
    print_section "Validating docker-compose.yml"

    local compose_file="supabase/docker/docker-compose.yml"

    # Check file exists
    increment_total
    if [ -f "$compose_file" ]; then
        print_success "docker-compose.yml exists"
    else
        print_error "docker-compose.yml not found"
        return 1
    fi

    # Check auth service
    increment_total
    if grep -q "container_name: supabase-auth" "$compose_file"; then
        print_success "Auth service (supabase-auth) configured"
        
        # Get auth image version
        local auth_image=$(grep -A 1 "container_name: supabase-auth" "$compose_file" | grep "image:" | awk '{print $2}')
        print_info "Auth image: $auth_image"
    else
        print_error "Auth service not found"
    fi

    # Check SAML environment variables
    increment_total
    if grep -q "GOTRUE_SAML_ENABLED" "$compose_file"; then
        print_success "GOTRUE_SAML_ENABLED variable configured"
    else
        print_error "GOTRUE_SAML_ENABLED not found in docker-compose.yml"
    fi

    increment_total
    if grep -q "GOTRUE_SAML_PRIVATE_KEY" "$compose_file"; then
        print_success "GOTRUE_SAML_PRIVATE_KEY variable configured"
    else
        print_error "GOTRUE_SAML_PRIVATE_KEY not found in docker-compose.yml"
    fi

    # Validate YAML syntax
    increment_total
    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$compose_file'))" 2>/dev/null; then
            print_success "YAML syntax is valid"
        else
            print_error "YAML syntax errors detected"
        fi
    else
        print_warning "Python3 not available, skipping YAML validation"
    fi
}

validate_env_file() {
    print_section "Validating .env File"

    # Check .env exists
    increment_total
    if [ -f ".env" ]; then
        print_success ".env file exists"
    else
        print_error ".env file not found"
        return 1
    fi

    # Check SAML enabled
    increment_total
    if grep -q "^GOTRUE_SAML_ENABLED=true" .env; then
        print_success "GOTRUE_SAML_ENABLED=true"
    elif grep -q "^GOTRUE_SAML_ENABLED=false" .env; then
        print_warning "GOTRUE_SAML_ENABLED=false (SAML is disabled)"
    else
        print_error "GOTRUE_SAML_ENABLED not set"
    fi

    # Check private key
    increment_total
    if grep -q "^GOTRUE_SAML_PRIVATE_KEY=.\{100,\}" .env; then
        local key_length=$(grep "^GOTRUE_SAML_PRIVATE_KEY=" .env | cut -d= -f2 | wc -c)
        print_success "GOTRUE_SAML_PRIVATE_KEY is set (length: $key_length chars)"
        
        # Validate key format
        local key=$(grep "^GOTRUE_SAML_PRIVATE_KEY=" .env | cut -d= -f2)
        
        increment_total
        if echo "$key" | grep -q " "; then
            print_error "Private key contains spaces"
        else
            print_success "Private key has no spaces"
        fi

        increment_total
        local line_count=$(grep "^GOTRUE_SAML_PRIVATE_KEY=" .env | wc -l)
        if [ "$line_count" -eq 1 ]; then
            print_success "Private key is single line"
        else
            print_error "Private key spans multiple lines"
        fi

        # Test base64 decoding and RSA key validity
        increment_total
        if echo "$key" | base64 -d 2>/dev/null | openssl rsa -inform DER -check -noout 2>/dev/null; then
            print_success "Private key is valid base64-encoded RSA DER key"
        elif echo "$key" | base64 -d > /dev/null 2>&1; then
            print_success "Private key is valid base64 (format not verified)"
        else
            print_warning "Private key format could not be verified"
        fi
    else
        print_error "GOTRUE_SAML_PRIVATE_KEY not set or too short"
    fi
}

validate_config_toml() {
    print_section "Validating config.toml"

    local config_file="supabase/config.toml"

    # Check file exists
    increment_total
    if [ -f "$config_file" ]; then
        print_success "config.toml exists"
    else
        print_error "config.toml not found"
        return 1
    fi

    # Check auth section exists
    increment_total
    if grep -q "^\[auth\]" "$config_file"; then
        print_success "Auth section configured"
    else
        print_error "Auth section not found"
    fi

    # Check SAML configuration
    increment_total
    if grep -q "^\[auth.external.saml\]" "$config_file"; then
        print_success "SAML configuration section found"
        
        # Check if enabled
        increment_total
        if grep -A 2 "^\[auth.external.saml\]" "$config_file" | grep -q "enabled = true"; then
            print_success "SAML is enabled in config.toml"
        else
            print_warning "SAML may not be enabled in config.toml"
        fi
    else
        print_error "SAML configuration section not found"
        print_info "Add [auth.external.saml] section to config.toml"
    fi
}

validate_scripts() {
    print_section "Validating SAML Scripts"

    local scripts=(
        "scripts/generate-saml-key.sh"
        "scripts/saml-setup.sh"
        "scripts/validate-saml-config.sh"
        "scripts/test_saml.sh"
        "scripts/check_saml_logs.sh"
        "scripts/test_saml_endpoints.sh"
        "scripts/validate_saml_attributes.sh"
    )

    for script in "${scripts[@]}"; do
        increment_total
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                print_success "$(basename $script) exists and is executable"
            else
                print_warning "$(basename $script) exists but not executable"
                print_info "Run: chmod +x $script"
            fi
        else
            print_error "$(basename $script) not found"
        fi
    done
}

validate_documentation() {
    print_section "Validating Documentation"

    local docs=(
        "SAML_QUICKSTART.md"
        "SAML_SETUP_COMPLETE.md"
        "SAML_IMPLEMENTATION_VALIDATION.md"
        "skogai/guides/saml/SAML Implementation Summary.md"
        "skogai/guides/saml/ZITADEL SAML Integration Guide.md"
        "skogai/guides/saml/SAML Admin API Reference.md"
    )

    for doc in "${docs[@]}"; do
        increment_total
        if [ -f "$doc" ]; then
            print_success "$(basename "$doc") exists"
        else
            print_warning "$(basename "$doc") not found"
        fi
    done
}

validate_docker_services() {
    if [ "$SKIP_SERVICES" = true ]; then
        print_warning "Skipping Docker service checks"
        return 0
    fi

    print_section "Validating Docker Services"

    # Check Docker is running
    increment_total
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        return 1
    fi

    # Check Supabase containers
    increment_total
    local container_count=$(docker ps --filter "name=supabase" --format "{{.Names}}" 2>/dev/null | wc -l)
    if [ "$container_count" -gt 0 ]; then
        print_success "Found $container_count Supabase containers running"
        
        # Check specific containers
        local containers=("supabase-auth" "supabase-db" "supabase-kong")
        for container in "${containers[@]}"; do
            increment_total
            if docker ps --filter "name=$container" --format "{{.Names}}" | grep -q "$container"; then
                local status=$(docker ps --filter "name=$container" --format "{{.Status}}")
                print_success "$container is running ($status)"
            else
                print_warning "$container is not running"
            fi
        done
    else
        print_warning "No Supabase containers running"
        print_info "Start services: cd supabase/docker && docker compose up -d"
    fi

    # Check auth service logs for SAML
    if docker ps --filter "name=supabase-auth" --format "{{.Names}}" | grep -q "supabase-auth"; then
        increment_total
        if docker logs supabase-auth 2>&1 | tail -100 | grep -qi "saml"; then
            print_success "Auth service logs mention SAML"
        else
            print_info "No SAML mentions in recent auth logs"
        fi
    fi
}

validate_endpoints() {
    if [ "$SKIP_ENDPOINTS" = true ]; then
        print_warning "Skipping endpoint validation"
        return 0
    fi

    print_section "Validating SAML Endpoints"

    # Check if services are running
    if ! docker ps --filter "name=supabase-kong" --format "{{.Names}}" | grep -q "supabase-kong"; then
        print_warning "Kong not running, skipping endpoint checks"
        print_info "Start services first: cd supabase/docker && docker compose up -d"
        return 0
    fi

    # Test auth health endpoint
    increment_total
    if curl -sf http://localhost:8000/auth/v1/health > /dev/null 2>&1; then
        print_success "Auth health endpoint responding"
    else
        print_warning "Auth health endpoint not responding"
    fi

    # Test SAML metadata endpoint
    increment_total
    local metadata_response=$(curl -sf http://localhost:8000/auth/v1/sso/saml/metadata 2>&1)
    if [ $? -eq 0 ]; then
        if echo "$metadata_response" | grep -q "EntityDescriptor"; then
            print_success "SAML metadata endpoint returns valid XML"
            
            # Check for required elements
            increment_total
            if echo "$metadata_response" | grep -q "AssertionConsumerService"; then
                print_success "Metadata contains AssertionConsumerService"
            else
                print_warning "Metadata missing AssertionConsumerService"
            fi

            increment_total
            if echo "$metadata_response" | grep -q "X509Certificate"; then
                print_success "Metadata contains X509Certificate"
            else
                print_warning "Metadata missing X509Certificate"
            fi
        else
            print_error "SAML metadata endpoint returns invalid response"
        fi
    else
        print_warning "SAML metadata endpoint not accessible"
        print_info "This is normal if SAML is not fully initialized"
    fi
}

validate_database() {
    print_section "Validating Database Configuration"

    # Check if database is accessible
    if ! docker ps --filter "name=supabase-db" --format "{{.Names}}" | grep -q "supabase-db"; then
        print_warning "Database not running, skipping database checks"
        return 0
    fi

    # Check auth schema
    increment_total
    if docker exec supabase-db psql -U postgres -d postgres -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='auth'" 2>/dev/null | grep -q "1"; then
        print_success "Auth schema exists"
    else
        print_error "Auth schema not found"
    fi

    # Check saml_providers table
    increment_total
    if docker exec supabase-db psql -U postgres -d postgres -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='auth' AND table_name='saml_providers'" 2>/dev/null | grep -q "1"; then
        print_success "saml_providers table exists"
        
        # Check provider count
        local provider_count=$(docker exec supabase-db psql -U postgres -d postgres -tAc "SELECT COUNT(*) FROM auth.saml_providers" 2>/dev/null || echo "0")
        print_info "SAML providers in database: $provider_count"
    else
        print_warning "saml_providers table not found"
        print_info "This is normal if migrations haven't run yet"
    fi
}

##############################################################################
# Summary and Recommendations
##############################################################################

print_summary() {
    print_header "Validation Summary"

    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo ""

    local pass_percentage=0
    if [ $TOTAL_CHECKS -gt 0 ]; then
        pass_percentage=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi

    echo "Pass Rate: ${pass_percentage}%"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}✓ All checks passed!${NC}"
            echo ""
            print_next_steps
        else
            echo -e "${YELLOW}⚠ Configuration valid but with warnings${NC}"
            echo "Review warnings above and address if needed."
            echo ""
            print_next_steps
        fi
        return 0
    else
        echo -e "${RED}✗ Configuration has errors${NC}"
        echo "Please fix the errors above before proceeding."
        echo ""
        print_fixes
        return 1
    fi
}

print_next_steps() {
    print_header "Next Steps"

    echo "Your SAML configuration is valid. Here's what to do next:"
    echo ""
    echo "1. Start Supabase services:"
    echo "   ${YELLOW}cd supabase/docker && docker compose up -d${NC}"
    echo ""
    echo "2. Verify SAML endpoints:"
    echo "   ${YELLOW}curl http://localhost:8000/auth/v1/sso/saml/metadata${NC}"
    echo ""
    echo "3. Configure ZITADEL IdP:"
    echo "   - Follow: skogai/guides/saml/ZITADEL SAML Integration Guide.md"
    echo ""
    echo "4. Register SAML provider:"
    echo "   ${YELLOW}export SERVICE_ROLE_KEY='your-key'${NC}"
    echo "   ${YELLOW}./scripts/saml-setup.sh -d example.com -m https://your-zitadel-url/saml/v2/metadata${NC}"
    echo ""
    echo "5. Test authentication flow:"
    echo "   ${YELLOW}./scripts/test_saml.sh --user-email test@example.com${NC}"
    echo ""
    echo "6. Review comprehensive checklist:"
    echo "   - See: SAML_IMPLEMENTATION_VALIDATION.md"
    echo ""
}

print_fixes() {
    print_header "Common Fixes"

    echo "To fix common issues:"
    echo ""
    echo "1. Missing SAML configuration in config.toml:"
    echo "   Add this section to supabase/config.toml:"
    echo "   ${YELLOW}[auth.external.saml]${NC}"
    echo "   ${YELLOW}enabled = true${NC}"
    echo ""
    echo "2. Missing or invalid private key:"
    echo "   ${YELLOW}./scripts/generate-saml-key.sh${NC}"
    echo "   Then copy the key to .env as GOTRUE_SAML_PRIVATE_KEY"
    echo ""
    echo "3. Docker services not running:"
    echo "   ${YELLOW}cd supabase/docker && docker compose up -d${NC}"
    echo ""
    echo "4. Scripts not executable:"
    echo "   ${YELLOW}chmod +x scripts/*.sh${NC}"
    echo ""
}

##############################################################################
# Main Execution
##############################################################################

main() {
    clear
    print_header "SAML SSO Complete Validation"
    
    parse_args "$@"

    echo "This script will validate your SAML SSO configuration."
    echo "Checks include: configuration files, certificates, services, and endpoints."
    echo ""

    # Run all validations
    validate_prerequisites
    validate_docker_compose
    validate_env_file
    validate_config_toml
    validate_scripts
    validate_documentation
    validate_docker_services
    validate_endpoints
    validate_database

    # Print summary
    print_summary
}

# Run main function
main "$@"
