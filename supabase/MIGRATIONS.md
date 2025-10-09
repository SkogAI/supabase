# Database Migrations

This directory contains all database schema migrations for the Supabase project. Migrations are applied in chronological order based on their timestamp prefix.

## 📋 Table of Contents

- [Naming Conventions](#naming-conventions)
- [Creating New Migrations](#creating-new-migrations)
- [Migration Best Practices](#migration-best-practices)
- [Running Migrations](#running-migrations)
- [Migration Structure](#migration-structure)
- [Examples](#examples)
- [Rollback Strategy](#rollback-strategy)
- [Troubleshooting](#troubleshooting)

## 🏷️ Naming Conventions

### File Naming Format

```
YYYYMMDDHHMMSS_descriptive_name.sql
```

**Components:**
- **Timestamp**: `YYYYMMDDHHMMSS` - Ensures chronological ordering
  - `YYYY`: 4-digit year (e.g., 2025)
  - `MM`: 2-digit month (01-12)
  - `DD`: 2-digit day (01-31)
  - `HH`: 2-digit hour (00-23) in UTC
  - `MM`: 2-digit minute (00-59)
  - `SS`: 2-digit second (00-59)
- **Descriptive Name**: Snake_case description of what the migration does

### Naming Examples

✅ **Good Names:**
- `20251005065505_initial_schema.sql`
- `20251005070000_add_categories_table.sql`
- `20251006120000_add_user_roles.sql`
- `20251007083000_add_posts_published_index.sql`
- `20251008150000_create_comments_table.sql`

❌ **Bad Names:**
- `migration.sql` - No timestamp, not descriptive
- `20251005_update.sql` - Missing time component
- `20251005065505_changes.sql` - Too vague
- `20251005065505_AddUserTable.sql` - PascalCase instead of snake_case

### Description Guidelines

Use clear, action-oriented names:
- `add_<table>_table` - Creating new tables
- `create_<feature>` - Creating a new feature
- `update_<table>_<field>` - Modifying existing schema
- `add_<table>_<column>` - Adding columns
- `drop_<table>_<column>` - Removing columns
- `add_<table>_index` - Adding indexes
- `enable_rls_<table>` - Adding security policies
- `fix_<issue>` - Fixing schema issues

## 🆕 Creating New Migrations

### Using Supabase CLI (Recommended)

```bash
# Create a new migration file with automatic timestamp
supabase migration new add_user_preferences

# Or using npm script
npm run migration:new add_user_preferences
```

This creates: `supabase/migrations/YYYYMMDDHHMMSS_add_user_preferences.sql`

### Manual Creation

If creating manually, use current UTC timestamp:

```bash
# Get current UTC timestamp
date -u +"%Y%m%d%H%M%S"

# Create file
touch supabase/migrations/20251005120000_my_migration.sql
```

### Migration Template

Start each migration with this header:

```sql
-- Migration: <Descriptive Title>
-- Created: YYYY-MM-DD
-- Description: <Detailed description of changes>
--
-- Changes:
-- - <List specific changes>
-- - <One per line>

-- Your SQL code here
```

## ✅ Migration Best Practices

### 1. **Idempotency**

Always use `IF NOT EXISTS` / `IF EXISTS` for idempotent operations:

```sql
-- ✅ Good - Can be run multiple times safely
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY
);

-- ❌ Bad - Fails if run twice
CREATE TABLE users (
    id UUID PRIMARY KEY
);
```

### 2. **Backward Compatibility**

Avoid breaking changes when possible:

```sql
-- ✅ Good - Add nullable column first
ALTER TABLE posts ADD COLUMN status TEXT;
UPDATE posts SET status = 'draft' WHERE status IS NULL;
ALTER TABLE posts ALTER COLUMN status SET NOT NULL;

-- ❌ Bad - Adding NOT NULL column breaks existing code
ALTER TABLE posts ADD COLUMN status TEXT NOT NULL DEFAULT 'draft';
```

### 3. **Use Transactions Implicitly**

Supabase wraps each migration in a transaction automatically, but be aware:

```sql
-- Each migration is wrapped in:
-- BEGIN;
-- ... your migration code ...
-- COMMIT;
```

### 4. **Enable RLS on All Public Tables**

```sql
-- Always enable RLS for security
ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;

-- Add appropriate policies
CREATE POLICY "Users can read their own data"
    ON public.my_table
    FOR SELECT
    USING (auth.uid() = user_id);
```

### 5. **Add Indexes for Performance**

```sql
-- Index foreign keys
CREATE INDEX IF NOT EXISTS posts_user_id_idx ON posts(user_id);

-- Index commonly queried columns
CREATE INDEX IF NOT EXISTS posts_created_at_idx ON posts(created_at DESC);

-- Partial indexes for specific queries
CREATE INDEX IF NOT EXISTS posts_published_idx 
    ON posts(published) WHERE published = true;
```

### 6. **Use Constraints for Data Integrity**

```sql
-- Check constraints
ALTER TABLE users ADD CONSTRAINT users_email_format 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Unique constraints
ALTER TABLE users ADD CONSTRAINT users_username_unique UNIQUE (username);

-- Foreign key constraints with proper cascade
ALTER TABLE posts ADD CONSTRAINT posts_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
```

### 7. **Add Documentation**

```sql
-- Table comments
COMMENT ON TABLE public.posts IS 'User-generated content with RLS policies';

-- Column comments
COMMENT ON COLUMN public.posts.published IS 'Whether the post is publicly visible';

-- Function comments
COMMENT ON FUNCTION handle_updated_at() IS 'Automatically updates updated_at timestamp';
```

### 8. **Organize with Section Headers**

```sql
-- ============================================================================
-- TABLES
-- ============================================================================

CREATE TABLE ...

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX ...

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

CREATE POLICY ...
```

### 9. **Use Consistent Naming**

- **Tables**: `snake_case`, plural (e.g., `users`, `blog_posts`)
- **Columns**: `snake_case` (e.g., `user_id`, `created_at`)
- **Indexes**: `<table>_<column>_idx` (e.g., `users_email_idx`)
- **Constraints**: `<table>_<column>_<type>` (e.g., `users_email_key`)
- **Functions**: `snake_case`, verb prefix (e.g., `handle_new_user`)
- **Policies**: Descriptive strings (e.g., `"Users can update their own posts"`)

### 10. **Handle Timestamps Consistently**

```sql
-- Use TIMESTAMPTZ (timestamp with time zone)
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()

-- Add automatic updated_at trigger
CREATE TRIGGER my_table_updated_at
    BEFORE UPDATE ON public.my_table
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
```

## 🏃 Running Migrations

### Local Development

```bash
# Start Supabase (if not running)
npm run db:start

# Apply all migrations (resets database)
npm run db:reset

# Check migration status
npm run db:status

# Generate TypeScript types after migration
npm run types:generate
```

### Production Deployment

Migrations are automatically applied on deployment via GitHub Actions:

1. Push to `master`/`main` branch
2. GitHub Actions workflow runs
3. Migrations are applied via `supabase db push`
4. Edge functions are deployed
5. Types are generated

### Manual Production Deployment

```bash
# Link to your project
supabase link --project-ref your-project-ref

# Push database changes
supabase db push

# Or push specific migration
supabase db push --dry-run  # Preview first
supabase db push
```

## 📁 Migration Structure

### Current Migrations

```
supabase/migrations/
├── README.md                                      # This file
├── 20251005065505_initial_schema.sql             # Base schema
└── 20251005070000_example_add_categories.sql     # Example migration
```

### Initial Schema (`20251005065505_initial_schema.sql`)

Includes:
- **Extensions**: `uuid-ossp`, `pgcrypto`
- **Tables**: `profiles`, `posts`
- **RLS Policies**: Complete policies for all tables
- **Functions**: `handle_updated_at()`, `handle_new_user()`
- **Triggers**: Auto-update timestamps, auto-create profiles

### Example Migration (`20251005070000_example_add_categories.sql`)

Demonstrates:
- Creating new tables with constraints
- Many-to-many relationships
- Indexing strategies
- RLS policy patterns
- Seed data insertion
- Comprehensive comments

## 📚 Examples

### Example 1: Add a Column

```sql
-- Migration: Add bio column to profiles
-- Created: 2025-10-05
-- Description: Add bio field for user descriptions

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS bio TEXT;

COMMENT ON COLUMN public.profiles.bio IS 'User biography or description';
```

### Example 2: Create a New Table

```sql
-- Migration: Create comments table
-- Created: 2025-10-05
-- Description: Add commenting functionality to posts

CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS comments_post_id_idx ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS comments_user_id_idx ON public.comments(user_id);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are viewable by everyone"
    ON public.comments FOR SELECT USING (true);

CREATE POLICY "Users can create comments"
    ON public.comments FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments"
    ON public.comments FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
    ON public.comments FOR DELETE 
    USING (auth.uid() = user_id);
```

### Example 3: Add an Index

```sql
-- Migration: Add index for post search
-- Created: 2025-10-05
-- Description: Improve performance of title searches

CREATE INDEX IF NOT EXISTS posts_title_search_idx 
ON public.posts USING gin(to_tsvector('english', title));
```

### Example 4: Modify Existing Data

```sql
-- Migration: Normalize email addresses
-- Created: 2025-10-05
-- Description: Convert all emails to lowercase

UPDATE public.profiles
SET email = LOWER(email)
WHERE email != LOWER(email);
```

## 🔄 Rollback Strategy

### Prevention is Better than Cure

1. **Test locally first**: Always test migrations with `npm run db:reset`
2. **Use CI/CD**: Migrations are validated in GitHub Actions
3. **Review carefully**: Get code review before merging
4. **Backup first**: Production databases are backed up automatically

### Manual Rollback

If a migration causes issues:

```bash
# 1. Create a rollback migration
supabase migration new rollback_problematic_change

# 2. Write the reverse operations
# Example: If you added a column, drop it
ALTER TABLE posts DROP COLUMN IF EXISTS problematic_column;

# 3. Apply the rollback
supabase db push
```

### Best Practices for Rollback-Friendly Migrations

- Keep migrations small and focused
- Avoid destructive operations when possible
- Use feature flags for application-level changes
- Document rollback steps in migration comments

## 🔧 Troubleshooting

### Migration Fails Locally

```bash
# Check current status
npm run db:status

# Reset database completely
npm run db:stop
npm run db:start
npm run db:reset
```

### Migration Timestamp Conflicts

If two developers create migrations simultaneously:

```bash
# Rename the newer migration file to a later timestamp
mv 20251005070000_my_migration.sql 20251005070100_my_migration.sql
```

### Migration Fails in Production

```bash
# Check migration status
supabase migration list

# View recent logs
supabase db logs

# Dry run to see what would happen
supabase db push --dry-run
```

### Can't Drop Table Due to Dependencies

```sql
-- Drop dependent views first
DROP VIEW IF EXISTS my_view CASCADE;

-- Then drop the table
DROP TABLE IF EXISTS my_table CASCADE;
```

### RLS Policies Not Working

```sql
-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check existing policies
SELECT * FROM pg_policies WHERE schemaname = 'public';

-- Test with specific user
SET request.jwt.claim.sub = 'user-uuid-here';
SELECT * FROM my_table;  -- Should respect RLS
```

## 🔗 Additional Resources

- [Supabase Migrations Documentation](https://supabase.com/docs/guides/database/migrations)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/current/)
- [Row Level Security Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Project README](../../README.md) - Development workflow
- [DEVOPS.md](../../DEVOPS.md) - CI/CD and deployment guide

## 📝 Migration Checklist

Before creating a migration, review this checklist:

- [ ] Migration name is descriptive and follows naming convention
- [ ] Header comment with description and date
- [ ] Uses `IF NOT EXISTS` / `IF EXISTS` for idempotency
- [ ] Includes necessary indexes for performance
- [ ] RLS is enabled on new public tables
- [ ] RLS policies are defined for all operations
- [ ] Foreign keys use appropriate `ON DELETE` behavior
- [ ] Constraints are added for data validation
- [ ] Comments are added for documentation
- [ ] Tested locally with `npm run db:reset`
- [ ] Backward compatible (or breaking changes documented)
- [ ] TypeScript types will be regenerated
- [ ] Reviewed by another team member

---

**Note**: This directory is automatically managed by Supabase CLI. Do not manually edit migration files after they've been applied to production.
