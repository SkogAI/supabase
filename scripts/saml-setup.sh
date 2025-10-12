#!/bin/bash

##############################################################################
# SAML SSO Setup Script for Self-Hosted Supabase
#
# This script automates the setup of SAML SSO with ZITADEL IdP:
# - Generates certificates
# - Configures environment variables
# - Creates SAML provider via Admin API
# - Validates configuration
#
# Usage: ./saml-setup.sh [options]
# Options:
#   -d, --domain DOMAIN        Email domain for SSO (required)
#   -m, --metadata-url URL     ZITADEL metadata URL (required)
#   -s, --skip-certs           Skip certificate generation
#   -h, --help                 Show this help message
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CERT_DIR="/secure/saml/certs"
BACKUP_DIR="/backups/saml"
SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Command line arguments
DOMAIN=""
METADATA_URL=""
SKIP_CERTS=false

##############################################################################
# Functions
##############################################################################

print_header() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

show_help() {
  cat <<EOF
SAML SSO Setup Script for Self-Hosted Supabase

Usage: $0 [options]

Options:
    -d, --domain DOMAIN        Email domain for SSO (required)
    -m, --metadata-url URL     ZITADEL metadata URL (required)
    -s, --skip-certs           Skip certificate generation
    -h, --help                 Show this help message

Examples:
    # Complete setup
    $0 -d example.com -m https://instance.zitadel.cloud/saml/v2/metadata

    # Skip certificate generation (already have certs)
    $0 -d example.com -m https://instance.zitadel.cloud/saml/v2/metadata -s

Environment Variables:
    SUPABASE_URL              Supabase instance URL (default: http://localhost:8000)
    SERVICE_ROLE_KEY          Supabase service role key (required)
    CERT_DIR                  Certificate directory (default: /secure/saml/certs)

Prerequisites:
    - Docker and Supabase running
    - OpenSSL installed
    - SERVICE_ROLE_KEY environment variable set
    - ZITADEL SAML application configured

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -d | --domain)
      DOMAIN="$2"
      shift 2
      ;;
    -m | --metadata-url)
      METADATA_URL="$2"
      shift 2
      ;;
    -s | --skip-certs)
      SKIP_CERTS=true
      shift
      ;;
    -h | --help)
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

check_prerequisites() {
  print_header "Checking Prerequisites"

  # Check if running as root or with sudo for cert directory creation
  if [ ! -w "$(dirname "$CERT_DIR")" ] && [ "$EUID" -ne 0 ]; then
    print_warning "May need sudo for certificate directory creation"
  fi

  # Check required commands
  for cmd in docker openssl curl jq; do
    if ! command -v $cmd &>/dev/null; then
      print_error "$cmd is not installed"
      exit 1
    fi
    print_success "$cmd is installed"
  done

  # Check Docker is running
  if ! docker info &>/dev/null; then
    print_error "Docker is not running"
    exit 1
  fi
  print_success "Docker is running"

  # Check Supabase is running
  if ! docker ps | grep -q supabase; then
    print_error "Supabase containers are not running"
    print_info "Run: npm run db:start"
    exit 1
  fi
  print_success "Supabase is running"

  # Check service role key
  if [ -z "$SERVICE_ROLE_KEY" ]; then
    print_error "SERVICE_ROLE_KEY environment variable is not set"
    print_info "Set it with: export SERVICE_ROLE_KEY='your-key'"
    exit 1
  fi
  print_success "SERVICE_ROLE_KEY is set"

  # Check required arguments
  if [ -z "$DOMAIN" ]; then
    print_error "Domain is required (-d or --domain)"
    show_help
    exit 1
  fi

  if [ -z "$METADATA_URL" ]; then
    print_error "Metadata URL is required (-m or --metadata-url)"
    show_help
    exit 1
  fi

  print_success "All prerequisites met"
  echo
}

