#!/bin/bash
# Supabase Project Setup Script
# This script sets up your local development environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check Docker
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            print_success "Docker is installed and running"
        else
            print_error "Docker is installed but not running"
            print_info "Please start Docker Desktop and try again"
            exit 1
        fi
    else
        print_error "Docker is not installed"
        print_info "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
        exit 1
    fi

    # Check Supabase CLI
    if command -v supabase &> /dev/null; then
        SUPABASE_VERSION=$(supabase --version | head -n1)
        print_success "Supabase CLI is installed ($SUPABASE_VERSION)"
    else
        print_error "Supabase CLI is not installed"
        print_info "Install: https://supabase.com/docs/guides/cli/getting-started"
        exit 1
    fi

    # Check Node.js (optional but recommended)
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js is installed ($NODE_VERSION)"
    else
        print_warning "Node.js is not installed (optional for TypeScript types)"
        print_info "Install: https://nodejs.org/"
    fi

    # Check Deno (for edge functions)
    if command -v deno &> /dev/null; then
        DENO_VERSION=$(deno --version | head -n1)
        print_success "Deno is installed ($DENO_VERSION)"
    else
        print_warning "Deno is not installed (needed for edge functions)"
        print_info "Install: https://deno.land/"
    fi
}

# Setup environment
setup_environment() {
    print_header "Setting Up Environment"

    if [ ! -f .env ]; then
        print_info "Creating .env file from .env.example"
        cp .env.example .env
        print_success ".env file created"
        print_warning "Please edit .env and add your API keys"
    else
        print_info ".env file already exists"
    fi
}

# Install dependencies
install_dependencies() {
    print_header "Installing Dependencies"

    if [ -f package.json ] && command -v npm &> /dev/null; then
        print_info "Installing npm packages..."
        npm install
        print_success "npm packages installed"
    else
        print_warning "No package.json found or npm not available"
    fi
}

# Start Supabase
start_supabase() {
    print_header "Starting Supabase"

    print_info "This may take a few minutes on first run..."
    supabase start

    print_success "Supabase started successfully!"
}

# Generate types
generate_types() {
    print_header "Generating TypeScript Types"

    if command -v npm &> /dev/null; then
        mkdir -p types
        print_info "Generating types from database schema..."
        npm run types:generate || supabase gen types typescript --local > types/database.ts
        print_success "TypeScript types generated at types/database.ts"
    else
        print_warning "npm not available, skipping type generation"
        print_info "Run manually: supabase gen types typescript --local > types/database.ts"
    fi
}

# Show access info
show_access_info() {
    print_header "Access Information"

    print_success "Setup complete! Your Supabase instance is running."
    echo ""
    echo "Access your local Supabase:"
    echo ""
    echo -e "  ${GREEN}Studio UI:${NC}    http://localhost:8000"
    echo -e "  ${GREEN}API URL:${NC}      http://localhost:8000"
    echo -e "  ${GREEN}Database:${NC}     postgresql://postgres:postgres@localhost:54322/postgres"
    echo ""
    echo "Useful commands:"
    echo ""
    echo -e "  ${BLUE}supabase status${NC}              - View service status"
    echo -e "  ${BLUE}supabase stop${NC}                - Stop all services"
    echo -e "  ${BLUE}supabase db reset${NC}            - Reset database with migrations"
    echo -e "  ${BLUE}npm run types:generate${NC}       - Regenerate TypeScript types"
    echo -e "  ${BLUE}npm run functions:serve${NC}      - Start edge functions"
    echo ""
    print_info "Check DEVOPS.md for comprehensive documentation"
}

# Main execution
main() {
    clear
    print_header "Supabase Project Setup"

    check_prerequisites
    setup_environment
    install_dependencies
    start_supabase
    generate_types
    show_access_info
}

# Run main function
main
