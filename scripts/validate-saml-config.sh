#!/bin/bash
# Validate SAML Configuration
# This script checks that SAML SSO is properly configured in docker-compose.yml and .env

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# Change to script directory
cd "$(dirname "$0")/.."

ERRORS=0
WARNINGS=0

print_header "SAML Configuration Validation"

# Check 1: docker-compose.yml exists
print_info "Checking docker-compose.yml..."
if [ ! -f "supabase/docker/docker-compose.yml" ]; then
    print_error "docker-compose.yml not found"
    ERRORS=$((ERRORS + 1))
else
    print_success "docker-compose.yml exists"
    
    # Check if SAML env vars are present
    if grep -q "GOTRUE_SAML_ENABLED" supabase/docker/docker-compose.yml; then
        print_success "GOTRUE_SAML_ENABLED found in docker-compose.yml"
    else
        print_error "GOTRUE_SAML_ENABLED not found in docker-compose.yml"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "GOTRUE_SAML_PRIVATE_KEY" supabase/docker/docker-compose.yml; then
        print_success "GOTRUE_SAML_PRIVATE_KEY found in docker-compose.yml"
    else
        print_error "GOTRUE_SAML_PRIVATE_KEY not found in docker-compose.yml"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check 2: .env file exists and has SAML config
print_info "Checking .env file..."
if [ ! -f ".env" ]; then
    print_error ".env file not found"
    ERRORS=$((ERRORS + 1))
else
    print_success ".env file exists"
    
    # Check if SAML is enabled
    if grep -q "^GOTRUE_SAML_ENABLED=true" .env; then
        print_success "GOTRUE_SAML_ENABLED=true in .env"
    elif grep -q "^GOTRUE_SAML_ENABLED=false" .env; then
        print_warning "GOTRUE_SAML_ENABLED=false in .env (SAML is disabled)"
        WARNINGS=$((WARNINGS + 1))
    else
        print_error "GOTRUE_SAML_ENABLED not set in .env"
        ERRORS=$((ERRORS + 1))
    fi
    
    # Check if private key is set
    if grep -q "^GOTRUE_SAML_PRIVATE_KEY=.\{100,\}" .env; then
        print_success "GOTRUE_SAML_PRIVATE_KEY is set in .env (appears to be valid length)"
    elif grep -q "^GOTRUE_SAML_PRIVATE_KEY=" .env; then
        print_error "GOTRUE_SAML_PRIVATE_KEY is set but appears empty or too short"
        ERRORS=$((ERRORS + 1))
    else
        print_error "GOTRUE_SAML_PRIVATE_KEY not set in .env"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check 3: Validate YAML syntax (if Python available)
if command -v python3 &> /dev/null; then
    print_info "Validating docker-compose.yml YAML syntax..."
    if python3 -c "import yaml; yaml.safe_load(open('supabase/docker/docker-compose.yml'))" 2>/dev/null; then
        print_success "docker-compose.yml is valid YAML"
    else
        print_error "docker-compose.yml has YAML syntax errors"
        ERRORS=$((ERRORS + 1))
    fi
else
    print_warning "Python3 not available, skipping YAML validation"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 4: Auth service configuration
print_info "Checking auth service in docker-compose.yml..."
if grep -q "container_name: supabase-auth" supabase/docker/docker-compose.yml; then
    print_success "Auth service (supabase-auth) found"
else
    print_error "Auth service not found in docker-compose.yml"
    ERRORS=$((ERRORS + 1))
fi

# Summary
print_header "Validation Summary"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_success "All checks passed! SAML configuration is valid."
    echo ""
    echo "Next steps:"
    echo "  1. Start Supabase: cd supabase/docker && docker compose up -d"
    echo "  2. Verify SAML endpoint: curl http://localhost:8000/auth/v1/sso/saml/metadata"
    echo "  3. Configure ZITADEL IdP"
    echo "  4. Register SAML provider: ./scripts/saml-setup.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    print_warning "$WARNINGS warning(s) found, but configuration is functional"
    exit 0
else
    print_error "$ERRORS error(s) and $WARNINGS warning(s) found"
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi
