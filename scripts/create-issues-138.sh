#!/bin/bash
set -e

# Issue Creation Script for Issue #138 Recommendations
# This script creates issues for the proposed changes and tests from issue #138

REPO="SkogAI/supabase"

echo "=========================================="
echo "GitHub Issue Creation Script - Issue #138"
echo "Repository: $REPO"
echo "=========================================="
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub"
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to create an issue
create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    
    echo "Creating issue: $title"
    # Split labels on commas and build --label arguments
    local label_args=()
    IFS=',' read -ra label_array <<< "$labels"
    for label in "${label_array[@]}"; do
        # Trim whitespace from label
        label="$(echo "$label" | xargs)"
        if [[ -n "$label" ]]; then
            label_args+=(--label "$label")
        fi
    done
    gh issue create \
        --repo "$REPO" \
        --title "$title" \
        --body "$body" \
        "${label_args[@]}" || echo "⚠️  Failed to create issue: $title"
    echo ""
}

# Issue 1: Add Storage Buckets to Tracked Migrations
read -r -d '' ISSUE_1_BODY << 'EOF' || true
## Description
The storage buckets (avatars, public-assets, user-files) currently exist only in local dev migrations (`volumes/db/migrations/`) but are NOT in tracked migrations (`supabase/migrations/`). This needs to be fixed for production deployment.

## Background
From issue #138 analysis: Storage buckets are documented in `docs/STORAGE.md` but the migrations are not tracked in version control.

## Tasks
- [ ] Review existing storage setup in `volumes/db/migrations/`
- [ ] Create new migration: `npm run migration:new setup_storage_buckets`
- [ ] Add storage bucket creation SQL:
  - `avatars` bucket (5MB limit, images only, public)
  - `public-assets` bucket (10MB limit, images/PDFs, public)
  - `user-files` bucket (50MB limit, all types, private)
- [ ] Add RLS policies for `storage.objects` table
- [ ] Test bucket creation with `npm run db:reset`
- [ ] Verify buckets appear in Supabase dashboard
- [ ] Document storage usage in README

## Acceptance Criteria
- [ ] Storage buckets created via tracked migration
- [ ] RLS policies prevent unauthorized access
- [ ] File upload/download works as expected
- [ ] Migration tested and working
- [ ] Documentation updated

## Priority
High - Required for production deployment

## References
- Issue #138 comment: https://github.com/SkogAI/supabase/issues/138#issuecomment-3386210007
- `docs/STORAGE.md` for bucket specifications
- Supabase Storage Docs: https://supabase.com/docs/guides/storage

## Related Test Issue
See test issue for storage bucket verification tests.
EOF

# Issue 2: Enable Realtime on Profiles Table
read -r -d '' ISSUE_2_BODY << 'EOF' || true
## Description
Enable Supabase Realtime subscriptions on the `profiles` table to allow real-time updates when user profiles change.

## Background
From issue #138 analysis: Realtime is not configured on profiles table, which would be useful for collaborative features and live user status updates.

## Tasks
- [ ] Create new migration: `npm run migration:new enable_realtime_profiles`
- [ ] Add SQL to enable realtime on profiles:
```sql
-- Enable realtime on profiles table
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER TABLE public.profiles REPLICA IDENTITY FULL;
```
- [ ] Create example client code for subscribing to profile changes
- [ ] Add to `examples/realtime/` directory
- [ ] Test realtime subscription locally
- [ ] Document realtime usage patterns
- [ ] Update README with realtime examples

## Example Usage
```typescript
// Subscribe to profile changes
const subscription = supabase
  .channel('profiles')
  .on('postgres_changes', { 
    event: '*', 
    schema: 'public', 
    table: 'profiles' 
  }, (payload) => {
    console.log('Profile changed:', payload)
  })
  .subscribe()
```

## Acceptance Criteria
- [ ] Realtime enabled on profiles table via migration
- [ ] Subscription example code works
- [ ] Changes to profiles trigger realtime events
- [ ] Documentation includes usage patterns
- [ ] Performance impact assessed and acceptable

## Priority
Medium - Nice to have for real-time features

## References
- Issue #138 comment: https://github.com/SkogAI/supabase/issues/138#issuecomment-3386210007
- Supabase Realtime Docs: https://supabase.com/docs/guides/realtime

## Related Test Issue
See test issue for realtime subscription verification tests.
EOF

# Issue 3: Add Service Role RLS Policy to Profiles
read -r -d '' ISSUE_3_BODY << 'EOF' || true
## Description
Add missing service role RLS policy to profiles table for admin operations and edge functions.

## Background
From issue #138 analysis: The profiles table is missing a service role policy, which can cause issues with admin operations and edge functions that need full access.

