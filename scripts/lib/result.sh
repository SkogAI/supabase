#!/usr/bin/env bash
# result.sh - Standardized result objects for script operations
#
# Provides consistent result/error structure across all scripts.
# Results follow the operation-result.schema.json format.
#
# Usage:
#   source "$(dirname "$0")/lib/result.sh"
#   result=$(success_result "create_issue" "$data")
#   result=$(error_result "network_error" "Failed to connect" "$data")

# Create a successful result
# Args:
#   $1 - operation name (string)
#   $2 - data (JSON string or object)
#   $3 - warnings array (optional, JSON array)
success_result() {
    local operation="$1"
    local data="$2"
    local warnings="${3:-[]}"
    local timestamp duration

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    duration="${RESULT_DURATION:-0}"

    jq -n \
        --arg op "$operation" \
        --argjson data "$data" \
        --argjson warnings "$warnings" \
        --arg ts "$timestamp" \
        --argjson dur "$duration" \
        '{
            result: {
                success: true,
                operation: $op,
                data: $data,
                error: null,
                warnings: $warnings,
                metadata: {
                    timestamp: $ts,
                    duration: $dur
                }
            }
        }'
}

# Create an error result
# Args:
#   $1 - error type (string)
#   $2 - error message (string)
#   $3 - data (JSON string or object, optional)
#   $4 - suggestions array (optional, JSON array of strings)
error_result() {
    local error_type="$1"
    local message="$2"
    local data="${3:-{}}"
    local suggestions="${4:-[]}"
    local timestamp duration

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    duration="${RESULT_DURATION:-0}"

    jq -n \
        --arg type "$error_type" \
        --arg msg "$message" \
        --argjson data "$data" \
        --argjson suggestions "$suggestions" \
        --arg ts "$timestamp" \
        --argjson dur "$duration" \
        '{
            result: {
                success: false,
                operation: null,
                data: $data,
                error: {
                    type: $type,
                    message: $msg,
                    suggestions: $suggestions
                },
                warnings: [],
                metadata: {
                    timestamp: $ts,
                    duration: $dur
                }
            }
        }'
}

# Add a warning to an existing result
# Args:
#   $1 - result JSON
#   $2 - warning message
add_warning() {
    local result="$1"
    local warning="$2"

    echo "$result" | jq \
        --arg warn "$warning" \
        '.result.warnings += [$warn]'
}

# Check if a result indicates success
is_success() {
    local result="$1"
    echo "$result" | jq -r '.result.success'
}

# Extract data from a result
get_result_data() {
    local result="$1"
    echo "$result" | jq -r '.result.data'
}

# Extract error message from a result
get_error_message() {
    local result="$1"
    echo "$result" | jq -r '.result.error.message // empty'
}

# Extract error type from a result
get_error_type() {
    local result="$1"
    echo "$result" | jq -r '.result.error.type // empty'
}

# Time a command and set RESULT_DURATION
# Usage: time_operation command args...
time_operation() {
    local start_time end_time
    start_time=$(date +%s.%N)

    "$@"
    local exit_code=$?

    end_time=$(date +%s.%N)
    RESULT_DURATION=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
    export RESULT_DURATION

    return $exit_code
}