generate_certificates() {
  if [ "$SKIP_CERTS" = true ]; then
    print_info "Skipping certificate generation"
    return
  fi

  print_header "Generating SAML Certificates"

  # Create certificate directory
  if [ ! -d "$CERT_DIR" ]; then
    print_info "Creating certificate directory: $CERT_DIR"
    sudo mkdir -p "$CERT_DIR"
    sudo chown $USER:$USER "$CERT_DIR"
  fi

  # Backup existing certificates
  if [ -f "$CERT_DIR/saml_sp_cert.pem" ]; then
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$BACKUP_DIR"
    print_info "Backing up existing certificates to $BACKUP_DIR"
    cp "$CERT_DIR/saml_sp_cert.pem" "$BACKUP_DIR/saml_sp_cert.pem.$BACKUP_TIMESTAMP"
    cp "$CERT_DIR/saml_sp_private.key" "$BACKUP_DIR/saml_sp_private.key.$BACKUP_TIMESTAMP"
  fi

  # Generate private key
  print_info "Generating RSA private key (2048-bit)..."
  openssl genrsa -out "$CERT_DIR/saml_sp_private.key" 2048 2>/dev/null

  # Generate self-signed certificate (valid 10 years)
  print_info "Generating self-signed certificate (valid 10 years)..."
  openssl req -new -x509 \
    -key "$CERT_DIR/saml_sp_private.key" \
    -out "$CERT_DIR/saml_sp_cert.pem" \
    -days 3650 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN" \
    2>/dev/null

  # Set permissions
  chmod 600 "$CERT_DIR/saml_sp_private.key"
  chmod 644 "$CERT_DIR/saml_sp_cert.pem"

  # Verify certificate
  print_info "Verifying certificate..."
  EXPIRY=$(openssl x509 -in "$CERT_DIR/saml_sp_cert.pem" -noout -enddate | cut -d= -f2)

  print_success "Certificates generated successfully"
  print_info "Private key: $CERT_DIR/saml_sp_private.key"
  print_info "Certificate: $CERT_DIR/saml_sp_cert.pem"
  print_info "Expiry: $EXPIRY"
  echo
}

update_environment() {
  print_header "Updating Environment Configuration"

  # Base64 encode the private key
  print_info "Encoding private key..."
  PRIVATE_KEY_BASE64=$(cat "$CERT_DIR/saml_sp_private.key" | base64 -w 0)

  # Update .env file if it exists
  ENV_FILE="$PROJECT_ROOT/.env"
  if [ -f "$ENV_FILE" ]; then
    # Backup .env
    cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"

    # Update or add SAML configuration
    if grep -q "SAML_SP_PRIVATE_KEY=" "$ENV_FILE"; then
      sed -i "s|^SAML_SP_PRIVATE_KEY=.*|SAML_SP_PRIVATE_KEY=$PRIVATE_KEY_BASE64|" "$ENV_FILE"
      print_success "Updated SAML_SP_PRIVATE_KEY in .env"
    else
      echo "SAML_SP_PRIVATE_KEY=$PRIVATE_KEY_BASE64" >>"$ENV_FILE"
      print_success "Added SAML_SP_PRIVATE_KEY to .env"
    fi

    if ! grep -q "GOTRUE_SAML_ENABLED=" "$ENV_FILE"; then
      echo "GOTRUE_SAML_ENABLED=true" >>"$ENV_FILE"
      print_success "Added GOTRUE_SAML_ENABLED to .env"
    fi
  else
    print_warning ".env file not found at $ENV_FILE"
    print_info "Create .env file with:"
    echo
    echo "SAML_SP_PRIVATE_KEY=$PRIVATE_KEY_BASE64"
    echo "GOTRUE_SAML_ENABLED=true"
    echo
  fi

  echo
}

restart_services() {
  print_header "Restarting Supabase Services"

  print_info "Restarting auth service..."
  docker restart supabase-auth 2>/dev/null || docker-compose restart auth

  print_info "Waiting for services to start (15 seconds)..."
  sleep 15

  # Verify service is up
  if curl -sf "$SUPABASE_URL/auth/v1/health" >/dev/null; then
    print_success "Auth service is running"
  else
    print_warning "Auth service health check failed"
  fi

  echo
}

