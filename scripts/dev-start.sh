#!/bin/bash
# Quick development start script

set -e

echo "🚀 Starting Supabase development environment..."

# Start Supabase
supabase start

echo ""
echo "✅ Development environment is ready!"
echo ""
echo "📊 Studio:     http://localhost:8000"
echo "🔌 API:        http://localhost:8000"
echo "🗄️  Database:   postgresql://postgres:postgres@localhost:54322/postgres"
echo ""
echo "Run 'supabase status' to see all services"
echo "Run 'supabase stop' to stop all services"