## Tasks
- [ ] Create new migration: `npm run migration:new add_service_role_policy_profiles`
- [ ] Add service role policy:
```sql
-- Service role should have full access for admin operations
CREATE POLICY "Service role full access" ON public.profiles
    FOR ALL TO service_role USING (true) WITH CHECK (true);
```
- [ ] Optional: Add delete policy for users:
```sql
-- Optional: Allow users to delete their own profile
CREATE POLICY "Users can delete own profile" ON public.profiles
    FOR DELETE USING (auth.uid() = id);
```
- [ ] Test policy with service role key
- [ ] Verify edge functions can access profiles
- [ ] Run RLS test suite: `npm run test:rls`
- [ ] Document policy purpose and usage

## Acceptance Criteria
- [ ] Service role policy added via migration
- [ ] Service role can perform all operations on profiles
- [ ] Edge functions work correctly with profiles
- [ ] RLS tests pass
- [ ] Policy is documented

## Priority
High - Important for production edge functions

## References
- Issue #138 comment: https://github.com/SkogAI/supabase/issues/138#issuecomment-3386210007
- `docs/RLS_POLICIES.md` for policy patterns

## Related Test Issue
See test issue for RLS policy verification tests.
EOF

# Issue 4: Create User Profile Edge Functions
read -r -d '' ISSUE_4_BODY << 'EOF' || true
## Description
Create production-ready edge functions for user profile management (get, update, upload avatar).

## Background
From issue #138 analysis: While we have good infrastructure functions (hello-world, health-check), we need more user-focused functions for common operations.

## Tasks

### 1. Get Profile Function
- [ ] Create `supabase/functions/get-profile/index.ts`
- [ ] Support query by username or ID
- [ ] Return public profile data
- [ ] Add proper error handling
- [ ] Add CORS headers
- [ ] Write tests in `test.ts`

### 2. Update Profile Function
- [ ] Create `supabase/functions/update-profile/index.ts`
- [ ] Require authentication
- [ ] Validate input (full_name, bio, avatar_url, website)
- [ ] Update user's own profile only
- [ ] Add proper error handling
- [ ] Write tests in `test.ts`

### 3. Upload Avatar Function (Optional)
- [ ] Create `supabase/functions/upload-avatar/index.ts`
- [ ] Validate image file (size, type)
- [ ] Resize/optimize image
- [ ] Upload to storage bucket
- [ ] Update profile with avatar URL
- [ ] Add proper error handling
- [ ] Write tests in `test.ts`

## Example Usage

### Get Profile
```bash
curl http://localhost:54321/functions/v1/get-profile?username=alice
```

### Update Profile
```bash
curl -X POST http://localhost:54321/functions/v1/update-profile \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"full_name": "Alice Smith", "bio": "Software engineer"}'
```

## Acceptance Criteria
- [ ] All functions created with proper structure
- [ ] Functions follow existing patterns (hello-world, health-check)
- [ ] Each function has comprehensive tests
- [ ] CORS is properly configured
- [ ] Error handling is robust
- [ ] Documentation includes usage examples
- [ ] Functions work with authentication
- [ ] Tests run in CI pipeline

## Priority
Medium - Useful for building user features

## References
- Issue #138 comment: https://github.com/SkogAI/supabase/issues/138#issuecomment-3386210007
- `supabase/functions/hello-world/` for example structure
- `supabase/functions/TESTING.md` for testing guide

## Related Test Issue
See test issue for edge function verification tests.
EOF

# Issue 5: Create Unit Tests for Profiles Functionality
read -r -d '' ISSUE_5_BODY << 'EOF' || true
## Description
Create small, incremental unit tests to verify that profiles functionality is working correctly.

## Background
From issue #138: User requested "small incremental unit tests to essentially prove anything is working."

## Test Categories

### 1. Database Tests (SQL)
Create `tests/profiles_test_suite.sql`:

- [ ] Test profile creation trigger
  - Verify `handle_new_user()` creates profile on user signup
  - Test profile has correct user_id, username, full_name
  - Verify timestamps are set correctly

- [ ] Test RLS policies
  - Verify anyone can read profiles
  - Verify users can update their own profile
  - Verify users cannot update other profiles
  - Verify service role has full access

- [ ] Test data constraints
  - Username minimum 3 characters
  - Username is unique
  - Avatar URL validation (optional)
  - Website URL validation (optional)

### 2. Edge Function Tests (Deno)
If profile edge functions are created:

- [ ] Test get-profile function
  - Get by username
  - Get by ID
  - Handle not found
  - Return correct fields

- [ ] Test update-profile function
  - Update with authentication
  - Reject without authentication
  - Validate input
  - Handle invalid data

### 3. Integration Tests
- [ ] Test full profile lifecycle
  - Create user → profile auto-created
  - Update profile → changes saved
  - Delete user → profile cascade deleted
  - Query profile → RLS enforced

