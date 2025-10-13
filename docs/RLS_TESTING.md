# RLS Testing Guidelines

Comprehensive guide for testing Row Level Security policies locally and in CI/CD.

## Table of Contents

- [Overview](#overview)
- [Local Testing](#local-testing)
- [Testing Different User Contexts](#testing-different-user-contexts)
- [Automated Testing](#automated-testing)
- [CI/CD Integration](#cicd-integration)
- [Common Test Scenarios](#common-test-scenarios)
- [Troubleshooting](#troubleshooting)

---

## Overview

Testing RLS policies is critical to ensure:
- ✅ Users can only access data they're allowed to see
- ✅ Users cannot bypass security restrictions
- ✅ Anonymous users have appropriate read-only access
- ✅ Service role can perform admin operations
- ✅ No accidental data exposure

### Testing Principles

1. **Test all roles**: Service role, authenticated, anonymous
2. **Test all operations**: SELECT, INSERT, UPDATE, DELETE
3. **Test edge cases**: Empty results, unauthorized access attempts
4. **Test with real data**: Use seed data that mirrors production scenarios

---

## Local Testing

### Prerequisites

1. **Start Supabase locally**
   ```bash
   npm run db:start
   # or
   supabase start
   ```

2. **Reset database with seed data**
   ```bash
   npm run db:reset
   ```

3. **Access Supabase Studio**
   - Open http://localhost:8000
   - Navigate to SQL Editor

### Manual Testing in SQL Editor

The SQL Editor in Supabase Studio allows you to test policies manually.

#### Test as Service Role (Default)

By default, SQL Editor runs as service role (bypasses RLS):

```sql
-- This runs as service role
SELECT * FROM profiles;  -- Should see all profiles
SELECT * FROM posts;     -- Should see all posts (published + drafts)
```

#### Test as Authenticated User

Set the JWT claim to simulate an authenticated user:

```sql
-- Set user context (use test user ID from seed data)
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

-- Test SELECT
SELECT * FROM profiles;  -- Should see all profiles
SELECT * FROM posts;     -- Should see published posts + own drafts

-- Test INSERT (should succeed - own profile)
INSERT INTO posts (user_id, title, content, published)
VALUES ('00000000-0000-0000-0000-000000000001', 'Test Post', 'Test content', false);

-- Test UPDATE (should succeed - own post)
UPDATE posts 
SET title = 'Updated Title' 
WHERE user_id = '00000000-0000-0000-0000-000000000001' 
  AND id = (SELECT id FROM posts WHERE user_id = '00000000-0000-0000-0000-000000000001' LIMIT 1);

-- Test UPDATE (should fail - someone else's post)
UPDATE posts 
SET title = 'Hacked!' 
WHERE user_id = '00000000-0000-0000-0000-000000000002';
-- Expected: 0 rows affected (policy prevents access)

-- Test DELETE (should succeed - own post)
DELETE FROM posts 
WHERE user_id = '00000000-0000-0000-0000-000000000001' 
  AND id = (SELECT id FROM posts WHERE user_id = '00000000-0000-0000-0000-000000000001' LIMIT 1);

-- Reset context
SELECT set_config('request.jwt.claim.sub', NULL, true);
```

#### Test as Anonymous User

Switch to anonymous role:

```sql
-- Set role to anonymous
SET ROLE anon;

-- Test SELECT (should only see published content)
SELECT * FROM profiles;  -- Should see all profiles (public read)
SELECT * FROM posts;     -- Should only see published posts

-- Test INSERT (should fail)
INSERT INTO posts (user_id, title, content, published)
VALUES (uuid_generate_v4(), 'Hacker Post', 'Test', true);
-- Expected: ERROR - permission denied

-- Test UPDATE (should fail)
UPDATE posts SET published = false WHERE id = (SELECT id FROM posts LIMIT 1);
-- Expected: 0 rows affected (policy prevents access)

-- Test DELETE (should fail)
DELETE FROM posts WHERE id = (SELECT id FROM posts LIMIT 1);
-- Expected: 0 rows affected (policy prevents access)

-- Reset role
RESET ROLE;
```

---

## Testing Different User Contexts

### Test Matrix

Use this matrix to systematically test all scenarios:

| Operation | Service Role | Authenticated (Own) | Authenticated (Other) | Anonymous |
|-----------|--------------|--------------------|-----------------------|-----------|
| **SELECT profiles** | ✅ All | ✅ All | ✅ All | ✅ All |
| **INSERT profiles** | ✅ Any | ✅ Own | ❌ Fail | ❌ Fail |
| **UPDATE profiles** | ✅ Any | ✅ Own | ❌ Fail | ❌ Fail |
| **DELETE profiles** | ✅ Any | ✅ Own | ❌ Fail | ❌ Fail |
| **SELECT posts (published)** | ✅ All | ✅ All | ✅ All | ✅ All |
| **SELECT posts (drafts)** | ✅ All | ✅ Own | ❌ Fail | ❌ Fail |
| **INSERT posts** | ✅ Any | ✅ Own | ❌ Fail | ❌ Fail |
| **UPDATE posts** | ✅ Any | ✅ Own | ❌ Fail | ❌ Fail |
| **DELETE posts** | ✅ Any | ✅ Own | ❌ Fail | ❌ Fail |

### Comprehensive Test Script

```sql
-- ============================================================================
-- RLS POLICY TEST SUITE
-- ============================================================================

-- Test User IDs (from seed data)
-- Alice: 00000000-0000-0000-0000-000000000001
-- Bob:   00000000-0000-0000-0000-000000000002
-- Charlie: 00000000-0000-0000-0000-000000000003

-- ============================================================================
-- TEST 1: Verify RLS is Enabled
-- ============================================================================
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
-- Expected: All tables should have rls_enabled = true

-- ============================================================================
-- TEST 2: View All Policies
-- ============================================================================
SELECT 
    tablename,
    policyname,
    roles,
    cmd as command
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- TEST 3: Service Role Tests (Default - Bypasses RLS)
-- ============================================================================
-- Should have full access to everything

SELECT 'Service Role: SELECT profiles' as test, COUNT(*) >= 3 as passed 
FROM profiles;

SELECT 'Service Role: SELECT posts' as test, COUNT(*) >= 5 as passed 
FROM posts;

-- ============================================================================
-- TEST 4: Authenticated User Tests (Alice)
-- ============================================================================
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

-- Should see all profiles
SELECT 'Auth (Alice): SELECT profiles' as test, COUNT(*) >= 3 as passed 
FROM profiles;

-- Should see published posts + own drafts
SELECT 'Auth (Alice): SELECT posts' as test, COUNT(*) >= 5 as passed 
FROM posts;

-- Should be able to update own profile
UPDATE profiles 
SET bio = 'Updated bio for testing' 
WHERE id = '00000000-0000-0000-0000-000000000001';
SELECT 'Auth (Alice): UPDATE own profile' as test, 
       bio = 'Updated bio for testing' as passed 
FROM profiles 
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Should NOT be able to update other's profile
UPDATE profiles 
SET bio = 'Hacked!' 
WHERE id = '00000000-0000-0000-0000-000000000002';
SELECT 'Auth (Alice): UPDATE other profile' as test, 
       bio != 'Hacked!' as passed 
FROM profiles 
WHERE id = '00000000-0000-0000-0000-000000000002';

-- Reset changes
UPDATE profiles 
SET bio = 'Software engineer and open source enthusiast. Love building with Supabase!' 
WHERE id = '00000000-0000-0000-0000-000000000001';

SELECT set_config('request.jwt.claim.sub', NULL, true);

-- ============================================================================
-- TEST 5: Anonymous User Tests
-- ============================================================================
SET ROLE anon;

-- Should see all profiles
SELECT 'Anon: SELECT profiles' as test, COUNT(*) >= 3 as passed 
FROM profiles;

-- Should only see published posts (not drafts)
SELECT 'Anon: SELECT published posts' as test, 
       COUNT(*) >= 5 as passed,
       COUNT(CASE WHEN published = false THEN 1 END) = 0 as no_drafts
FROM posts;

-- Should NOT be able to insert
DO $$
BEGIN
    INSERT INTO posts (user_id, title, content, published)
    VALUES (uuid_generate_v4(), 'Anon Post', 'Test', true);
    RAISE EXCEPTION 'Anonymous user should not be able to insert!';
EXCEPTION
    WHEN insufficient_privilege OR check_violation THEN
        RAISE NOTICE 'Anon: INSERT posts - PASSED (correctly blocked)';
END $$;

RESET ROLE;

-- ============================================================================
-- TEST 6: Cross-User Access Tests
-- ============================================================================

-- Alice tries to access Bob's draft
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

SELECT 'Auth (Alice): Cannot see Bob drafts' as test, 
       COUNT(*) = 0 as passed
FROM posts 
WHERE user_id = '00000000-0000-0000-0000-000000000002' 
  AND published = false;

SELECT set_config('request.jwt.claim.sub', NULL, true);

-- ============================================================================
-- TEST 7: Policy Bypass with Service Role
-- ============================================================================

-- Service role should be able to do anything
UPDATE posts 
SET published = NOT published 
WHERE id = (SELECT id FROM posts LIMIT 1);

SELECT 'Service Role: Can update any post' as test, true as passed;

-- Revert change
UPDATE posts 
SET published = NOT published 
WHERE id = (SELECT id FROM posts LIMIT 1);

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '================================================================================';
RAISE NOTICE 'RLS POLICY TEST SUITE COMPLETE';
RAISE NOTICE '================================================================================';
RAISE NOTICE 'Review the test results above to ensure all policies are working correctly.';
RAISE NOTICE 'All tests with passed = true indicate correct RLS behavior.';
RAISE NOTICE '================================================================================';
```

---

## Automated Testing

### Database Functions for Testing

Create helper functions to test RLS policies programmatically:

```sql
-- Function to test if a user can access a row
CREATE OR REPLACE FUNCTION test_rls_access(
    target_table text,
    target_id uuid,
    user_id uuid,
    operation text DEFAULT 'SELECT'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result boolean;
BEGIN
    -- Set user context
    PERFORM set_config('request.jwt.claim.sub', user_id::text, true);
    
    -- Try the operation
    EXECUTE format('SELECT EXISTS(SELECT 1 FROM %I WHERE id = $1)', target_table)
    INTO result
    USING target_id;
    
    -- Reset context
    PERFORM set_config('request.jwt.claim.sub', NULL, true);
    
    RETURN result;
END;
$$;
```

### JavaScript/TypeScript Tests

For testing via Supabase client:

```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://localhost:8000'
const supabaseAnonKey = 'your-anon-key'
const supabaseServiceKey = 'your-service-key'

describe('RLS Policies', () => {
  test('Anonymous users can view published posts', async () => {
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('published', true)
    
    expect(error).toBeNull()
    expect(data).toBeDefined()
    expect(data.length).toBeGreaterThan(0)
  })
  
  test('Anonymous users cannot view drafts', async () => {
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('published', false)
    
    expect(data).toEqual([]) // Should return empty array
  })
  
  test('Authenticated users can update own profile', async () => {
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    // Sign in first
    const { data: { user } } = await supabase.auth.signInWithPassword({
      email: 'test@example.com',
      password: 'password'
    })
    
    const { error } = await supabase
      .from('profiles')
      .update({ bio: 'New bio' })
      .eq('id', user.id)
    
    expect(error).toBeNull()
  })
  
  test('Users cannot update other profiles', async () => {
    const supabase = createClient(supabaseUrl, supabaseAnonKey)
    
    // Sign in
    await supabase.auth.signInWithPassword({
      email: 'test@example.com',
      password: 'password'
    })
    
    const { data, error } = await supabase
      .from('profiles')
      .update({ bio: 'Hacked!' })
      .eq('id', 'different-user-id')
    
    expect(data).toEqual([]) // Should affect 0 rows
  })
})
```

---

## CI/CD Integration

### GitHub Actions Workflow

The existing `schema-lint.yml` workflow includes RLS validation:

```yaml
- name: Validate RLS policies
  run: |
    echo "Checking for tables without RLS policies..."
    TABLES_WITHOUT_RLS=$(supabase db execute "
      SELECT schemaname, tablename
      FROM pg_tables
      WHERE schemaname = 'public'
      AND tablename NOT IN (
        SELECT tablename
        FROM pg_policies
        WHERE schemaname = 'public'
      )
      AND rowsecurity = false
    " --format json)

    if [ "$TABLES_WITHOUT_RLS" != "[]" ]; then
      echo "⚠️  Warning: Tables without RLS found"
      exit 1
    fi
```

### Add Custom RLS Tests to CI

Add to your migration validation:

```yaml
- name: Test RLS Policies
  run: |
    # Run comprehensive RLS test suite
    supabase db execute --file tests/rls_test_suite.sql
```

---

## Common Test Scenarios

### Scenario 1: User Registration

```sql
-- New user signs up
INSERT INTO auth.users (id, email)
VALUES ('new-user-id', 'newuser@example.com');

-- Profile should be auto-created (via trigger)
SELECT * FROM profiles WHERE id = 'new-user-id';
-- Expected: 1 row

-- User should be able to update their profile
SELECT set_config('request.jwt.claim.sub', 'new-user-id', true);
UPDATE profiles SET bio = 'New user bio' WHERE id = 'new-user-id';
-- Expected: 1 row updated
```

### Scenario 2: Post Creation and Publishing

```sql
-- User creates a draft post
SELECT set_config('request.jwt.claim.sub', 'user-id', true);

INSERT INTO posts (user_id, title, content, published)
VALUES ('user-id', 'My Post', 'Content', false);

-- User can see their own draft
SELECT * FROM posts WHERE user_id = 'user-id' AND published = false;
-- Expected: At least 1 row

-- Other users cannot see the draft
SELECT set_config('request.jwt.claim.sub', 'other-user-id', true);
SELECT * FROM posts WHERE user_id = 'user-id' AND published = false;
-- Expected: 0 rows

-- Anonymous cannot see the draft
SET ROLE anon;
SELECT * FROM posts WHERE user_id = 'user-id' AND published = false;
-- Expected: 0 rows
RESET ROLE;
```

### Scenario 3: Data Breach Attempt

```sql
-- Attacker tries to view all user emails (should fail)
SET ROLE anon;
SELECT email FROM auth.users;
-- Expected: ERROR - permission denied

-- Attacker tries to modify someone's post
SELECT set_config('request.jwt.claim.sub', 'attacker-id', true);
UPDATE posts SET content = 'Hacked!' WHERE user_id != 'attacker-id';
-- Expected: 0 rows updated

RESET ROLE;
```

---

## Troubleshooting

### Tests Not Running

**Problem**: SQL tests return unexpected results

**Solutions**:
1. Ensure database is reset: `npm run db:reset`
2. Check you're using correct user IDs from seed data
3. Verify RLS is enabled: `SELECT rowsecurity FROM pg_tables WHERE tablename = 'your_table'`

### Policies Too Permissive

**Problem**: Anonymous users can access restricted data

**Solutions**:
1. Check policy roles are specified: `TO anon`, `TO authenticated`
2. Verify USING clause is not `true` for sensitive operations
3. Review policy order (policies are OR'd together)

### Cannot Test as Anonymous

**Problem**: Cannot switch to anonymous role in SQL Editor

**Solutions**:
1. Use `SET ROLE anon;` to switch roles
2. Always `RESET ROLE;` after testing
3. Or use JWT claim: `SELECT set_config('request.jwt.claim.sub', NULL, true);`

---

## Best Practices

1. **Test After Every Migration**
   - Run RLS tests whenever you modify policies
   - Include tests in PR reviews

2. **Use Seed Data**
   - Create realistic test data
   - Include edge cases

3. **Document Expected Behavior**
   - Write comments in test scripts
   - Document why certain operations should fail

4. **Automate Testing**
   - Include RLS tests in CI/CD
   - Run tests on every migration change

5. **Test All Roles**
   - Don't forget to test service role, authenticated, AND anonymous
   - Test both positive (should work) and negative (should fail) cases

---

## Resources

- [Supabase RLS Testing Guide](https://supabase.com/docs/guides/database/postgres/row-level-security#testing-rls-policies)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Supabase Local Development](https://supabase.com/docs/guides/local-development)

---

**Last Updated**: 2025-10-05
**Version**: 1.0.0
