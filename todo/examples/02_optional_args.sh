#!/usr/bin/env bash
# Example 2: Optional Arguments with Defaults

set -e

# @cmd Greet someone with optional title
# @arg name!   Person's name (required)
# @arg title   Title (optional, defaults to "Friend")
greet() {
    local title="${argc_title:-Friend}"
    echo "Hello, $title $argc_name!"
}

eval "$(argc --argc-eval "$0" "$@")"

# Usage:
# ./02_optional_args.sh greet John
# Output: Hello, Friend John!
#
# ./02_optional_args.sh greet John "Dr."
# Output: Hello, Dr. John!