## Test Structure
```sql
-- Example test in profiles_test_suite.sql
\echo 'TEST: Profile auto-creation on user signup'
DO $$
DECLARE
    test_user_id UUID;
    profile_count INTEGER;
BEGIN
    -- Create test user
    INSERT INTO auth.users (id, email) 
    VALUES (gen_random_uuid(), 'test@example.com')
    RETURNING id INTO test_user_id;
    
    -- Check profile was created
    SELECT COUNT(*) INTO profile_count
    FROM profiles WHERE id = test_user_id;
    
    IF profile_count = 1 THEN
        RAISE NOTICE 'PASS: Profile auto-created';
    ELSE
        RAISE EXCEPTION 'FAIL: Profile not created';
    END IF;
END $$;
```

## Running Tests
```bash
# Run profiles test suite
supabase db execute --file tests/profiles_test_suite.sql

# Run RLS tests (includes profiles)
npm run test:rls

# Run edge function tests (if created)
cd supabase/functions/get-profile && deno test --allow-all test.ts
```

## Acceptance Criteria
- [ ] Test suite covers all profile functionality
- [ ] Tests are small and incremental
- [ ] Each test proves one specific thing
- [ ] Tests can run in CI/CD
- [ ] Test output is clear (PASS/FAIL messages)
- [ ] Tests are documented
- [ ] README includes test commands

## Priority
High - Requested by user to prove things work

## References
- Issue #138: https://github.com/SkogAI/supabase/issues/138#issuecomment-3386228717
- `tests/rls_test_suite.sql` for test patterns
- `supabase/functions/hello-world/test.ts` for Deno test examples

## Related Issues
- Storage bucket tests (separate issue)
- Realtime tests (separate issue)
- Edge function tests (separate issue)
EOF

# Issue 6: Create Tests for Storage Buckets
read -r -d '' ISSUE_6_BODY << 'EOF' || true
## Description
Create incremental tests to verify storage bucket configuration and policies are working.

## Background
From issue #138: Need tests to prove storage buckets are working correctly.

## Test Categories

### 1. Bucket Existence Tests
Create tests to verify buckets are created:

- [ ] Test `avatars` bucket exists
- [ ] Test `public-assets` bucket exists
- [ ] Test `user-files` bucket exists
- [ ] Verify bucket configuration (size limits, file types)
- [ ] Test bucket RLS policies are enabled

### 2. Upload Permission Tests
- [ ] Test authenticated user can upload to avatars
- [ ] Test authenticated user can upload to user-files
- [ ] Test anyone can read from public-assets
- [ ] Test users cannot access other users' private files
- [ ] Test file size limits are enforced
- [ ] Test MIME type restrictions work

### 3. RLS Policy Tests
- [ ] Test users can only delete their own files
- [ ] Test users can update their own file metadata
- [ ] Test public bucket allows anonymous read
- [ ] Test service role has full access

## Test Structure
```sql
-- Example storage test
\echo 'TEST: Storage buckets exist'
DO $$
DECLARE
    bucket_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO bucket_count
    FROM storage.buckets
    WHERE name IN ('avatars', 'public-assets', 'user-files');
    
    IF bucket_count = 3 THEN
        RAISE NOTICE 'PASS: All storage buckets exist';
    ELSE
        RAISE EXCEPTION 'FAIL: Expected 3 buckets, found %', bucket_count;
    END IF;
END $$;
```

## Test File Location
Create `tests/storage_buckets_test_suite.sql`

## Running Tests
```bash
# Run storage bucket tests
supabase db execute --file tests/storage_buckets_test_suite.sql

# Or use existing storage test
npm run test:storage
```

## Acceptance Criteria
- [ ] All bucket tests pass
- [ ] Upload/download permissions verified
- [ ] RLS policies tested and working
- [ ] File size limits enforced
- [ ] Tests documented and runnable
- [ ] Tests prove storage is working

## Priority
High - Proves storage functionality works

## References
- Issue #138: https://github.com/SkogAI/supabase/issues/138#issuecomment-3386228717
- `tests/storage_test_suite.sql` (if exists) for patterns
- Supabase Storage Testing: https://supabase.com/docs/guides/storage

## Related Issues
- Storage buckets migration (parent issue)
- Profiles tests (related)
EOF

# Issue 7: Create Tests for Realtime Subscriptions
read -r -d '' ISSUE_7_BODY << 'EOF' || true
## Description
Create tests to verify realtime subscriptions are working on profiles table.

## Background
From issue #138: Need tests to prove realtime functionality works.

## Test Categories

### 1. Realtime Configuration Tests
- [ ] Test realtime is enabled on profiles table
- [ ] Verify publication includes profiles
- [ ] Check replica identity is set correctly
- [ ] Test realtime channel creation

