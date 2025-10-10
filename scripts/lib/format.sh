#!/usr/bin/env bash
# format.sh - Output formatting for structured results
#
# Supports multiple output formats: json, compact, human, table
# Automatically detects format based on TTY unless --format is specified
#
# Usage:
#   source "$(dirname "$0")/lib/format.sh"
#   format_output "$result" "$format"

# Get the directory containing this library
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$LIB_DIR/colors.sh"

# Detect output format
# Returns: json, compact, human, or table
detect_format() {
    # If --format flag was provided, use it
    if [ -n "$OUTPUT_FORMAT" ]; then
        echo "$OUTPUT_FORMAT"
        return
    fi

    # Auto-detect based on TTY
    if [ -t 1 ]; then
        # stdout is a TTY - use human-readable format
        echo "human"
    else
        # stdout is not a TTY (pipe/redirect) - use JSON
        echo "json"
    fi
}

# Format a result for output
# Args:
#   $1 - result JSON
#   $2 - format (optional: json, compact, human, table)
format_output() {
    local result="$1"
    local format="${2:-$(detect_format)}"

    case "$format" in
        json)
            format_json "$result"
            ;;
        compact)
            format_compact "$result"
            ;;
        human)
            format_human "$result"
            ;;
        table)
            format_table "$result"
            ;;
        *)
            echo "Unknown format: $format" >&2
            return 1
            ;;
    esac
}

# Format as pretty JSON
format_json() {
    local result="$1"
    echo "$result" | jq .
}

# Format as compact JSON (single line)
format_compact() {
    local result="$1"
    echo "$result" | jq -c .
}

# Format as human-readable output with colors
format_human() {
    local result="$1"
    local success operation data error warnings

    success=$(echo "$result" | jq -r '.result.success')
    operation=$(echo "$result" | jq -r '.result.operation // empty')

    if [ "$success" = "true" ]; then
        # Success output
        echo -e "${COLOR_SUCCESS}${SYMBOL_SUCCESS} Success${NC}"

        if [ -n "$operation" ]; then
            echo -e "${COLOR_INFO}Operation:${NC} $operation"
        fi

        # Display data in human-readable format
        data=$(echo "$result" | jq -r '.result.data')
        format_human_data "$data"

        # Display warnings if any
        warnings=$(echo "$result" | jq -r '.result.warnings[]' 2>/dev/null)
        if [ -n "$warnings" ]; then
            echo ""
            echo -e "${COLOR_WARNING}Warnings:${NC}"
            while IFS= read -r warning; do
                echo -e "  ${SYMBOL_WARNING} $warning"
            done <<< "$warnings"
        fi
    else
        # Error output
        error=$(echo "$result" | jq -r '.result.error')
        local error_type error_msg suggestions

        error_type=$(echo "$error" | jq -r '.type')
        error_msg=$(echo "$error" | jq -r '.message')

        echo -e "${COLOR_ERROR}${SYMBOL_ERROR} Error: $error_msg${NC}"
        echo -e "${COLOR_DEBUG}Type:${NC} $error_type"

        # Display suggestions if any
        suggestions=$(echo "$error" | jq -r '.suggestions[]?' 2>/dev/null)
        if [ -n "$suggestions" ]; then
            echo ""
            echo -e "${COLOR_INFO}Suggestions:${NC}"
            while IFS= read -r suggestion; do
                echo -e "  ${SYMBOL_BULLET} $suggestion"
            done <<< "$suggestions"
        fi
    fi
}

# Format data section in human-readable format
format_human_data() {
    local data="$1"

    # Try to format common data types
    if echo "$data" | jq -e 'has("number")' &>/dev/null; then
        # Issue or PR data
        local number url title
        number=$(echo "$data" | jq -r '.number // empty')
        url=$(echo "$data" | jq -r '.url // empty')
        title=$(echo "$data" | jq -r '.title // empty')

        if [ -n "$number" ]; then
            echo -e "${COLOR_INFO}Number:${NC} #$number"
        fi
        if [ -n "$title" ]; then
            echo -e "${COLOR_INFO}Title:${NC} $title"
        fi
        if [ -n "$url" ]; then
            echo -e "${COLOR_INFO}URL:${NC} $url"
        fi
    else
        # Generic data - just display as indented JSON
        echo "$data" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "$data"
    fi
}

# Format as table (for list results)
format_table() {
    local result="$1"
    local data

    data=$(echo "$result" | jq -r '.result.data')

    # Check if data is an array
    if echo "$data" | jq -e 'type == "array"' &>/dev/null; then
        # Use column command for table formatting
        echo "$data" | jq -r '
            (.[0] | keys_unsorted) as $keys |
            ($keys | join("\t")),
            (.[] | [.[$keys[]]] | join("\t"))
        ' | column -t -s $'\t'
    else
        # Not an array, fall back to human format
        format_human "$result"
    fi
}

# Parse command line arguments for format flag
# Sets OUTPUT_FORMAT variable
# Usage: parse_format_args "$@"
parse_format_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format=*)
                OUTPUT_FORMAT="${1#*=}"
                shift
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    export OUTPUT_FORMAT
}
