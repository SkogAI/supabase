#!/bin/bash
# Hotfix worktree setup script
# Auto-executed after worktree creation

set -e

WORKTREE_DIR="$(pwd)"

echo "🚨 Setting up HOTFIX worktree..."
echo ""

# Copy environment file if not exists
if [ ! -f ".env" ]; then
    echo "📋 Creating .env from template..."
    cp .dev/worktree-templates/hotfix/.env.example .env
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
echo "⚠️  HOTFIX Worktree Setup Complete!"
echo ""
echo "🚨 CRITICAL HOTFIX CHECKLIST:"
echo "   ⚠️  This is a PRODUCTION hotfix - exercise extreme caution"
echo ""
echo "   - [ ] Reproduce critical issue"
echo "   - [ ] Implement minimal fix only"
echo "   - [ ] Test thoroughly (no shortcuts!)"
echo "   - [ ] Run ALL test suites"
echo "   - [ ] Verify no side effects"
echo "   - [ ] Get expedited code review"
echo "   - [ ] Test deployment process"
echo "   - [ ] Prepare rollback plan"
echo ""
echo "📚 Required Commands:"
echo "   npm run test:rls         # Test RLS policies"
echo "   npm run test:functions   # Test all functions"
echo "   npm run db:reset         # Verify migrations"
echo ""
echo "⚠️  Remember: Hotfixes merge to 'master' and require immediate deployment!"
echo ""
