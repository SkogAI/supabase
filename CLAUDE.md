# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Production-ready Supabase backend with PostgreSQL database, Row Level Security (RLS), Edge Functions (Deno), Storage buckets, Realtime subscriptions, and comprehensive CI/CD pipeline. The project includes MCP (Model Context Protocol) server infrastructure for AI agent integration.

## Essential Commands

### Database Operations

```bash
# Start local Supabase (requires Docker Desktop running)
npm run db:start

# Stop Supabase services
npm run db:stop

# Reset database (drops, recreates, runs all migrations + seed data)
npm run db:reset

# Check migration status and service info
npm run db:status

# Generate SQL diff of current schema changes
npm run db:diff

# Create new migration (auto-generates timestamp)
npm run migration:new <migration_name>
```

### Edge Functions

```bash
# Create new edge function
npm run functions:new <function_name>

# Serve functions locally with hot reload
npm run functions:serve

# Deploy all functions to production
npm run functions:deploy

# Deploy specific function
supabase functions deploy <function_name>

# Lint Deno functions
npm run lint:functions

# Format Deno functions
npm run format:functions

# Test all edge functions
npm run test:functions

# Test specific function
cd supabase/functions/<function-name> && deno test --allow-all test.ts
```

### TypeScript Type Generation

```bash
# Generate TypeScript types from database schema
npm run types:generate

# Watch migrations and auto-regenerate types
npm run types:watch
```

### Testing

```bash
# Test RLS policies with comprehensive test suite
npm run test:rls

# Test storage policies
supabase db execute --file tests/storage_test_suite.sql

# Test realtime functionality
npm run test:realtime

# Validate SQL syntax
npm run lint:sql
```

### Development Dependencies

```bash
# Install Python development dependencies (sqlfluff for SQL linting)
pip install -r requirements-dev.txt

# Or install with pipx for isolated environment
pipx install sqlfluff
```

## Architecture

### Directory Structure

```
supabase/
├── migrations/              # Timestamped SQL migrations (YYYYMMDDHHMMSS_description.sql)
├── functions/               # Deno edge functions (TypeScript 5.3+)
│   ├── hello-world/
│   ├── openai-chat/         # OpenAI integration example
│   ├── openrouter-chat/     # Multi-model AI via OpenRouter
│   └── _shared/             # Shared utilities across functions
├── seed.sql                 # Test data with 3 users (alice, bob, charlie)
└── config.toml              # Supabase project configuration

types/
└── database.ts              # Auto-generated from schema (run types:generate after schema changes)

tests/
├── rls_test_suite.sql       # Comprehensive RLS policy tests
└── storage_test_suite.sql   # Storage bucket permission tests

scripts/
├── setup.sh                 # Automated project setup
├── dev.sh                   # Quick development start
└── reset.sh                 # Database reset helper
```

### Database Schema Organization

- **Custom schemas**: Additional schemas can be added via `config.toml` `api.schemas` array (currently: `public`, `graphql_public`)
- **Search path**: `public` and `extensions` schemas in search path
- **Migrations**: All migrations in `supabase/migrations/` with format `YYYYMMDDHHMMSS_description.sql`
- **Seed data**: Contains 3 test users with fixed UUIDs for RLS testing (see `supabase/seed.sql`)

Current tables:
- `profiles` - User profiles with comprehensive RLS policies
- `posts` - User-generated content with publish/draft states

### Row Level Security (RLS)

**Critical**: All public tables MUST have RLS enabled with policies for:
- Service role (full admin access)
- Authenticated users (own data + public data)
- Anonymous users (read-only published content)

**Testing RLS**: Always run `npm run test:rls` after schema changes affecting permissions.

### Edge Functions Architecture

- **Runtime**: Deno 2.x with TypeScript
- **Shared code**: Place reusable utilities in `supabase/functions/_shared/`
- **Environment**: Functions access secrets via `Deno.env.get()` (set in Supabase Dashboard)
- **CORS**: Configure in function code for browser access
- **AI integrations**: Examples in `openai-chat` and `openrouter-chat` functions

### Storage Buckets

Pre-configured buckets with RLS policies:
- `avatars` - Public, 5MB limit, images only
- `public-assets` - Public, 10MB limit, images/PDFs
- `user-files` - Private, 50MB limit, user documents

Files must be organized in user-scoped paths: `{bucket}/{user_id}/filename.ext`

### Realtime Configuration

Enabled for tables: `profiles`, `posts`

Enable realtime on new tables:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE your_table;
ALTER TABLE your_table REPLICA IDENTITY FULL;
```

Rate limits (configurable in `config.toml`):
- 100 concurrent connections per client
- 100 channels per connection
- 500 joins/sec, 1000 messages/sec

## Development Workflow

### Creating Database Migrations

1. **Create migration**: `npm run migration:new add_feature_name`
2. **Edit** the generated file in `supabase/migrations/`
3. **Apply locally**: `npm run db:reset`
4. **Test RLS**: `npm run test:rls` if security policies changed
5. **Generate types**: `npm run types:generate`
6. **Commit** migration file and updated types

**Migration naming**: Use snake_case with clear action verbs:
- `add_<table>_table` - New tables
- `add_<table>_<column>` - New columns
- `enable_rls_<table>` - Security policies
- `add_<table>_index` - Performance indexes

### Working with Edge Functions

1. **Create**: `npm run functions:new my-function`
2. **Develop**: Edit `supabase/functions/my-function/index.ts`
3. **Test locally**: `npm run functions:serve` then `curl http://localhost:54321/functions/v1/my-function`
4. **Write tests**: Create `test.ts` in function directory
5. **Run tests**: `cd supabase/functions/my-function && deno test --allow-all test.ts`
6. **Deploy**: `supabase functions deploy my-function`

