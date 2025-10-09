# Issue #138 Quick Start Guide

Quick reference for implementing issue #138 recommendations.

## What is This?

This guide helps you create GitHub issues and run tests for the improvements identified in [issue #138](https://github.com/SkogAI/supabase/issues/138).

## Quick Commands

### 1. Create GitHub Issues

```bash
# Authenticate with GitHub CLI (first time only)
gh auth login

# Create the 7 issues
./scripts/create-issues-138.sh
```

### 2. Run Profiles Tests

```bash
# Start Supabase
npm run db:start

# Reset database with migrations and seed data
npm run db:reset

# Run profiles test
npm run test:profiles
```

### 3. Run All Tests

```bash
# Run all test suites
npm run test:profiles
npm run test:rls
npm run test:storage
npm run diagnose:connection
```

## What Issues Will Be Created?

Running `./scripts/create-issues-138.sh` creates these 7 issues:

### High Priority ⚠️
1. **Add Storage Buckets to Tracked Migrations**
   - Move storage config from local dev to tracked migrations
   - Labels: `enhancement,storage,high-priority`

2. **Add Service Role RLS Policy to Profiles**
   - Add missing service role policy for admin operations
   - Labels: `enhancement,security,database,high-priority`

3. **Create Unit Tests for Profiles Functionality**
   - Database tests for profiles table
   - Labels: `testing,high-priority`

4. **Create Tests for Storage Buckets**
   - Verify bucket configuration and permissions
   - Labels: `testing,storage,high-priority`

### Medium Priority 📋
5. **Enable Realtime on Profiles Table**
   - Configure realtime subscriptions
   - Labels: `enhancement,realtime`

6. **Create User Profile Edge Functions**
   - Build get-profile and update-profile functions
   - Labels: `enhancement,edge-functions`

7. **Create Tests for Realtime Subscriptions**
   - Verify realtime functionality
   - Labels: `testing,realtime`

## What Tests Are Available?

### Profiles Basic Test Suite ⭐ NEW

**File:** `tests/profiles_basic_test_suite.sql`

10 incremental tests that verify:
- ✅ Profiles table exists
- ✅ RLS is enabled
- ✅ Expected columns present
- ✅ Seed data loaded
- ✅ Trigger for auto-profile creation
- ✅ Constraints (unique username, foreign key)
- ✅ RLS policies exist
- ✅ Basic operations work

**Run with:**
```bash
npm run test:profiles
```

### Other Test Suites

```bash
npm run test:rls          # RLS policy tests
npm run test:storage      # Storage bucket tests
npm run test:connection   # Database connectivity
npm run test:db-health    # Database health check
```

## Expected Output

### Issue Creation
```
==========================================
GitHub Issue Creation Script - Issue #138
==========================================

✅ GitHub CLI is installed and authenticated

This script will create 7 GitHub issues based on issue #138 recommendations.

Issues to be created:
1. Add Storage Buckets to Tracked Migrations
2. Enable Realtime on Profiles Table
...

Do you want to proceed? (y/n) y

Creating issues...

Creating issue: Add Storage Buckets to Tracked Migrations
✓ Created issue #141

...

✅ Issue creation complete!
```

### Profiles Test
```
================================================================================
PROFILES BASIC TEST SUITE
================================================================================

TEST 1: Verifying profiles table exists...
NOTICE:  PASS: Profiles table exists

TEST 2: Verifying RLS is enabled on profiles...
NOTICE:  PASS: RLS is enabled on profiles

TEST 3: Verifying profiles has expected columns...
NOTICE:  PASS: All expected columns exist

...

TEST 10: Testing simple profile query...
NOTICE:  PASS: Can query profiles (found profile: alice)

================================================================================
TEST SUITE COMPLETE
================================================================================
```

## Next Steps

After creating issues and running tests:

1. **Review the created issues** at https://github.com/SkogAI/supabase/issues

2. **Start with high-priority items:**
   - Storage buckets migration
   - Service role RLS policy
   - Profiles tests
   - Storage tests

3. **Implement incrementally:**
   - Create one feature at a time
   - Run tests after each change
   - Commit frequently

4. **Track progress:**
   - Update issue status
   - Link PRs to issues
   - Document any blockers

## Troubleshooting

### "gh: command not found"
Install GitHub CLI: https://cli.github.com/

### "Not authenticated with GitHub"
Run: `gh auth login`

### "Supabase not running"
Run: `npm run db:start`

### "Test failed"
Run: `npm run db:reset` to apply migrations and seed data

## Reference Documentation

- **Full Guide:** [ISSUE_138_IMPLEMENTATION.md](../ISSUE_138_IMPLEMENTATION.md)
- **Issue Script:** [scripts/create-issues-138.sh](../scripts/create-issues-138.sh)
- **Test Suite:** [tests/profiles_basic_test_suite.sql](../tests/profiles_basic_test_suite.sql)
- **Tests README:** [tests/README.md](../tests/README.md)
- **Original Issue:** https://github.com/SkogAI/supabase/issues/138

## Questions?

- Comment on issue #138 for clarification
- Review the generated issue descriptions
- Check the test examples

---

**Quick Tip:** Run `./scripts/create-issues-138.sh` first, then implement issues in priority order while running tests frequently to verify functionality.
