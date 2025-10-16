#!/usr/bin/env bash
# Example 4: Multiple Commands (Subcommands)

set -e

# @cmd Start the application
start() {
    echo "🚀 Starting application..."
    echo "✓ Application started on http://localhost:3000"
}

# @cmd Stop the application
stop() {
    echo "⏹ Stopping application..."
    echo "✓ Application stopped"
}

# @cmd Show application status
status() {
    echo "📊 Application Status:"
    echo "  Status: Running"
    echo "  Uptime: 2h 34m"
    echo "  Memory: 245MB"
}

# @cmd Restart the application
restart() {
    echo "🔄 Restarting application..."
    stop
    start
}

eval "$(argc --argc-eval "$0" "$@")"

# Usage:
# ./04_multi_command.sh start
# ./04_multi_command.sh stop
# ./04_multi_command.sh status
# ./04_multi_command.sh restart
# ./04_multi_command.sh --help    # Shows all commands
