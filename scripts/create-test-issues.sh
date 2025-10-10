#!/bin/bash
# Script to create GitHub issues for unit tests
# Based on content from docs/PROPOSED_TEST_ISSUES.md
#
# Prerequisites:
#   - GitHub CLI installed: https://cli.github.com/
#   - Authenticated with: gh auth login
#
# Usage:
#   ./scripts/create-test-issues.sh

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUES_FILE="${REPO_ROOT}/docs/PROPOSED_TEST_ISSUES.md"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Creating GitHub Issues from Proposed Tests${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}ERROR: GitHub CLI (gh) is not installed${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}ERROR: Not authenticated with GitHub CLI${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Check if issues file exists
if [ ! -f "$ISSUES_FILE" ]; then
    echo -e "${YELLOW}ERROR: Issues file not found: $ISSUES_FILE${NC}"
    exit 1
fi

cd "$REPO_ROOT"

echo -e "${GREEN}Creating 5 unit test issues...${NC}"
echo ""

# Issue 1: Profile RLS Tests
echo "Creating Issue 1: Profile RLS policy tests..."
gh issue create \
  --title "Unit Test: Verify profile RLS policies (service role, CRUD operations)" \
  --label "test,enhancement" \
  --body "$(cat << 'EOF'
## Objective
Create comprehensive unit tests to verify that all RLS policies on the `profiles` table work correctly.

## Related Issue
- Implements testing for existing profile policies

## Test Coverage Required

### 1. Service Role Access
- [ ] Service role can SELECT all profiles
- [ ] Service role can INSERT profiles for any user
- [ ] Service role can UPDATE any profile
- [ ] Service role can DELETE any profile

### 2. Authenticated User Access
- [ ] Authenticated users can view all profiles (public read)
- [ ] Authenticated users can insert their own profile
- [ ] Authenticated users can update their own profile
- [ ] Authenticated users CANNOT update other users' profiles
- [ ] Authenticated users can delete their own profile (if policy exists)
- [ ] Authenticated users CANNOT delete other users' profiles

### 3. Anonymous User Access
- [ ] Anonymous users can view all profiles (public read)
- [ ] Anonymous users CANNOT insert profiles
- [ ] Anonymous users CANNOT update profiles
- [ ] Anonymous users CANNOT delete profiles

## Implementation
Add tests to `tests/rls_test_suite.sql` or create `tests/profile_rls_test.sql`

## Success Criteria
- All tests pass with PASS status
- Test covers all CRUD operations for all roles (service_role, authenticated, anon)
- Clear error messages when policies are violated

## Test Command
\`\`\`bash
npm run test:rls
\`\`\`
EOF
)"

echo -e "${GREEN}✓ Issue 1 created${NC}"
echo ""

# Issue 2: Storage Bucket Tests
echo "Creating Issue 2: Storage bucket configuration tests..."
gh issue create \
  --title "Unit Test: Verify storage buckets and RLS policies" \
  --label "test,enhancement" \
  --body "$(cat << 'EOF'
## Objective
Create unit tests to verify that storage buckets are properly configured with correct size limits, file type restrictions, and RLS policies.

## Related Issue
- Verifies existing storage bucket configuration

## Test Coverage Required

### 1. Bucket Configuration
- [ ] `avatars` bucket exists with 5MB limit
- [ ] `avatars` bucket only allows image file types
- [ ] `public-assets` bucket exists with 10MB limit
- [ ] `public-assets` bucket allows images and PDFs
- [ ] `user-files` bucket exists with 50MB limit
- [ ] `user-files` bucket is private by default

### 2. Storage RLS Policies
- [ ] Authenticated users can upload to their own folder in `avatars`
- [ ] Authenticated users can read from their own folder in `avatars`
- [ ] Anyone can read from `public-assets`
- [ ] Only authenticated users can upload to `public-assets`
- [ ] Users can only access their own files in `user-files`
- [ ] Service role has full access to all buckets

### 3. File Type Validation
- [ ] `avatars` rejects non-image files
- [ ] `public-assets` rejects files other than images/PDFs
- [ ] File size limits are enforced correctly

## Implementation
Enhance `tests/storage_test_suite.sql` or create `tests/storage_buckets_test.sql`

## Success Criteria
- All bucket configuration tests pass
- All RLS policy tests pass
- File type and size restrictions work correctly

## Test Command
\`\`\`bash
npm run test:storage
# or
supabase db execute --file tests/storage_buckets_test.sql
\`\`\`
EOF
)"

echo -e "${GREEN}✓ Issue 2 created${NC}"
echo ""

# Issue 3: Realtime Tests
echo "Creating Issue 3: Realtime functionality tests..."
gh issue create \
  --title "Unit Test: Verify realtime subscriptions on profiles table" \
  --label "test,enhancement" \
  --body "$(cat << 'EOF'
## Objective
Create unit tests to verify that realtime subscriptions work correctly on the `profiles` table.

## Related Issue
- Verifies realtime configuration for profiles

## Test Coverage Required

### 1. Realtime Configuration
- [ ] `profiles` table is added to `supabase_realtime` publication
- [ ] `profiles` table has `REPLICA IDENTITY FULL` set
- [ ] Realtime is enabled in `config.toml` for profiles

### 2. Subscription Events
- [ ] INSERT events are broadcast when new profile is created
- [ ] UPDATE events are broadcast when profile is updated
- [ ] DELETE events are broadcast when profile is deleted
- [ ] Events contain correct payload data

### 3. Authorization
- [ ] Authenticated users can subscribe to profile changes
- [ ] Anonymous users can subscribe to public profile changes
- [ ] Users receive updates for all profiles (public read)

## Implementation
Create `tests/realtime_profiles_test.sql` and/or `tests/realtime_profiles_test.ts`

For JavaScript/TypeScript tests:
- Use `@supabase/supabase-js` client
- Subscribe to `profiles` table changes
- Verify events are received for INSERT/UPDATE/DELETE

For SQL tests:
- Verify publication includes profiles table
- Verify replica identity is set

## Success Criteria
- Publication configuration is correct
- Real-time events are received for all CRUD operations
- Event payloads contain expected data

## Test Command
\`\`\`bash
npm run test:realtime
\`\`\`
EOF
)"

echo -e "${GREEN}✓ Issue 3 created${NC}"
echo ""

# Issue 4: Edge Function Tests
echo "Creating Issue 4: Edge function comprehensive tests..."
gh issue create \
  --title "Unit Test: Comprehensive edge function tests (CORS, auth, errors)" \
  --label "test,enhancement" \
  --body "$(cat << 'EOF'
## Objective
Create comprehensive unit tests for existing edge functions to verify they handle all scenarios correctly.

## Related Issue
- Verifies existing edge function implementations

## Test Coverage Required

### 1. hello-world Function
- [ ] Returns 200 with default name when no body provided
- [ ] Returns personalized greeting with provided name
- [ ] Handles CORS preflight requests correctly
- [ ] Detects authenticated vs anonymous users
- [ ] Database connectivity check works
- [ ] Returns proper error responses for malformed requests

### 2. health-check Function
- [ ] Returns database connection health status
- [ ] Returns connection pool metrics
- [ ] Returns AI agent connection count
- [ ] Alert levels (OK, WARNING, CRITICAL) work correctly
- [ ] Different query modes work (simple, full, agents, metrics)
- [ ] CORS headers are set correctly

### 3. Error Handling
- [ ] Functions return proper HTTP status codes
- [ ] Error messages are clear and actionable
- [ ] Functions handle missing environment variables gracefully

### 4. Authentication
- [ ] Functions correctly identify authenticated users via JWT
- [ ] Functions handle requests without auth headers
- [ ] Service role key provides elevated access

## Implementation
Enhance existing tests:
- `supabase/functions/hello-world/test.ts`
- `supabase/functions/health-check/test.ts`

Create comprehensive test suite with:
\`\`\`typescript
Deno.test("hello-world - default greeting", async () => { ... })
Deno.test("hello-world - custom name", async () => { ... })
Deno.test("hello-world - authenticated user", async () => { ... })
Deno.test("hello-world - CORS preflight", async () => { ... })
\`\`\`

## Success Criteria
- All edge function tests pass
- Test coverage includes happy path and error cases
- CORS, authentication, and error handling all verified

## Test Command
\`\`\`bash
npm run test:functions
# or for individual functions
cd supabase/functions/hello-world && deno test --allow-all test.ts
cd supabase/functions/health-check && deno test --allow-all test.ts
\`\`\`
EOF
)"

echo -e "${GREEN}✓ Issue 4 created${NC}"
echo ""

# Issue 5: Integration Tests
echo "Creating Issue 5: Integration test suite..."
gh issue create \
  --title "Unit Test: End-to-end integration tests (profile creation, storage, realtime)" \
  --label "test,enhancement,integration" \
  --body "$(cat << 'EOF'
## Objective
Create end-to-end integration tests that verify multiple features work together correctly.

## Related Issues
- Tests integration of profiles, storage, realtime, and edge functions

## Test Coverage Required

### 1. User Profile Lifecycle
- [ ] New user signup creates profile automatically (via trigger)
- [ ] Profile data is populated from user metadata
- [ ] Profile can be updated via edge function
- [ ] Profile updates trigger realtime events
- [ ] Profile deletion cascades correctly

### 2. Avatar Upload Flow
- [ ] User can upload avatar to storage
- [ ] Avatar URL is saved to profile
- [ ] Avatar is publicly accessible
- [ ] Old avatar is cleaned up on update

### 3. Cross-Feature Integration
- [ ] Profile changes are visible in realtime subscriptions
- [ ] Storage policies respect profile ownership
- [ ] Edge functions can query profiles with correct RLS context
- [ ] Service role can perform admin operations

## Implementation
Create `tests/integration_test_suite.sql` and `tests/integration_test_suite.ts`

Use a combination of:
- SQL for database-level integration tests
- TypeScript/JavaScript for client-side integration tests
- Edge function calls to test full stack

## Success Criteria
- All integration tests pass
- Tests verify features work together, not in isolation
- Realistic user workflows are tested

## Test Command
\`\`\`bash
npm run test:integration
# or
npm test
\`\`\`
EOF
)"

echo -e "${GREEN}✓ Issue 5 created${NC}"
echo ""

echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Successfully created 5 issues!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "View created issues with: gh issue list"
echo ""
