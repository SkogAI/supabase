#!/usr/bin/env bash
# Example 1: Hello World - Simplest possible argc script

set -e

# @cmd Say hello to someone
# @arg name!  Person's name
hello() {
    echo "Hello, $argc_name!"
}

eval "$(argc --argc-eval "$0" "$@")"
