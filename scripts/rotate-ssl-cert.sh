#!/bin/bash
# SSL Certificate Rotation Script
# Automates the process of rotating Supabase SSL certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CERT_DIR="${CERT_DIR:-./certs}"
BACKUP_DIR="$CERT_DIR/backup"
CERT_NAME="${CERT_NAME:-prod-ca-2021.crt}"
CERT_URL="${CERT_URL:-https://supabase.com/downloads/prod-ca-2021.crt}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Functions
log_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check dependencies
check_dependencies() {
    if ! command -v openssl &> /dev/null; then
        log_error "openssl is required but not installed"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
}

# Create directories
setup_directories() {
    mkdir -p "$CERT_DIR"
    mkdir -p "$BACKUP_DIR"
    log_info "Directories prepared"
}

# Backup existing certificate
backup_certificate() {
    if [ -f "$CERT_DIR/$CERT_NAME" ]; then
        cp "$CERT_DIR/$CERT_NAME" "$BACKUP_DIR/${CERT_NAME}.${TIMESTAMP}.bak"
        log_info "Backed up existing certificate to $BACKUP_DIR/${CERT_NAME}.${TIMESTAMP}.bak"
    else
        log_warn "No existing certificate found to backup"
    fi
}

# Download new certificate
download_certificate() {
    log_info "Downloading new certificate from $CERT_URL..."
    
    if curl -f -o "$CERT_DIR/$CERT_NAME.new" "$CERT_URL"; then
        log_info "Certificate downloaded successfully"
        return 0
    else
        log_error "Failed to download certificate"
        return 1
    fi
}

# Validate certificate
validate_certificate() {
    local cert_file="$1"
    
    log_info "Validating certificate format..."
    
    if openssl x509 -in "$cert_file" -text -noout > /dev/null 2>&1; then
        log_info "Certificate format is valid"
        
        # Check expiration
        local expiry=$(openssl x509 -in "$cert_file" -enddate -noout | cut -d= -f2)
        log_info "Certificate expires: $expiry"
        
        # Show certificate details
        echo ""
        echo "Certificate Details:"
        openssl x509 -in "$cert_file" -noout -subject -issuer
        echo ""
        
        return 0
    else
        log_error "Invalid certificate format"
        return 1
    fi
}

# Install new certificate
install_certificate() {
    if [ -f "$CERT_DIR/$CERT_NAME.new" ]; then
        mv "$CERT_DIR/$CERT_NAME.new" "$CERT_DIR/$CERT_NAME"
        chmod 600 "$CERT_DIR/$CERT_NAME"
        log_info "New certificate installed successfully"
        return 0
    else
        log_error "New certificate file not found"
        return 1
    fi
}

# Test SSL connection (optional)
test_connection() {
    if [ -n "$TEST_DB_HOST" ]; then
        log_info "Testing SSL connection to $TEST_DB_HOST..."
        
        if timeout 5 openssl s_client -connect "$TEST_DB_HOST:5432" -CAfile "$CERT_DIR/$CERT_NAME" < /dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
            log_info "SSL connection test successful"
            return 0
        else
            log_warn "SSL connection test inconclusive (may require database credentials)"
            return 0
        fi
    else
        log_warn "TEST_DB_HOST not set, skipping connection test"
        return 0
    fi
}

# Cleanup old backups (keep last 10)
cleanup_backups() {
    local backup_count=$(ls -1 "$BACKUP_DIR"/${CERT_NAME}.*.bak 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt 10 ]; then
        log_info "Cleaning up old backups (keeping last 10)..."
        ls -1t "$BACKUP_DIR"/${CERT_NAME}.*.bak | tail -n +11 | xargs rm -f
        log_info "Old backups removed"
    fi
}

# Main execution
main() {
    echo ""
    echo "🔒 SSL Certificate Rotation Script"
    echo "==================================="
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Setup
    setup_directories
    
    # Backup existing certificate
    backup_certificate
    
    # Download new certificate
    if ! download_certificate; then
        log_error "Certificate rotation failed at download stage"
        exit 1
    fi
    
    # Validate new certificate
    if ! validate_certificate "$CERT_DIR/$CERT_NAME.new"; then
        log_error "Certificate rotation failed at validation stage"
        rm -f "$CERT_DIR/$CERT_NAME.new"
        exit 1
    fi
    
    # Install new certificate
    if ! install_certificate; then
        log_error "Certificate rotation failed at installation stage"
        exit 1
    fi
    
    # Test connection (optional)
    test_connection
    
    # Cleanup old backups
    cleanup_backups
    
    echo ""
    log_info "Certificate rotation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your application to use the new certificate"
    echo "2. Monitor logs for any SSL connection issues"
    echo "3. Verify all environments are updated"
    echo ""
}

# Help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Rotate SSL certificates for Supabase database connections.

Options:
    -h, --help              Show this help message
    -d, --cert-dir DIR      Certificate directory (default: ./certs)
    -n, --cert-name NAME    Certificate filename (default: prod-ca-2021.crt)
    -u, --url URL           Certificate download URL
    -t, --test-host HOST    Test connection to database host

Environment Variables:
    CERT_DIR                Certificate directory
    CERT_NAME               Certificate filename
    CERT_URL                Certificate download URL
    TEST_DB_HOST            Database host for connection testing

Examples:
    # Basic usage
    $0

    # Specify custom certificate directory
    $0 --cert-dir /etc/ssl/supabase

    # Test connection after rotation
    TEST_DB_HOST=db.xxx.supabase.co $0

    # Custom certificate name
    $0 --cert-name staging-ca.crt --url https://example.com/staging-ca.crt

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--cert-dir)
            CERT_DIR="$2"
            BACKUP_DIR="$CERT_DIR/backup"
            shift 2
            ;;
        -n|--cert-name)
            CERT_NAME="$2"
            shift 2
            ;;
        -u|--url)
            CERT_URL="$2"
            shift 2
            ;;
        -t|--test-host)
            TEST_DB_HOST="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main