create_saml_provider() {
  print_header "Creating SAML Provider"

  # Create provider configuration
  PROVIDER_JSON=$(
    cat <<EOF
{
  "type": "saml",
  "domains": ["$DOMAIN"],
  "metadata_url": "$METADATA_URL",
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "first_name": "FirstName",
      "last_name": "SurName"
    }
  }
}
EOF
  )

  print_info "Creating provider for domain: $DOMAIN"

  # Call Admin API
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$SUPABASE_URL/auth/v1/admin/sso/providers" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "$PROVIDER_JSON")

  BODY=$(echo "$RESPONSE" | head -n -1)
  STATUS=$(echo "$RESPONSE" | tail -n 1)

  if [ "$STATUS" = "201" ] || [ "$STATUS" = "200" ]; then
    PROVIDER_ID=$(echo "$BODY" | jq -r '.id')
    print_success "Provider created successfully"
    print_info "Provider ID: $PROVIDER_ID"
  elif [ "$STATUS" = "409" ]; then
    print_warning "Provider already exists for domain: $DOMAIN"
    # Try to get existing provider
    LIST_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/sso/providers" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY")
    PROVIDER_ID=$(echo "$LIST_RESPONSE" | jq -r ".items[] | select(.domains[] == \"$DOMAIN\") | .id")
    if [ -n "$PROVIDER_ID" ]; then
      print_info "Existing Provider ID: $PROVIDER_ID"
    fi
  else
    print_error "Failed to create provider (HTTP $STATUS)"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
  fi

  echo
}

verify_setup() {
  print_header "Verifying SAML Configuration"

  # Check metadata endpoint
  print_info "Testing metadata endpoint..."
  if curl -sf "$SUPABASE_URL/auth/v1/sso/saml/metadata" >/dev/null; then
    print_success "Metadata endpoint is accessible"
  else
    print_error "Metadata endpoint is not accessible"
  fi

  # Check provider in database
  print_info "Checking database..."
  PROVIDER_COUNT=$(docker exec supabase-db psql -U postgres -d postgres -t \
    -c "SELECT COUNT(*) FROM auth.saml_providers WHERE domains @> ARRAY['$DOMAIN']::text[]" \
    2>/dev/null | tr -d ' ')

  if [ "$PROVIDER_COUNT" -gt 0 ]; then
    print_success "Provider found in database"
  else
    print_warning "Provider not found in database"
  fi

  # Check certificate expiry
  print_info "Checking certificate expiry..."
  DAYS_UNTIL_EXPIRY=$(openssl x509 -in "$CERT_DIR/saml_sp_cert.pem" -noout -enddate |
    cut -d= -f2 | xargs -I {} date -d "{}" +%s |
    xargs -I {} echo "({} - $(date +%s)) / 86400" | bc)

  if [ "$DAYS_UNTIL_EXPIRY" -gt 30 ]; then
    print_success "Certificate valid for $DAYS_UNTIL_EXPIRY days"
  else
    print_warning "Certificate expires in $DAYS_UNTIL_EXPIRY days"
  fi

  echo
}

print_summary() {
  print_header "Setup Complete!"

  echo -e "${GREEN}SAML SSO has been configured successfully!${NC}"
  echo
  echo "Configuration Summary:"
  echo "  Domain:         $DOMAIN"
  echo "  Metadata URL:   $METADATA_URL"
  echo "  Supabase URL:   $SUPABASE_URL"
  echo "  Certificates:   $CERT_DIR"
  echo
  echo "Next Steps:"
  echo "  1. Get SP metadata:"
  echo "     curl $SUPABASE_URL/auth/v1/sso/saml/metadata > supabase-sp-metadata.xml"
  echo
  echo "  2. Update ZITADEL SAML application with SP metadata"
  echo "     - Entity ID: $SUPABASE_URL/auth/v1/sso/saml/metadata"
  echo "     - ACS URL:   $SUPABASE_URL/auth/v1/sso/saml/acs"
  echo
  echo "  3. Test SSO login:"
  echo "     Open: $SUPABASE_URL/auth/v1/sso?domain=$DOMAIN"
  echo
  echo "  4. Integration guides:"
  echo "     - Main guide:    docs/AUTH_ZITADEL_SAML_SELF_HOSTED.md"
  echo "     - API reference: docs/SAML_ADMIN_API.md"
  echo "     - User guide:    docs/USER_GUIDE_SAML.md"
  echo
}

##############################################################################
# Main
##############################################################################

main() {
  # Parse command line arguments
  parse_args "$@"

  # Print banner
  echo
  print_header "SAML SSO Setup for Self-Hosted Supabase"
  echo

  # Run setup steps
  check_prerequisites
  generate_certificates
  update_environment
  restart_services
  create_saml_provider
  verify_setup
  print_summary
}

# Run main function
main "$@"
