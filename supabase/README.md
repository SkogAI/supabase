# Supabase Database Configuration

This directory contains all database-related configuration and scripts for local development and testing.

## 📁 Directory Structure

```
supabase/
├── config.toml           # Supabase project configuration
├── migrations/           # Database schema migrations (timestamped SQL files)
├── functions/            # Edge Functions (Deno/TypeScript)
├── seed.sql             # Development seed data
├── seed.sql             # Development seed data (this file)
└── README.md            # This file
```

## 🌱 Seed Data (`seed.sql`)

The `seed.sql` file contains test data for local development and testing. It is automatically loaded when running `supabase db reset`.

### ⚠️ Important Notes

- **DO NOT use seed data in production!** This data is for local development only.
- The seed file is referenced in `config.toml` under `[db.seed]` section.
- Seed data is applied **after** all migrations are run.

### 📊 Seed Data Structure

#### Test Users

The seed file creates three test users in the `auth.users` table with corresponding profiles:

| Username | User ID | Email | Password | Description |
|----------|---------|-------|----------|-------------|
| **alice** | `00000000-0000-0000-0000-000000000001` | alice@example.com | `password123` | Software engineer and open source enthusiast |
| **bob** | `00000000-0000-0000-0000-000000000002` | bob@example.com | `password123` | Full-stack developer |
| **charlie** | `00000000-0000-0000-0000-000000000003` | charlie@example.com | `password123` | Designer and developer hybrid |

#### Test Data Summary

- **3 User Profiles** - Complete with usernames, full names, avatars, and bios
- **7 Sample Posts** - Mix of published posts and draft content
  - Alice: 2 published posts + 1 draft
  - Bob: 2 published posts
  - Charlie: 2 published posts

### 🔐 Authentication Setup

Test users are created with:
- Properly encrypted passwords using `crypt()` and `gen_salt('bf')`
- Email confirmation already completed
- User metadata including username, full_name, and avatar_url in `raw_user_meta_data`
- Creation dates spread over 30 days for realistic testing
- **Automatic profile creation via `handle_new_user()` trigger** (defined in `migrations/20251005052938_initial_schema.sql`)

#### 🔄 How Profile Creation Works

When a user is inserted into `auth.users`, the `handle_new_user()` trigger automatically:
1. Extracts `username`, `full_name`, and `avatar_url` from `raw_user_meta_data`
2. Creates a corresponding entry in `public.profiles` table
3. Links the profile to the auth user via the user's UUID

The `bio` field is then populated via UPDATE statements since it's not stored in metadata. This approach matches production behavior where Supabase Auth creates profiles automatically on signup.
- User metadata including username and full_name
- Creation dates spread over 30 days for realistic testing

### 🧪 Using Test Users for RLS Testing

The test user IDs are fixed and can be used for testing Row Level Security policies:

```sql
-- Set user context as Alice
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

-- Test SELECT operations
SELECT * FROM profiles;
SELECT * FROM posts;

-- Test INSERT operations
INSERT INTO posts (user_id, title, content, published)
VALUES ('00000000-0000-0000-0000-000000000001', 'My Test Post', 'Content here', true);
```

See `tests/rls_test_suite.sql` for comprehensive RLS testing examples.

### 🔄 Resetting the Database

To reload the seed data:

```bash
# Reset database (runs migrations + seed data)
npm run db:reset

# Or using Supabase CLI directly
supabase db reset

# Validate SQL syntax before resetting
npm run lint:sql
```

This will:
1. Drop the existing database
2. Create a fresh database
3. Run all migrations in order (including trigger creation)
4. Load the seed data (which triggers profile auto-creation)
3. Run all migrations in order
4. Load the seed data
5. Display a summary of loaded data

### 📋 Seed Data Verification

The seed file includes an automated verification script that runs after loading data. It displays:
- Number of profiles created
- Number of posts created
- List of test users and their IDs
- Instructions for using test users in RLS testing

### ✏️ Customizing Seed Data

To add your own test data:

1. Edit `supabase/seed.sql`
2. Add INSERT statements for your tables
3. Use `ON CONFLICT DO NOTHING` to make the script idempotent
4. Reset the database to load your changes: `npm run db:reset`

**Example:**

```sql
-- Add custom test data
INSERT INTO public.my_table (id, name, description)
VALUES
    (uuid_generate_v4(), 'Test Item 1', 'Description here'),
    (uuid_generate_v4(), 'Test Item 2', 'Another description')
ON CONFLICT DO NOTHING;
```

### 🎯 Best Practices

1. **Keep seed data minimal** - Only include data needed for testing
2. **Use fixed UUIDs for test users** - Makes RLS testing easier
3. **Include diverse scenarios** - Published/unpublished content, different user roles
4. **Make it idempotent** - Use `ON CONFLICT DO NOTHING` to allow re-running
5. **Add verification** - Include counts and summaries at the end
6. **Document test credentials** - Make it easy for developers to test

### 🔗 Related Documentation

- **Migrations**: See `migrations/README.md` for database schema changes
- **RLS Testing**: See `tests/README.md` and `docs/RLS_TESTING.md` for security testing
- **RLS Policies**: See `docs/RLS_POLICIES.md` for policy patterns and best practices
- **Trigger Functions**: The `handle_new_user()` trigger is defined in `migrations/20251005052938_initial_schema.sql`
- **Config**: See `config.toml` for Supabase project configuration
- **Types**: Run `npm run types:generate` to update TypeScript types after schema changes

---

## 🗄️ Migrations

Database migrations are stored in the `migrations/` directory. Each migration is a timestamped SQL file.

### Creating a New Migration

```bash
# Create a new migration file
npm run migration:new my_migration_name

# Edit the generated file in migrations/
# Then apply it
npm run db:reset
```

See `migrations/README.md` for detailed migration guidelines and best practices.

---

## ⚡ Edge Functions

Edge Functions are serverless functions that run on Deno. They are stored in the `functions/` directory.

### Working with Edge Functions

```bash
# Create a new function
npm run functions:new my-function

# Serve functions locally
npm run functions:serve

# Test functions
npm run test:functions

# Deploy to production
npm run functions:deploy my-function
```

See `functions/README.md` for detailed function development guidelines.

---

## 🔧 Configuration (`config.toml`)

The `config.toml` file contains all Supabase project configuration including:

- Database settings (ports, versions, pooling)
- API configuration (schemas, row limits)
- Auth settings (providers, rate limits)
- Storage configuration
- Realtime settings
- Edge Runtime configuration
- **Seed data paths** (see `[db.seed]` section)

For detailed configuration options, see the [official Supabase config documentation](https://supabase.com/docs/guides/local-development/cli/config).

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase CLI Reference](https://supabase.com/docs/guides/cli)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- Project Documentation in `docs/` directory
