#!/bin/bash
# Feature worktree setup script
# Auto-executed after worktree creation

set -e

WORKTREE_DIR="$(pwd)"

echo "🚀 Setting up feature worktree..."
echo ""

# Copy environment file if not exists
if [ ! -f ".env" ]; then
    echo "📋 Creating .env from template..."
    cp .dev/worktree-templates/feature/.env.example .env
    echo "   ✓ .env created (update with your API keys)"
else
    echo "   ℹ .env already exists, skipping"
fi

# Check if npm dependencies are installed
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 Installing npm dependencies..."
    npm install --silent
    echo "   ✓ Dependencies installed"
else
    echo "   ℹ Dependencies already installed"
fi

# Check if Supabase is running
echo ""
echo "🔍 Checking Supabase status..."
if ! supabase status > /dev/null 2>&1; then
    echo "   ⚠ Supabase is not running"
    echo "   Starting Supabase (this may take a minute)..."
    npm run db:start
    echo "   ✓ Supabase started"
else
    echo "   ✓ Supabase is running"
fi

# Reset database to apply all migrations
echo ""
echo "🗄️  Applying database migrations..."
npm run db:reset > /dev/null 2>&1
echo "   ✓ Database reset complete"

# Generate TypeScript types
echo ""
echo "📝 Generating TypeScript types..."
npm run types:generate > /dev/null 2>&1
echo "   ✓ Types generated"

echo ""
echo "✅ Feature Worktree Setup Complete!"
echo ""
echo "📋 Feature Development Checklist:"
echo "   - [ ] Create migration: npm run migration:new <name>"
echo "   - [ ] Add RLS policies for new tables"
echo "   - [ ] Test RLS: npm run test:rls"
echo "   - [ ] Generate types: npm run types:generate"
echo "   - [ ] Write edge function tests"
echo "   - [ ] Update documentation"
echo "   - [ ] Test locally before pushing"
echo ""
echo "📚 Useful Commands:"
echo "   npm run db:status        # Check services"
echo "   npm run db:reset         # Reset database"
echo "   npm run functions:serve  # Test edge functions"
echo "   npm run test:rls         # Test RLS policies"
echo ""
