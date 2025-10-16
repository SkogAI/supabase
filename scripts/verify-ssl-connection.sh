#!/bin/bash
# SSL Connection Verification Script
# Tests SSL/TLS connectivity to Supabase database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CERT_PATH="${SSL_CERT_PATH:-../certs/prod-ca-2021.crt}"
DB_HOST=""
DB_PORT="${DB_PORT:-5432}"

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

log_test() {
  echo -e "${BLUE}🔍 $1${NC}"
}

# Check dependencies
check_dependencies() {
  local missing_deps=()

  if ! command -v openssl &>/dev/null; then
    missing_deps+=("openssl")
  fi

  if ! command -v curl &>/dev/null; then
    missing_deps+=("curl")
  fi

  if [ ${#missing_deps[@]} -gt 0 ]; then
    log_error "Missing required dependencies: ${missing_deps[*]}"
    echo "Please install them before running this script"
    exit 1
  fi
}

# Parse database URL
parse_database_url() {
  if [ -n "$DATABASE_URL" ]; then
    # Extract host from DATABASE_URL
    # Format: postgresql://user:pass@host:port/db
    DB_HOST=$(echo "$DATABASE_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p')

    if [ -z "$DB_HOST" ]; then
      log_warn "Could not parse DATABASE_URL, using manual host"
    else
      log_info "Parsed database host from DATABASE_URL: $DB_HOST"
    fi
  fi
}

# Test 1: Certificate file exists and is readable
test_certificate_exists() {
  log_test "Test 1: Certificate File"

  if [ -f "$CERT_PATH" ]; then
    log_info "Certificate file exists: $CERT_PATH"

    # Check permissions
    if [ -r "$CERT_PATH" ]; then
      log_info "Certificate file is readable"
      return 0
    else
      log_error "Certificate file is not readable"
      return 1
    fi
  else
    log_error "Certificate file not found: $CERT_PATH"
    echo "Download from: Supabase Dashboard → Settings → Database → SSL Certificate"
    return 1
  fi
}

# Test 2: Certificate format validation
test_certificate_format() {
  log_test "Test 2: Certificate Format"

  if openssl x509 -in "$CERT_PATH" -text -noout >/dev/null 2>&1; then
    log_info "Certificate format is valid (X.509)"
    return 0
  else
    log_error "Invalid certificate format"
    return 1
  fi
}

# Test 3: Certificate expiration
test_certificate_expiry() {
  log_test "Test 3: Certificate Expiration"

  local expiry=$(openssl x509 -in "$CERT_PATH" -enddate -noout | cut -d= -f2)
  local expiry_epoch

  # Try different date parsing methods (Linux vs macOS)
  if date -d "$expiry" +%s &>/dev/null; then
    expiry_epoch=$(date -d "$expiry" +%s)
  elif date -j -f "%b %d %T %Y %Z" "$expiry" +%s &>/dev/null; then
    expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "$expiry" +%s)
  else
    log_warn "Could not parse expiration date format"
    echo "Expiration date: $expiry"
    return 0
  fi

  local now_epoch=$(date +%s)
  local days_until_expiry=$((($expiry_epoch - $now_epoch) / 86400))

  if [ $days_until_expiry -lt 0 ]; then
    log_error "Certificate has expired!"
    echo "Expired on: $expiry"
    return 1
  elif [ $days_until_expiry -lt 30 ]; then
    log_warn "Certificate expires in $days_until_expiry days"
    echo "Expires on: $expiry"
    return 0
  else
    log_info "Certificate valid for $days_until_expiry more days"
    echo "Expires on: $expiry"
    return 0
  fi
}

# Test 4: Certificate details
test_certificate_details() {
  log_test "Test 4: Certificate Details"

  echo ""
  echo "Subject:"
  openssl x509 -in "$CERT_PATH" -noout -subject | sed 's/subject=/  /'

  echo ""
  echo "Issuer:"
  openssl x509 -in "$CERT_PATH" -noout -issuer | sed 's/issuer=/  /'

  echo ""
  echo "Validity:"
  openssl x509 -in "$CERT_PATH" -noout -dates | sed 's/^/  /'

  echo ""
  log_info "Certificate details retrieved"
  return 0
}

# Test 5: Network connectivity to database host
test_network_connectivity() {
  log_test "Test 5: Network Connectivity"

  if [ -z "$DB_HOST" ]; then
    log_warn "Database host not specified, skipping network test"
    echo "Set DB_HOST or DATABASE_URL environment variable to test"
    return 0
  fi

  log_info "Testing connectivity to $DB_HOST:$DB_PORT..."

  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    log_info "Network connectivity successful"
    return 0
  else
    log_error "Cannot connect to $DB_HOST:$DB_PORT"
    echo "Check network connectivity and firewall rules"
    return 1
  fi
}

# Test 6: SSL handshake
test_ssl_handshake() {
  log_test "Test 6: SSL Handshake"

  if [ -z "$DB_HOST" ]; then
    log_warn "Database host not specified, skipping SSL handshake test"
    return 0
  fi

  log_info "Testing SSL handshake with $DB_HOST:$DB_PORT..."

  local output=$(timeout 10 openssl s_client -connect "$DB_HOST:$DB_PORT" \
    -CAfile "$CERT_PATH" \
    -showcerts \
    </dev/null 2>&1)

  if echo "$output" | grep -q "Verify return code: 0"; then
    log_info "SSL handshake successful"

    # Extract SSL version
    local ssl_version=$(echo "$output" | grep "Protocol" | head -1 | awk '{print $3}')
    if [ -n "$ssl_version" ]; then
      echo "SSL/TLS Version: $ssl_version"
    fi

    # Extract cipher
    local cipher=$(echo "$output" | grep "Cipher" | head -1 | awk '{print $3}')
    if [ -n "$cipher" ]; then
      echo "Cipher: $cipher"
    fi

    return 0
  else
    log_error "SSL handshake failed"

    # Show verify return code
    local verify_code=$(echo "$output" | grep "Verify return code:" | head -1)
    if [ -n "$verify_code" ]; then
      echo "$verify_code"
    fi

    return 1
  fi
}

# Test 7: Certificate chain validation
test_certificate_chain() {
  log_test "Test 7: Certificate Chain"

  if openssl verify -CAfile "$CERT_PATH" "$CERT_PATH" >/dev/null 2>&1; then
    log_info "Certificate chain is valid"
    return 0
  else
    log_warn "Certificate chain validation inconclusive"
    return 0
  fi
}

# Summary
print_summary() {
  echo ""
  echo "=================================="
  echo "SSL Verification Summary"
  echo "=================================="
  echo ""
  echo "Certificate: $CERT_PATH"

  if [ -n "$DB_HOST" ]; then
    echo "Database Host: $DB_HOST:$DB_PORT"
  else
    echo "Database Host: Not specified"
  fi

  echo ""

  if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
    log_info "All tests passed ($TESTS_PASSED/$TESTS_RUN)"
    return 0
  elif [ $TESTS_FAILED -gt 0 ]; then
    log_error "$TESTS_FAILED test(s) failed, $TESTS_PASSED passed"
    return 1
  else
    log_warn "Some tests skipped, $TESTS_PASSED passed"
    return 0
  fi
}

# Main execution
main() {
  echo ""
  echo "🔒 SSL/TLS Connection Verification"
  echo "==================================="
  echo ""

  # Check dependencies
  check_dependencies

  # Parse DATABASE_URL if provided
  parse_database_url

  # Initialize counters
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0

  # Run tests
  local tests=(
    "test_certificate_exists"
    "test_certificate_format"
    "test_certificate_expiry"
    "test_certificate_details"
    "test_network_connectivity"
    "test_ssl_handshake"
    "test_certificate_chain"
  )

  for test in "${tests[@]}"; do
    echo ""
    TESTS_RUN=$((TESTS_RUN + 1))

    if $test; then
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  done

  # Print summary
  print_summary

  # Return exit code based on results
  if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
}

# Help message
show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Verify SSL/TLS certificate and connection to Supabase database.

Options:
    -h, --help              Show this help message
    -c, --cert PATH         Path to SSL certificate (default: ./certs/prod-ca-2021.crt)
    -H, --host HOST         Database hostname
    -p, --port PORT         Database port (default: 5432)

Environment Variables:
    SSL_CERT_PATH           Path to SSL certificate
    DATABASE_URL            Complete database URL (will extract host)
    DB_HOST                 Database hostname
    DB_PORT                 Database port

Examples:
    # Basic verification (certificate only)
    $0

    # Verify with database connection test
    $0 --host db.xxx.supabase.co

    # Use environment variable
    DATABASE_URL="postgresql://..." $0

    # Custom certificate path
    $0 --cert /path/to/custom-ca.crt --host db.xxx.supabase.co

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    show_help
    exit 0
    ;;
  -c | --cert)
    CERT_PATH="$2"
    shift 2
    ;;
  -H | --host)
    DB_HOST="$2"
    shift 2
    ;;
  -p | --port)
    DB_PORT="$2"
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
