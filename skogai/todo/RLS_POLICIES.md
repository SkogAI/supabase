# Row Level Security (RLS) Policies

Complete guide to RLS policies in this Supabase project.

## Table of Contents

- [Overview](#overview)
- [Policy Patterns](#policy-patterns)
- [Role-Based Access](#role-based-access)
- [Common Policy Examples](#common-policy-examples)
- [Security Best Practices](#security-best-practices)
- [Testing RLS Policies](#testing-rls-policies)

---

## Overview

Row Level Security (RLS) is a PostgreSQL feature that allows you to control which rows users can access in a database table. In Supabase, RLS is the primary security mechanism for protecting your data.

### Why RLS?

- **Security by Default**: Users can only access data they're allowed to see
- **Fine-Grained Control**: Different policies for SELECT, INSERT, UPDATE, DELETE
- **Role-Based**: Different rules for service role, authenticated, and anonymous users
- **Database-Level Enforcement**: Security enforced at the database, not just the application layer

### Current RLS Implementation

All tables in the `public` schema have RLS enabled:

| Table | RLS Enabled | Policies |
|-------|-------------|----------|
| `profiles` | ✅ Yes | Service role, authenticated, anonymous |
| `posts` | ✅ Yes | Service role, authenticated, anonymous |

---

## Policy Patterns

### Pattern 1: Public Read, Authenticated Write

**Use Case**: Content that anyone can view, but only authenticated users can create/modify their own.

```sql
-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Anyone can view published posts
CREATE POLICY "Public posts are viewable"
    ON posts FOR SELECT
    USING (published = true);

-- Authenticated users can create their own posts
CREATE POLICY "Users can create posts"
    ON posts FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can only update their own posts
CREATE POLICY "Users can update own posts"
    ON posts FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

### Pattern 2: User-Owned Resources

**Use Case**: Users can only see and modify their own data.

```sql
-- Users can only see their own profiles
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
```

### Pattern 3: Service Role Bypass

**Use Case**: Admin operations that need to bypass RLS.

```sql
-- Service role has full access
CREATE POLICY "Service role full access"
    ON posts FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
```

### Pattern 4: Anonymous Read Access

**Use Case**: Allow unauthenticated users to view public content.

```sql
-- Anonymous users can view published content
CREATE POLICY "Anonymous users can view published posts"
    ON posts FOR SELECT
    TO anon
    USING (published = true);
```

### Pattern 5: Conditional Access

**Use Case**: Access based on relationships or specific conditions.

```sql
-- Users can view posts from people they follow
CREATE POLICY "Users can view followed posts"
    ON posts FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM follows
            WHERE follows.follower_id = auth.uid()
            AND follows.following_id = posts.user_id
        )
        OR posts.user_id = auth.uid()
    );
```

---

## Role-Based Access

### Supabase Roles

Supabase uses three main roles:

1. **`service_role`** (Admin)
   - Has full access to all data
   - Bypasses RLS
   - Used for admin operations, cron jobs, server-side functions
   - ⚠️ **Never expose service_role key to clients!**

2. **`authenticated`** (Logged-in Users)
   - Users who have signed in
   - Subject to RLS policies
   - Can access data based on their user ID (`auth.uid()`)

3. **`anon`** (Anonymous Users)
   - Unauthenticated users
   - Most restrictive access
   - Typically read-only for public content

### Checking Current User

Use `auth.uid()` to get the current user's ID:

```sql
-- Check if current user owns a resource
auth.uid() = user_id

-- Check if user is authenticated
auth.uid() IS NOT NULL

-- Get user metadata
auth.jwt() -> 'user_metadata' ->> 'role'
```

---

## Common Policy Examples

### Allow Users to View All Profiles

```sql
CREATE POLICY "Anyone can view profiles"
    ON profiles FOR SELECT
    USING (true);
```

### Allow Users to Update Only Their Own Profile

```sql
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
```

### Allow Users to See Published Posts + Own Drafts

```sql
CREATE POLICY "Users see published and own posts"
    ON posts FOR SELECT
    TO authenticated
    USING (published = true OR auth.uid() = user_id);
```

### Prevent Users from Changing User ID on Update

```sql
CREATE POLICY "Users cannot change post ownership"
    ON posts FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id AND user_id = (SELECT user_id FROM posts WHERE id = posts.id));
```

### Time-Based Access

```sql
CREATE POLICY "Users can edit within 1 hour"
    ON posts FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = user_id
        AND created_at > NOW() - INTERVAL '1 hour'
    );
```

---

## Security Best Practices

### ✅ DO

1. **Always enable RLS on public tables**
   ```sql
   ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;
   ```

2. **Use role-specific policies**
   ```sql
   -- Better: Explicit role
   CREATE POLICY "policy_name" ON table FOR SELECT TO authenticated USING (...);
   
   -- Avoid: Implicit all roles
   CREATE POLICY "policy_name" ON table FOR SELECT USING (...);
   ```

3. **Use `USING` for read access and `WITH CHECK` for write access**
   ```sql
   CREATE POLICY "policy" ON table FOR UPDATE
       USING (can_read_condition)      -- Check if user can see existing row
       WITH CHECK (can_write_condition); -- Check if new values are allowed
   ```

4. **Test policies with different roles**
   ```sql
   -- Test as specific user
   SELECT set_config('request.jwt.claim.sub', 'user-uuid', true);
   
   -- Test as anonymous
   SET ROLE anon;
   
   -- Reset to service role
   RESET ROLE;
   ```

5. **Document your policies**
   ```sql
   COMMENT ON POLICY "policy_name" ON table IS 
       'Allows authenticated users to view their own posts';
   ```

### ❌ DON'T

1. **Don't disable RLS on public tables**
   ```sql
   -- ⚠️ DANGEROUS!
   ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
   ```

2. **Don't expose service_role key**
   - Never commit service_role key to git
   - Never send to client-side code
   - Use environment variables

3. **Don't use overly permissive policies**
   ```sql
   -- ⚠️ Too permissive!
   CREATE POLICY "allow_all" ON table USING (true);
   ```

4. **Don't forget `WITH CHECK` on INSERT/UPDATE**
   ```sql
   -- ⚠️ Incomplete! Missing WITH CHECK
   CREATE POLICY "policy" ON table FOR UPDATE USING (auth.uid() = user_id);
   
   -- ✅ Complete
   CREATE POLICY "policy" ON table FOR UPDATE
       USING (auth.uid() = user_id)
       WITH CHECK (auth.uid() = user_id);
   ```

5. **Don't rely solely on client-side checks**
   - Always enforce security at the database level
   - Client-side checks are for UX only

---

## Testing RLS Policies

See [RLS_TESTING.md](./RLS_TESTING.md) for comprehensive testing guide.

### Quick Test

```sql
-- Test as authenticated user
SELECT set_config('request.jwt.claim.sub', 'test-user-uuid', true);
SELECT * FROM profiles; -- Should only see accessible profiles

-- Test as anonymous
SET ROLE anon;
SELECT * FROM posts; -- Should only see published posts

-- Reset
RESET ROLE;
```

### Verify RLS is Enabled

```sql
-- Check which tables have RLS enabled
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

### View All Policies

```sql
-- See all policies for a table
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

---

## Policy Naming Convention

Use descriptive names that explain what the policy does:

**Format**: `[Role] [Action] [Condition]`

Examples:
- ✅ `"Authenticated users can view own posts"`
- ✅ `"Service role can manage all profiles"`
- ✅ `"Anonymous users can view published posts"`
- ❌ `"policy_1"`
- ❌ `"select_policy"`

---

## Troubleshooting

### Policy Not Working?

1. **Check if RLS is enabled**
   ```sql
   SELECT rowsecurity FROM pg_tables WHERE tablename = 'your_table';
   ```

2. **Check policy order**
   - Policies are OR'd together
   - If any policy allows access, the action is permitted

3. **Test with explicit role**
   ```sql
   SET ROLE anon;
   -- Your query here
   RESET ROLE;
   ```

4. **Check for conflicting policies**
   ```sql
   -- List all policies for a table
   \d+ your_table
   ```

### Common Issues

**Issue**: "Row level security is enabled but no policy exists"
- **Solution**: Create at least one policy for each operation you want to allow

**Issue**: "Permission denied for table"
- **Solution**: Check if RLS is enabled and policies exist for the current role

**Issue**: "Infinite recursion in RLS policy"
- **Solution**: Avoid circular references in policy conditions

---

## Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Supabase Auth Helpers](https://supabase.com/docs/guides/auth/auth-helpers)

---

## Migration History

| Migration | Date | Description |
|-----------|------|-------------|
| `20251005065505_initial_schema.sql` | 2025-10-05 | Initial RLS policies for profiles and posts |
| `20251005053101_enhanced_rls_policies.sql` | 2025-10-05 | Enhanced role-specific policies, service role, anonymous access |

---

**Last Updated**: 2025-10-05
**Version**: 1.0.0
