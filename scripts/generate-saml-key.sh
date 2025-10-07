#!/bin/bash
# Generate SAML Private Key for Supabase
# This script generates a private key in DER format and encodes it to base64

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

    # Check OpenSSL
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is not installed"
        echo "Please install OpenSSL and try again"
        exit 1
    fi
    
    OPENSSL_VERSION=$(openssl version)
    print_success "OpenSSL is installed ($OPENSSL_VERSION)"

    # Check base64
    if ! command -v base64 &> /dev/null; then
        print_error "base64 command is not available"
        exit 1
    fi
    print_success "base64 command is available"
}

# Create keys directory
create_keys_directory() {
    print_header "Creating Keys Directory"

    # Default location
    KEYS_DIR="${HOME}/supabase-saml-keys"

    # Allow custom directory
    if [ ! -z "$1" ]; then
        KEYS_DIR="$1"
    fi

    # Create directory
    if [ ! -d "$KEYS_DIR" ]; then
        mkdir -p "$KEYS_DIR"
        print_success "Created directory: $KEYS_DIR"
    else
        print_info "Directory already exists: $KEYS_DIR"
    fi

    cd "$KEYS_DIR"
    print_info "Working in: $(pwd)"
}

# Generate RSA private key
generate_private_key() {
    print_header "Generating RSA Private Key"

    # Key file paths
    DER_KEY="private_key.der"
    BASE64_KEY="private_key.base64"

    # Backup existing keys
    if [ -f "$DER_KEY" ]; then
        BACKUP="${DER_KEY}.backup.$(date +%Y%m%d%H%M%S)"
        mv "$DER_KEY" "$BACKUP"
        print_warning "Backed up existing key to: $BACKUP"
    fi

    # Generate 2048-bit RSA key in DER format
    print_info "Generating 2048-bit RSA key in DER format..."
    openssl genpkey \
        -algorithm RSA \
        -pkeyopt rsa_keygen_bits:2048 \
        -outform DER \
        -out "$DER_KEY"

    if [ $? -eq 0 ] && [ -f "$DER_KEY" ]; then
        print_success "Private key generated: $DER_KEY"
        
        # Set secure permissions
        chmod 600 "$DER_KEY"
        print_success "Set secure permissions (600) on key file"
    else
        print_error "Failed to generate private key"
        exit 1
    fi
}

# Encode to base64
encode_to_base64() {
    print_header "Encoding to Base64"

    DER_KEY="private_key.der"
    BASE64_KEY="private_key.base64"

    # Backup existing base64 key
    if [ -f "$BASE64_KEY" ]; then
        BACKUP="${BASE64_KEY}.backup.$(date +%Y%m%d%H%M%S)"
        mv "$BASE64_KEY" "$BACKUP"
        print_warning "Backed up existing base64 key to: $BACKUP"
    fi

    # Detect OS and encode accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        print_info "Detected macOS - using base64 without -w flag"
        base64 -i "$DER_KEY" -o "$BASE64_KEY"
    else
        # Linux
        print_info "Detected Linux - using base64 with -w 0 flag"
        base64 -w 0 "$DER_KEY" > "$BASE64_KEY"
    fi

    if [ $? -eq 0 ] && [ -f "$BASE64_KEY" ]; then
        print_success "Base64-encoded key generated: $BASE64_KEY"
        
        # Set secure permissions
        chmod 600 "$BASE64_KEY"
        print_success "Set secure permissions (600) on base64 file"
    else
        print_error "Failed to encode key to base64"
        exit 1
    fi
}

# Verify key
verify_key() {
    print_header "Verifying Key"

    DER_KEY="private_key.der"
    BASE64_KEY="private_key.base64"

    # Check DER key
    print_info "Verifying DER key structure..."
    if openssl rsa -inform DER -in "$DER_KEY" -check -noout 2>&1 | grep -q "RSA key ok"; then
        print_success "DER key is valid"
    else
        print_error "DER key verification failed"
        exit 1
    fi

    # Check base64 encoding
    print_info "Verifying base64 encoding..."
    LINE_COUNT=$(cat "$BASE64_KEY" | wc -l)
    if [ "$LINE_COUNT" -eq 1 ]; then
        print_success "Base64 key is single line (correct format)"
    else
        print_warning "Base64 key has multiple lines - GoTrue expects single line"
        print_info "Fixing line breaks..."
        tr -d '\n' < "$BASE64_KEY" > "${BASE64_KEY}.tmp"
        mv "${BASE64_KEY}.tmp" "$BASE64_KEY"
        print_success "Fixed line breaks"
    fi

    # Check for spaces
    if grep -q " " "$BASE64_KEY"; then
        print_error "Base64 key contains spaces - this will cause issues"
        exit 1
    else
        print_success "Base64 key has no spaces"
    fi

    # Test decode
    print_info "Testing base64 decode..."
    if cat "$BASE64_KEY" | base64 -d | openssl rsa -inform DER -check -noout 2>&1 | grep -q "RSA key ok"; then
        print_success "Base64 decoding successful - key is valid"
    else
        print_error "Base64 decoding failed"
        exit 1
    fi
}

# Display next steps
show_next_steps() {
    print_header "🎉 Key Generation Complete!"

    BASE64_KEY="private_key.base64"

    echo ""
    echo "Your SAML private key has been generated and encoded:"
    echo ""
    echo -e "${BLUE}Location:${NC} $(pwd)/$BASE64_KEY"
    echo ""
    
    print_header "Next Steps"
    
    echo "1️⃣  Copy the base64-encoded key to your .env file:"
    echo ""
    echo "   ${YELLOW}cat $(pwd)/$BASE64_KEY${NC}"
    echo ""
    echo "   Then add to .env:"
    echo "   ${YELLOW}GOTRUE_SAML_ENABLED=true${NC}"
    echo "   ${YELLOW}GOTRUE_SAML_PRIVATE_KEY=<paste-key-here>${NC}"
    echo ""
    
    echo "2️⃣  Update supabase/config.toml:"
    echo ""
    echo "   ${YELLOW}[auth.external.saml]${NC}"
    echo "   ${YELLOW}enabled = true${NC}"
    echo ""
    
    echo "3️⃣  Restart Supabase:"
    echo ""
    echo "   ${YELLOW}supabase stop${NC}"
    echo "   ${YELLOW}supabase start${NC}"
    echo ""
    
    echo "4️⃣  Verify SAML endpoints:"
    echo ""
    echo "   ${YELLOW}curl http://localhost:54321/auth/v1/sso/saml/metadata${NC}"
    echo ""
    
    print_info "For complete setup instructions, see: docs/SUPABASE_SAML_CONFIGURATION.md"
    
    print_warning "🔒 SECURITY: Never commit these keys to git!"
    echo "             Add to .gitignore: $(pwd)"
    echo ""
}

# Main execution
main() {
    clear
    print_header "SAML Private Key Generator"
    
    # Allow custom directory as argument
    CUSTOM_DIR=""
    if [ ! -z "$1" ]; then
        CUSTOM_DIR="$1"
    fi

    check_prerequisites
    create_keys_directory "$CUSTOM_DIR"
    generate_private_key
    encode_to_base64
    verify_key
    show_next_steps
}

# Run main function
main "$@"