### 2. Subscription Tests (TypeScript/JavaScript)
Create `tests/realtime_profiles_test.ts`:

- [ ] Test can subscribe to profile changes
- [ ] Test INSERT events trigger notifications
- [ ] Test UPDATE events trigger notifications
- [ ] Test DELETE events trigger notifications
- [ ] Test filtering by specific user ID
- [ ] Test unsubscribe works correctly

### 3. Permission Tests
- [ ] Test RLS policies apply to realtime
- [ ] Test users only see allowed profiles in realtime
- [ ] Test anonymous users can subscribe (if allowed)
- [ ] Test service role can see all changes

## Test Structure
```typescript
// Example realtime test
Deno.test("Realtime: Profile update triggers event", async () => {
  const updates: any[] = [];
  
  // Subscribe to profile changes
  const subscription = supabase
    .channel('test-profiles')
    .on('postgres_changes', {
      event: 'UPDATE',
      schema: 'public',
      table: 'profiles'
    }, (payload) => {
      updates.push(payload);
    })
    .subscribe();
  
  // Wait for subscription to be ready
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Update a profile
  await supabase.from('profiles').update({
    full_name: 'Test User Updated'
  }).eq('id', testUserId);
  
  // Wait for event
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Verify event received
  assertEquals(updates.length, 1);
  assertEquals(updates[0].new.full_name, 'Test User Updated');
  
  // Cleanup
  subscription.unsubscribe();
});
```

## SQL Configuration Test
```sql
-- Test realtime is enabled
\echo 'TEST: Realtime enabled on profiles'
DO $$
DECLARE
    is_enabled BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND tablename = 'profiles'
    ) INTO is_enabled;
    
    IF is_enabled THEN
        RAISE NOTICE 'PASS: Realtime enabled on profiles';
    ELSE
        RAISE EXCEPTION 'FAIL: Realtime not enabled';
    END IF;
END $$;
```

## Test File Locations
- `tests/realtime_profiles.sql` - SQL configuration tests
- `examples/realtime/test-profiles.ts` - Integration tests

## Running Tests
```bash
# Test SQL configuration
supabase db execute --file tests/realtime_profiles.sql

# Test realtime subscriptions
npm run test:realtime

# Or with Supabase running
supabase start
deno test --allow-all examples/realtime/test-profiles.ts
```

## Acceptance Criteria
- [ ] Configuration tests pass
- [ ] Subscription tests work
- [ ] Events trigger correctly
- [ ] RLS policies enforced in realtime
- [ ] Tests documented
- [ ] README includes realtime test commands

## Priority
Medium - Proves realtime works

## References
- Issue #138: https://github.com/SkogAI/supabase/issues/138#issuecomment-3386228717
- Supabase Realtime Testing: https://supabase.com/docs/guides/realtime
- `examples/realtime/` for existing examples

## Related Issues
- Enable realtime on profiles (parent issue)
- Profiles tests (related)
EOF

# Ask for confirmation before creating issues
echo "This script will create 7 GitHub issues based on issue #138 recommendations."
echo ""
echo "Issues to be created:"
echo "1. Add Storage Buckets to Tracked Migrations"
echo "2. Enable Realtime on Profiles Table"
echo "3. Add Service Role RLS Policy to Profiles"
echo "4. Create User Profile Edge Functions"
echo "5. Create Unit Tests for Profiles Functionality"
echo "6. Create Tests for Storage Buckets"
echo "7. Create Tests for Realtime Subscriptions"
echo ""
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Creating issues..."
echo ""

# Create all issues
create_issue "Add Storage Buckets to Tracked Migrations" "$ISSUE_1_BODY" "enhancement,storage,high-priority"
create_issue "Enable Realtime on Profiles Table" "$ISSUE_2_BODY" "enhancement,realtime"
create_issue "Add Service Role RLS Policy to Profiles" "$ISSUE_3_BODY" "enhancement,security,database,high-priority"
create_issue "Create User Profile Edge Functions" "$ISSUE_4_BODY" "enhancement,edge-functions"
create_issue "Create Unit Tests for Profiles Functionality" "$ISSUE_5_BODY" "testing,high-priority"
create_issue "Create Tests for Storage Buckets" "$ISSUE_6_BODY" "testing,storage,high-priority"
create_issue "Create Tests for Realtime Subscriptions" "$ISSUE_7_BODY" "testing,realtime"

echo ""
echo "=========================================="
echo "✅ Issue creation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review created issues at: https://github.com/$REPO/issues"
echo "2. Run this script to create the issues (requires gh CLI authentication)"
echo "3. Start working on high-priority items (storage, service role policy, tests)"
echo "4. Implement incremental tests to prove functionality"
echo ""
echo "Reference: Issue #138 - https://github.com/$REPO/issues/138"
echo ""
