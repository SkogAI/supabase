# NPM Scripts Quick Reference

## Overview

This document provides a quick reference for all npm scripts available in this project. For detailed usage and workflows, see [CLAUDE.md](CLAUDE.md) and [WORKFLOWS.md](WORKFLOWS.md).

## Verification

```bash
# Verify all npm scripts work correctly
./scripts/verify_npm_scripts.sh
```

See [VERIFICATION_RESULTS.md](VERIFICATION_RESULTS.md) for detailed verification results.

## Database Operations

### Starting and Stopping

```bash
# Start local Supabase (requires Docker)
npm run db:start

# Stop Supabase services
npm run db:stop

# Check service status
npm run db:status
```

### Database Management

```bash
# Reset database (drops, recreates, runs migrations + seed)
npm run db:reset

# Show schema changes since last migration
npm run db:diff
```

### Migrations

```bash
# Create new migration with timestamp
npm run migration:new <migration_name>

# Apply migrations (alias for db:reset)
npm run migration:up
```

**Example:**
```bash
npm run migration:new add_users_table
```

## Edge Functions

### Function Management

```bash
# Create new edge function
npm run functions:new <function_name>

# Serve functions locally with hot reload
npm run functions:serve

# Deploy all functions to production
npm run functions:deploy
```

**Example:**
```bash
npm run functions:new my-api
```

### Function Development

```bash
# Lint Deno functions
npm run lint:functions

# Format Deno functions
npm run format:functions

# Test all edge functions
npm run test:functions

# Test with watch mode
npm run test:functions:watch

# Test with coverage
npm run test:functions:coverage

# Test with LCOV coverage report
npm run test:functions:coverage-lcov

# Run integration tests
npm run test:functions:integration
```

## Type Generation

```bash
# Generate TypeScript types from database schema
npm run types:generate

# Watch migrations and auto-regenerate types
npm run types:watch
```

**Note:** Run `types:generate` after any database schema changes.

## Testing

### Database Testing

```bash
# Test RLS policies
npm run test:rls

# Test storage policies (manual command)
supabase db execute --file tests/storage_test_suite.sql

# Test connection monitoring (manual command)
supabase db execute --file tests/connection_monitoring_test_suite.sql
```

### Application Testing

```bash
# Test realtime functionality
npm run test:realtime

# Setup realtime examples
npm run examples:realtime
```

### SAML Testing

```bash
# Run SAML integration tests
npm run test:saml

# Test SAML endpoints
npm run test:saml:endpoints

# Check SAML logs
npm run test:saml:logs
```

## Linting and Formatting

```bash
# Validate SQL syntax in migrations
npm run lint:sql

# Lint edge functions (same as lint:functions)
npm run lint:functions

# Format edge functions (same as format:functions)
npm run format:functions
```

## Utility Scripts

```bash
# Start development environment (db + functions in parallel)
npm run dev

# Setup project (start db + generate types)
npm run setup
```

## Common Workflows

### Initial Setup

```bash
# Install dependencies
npm install

# Start Supabase
npm run db:start

# Generate types
npm run types:generate

# Verify everything works
./scripts/verify_npm_scripts.sh
```

### Daily Development

```bash
# Start development environment
npm run dev

# In another terminal, watch types
npm run types:watch
```

### Creating a Feature with Database Changes

```bash
# 1. Create migration
npm run migration:new add_my_feature

# 2. Edit migration file in supabase/migrations/

# 3. Apply migration
npm run db:reset

# 4. Test RLS policies
npm run test:rls

# 5. Generate types
npm run types:generate

# 6. Commit changes
git add supabase/migrations/ types/database.ts
git commit -m "Add my feature"
```

### Creating a New Edge Function

```bash
# 1. Create function
npm run functions:new my-function

# 2. Develop function in supabase/functions/my-function/index.ts

# 3. Test locally
npm run functions:serve
# Then test: curl http://localhost:54321/functions/v1/my-function

# 4. Write tests in supabase/functions/my-function/test.ts

# 5. Run tests
npm run test:functions

# 6. Lint and format
npm run lint:functions
npm run format:functions

# 7. Deploy
npm run functions:deploy
```

### Before Pull Request

```bash
# Run all tests
npm run test:rls
npm run test:functions
npm run lint:sql
npm run lint:functions

# Generate types
npm run types:generate

# Verify everything
./scripts/verify_npm_scripts.sh
```

## Prerequisites

Different scripts require different tools to be installed:

| Tool | Required For | Install |
|------|--------------|---------|
| Docker | Database operations | [docker.com](https://docker.com) |
| Supabase CLI | Most operations | [supabase.com/docs/guides/cli](https://supabase.com/docs/guides/cli) |
| Deno | Edge functions | [deno.land](https://deno.land) |
| Node.js/npm | All scripts | [nodejs.org](https://nodejs.org) |
| sqlfluff | SQL linting | `pip install sqlfluff` |

## Script Categories

### By Frequency of Use

**Daily:**
- `npm run dev` - Start development environment
- `npm run db:reset` - Apply database changes
- `npm run types:generate` - Update types
- `npm run test:functions` - Test edge functions

**Weekly:**
- `npm run db:status` - Check services
- `npm run lint:functions` - Code quality
- `npm run test:rls` - Security testing

**As Needed:**
- `npm run migration:new` - Schema changes
- `npm run functions:new` - New functionality
- `npm run functions:deploy` - Production deployment

### By Purpose

**Development:**
- `dev`, `setup`, `db:start`, `db:stop`, `db:status`, `functions:serve`

**Database:**
- `db:reset`, `db:diff`, `migration:new`, `migration:up`

**Code Quality:**
- `lint:sql`, `lint:functions`, `format:functions`

**Testing:**
- `test:rls`, `test:functions`, `test:realtime`, `test:saml*`

**Deployment:**
- `functions:deploy`, `types:generate`

## Troubleshooting

### Script Fails with "command not found"

**Problem:** Missing prerequisite tool

**Solution:** Run `./scripts/verify_npm_scripts.sh` to see what's missing and get installation instructions

### Types are Out of Sync

**Problem:** Database schema changed but types weren't regenerated

**Solution:**
```bash
npm run types:generate
```

### Functions Won't Serve

**Problem:** Supabase not running or port conflict

**Solution:**
```bash
npm run db:status
npm run db:stop
npm run db:start
```

### Tests Fail After Migration

**Problem:** RLS policies or data changed

**Solution:**
```bash
npm run db:reset
npm run test:rls
```

## Additional Resources

- **[CLAUDE.md](CLAUDE.md)** - Essential commands and architecture
- **[WORKFLOWS.md](WORKFLOWS.md)** - Detailed development workflows
- **[VERIFICATION_RESULTS.md](VERIFICATION_RESULTS.md)** - Script verification results
- **[README.md](README.md)** - Project overview and setup
- **[supabase/functions/TESTING.md](supabase/functions/TESTING.md)** - Edge functions testing guide
- **[docs/RLS_TESTING.md](docs/RLS_TESTING.md)** - RLS testing guidelines

## Quick Links

- **Local Studio:** http://localhost:8000
- **Local API:** http://localhost:54321
- **Functions:** http://localhost:54321/functions/v1/
- **Database:** `postgresql://postgres:postgres@localhost:54322/postgres`

---

**Last Updated:** 2025-10-08  
**Total Scripts:** 28  
**Script Verification:** `./scripts/verify_npm_scripts.sh`
