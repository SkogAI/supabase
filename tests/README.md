# Database Test Suites

Automated tests for database security, RLS policies, and AI agent authentication.

## Overview

This directory contains SQL test scripts to validate database functionality:

### RLS Policy Test Suite (`rls_test_suite.sql`)
- RLS is enabled on all public tables
- Service role has full access
- Authenticated users can only access/modify their own data
- Anonymous users have read-only access to published content
- No accidental data exposure occurs

### AI Agent Authentication Test Suite (`ai_agent_authentication_test.sql`)
- AI agent roles are created correctly
- Audit logging infrastructure is functional
- RLS policies protect audit tables
- API key generation and validation works
- Authentication and query logging is operational

## Running Tests

### Option 1: Using Supabase CLI

```bash
# Start Supabase (if not already running)
npm run db:start

# Reset database with migrations and seed data
npm run db:reset

# Run the RLS test suite
npm run test:rls
# or: supabase db execute --file tests/rls_test_suite.sql

# Run the AI Agent Authentication test suite
supabase db execute --file tests/ai_agent_authentication_test.sql

# Run all tests
supabase db execute --file tests/rls_test_suite.sql
supabase db execute --file tests/ai_agent_authentication_test.sql
```

### Option 2: Using Supabase Studio

1. Start Supabase: `npm run db:start`
2. Open Supabase Studio: http://localhost:8000
3. Navigate to **SQL Editor**
4. Open `tests/rls_test_suite.sql` or `tests/ai_agent_authentication_test.sql`
5. Copy and paste the entire file
6. Click **Run** to execute all tests

### Option 3: Using psql

```bash
# Connect to local database
psql postgresql://postgres:postgres@localhost:54322/postgres

# Run RLS tests
\i tests/rls_test_suite.sql

# Run AI Agent Authentication tests
\i tests/ai_agent_authentication_test.sql
```

## Test Coverage

### RLS Test Suite

The test suite includes:

1. **RLS Status Check** - Verifies RLS is enabled on all tables
2. **Policy Inventory** - Lists all policies by table
3. **Service Role Tests** - Verifies admin access
4. **Authenticated User Tests** - Tests logged-in user permissions
5. **Anonymous User Tests** - Tests unauthenticated access
6. **Write Operation Tests** - Verifies anonymous users cannot modify data
7. **Cross-User Access** - Ensures users can't access other users' private data
8. **Service Role Bypass** - Confirms admins can perform any operation

## Expected Output

When all tests pass, you'll see output like:

```
================================================================================
RLS POLICY TEST SUITE
================================================================================

TEST 1: Verifying RLS is enabled on all public tables...
NOTICE:  PASS: All public tables have RLS enabled

TEST 2: Listing all RLS policies...
 tablename | policy_count
-----------+--------------
 posts     |            8
 profiles  |            7

TEST 3: Testing service role access...
NOTICE:  PASS: Service role can view all profiles (3 found)
NOTICE:  PASS: Service role can view all posts (7 found)

TEST 4: Testing authenticated user access (Alice)...
NOTICE:  PASS: Authenticated user can view all profiles (3 found)
NOTICE:  PASS: Authenticated user can view posts (7 found)
NOTICE:  PASS: Authenticated user can view own drafts (1 found)
NOTICE:  PASS: Authenticated user can update own profile
NOTICE:  PASS: Authenticated user cannot update other profiles

TEST 5: Testing anonymous user access...
NOTICE:  PASS: Anonymous user can view all profiles (3 found)
NOTICE:  PASS: Anonymous user can only view published posts (6 found)

TEST 6: Testing anonymous user cannot modify data...
NOTICE:  PASS: Anonymous user cannot insert posts
NOTICE:  PASS: Anonymous user cannot update posts
NOTICE:  PASS: Anonymous user cannot delete posts

TEST 7: Testing cross-user access restrictions...
NOTICE:  PASS: User cannot see other users' drafts

TEST 8: Testing service role can bypass all restrictions...
NOTICE:  PASS: Service role can update any post

================================================================================
TEST SUITE COMPLETE
================================================================================
All tests passed! RLS policies are working correctly.

Summary:
  ✅ RLS enabled on all public tables
  ✅ Service role has full access
  ✅ Authenticated users can view all public data
  ✅ Authenticated users can only modify own data
  ✅ Anonymous users have read-only access to published content
  ✅ Anonymous users cannot modify any data
  ✅ Cross-user access is properly restricted

================================================================================
```

## Troubleshooting

### Test Failures

If tests fail:

1. **Check database state**: Ensure you've run `npm run db:reset` to apply migrations and seed data
2. **Check migration order**: Migrations must be applied in order
3. **Check seed data**: The test suite expects specific test users (Alice, Bob, Charlie)
4. **Check Supabase version**: Ensure you're using a recent version of Supabase CLI

### Common Issues

**"Table or view not found"**
- Solution: Run `npm run db:reset` to create tables

**"Test user not found"**
- Solution: Verify seed data was loaded (`supabase/seed.sql`)

**"Permission denied"**
- Solution: Check if RLS is enabled: `SELECT rowsecurity FROM pg_tables WHERE tablename = 'your_table'`

## CI/CD Integration

These tests can be integrated into your CI/CD pipeline:

```yaml
# In .github/workflows/migrations-validation.yml
- name: Run RLS tests
  run: |
    supabase start
    supabase db reset
    supabase db execute --file tests/rls_test_suite.sql
```

## Writing Custom Tests

To add new tests:

1. Follow the existing test structure
2. Use DO blocks with proper error handling
3. Test both positive (should work) and negative (should fail) cases
4. Always clean up after tests (revert changes)
5. Document expected behavior

Example:

```sql
-- Test: New feature
DO $$
BEGIN
    -- Your test logic here
    IF condition THEN
        RAISE NOTICE 'PASS: Test description';
    ELSE
        RAISE EXCEPTION 'FAIL: Test description';
    END IF;
END $$;
```

## Documentation

For more information about RLS policies and testing:

- [RLS Policy Documentation](../docs/RLS_POLICIES.md)
- [RLS Testing Guidelines](../docs/RLS_TESTING.md)
- [Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)

---

**Last Updated**: 2025-10-05
**Version**: 1.0.0
