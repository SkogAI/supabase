# Database Schema Organization

This document describes the database schema organization, custom types, and best practices for the Supabase project.

## 📋 Table of Contents

- [Schema Overview](#schema-overview)
- [Custom Types](#custom-types)
- [Schema Permissions](#schema-permissions)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Migration Strategy](#migration-strategy)

## 📊 Schema Overview

### Core Schemas (Managed by Supabase)

These schemas are automatically created and managed by Supabase:

| Schema | Purpose | API Exposed |
|--------|---------|-------------|
| `public` | Application tables and data | ✅ Yes (default) |
| `auth` | Authentication and user management | ❌ No (internal) |
| `storage` | File storage metadata | ❌ No (internal) |
| `realtime` | Real-time subscriptions | ❌ No (internal) |
| `graphql_public` | GraphQL API endpoint | ✅ Yes (if enabled) |
| `extensions` | PostgreSQL extensions | ❌ No (internal) |

### Application Schemas

Currently, the application uses the `public` schema for all application tables:

- **`public.profiles`** - User profile information
- **`public.posts`** - User-generated content

### Schema Configuration

The schemas exposed via the API are configured in `supabase/config.toml`:

```toml
[api]
schemas = ["public", "graphql_public"]
extra_search_path = ["public", "extensions"]
```

## 🎨 Custom Types

Custom PostgreSQL types provide type safety and better data modeling. This project includes several pre-defined types.

### Enum Types

#### `public.user_role`

Defines authorization roles for users:

```sql
CREATE TYPE public.user_role AS ENUM (
    'user',          -- Regular user
    'moderator',     -- Content moderator
    'admin'          -- Administrator
);
```

**Usage Example:**
```sql
ALTER TABLE public.profiles 
ADD COLUMN role public.user_role DEFAULT 'user' NOT NULL;
```

#### `public.post_status`

Tracks content lifecycle:

```sql
CREATE TYPE public.post_status AS ENUM (
    'draft',         -- Initial state
    'review',        -- Under review
    'published',     -- Published
    'archived'       -- Archived
);
```

**Usage Example:**
```sql
ALTER TABLE public.posts 
ADD COLUMN status public.post_status DEFAULT 'draft' NOT NULL;
```

#### `public.priority_level`

Priority levels for tasks or tickets:

```sql
CREATE TYPE public.priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);
```

### Composite Types

#### `public.address_info`

Structured address data:

```sql
CREATE TYPE public.address_info AS (
    street_line1 TEXT,
    street_line2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT
);
```

**Usage Example:**
```sql
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address public.address_info,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Inserting data
INSERT INTO public.organizations (name, address) VALUES (
    'Acme Corp',
    ROW('123 Main St', 'Suite 100', 'San Francisco', 'CA', '94102', 'USA')::public.address_info
);

-- Querying composite fields
SELECT name, (address).city, (address).country 
FROM public.organizations;
```

#### `public.contact_details`

Contact information structure:

```sql
CREATE TYPE public.contact_details AS (
    email TEXT,
    phone TEXT,
    preferred_method TEXT
);
```

#### `public.geo_location`

Geographic coordinates:

```sql
CREATE TYPE public.geo_location AS (
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    accuracy_meters NUMERIC(10, 2)
);
```

## 🔒 Schema Permissions

### Default Permissions

Custom types have the following permissions configured:

- **`authenticated`** role - Can use all custom types
- **`service_role`** role - Can use all custom types (for server-side operations)
- **`anon`** role - No access by default (add if needed)

### Granting Permissions

When creating new types, grant appropriate permissions:

```sql
-- Grant to authenticated users
GRANT USAGE ON TYPE public.my_custom_type TO authenticated;

-- Grant to service role
GRANT USAGE ON TYPE public.my_custom_type TO service_role;

-- Grant to anonymous users (if needed)
GRANT USAGE ON TYPE public.my_custom_type TO anon;
```

### Table-Level Permissions

Remember to also configure Row Level Security (RLS) policies on tables that use custom types:

```sql
ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own data"
    ON public.my_table
    FOR SELECT
    USING (auth.uid() = user_id);
```

## 💡 Usage Examples

### Example 1: User Roles with Enum

```sql
-- Add role column to profiles
ALTER TABLE public.profiles 
ADD COLUMN role public.user_role DEFAULT 'user' NOT NULL;

-- Create RLS policy based on role
CREATE POLICY "Admins can view all profiles"
    ON public.profiles
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT id FROM public.profiles WHERE role = 'admin'
        )
    );
```

### Example 2: Post Status Workflow

```sql
-- Add status to posts
ALTER TABLE public.posts 
ADD COLUMN status public.post_status DEFAULT 'draft' NOT NULL;

-- Only show published posts publicly
CREATE POLICY "Public can view published posts"
    ON public.posts
    FOR SELECT
    USING (status = 'published');
```

### Example 3: Organizations with Address

```sql
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address public.address_info,
    contact public.contact_details,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Trigger for updated_at
CREATE TRIGGER organizations_updated_at
    BEFORE UPDATE ON public.organizations
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
```

### Example 4: Array of Enums

```sql
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    priority public.priority_level DEFAULT 'medium',
    assigned_roles public.user_role[] DEFAULT ARRAY['user']::public.user_role[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Query tasks by priority
SELECT * FROM public.tasks WHERE priority = 'high';

-- Query tasks by role
SELECT * FROM public.tasks WHERE 'admin' = ANY(assigned_roles);
```

## 📚 Best Practices

### 1. Naming Conventions

- **Schemas**: Use lowercase, descriptive names (e.g., `public`, `analytics`)
- **Types**: Use snake_case with descriptive names (e.g., `user_role`, `post_status`)
- **Enum values**: Use lowercase, descriptive strings (e.g., `'draft'`, `'published'`)

### 2. Type Organization

- Keep related types in the same migration
- Document each type with `COMMENT ON TYPE`
- Group types by domain (e.g., user types, content types)

### 3. Enum Design

- Keep enum values stable (avoid renaming)
- Add new values at the end when possible
- Consider using a lookup table for frequently changing values

### 4. Composite Type Usage

- Use for complex, reusable data structures
- Prefer composite types over JSON when structure is known
- Access fields with `(column).field` syntax in queries

### 5. Migration Safety

```sql
-- ✅ Good: Adding new enum value (safe)
ALTER TYPE public.user_role ADD VALUE 'super_admin';

-- ❌ Bad: Renaming enum values (breaks existing data)
-- Instead, create a new type and migrate data

-- ✅ Example: Safely renaming enum values by migrating to a new type
-- Step 1: Create the new enum type with desired values
CREATE TYPE public.user_role_new AS ENUM ('user', 'admin', 'superadmin');

-- Step 2: Alter affected tables to use the new type
ALTER TABLE public.users
  ALTER COLUMN role TYPE public.user_role_new
  USING CASE
    WHEN role = 'super_admin' THEN 'superadmin'::public.user_role_new
    ELSE role::public.user_role_new
  END;

-- Step 3: Drop the old enum type (after verifying migration)
DROP TYPE public.user_role;
-- ✅ Good: Adding fields to composite types
ALTER TYPE public.address_info ADD ATTRIBUTE apartment TEXT;

-- ⚠️  Note: Dropping fields requires recreating the type
```

### 6. TypeScript Integration

After adding or modifying types, regenerate TypeScript definitions:

```bash
npm run types:generate
```

This will create type-safe TypeScript interfaces for your database schema.

## 🔄 Migration Strategy

### Creating Types Migration

1. **Create a new migration:**
   ```bash
   npm run migration:new add_custom_types
   ```

2. **Add type definitions:**
   ```sql
   CREATE TYPE public.my_type AS ENUM ('value1', 'value2');
   GRANT USAGE ON TYPE public.my_type TO authenticated;
   COMMENT ON TYPE public.my_type IS 'Description of the type';
   ```

3. **Test locally:**
   ```bash
   npm run db:reset
   ```

### Modifying Existing Types

#### Adding Enum Values

```sql
-- Safe operation: adds new value
ALTER TYPE public.user_role ADD VALUE 'contributor';
```

#### Modifying Composite Types

```sql
-- Add attribute (safe)
ALTER TYPE public.address_info ADD ATTRIBUTE region TEXT;

-- Drop attribute (requires recreation)
-- 1. Create new type
CREATE TYPE public.address_info_v2 AS (
    street_line1 TEXT,
    city TEXT,
    country TEXT
);

-- 2. Migrate data in a new migration
-- 3. Drop old type and rename new one
```

### Schema Evolution

1. **Version Control**: Keep all schema changes in migrations
2. **Documentation**: Update this file when adding new types
3. **Type Generation**: Run `npm run types:generate` after schema changes
4. **Testing**: Test migrations locally before deploying

## 🔗 References

- [PostgreSQL CREATE TYPE Documentation](https://www.postgresql.org/docs/current/sql-createtype.html)
- [Supabase Schema Configuration](https://supabase.com/docs/guides/database/schemas)
- [PostgreSQL Enum Types](https://www.postgresql.org/docs/current/datatype-enum.html)
- [PostgreSQL Composite Types](https://www.postgresql.org/docs/current/rowtypes.html)

## 📝 Additional Notes

### API Exposure

Only tables in schemas listed in `config.toml` `[api].schemas` are exposed via the API:

```toml
[api]
schemas = ["public", "graphql_public"]
```

To expose a new schema:
1. Update `config.toml`
2. Restart Supabase: `npm run db:stop && npm run db:start`

### Search Path

The `extra_search_path` setting determines which schemas are automatically searched:

```toml
[api]
extra_search_path = ["public", "extensions"]
```

This allows referencing tables without schema qualification in most cases.

### Custom Schemas (Advanced)

To create custom schemas for organization:

```sql
-- Create schema
CREATE SCHEMA analytics;

-- Grant access
GRANT USAGE ON SCHEMA analytics TO authenticated;

-- Create table in schema
CREATE TABLE analytics.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Expose in API (update config.toml)
-- schemas = ["public", "graphql_public", "analytics"]
```

## 🎯 Next Steps

1. Review the custom types in `supabase/migrations/20251005052939_schemas_and_types.sql`
2. Uncomment and adapt example usage as needed for your application
3. Create new migrations to apply types to existing tables
4. Update TypeScript types: `npm run types:generate`
5. Document any application-specific types in this file
