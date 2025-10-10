# Quickstart: Testing Basic Supabase Features

This guide helps you verify that the basic Supabase features (user profiles, edge functions, storage, realtime) are working correctly.

## Prerequisites

- Docker Desktop running
- Node.js and npm installed
- Supabase CLI installed (`npm install -g supabase` or see [installation guide](https://supabase.com/docs/guides/cli))

## Quick Setup

1. **Start Supabase locally**:
   ```bash
   npm run db:start
   ```
   
   This starts all Supabase services (database, auth, storage, realtime, edge functions).

2. **Wait for services** to be ready (about 30 seconds)

3. **Verify status**:
   ```bash
   npm run db:status
   ```

## Testing Basic Features

### 1. Test User Profiles (Database + RLS)

**What it tests**: User profiles table, Row Level Security policies, automatic profile creation

```bash
npm run test:rls
```

**Expected output**:
```
PASS: All public tables have RLS enabled
PASS: Service role can view all profiles (3 found)
PASS: Authenticated users can view all profiles
PASS: Alice can update own profile
PASS: Alice cannot update Bob's profile
```

**What's being tested**:
- ✅ RLS is enabled on all tables
- ✅ Service role has full access
- ✅ Authenticated users can view all profiles
- ✅ Users can only update their own profiles
- ✅ Anonymous users have read-only access

### 2. Test Edge Functions

**What it tests**: Edge functions (hello-world, health-check) handle CORS, auth, errors correctly

```bash
npm run test:functions
```

**Expected output**:
```
hello-world: Basic request returns 200 ... ok (100ms)
hello-world: Returns correct message structure ... ok (50ms)
hello-world: CORS headers present ... ok (20ms)
hello-world: Database check works ... ok (150ms)
```

**What's being tested**:
- ✅ Functions return correct responses
- ✅ CORS headers are set properly
- ✅ Authentication detection works
- ✅ Database connectivity is working
- ✅ Error handling is graceful

### 3. Test Storage Buckets

**What it tests**: Storage bucket configuration, RLS policies, file type restrictions

```bash
npm run test:storage-buckets
```

**Expected output**:
```
PASS: avatars bucket exists with correct config
PASS: public-assets bucket exists
PASS: user-files bucket exists
PASS: Storage RLS policies work correctly
```

**What's being tested**:
- ✅ Storage buckets are configured
- ✅ Size limits are set correctly
- ✅ File type restrictions work
- ✅ RLS policies prevent unauthorized access

### 4. Test Realtime Subscriptions

**What it tests**: Realtime events broadcast for profile changes

```bash
npm run test:realtime
```

**What's being tested**:
- ✅ Realtime is enabled on profiles table
- ✅ INSERT/UPDATE/DELETE events are broadcast
- ✅ Subscribers receive events
- ✅ Event payloads contain correct data

### 5. Test Profile-Specific Features

**What it tests**: Profile creation triggers, metadata population, cascading deletes

```bash
npm run test:profiles
```

**What's being tested**:
- ✅ Profile auto-creation on user signup
- ✅ Metadata is populated correctly
- ✅ Updated timestamps work
- ✅ Cascade deletes work properly

## Manual Testing via Supabase Studio

Open Supabase Studio at: **http://localhost:8000**

### Test 1: View Profiles
1. Go to "Table Editor" → "profiles"
2. You should see 3 test users: alice, bob, charlie
3. Click on any profile to see details

### Test 2: Test Edge Function
1. Open terminal and run:
   ```bash
   curl -i http://localhost:54321/functions/v1/hello-world \
     -H "Content-Type: application/json" \
     -d '{"name": "Test User"}'
   ```
2. You should see: `{"message": "Hello, Test User!", "timestamp": "..."}`

### Test 3: Test Authentication
1. Go to "Authentication" → "Users" in Studio
2. You should see 3 test users with confirmed emails
3. Copy a user ID for RLS testing

### Test 4: Test Storage
1. Go to "Storage" in Studio
2. You should see 3 buckets: avatars, public-assets, user-files
3. Try uploading a file to test policies

## What if Tests Fail?

### Database not started
```bash
# Check Docker is running
docker info

# Start Supabase
npm run db:start
```

### Migrations not applied
```bash
# Reset database (reapplies all migrations)
npm run db:reset
```

### Edge functions not working
```bash
# Check function logs
docker logs supabase_functions_hello-world

# Restart functions
npm run functions:serve
```

### Environment issues
```bash
# Check all services are running
npm run db:status

# Should show:
# - Kong (API Gateway): Running
# - PostgreSQL: Running
# - Auth: Running
# - Storage: Running
# - Realtime: Running
# - Edge Functions: Running
```

## Creating Test Issues

To create GitHub issues that track these tests:

```bash
# Run the automated script
./scripts/create-test-issues.sh
```

This creates 5 issues:
1. Profile RLS policy tests
2. Storage bucket tests
3. Realtime functionality tests
4. Edge function tests
5. Integration test suite

See [`docs/CREATING_TEST_ISSUES.md`](docs/CREATING_TEST_ISSUES.md) for details.

## Next Steps

After verifying tests pass:

1. **Review test coverage** in each test file
2. **Add missing tests** for uncovered scenarios
3. **Document any failures** as GitHub issues
4. **Expand tests** for new features you add

## Test Files Reference

- **Database/RLS**: `tests/rls_test_suite.sql`
- **Profiles**: `tests/profiles_test_suite.sql`
- **Storage**: `tests/storage_buckets_test_suite.sql`
- **Edge Functions**: `supabase/functions/*/test.ts`
- **Realtime**: `examples/realtime/`

## Useful Commands Summary

```bash
# Start everything
npm run db:start

# Run all tests
npm run test:rls
npm run test:profiles
npm run test:storage-buckets
npm run test:functions
npm run test:realtime

# View Supabase Studio
open http://localhost:8000

# View API docs
open http://localhost:54321

# Stop everything
npm run db:stop
```

## Need Help?

- Check `CLAUDE.md` for complete command reference
- Review `docs/ARCHITECTURE.md` for system architecture
- See `docs/TROUBLESHOOTING.md` for common issues
- Read `docs/PROPOSED_TEST_ISSUES.md` for detailed test specifications

---

**Summary**: This quickstart proves that user profiles, edge functions, storage, and realtime features are all working correctly in your local Supabase instance. If all tests pass, your basic infrastructure is solid! 🎉
