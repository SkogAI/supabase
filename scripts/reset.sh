#!/bin/bash
# Reset database with fresh migrations and seed data

set -e

echo "🔄 Resetting database..."
echo "⚠️  This will delete all data and reapply migrations"
echo ""
read -p "Are you sure? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    supabase db reset
    echo ""
    echo "✅ Database reset complete!"
    echo "📝 Check seed data in Supabase Studio: http://localhost:8000"
else
    echo "❌ Reset cancelled"
fi
