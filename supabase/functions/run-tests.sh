#!/bin/bash
# Script to run all edge function tests
# Usage: ./run-tests.sh [options]
#
# Options:
#   --coverage    Generate coverage report
#   --watch       Run tests in watch mode
#   --help        Show this help message

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Deno is installed
if ! command -v deno &> /dev/null; then
    echo -e "${RED}Error: Deno is not installed${NC}"
    echo "Please install Deno: https://deno.land/#installation"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Edge Functions Test Runner          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
COVERAGE=false
WATCH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            COVERAGE=true
            shift
            ;;
        --watch)
            WATCH=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --coverage    Generate coverage report"
            echo "  --watch       Run tests in watch mode"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Run tests
if [ "$WATCH" = true ]; then
    echo -e "${YELLOW}Running tests in watch mode...${NC}"
    deno test --allow-all --watch
elif [ "$COVERAGE" = true ]; then
    echo -e "${YELLOW}Running tests with coverage...${NC}"
    echo ""
    
    # Run tests with coverage
    deno test --allow-all --coverage=coverage
    
    # Generate coverage report
    echo ""
    echo -e "${BLUE}Generating coverage report...${NC}"
    deno coverage coverage --lcov --output=coverage.lcov
    
    # Calculate and display coverage
    if [ -f "coverage.lcov" ]; then
        LINES=$(grep -c "^DA:" coverage.lcov || echo "0")
        HIT=$(grep "^DA:" coverage.lcov | grep -cv ",0$" || echo "0")
        
        if [ "$LINES" -gt 0 ]; then
            COVERAGE_PCT=$(awk "BEGIN {printf \"%.2f\", ($HIT/$LINES)*100}")
            echo ""
            echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║        Coverage Report                 ║${NC}"
            echo -e "${GREEN}╠════════════════════════════════════════╣${NC}"
            echo -e "${GREEN}║ Coverage:    ${COVERAGE_PCT}%                ║${NC}"
            echo -e "${GREEN}║ Lines Hit:   ${HIT}/${LINES}                   ║${NC}"
            
            if (( $(echo "$COVERAGE_PCT < 80" | bc -l 2>/dev/null || echo "0") )); then
                echo -e "${YELLOW}║ Status:      ⚠️  Below 80% threshold   ║${NC}"
            else
                echo -e "${GREEN}║ Status:      ✅ Meets 80% threshold    ║${NC}"
            fi
            echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Running all tests...${NC}"
    echo ""
    deno test --allow-all
fi

echo ""
echo -e "${GREEN}✅ Tests completed!${NC}"
echo ""
echo -e "${BLUE}Tip: Use --coverage to generate coverage report${NC}"
echo -e "${BLUE}Tip: Use --watch to run tests in watch mode${NC}"