### Seed Data for Testing

Test users (password: `password123`):
- Alice: `00000000-0000-0000-0000-000000000001` (alice@example.com)
- Bob: `00000000-0000-0000-0000-000000000002` (bob@example.com)
- Charlie: `00000000-0000-0000-0000-000000000003` (charlie@example.com)

Use these fixed UUIDs in RLS tests:
```sql
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
```

## CI/CD Integration

Workflows in `.github/workflows/`:
- `claude-code-review.yml` - AI-powered PR reviews
- `claude-general.yml` - General Claude Code integration

**Required GitHub Secrets** (set in repository settings):
- `SUPABASE_ACCESS_TOKEN` - From Supabase Dashboard → Account → Access Tokens
- `SUPABASE_PROJECT_ID` - From Supabase Dashboard → Project Settings → Reference ID
- `SUPABASE_DB_PASSWORD` - From Supabase Dashboard → Database settings
- `CLAUDE_CODE_OAUTH_TOKEN` - (Optional) For AI PR analysis

**Deployment**: Merge to `develop` branch triggers automated deployment

## AI Integration (MCP)

This project includes Model Context Protocol (MCP) server infrastructure for AI agents.

**Connection types**:
- Direct IPv6 (port 5432) - Persistent agents, full PostgreSQL features
- Supavisor Session (port 5432) - IPv4 persistent agents
- Supavisor Transaction (port 6543) - Serverless/Edge agents with auto-cleanup
- Dedicated Pooler - High-performance isolated resources

**Documentation**: See `docs/MCP_*.md` files for complete implementation guides

## Local Development URLs

- **Studio UI**: http://localhost:8000
- **API**: http://localhost:54321
- **Database**: `postgresql://postgres:postgres@localhost:54322/postgres`
- **Edge Functions**: http://localhost:54321/functions/v1/<function-name>
- **Deno Inspector**: http://localhost:8083

## Common Patterns

### Adding a New Table

```sql
-- In new migration file
CREATE TABLE public.my_table (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;

-- Service role full access
CREATE POLICY "Service role full access" ON public.my_table
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Authenticated users: view all, manage own
CREATE POLICY "Authenticated view all" ON public.my_table
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users manage own data" ON public.my_table
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Anonymous read-only
CREATE POLICY "Anonymous read all" ON public.my_table
    FOR SELECT TO anon USING (true);

-- Auto-update updated_at
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.my_table
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable realtime (optional)
ALTER PUBLICATION supabase_realtime ADD TABLE public.my_table;
ALTER TABLE public.my_table REPLICA IDENTITY FULL;
```

### Testing RLS Policies

Run the comprehensive test suite after any RLS changes:
```bash
npm run test:rls
```

Expected output includes PASS/FAIL for:
- RLS enabled on all tables
- Service role access
- Authenticated user permissions
- Anonymous user restrictions
- Cross-user access controls

## Troubleshooting

**Docker not running**:
```bash
docker info  # Verify Docker is running
```

**Port conflicts**:
```bash
supabase stop
lsof -i :8000
lsof -i :54322
```

**Migration errors**:
```bash
supabase db reset --debug
```

**Function deployment fails**:
```bash
supabase functions logs <function-name>
supabase functions serve <function-name>  # Test locally first
```

**Type generation fails**:
Ensure Supabase is running: `npm run db:start` then `npm run types:generate`

## Key Configuration Files

- **supabase/config.toml**: All Supabase settings (ports, database version, realtime limits, storage)
- **.env.example**: Template for local environment variables (copy to `.env`, never commit `.env`)
- **package.json**: npm scripts for all common operations
- **types/database.ts**: Auto-generated, regenerate after schema changes

## Documentation References

Core documentation in repository:
- `README.md` - Quick start and feature overview
- `CONTRIBUTING.md` - Complete contributor guide with code guidelines and PR process
- `WORKFLOWS.md` - Detailed development workflows and common procedures
- `TROUBLESHOOTING.md` - Comprehensive troubleshooting guide for all common issues
- `ARCHITECTURE.md` - System architecture overview and design decisions
- `DEVOPS.md` - Complete CI/CD and deployment guide
- `docs/RLS_POLICIES.md` - RLS patterns and best practices
- `docs/STORAGE.md` - Storage bucket configuration and usage
- `docs/MCP_*.md` - AI agent integration guides
- `supabase/README.md` - Seed data and configuration details
- `supabase/migrations/README.md` - Migration guidelines and naming conventions
- `supabase/functions/README.md` - Edge function development guide
