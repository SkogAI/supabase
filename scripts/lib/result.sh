#!/usr/bin/env bash
# result.sh - Standardized result objects for script operations
# Usage: source "$(dirname "$0")/lib/result.sh"

# Create a success result
# Usage: success_result "operation_name" '{"key": "value"}'
success_result() {
    local operation="$1"
    local data="${2:-{}}"
    local timestamp

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq -n \
        --arg op "$operation" \
        --argjson data "$data" \
        --arg ts "$timestamp" \
        '{
            result: {
                success: true,
                operation: $op,
                data: $data,
                error: null,
                warnings: [],
                metadata: {
                    timestamp: $ts
                }
            }
        }'
}

# Create an error result
# Usage: error_result "operation_name" "error_message" "error_type" '{"context": "data"}'
error_result() {
    local operation="$1"
    local message="$2"
    local error_type="${3:-general}"
    local context="${4:-{}}"
    local timestamp

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq -n \
        --arg op "$operation" \
        --arg msg "$message" \
        --arg type "$error_type" \
        --argjson ctx "$context" \
        --arg ts "$timestamp" \
        '{
            result: {
                success: false,
                operation: $op,
                data: null,
                error: {
                    message: $msg,
                    type: $type,
                    context: $ctx
                },
                warnings: [],
                metadata: {
                    timestamp: $ts
                }
            }
        }'
}

# Add a warning to a result
# Usage: result=$(echo "$result" | add_warning "warning message")
add_warning() {
    local warning="$1"

    jq --arg warn "$warning" \
        '.result.warnings += [$warn]'
}

# Add metadata to a result
# Usage: result=$(echo "$result" | add_metadata "key" "value")
add_metadata() {
    local key="$1"
    local value="$2"

    jq --arg k "$key" --arg v "$value" \
        '.result.metadata[$k] = $v'
}

# Check if result is successful
# Usage: if is_success "$result"; then ...
is_success() {
    local result="$1"

    echo "$result" | jq -e '.result.success' > /dev/null 2>&1
}

# Extract data from result
# Usage: data=$(get_result_data "$result")
get_result_data() {
    local result="$1"

    echo "$result" | jq -r '.result.data'
}

# Extract error from result
# Usage: error=$(get_result_error "$result")
get_result_error() {
    local result="$1"

    echo "$result" | jq -r '.result.error'
}

# Get error type from result
# Usage: error_type=$(get_error_type "$result")
get_error_type() {
    local result="$1"

    echo "$result" | jq -r '.result.error.type // "unknown"'
}

# Print result summary (for debugging)
# Usage: print_result_summary "$result"
print_result_summary() {
    local result="$1"
    local success operation

    success=$(echo "$result" | jq -r '.result.success')
    operation=$(echo "$result" | jq -r '.result.operation')

    if [ "$success" = "true" ]; then
        echo "✓ $operation succeeded"
    else
        local error_msg
        error_msg=$(echo "$result" | jq -r '.result.error.message')
        echo "✗ $operation failed: $error_msg"
    fi
}
