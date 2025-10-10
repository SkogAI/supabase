#!/usr/bin/env bash
# format.sh - Output formatting for different output modes
# Usage: source "$(dirname "$0")/lib/format.sh"

# Load dependencies
SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=colors.sh
source "$SCRIPT_LIB_DIR/colors.sh"

# Detect if stdout is a TTY
is_tty() {
    [ -t 1 ]
}

# Auto-detect output format
# Returns: json, human, compact, or table
detect_format() {
    local explicit_format="${1:-}"

    # If format is explicitly set, use it
    if [ -n "$explicit_format" ]; then
        echo "$explicit_format"
        return
    fi

    # Auto-detect: JSON if not TTY, human if TTY
    if is_tty; then
        echo "human"
    else
        echo "json"
    fi
}

# Format output based on mode
# Usage: format_output "$result" "$format"
format_output() {
    local result="$1"
    local format="${2:-auto}"

    # Auto-detect if needed
    if [ "$format" = "auto" ]; then
        format=$(detect_format)
    fi

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
            echo "Error: Unknown format '$format'" >&2
            echo "Supported formats: json, compact, human, table" >&2
            return 1
            ;;
    esac
}

# Format as JSON (pretty-printed)
format_json() {
    local result="$1"
    echo "$result" | jq '.'
}

# Format as compact JSON (single line)
format_compact() {
    local result="$1"
    echo "$result" | jq -c '.'
}

# Format as human-readable text
format_human() {
    local result="$1"
    local success operation data error

    success=$(echo "$result" | jq -r '.result.success')
    operation=$(echo "$result" | jq -r '.result.operation')

    if [ "$success" = "true" ]; then
        data=$(echo "$result" | jq -r '.result.data')
        echo -e "${GREEN}${SYMBOL_SUCCESS}${NC} ${BOLD}$(format_operation_name "$operation")${NC}"

        # Format data based on operation type
        format_human_data "$operation" "$data"

        # Show warnings if any
        local warnings
        warnings=$(echo "$result" | jq -r '.result.warnings[]' 2>/dev/null)
        if [ -n "$warnings" ]; then
            echo -e "\n${YELLOW}${SYMBOL_WARNING} Warnings:${NC}"
            echo "$warnings" | while IFS= read -r warning; do
                echo "  • $warning"
            done
        fi
    else
        error=$(echo "$result" | jq -r '.result.error')
        local error_msg error_type
        error_msg=$(echo "$error" | jq -r '.message')
        error_type=$(echo "$error" | jq -r '.type')

        echo -e "${RED}${SYMBOL_ERROR}${NC} ${BOLD}$(format_operation_name "$operation") failed${NC}"
        echo -e "${RED}Error:${NC} $error_msg"

        if [ "$error_type" != "general" ]; then
            echo -e "${DIM}Type: $error_type${NC}"
        fi
    fi
}

# Format operation name for human output
format_operation_name() {
    local operation="$1"

    # Convert snake_case to Title Case
    echo "$operation" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1'
}

# Format data for human output based on operation type
format_human_data() {
    local operation="$1"
    local data="$2"

    case "$operation" in
        create_issue)
            local number url
            number=$(echo "$data" | jq -r '.number // .issueNumber // empty')
            url=$(echo "$data" | jq -r '.url // empty')

            if [ -n "$number" ]; then
                echo "  Issue: #$number"
            fi
            if [ -n "$url" ]; then
                echo "  URL: $url"
            fi
            ;;

        create_pr)
            local number url
            number=$(echo "$data" | jq -r '.number // .prNumber // empty')
            url=$(echo "$data" | jq -r '.url // empty')

            if [ -n "$number" ]; then
                echo "  PR: #$number"
            fi
            if [ -n "$url" ]; then
                echo "  URL: $url"
            fi
            ;;

        branch_status)
            local branch state
            branch=$(echo "$data" | jq -r '.branch.name // empty')
            state=$(echo "$data" | jq -r '.branch.status.state // empty')

            if [ -n "$branch" ]; then
                echo "  Branch: $branch"
            fi
            if [ -n "$state" ]; then
                echo "  Status: $state"
            fi
            ;;

        *)
            # Generic data output
            if [ "$data" != "null" ] && [ -n "$data" ]; then
                echo "$data" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  $data"
            fi
            ;;
    esac
}

# Format as table (for list operations)
format_table() {
    local result="$1"
    local data

    data=$(echo "$result" | jq -r '.result.data')

    # Check if data is an array
    if echo "$data" | jq -e 'type == "array"' > /dev/null 2>&1; then
        echo "$data" | jq -r '
            (.[0] | keys_unsorted) as $keys |
            $keys,
            (map([.[ $keys[] ]])[] | @tsv)
        ' | column -t -s $'\t'
    else
        # Not an array, fall back to human format
        format_human "$result"
    fi
}

# Format error for stderr
# Usage: format_error "error message" "error_type"
format_error() {
    local message="$1"
    local error_type="${2:-error}"

    if is_tty; then
        case "$error_type" in
            warning)
                echo -e "${YELLOW}${SYMBOL_WARNING} Warning:${NC} $message" >&2
                ;;
            info)
                echo -e "${BLUE}${SYMBOL_INFO} Info:${NC} $message" >&2
                ;;
            *)
                echo -e "${RED}${SYMBOL_ERROR} Error:${NC} $message" >&2
                ;;
        esac
    else
        echo "$error_type: $message" >&2
    fi
}

# Format success message
# Usage: format_success "success message"
format_success() {
    local message="$1"

    if is_tty; then
        echo -e "${GREEN}${SYMBOL_SUCCESS}${NC} $message"
    else
        echo "$message"
    fi
}

# Format info message
# Usage: format_info "info message"
format_info() {
    local message="$1"

    if is_tty; then
        echo -e "${BLUE}${SYMBOL_INFO}${NC} $message"
    else
        echo "$message"
    fi
}
