# Feature Worktree

This worktree is configured for feature development following GitHub Git Flow.

## Branch Info

- **Type**: Feature
- **Base Branch**: `develop`
- **Purpose**: New features and enhancements

## Quick Start

```bash
# Database operations
npm run db:status        # Check service status
npm run db:reset         # Apply all migrations
npm run db:diff          # Generate schema diff

# Create migration
npm run migration:new add_feature_name

# Generate types after schema changes
npm run types:generate

# Test RLS policies
npm run test:rls

# Edge functions
npm run functions:serve  # Start local server
npm run test:functions   # Run function tests
```

## Feature Development Workflow

### 1. Create Database Migration (if needed)

```bash
npm run migration:new add_feature_table
```

Edit the generated file in `supabase/migrations/`:

```sql
-- Example: Add feature table
create table public.feature_data (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade not null,
    data jsonb not null,
    created_at timestamptz default now()
);

-- Enable RLS
alter table public.feature_data enable row level security;

-- Service role full access
create policy "Service role full access" on public.feature_data
    for all to service_role using (true) with check (true);

-- Users manage own data
create policy "Users manage own data" on public.feature_data
    for all to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
```

### 2. Apply Migration & Test

```bash
npm run db:reset      # Apply migration
npm run test:rls      # Test RLS policies
npm run types:generate # Update TypeScript types
```

### 3. Develop Edge Function (if needed)

```bash
npm run functions:new my-feature
cd supabase/functions/my-feature

# Edit index.ts
# Create test.ts
deno test --allow-all test.ts
```

### 4. Test Locally

```bash
npm run functions:serve  # Start function server
npm run test:functions   # Run all tests
```

### 5. Commit & Push

```bash
git add .
git commit -m "Add feature: description

- Implement feature table with RLS
- Add edge function for feature logic
- Update TypeScript types

Closes SkogAI/supabase#<issue-number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

git push -u origin feature/<branch-name>
```

### 6. Create Pull Request

```bash
gh pr create --base develop --title "Add feature name" --body "Implements #<issue-number>"
```

## Migration Naming Conventions

- `add_<table>_table` - New tables
- `add_<table>_<column>` - New columns
- `enable_rls_<table>` - Security policies
- `add_<table>_index` - Performance indexes
- `alter_<table>_<change>` - Schema modifications

## RLS Policy Requirements

All public tables must have:
- Service role full access policy
- Authenticated user policies (own data + public data)
- Anonymous user policies (read-only for published content)

## Testing Checklist

- [ ] Database migration applies cleanly
- [ ] RLS policies tested with `npm run test:rls`
- [ ] TypeScript types generated
- [ ] Edge functions have tests
- [ ] Manual testing completed
- [ ] Documentation updated

## Common Issues

**Migration fails**: Check syntax with `npm run lint:sql`

**RLS test fails**: Verify policy logic in test suite

**Type generation fails**: Ensure Supabase is running (`npm run db:status`)

**Function deployment fails**: Test locally first (`npm run functions:serve`)

## Resources

- [RLS Policies Guide](../../docs/RLS_POLICIES.md)
- [Migration Guidelines](../../supabase/migrations/README.md)
- [Edge Functions Guide](../../supabase/functions/README.md)
- [Development Conventions](../../docs/CONVENTIONS.md)
