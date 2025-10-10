#!/usr/bin/env bash
# colors.sh - Centralized color and formatting constants
#
# Usage:
#   source "$(dirname "$0")/lib/colors.sh"
#   echo -e "${GREEN}Success!${NC}"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Semantic colors for consistent messaging
readonly COLOR_SUCCESS="${GREEN}"
readonly COLOR_ERROR="${RED}"
readonly COLOR_WARNING="${YELLOW}"
readonly COLOR_INFO="${BLUE}"
readonly COLOR_DEBUG="${DIM}"

# Status symbols
readonly SYMBOL_SUCCESS="✓"
readonly SYMBOL_ERROR="✗"
readonly SYMBOL_WARNING="⚠"
readonly SYMBOL_INFO="ℹ"
readonly SYMBOL_PROGRESS="◉"
readonly SYMBOL_BULLET="•"
