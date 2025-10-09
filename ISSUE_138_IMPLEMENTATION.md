# Issue #138 Implementation Guide

This document outlines the implementation for issue #138: Creating issues for proposed changes and incremental unit tests.

## Overview

Based on the analysis in [issue #138](https://github.com/SkogAI/supabase/issues/138), we identified several improvements and created:

1. **A script to generate GitHub issues** for tracking the proposed changes
2. **Incremental unit tests** to prove functionality is working

## What Was Created

### 1. Issue Creation Script

**File:** `scripts/create-issues-138.sh`

Creates 7 GitHub issues to track the recommended improvements:

1. **Add Storage Buckets to Tracked Migrations** (High Priority)
   - Move storage bucket configuration from local dev to tracked migrations
   - Enable proper versioning and deployment

2. **Enable Realtime on Profiles Table** (Medium Priority)
   - Configure realtime subscriptions for profile changes
   - Add example subscription code

3. **Add Service Role RLS Policy to Profiles** (High Priority)
   - Add missing service role policy for admin operations
   - Enable edge functions to access profiles correctly

4. **Create User Profile Edge Functions** (Medium Priority)
   - Build `get-profile` function (query by username/ID)
   - Build `update-profile` function (authenticated updates)
   - Optional: `upload-avatar` function

5. **Create Unit Tests for Profiles Functionality** (High Priority)
   - Database tests (trigger, RLS, constraints)
   - Edge function tests (if created)
   - Integration tests (full lifecycle)

6. **Create Tests for Storage Buckets** (High Priority)
   - Verify bucket existence and configuration
   - Test upload/download permissions
   - Validate RLS policies

7. **Create Tests for Realtime Subscriptions** (Medium Priority)
   - Test realtime configuration
   - Verify subscription events
   - Check RLS enforcement in realtime

### 2. Profiles Basic Test Suite

**File:** `tests/profiles_basic_test_suite.sql`

Small, incremental unit tests that verify:

✅ **TEST 1:** Profiles table exists  
✅ **TEST 2:** RLS is enabled on profiles  
✅ **TEST 3:** Table has expected columns (id, username, full_name, avatar_url, website, updated_at)  
✅ **TEST 4:** Seed profiles exist (at least 3 from seed data)  
✅ **TEST 5:** `handle_new_user` trigger exists for auto-profile creation  
✅ **TEST 6:** Username constraints (unique, minimum length)  
✅ **TEST 7:** RLS policies exist (at least 3)  
✅ **TEST 8:** Lists all RLS policies on profiles  
✅ **TEST 9:** Foreign key to auth.users exists  
✅ **TEST 10:** Basic profile query works  

### 3. Updated Documentation

**Files Updated:**
- `tests/README.md` - Added profiles test documentation
- `package.json` - Added `test:profiles` npm script

## How to Use

### Step 1: Create the GitHub Issues

Run the issue creation script (requires GitHub CLI authentication):

```bash
# Authenticate with GitHub (if not already)
gh auth login

# Run the script
./scripts/create-issues-138.sh
```

This will create 7 issues in the repository for tracking the proposed changes.

### Step 2: Run the Profiles Test

Verify that profiles functionality is working:

```bash
# Start Supabase
npm run db:start

# Reset database with migrations and seed data
npm run db:reset

# Run the profiles test
npm run test:profiles
```

**Expected output:** All tests should pass with "PASS" notices. Warnings are informational.

### Step 3: Implement the Issues

Work through the created issues in priority order:

**High Priority (Do First):**
1. Add Storage Buckets to Tracked Migrations
2. Add Service Role RLS Policy to Profiles
3. Create Unit Tests for Profiles Functionality
4. Create Tests for Storage Buckets

**Medium Priority (Do After):**
5. Enable Realtime on Profiles Table
6. Create User Profile Edge Functions
7. Create Tests for Realtime Subscriptions

## Testing Strategy

The testing approach follows these principles:

### 1. Small and Incremental
- Each test proves one specific thing
- Tests are independent and can run in any order
- Clear PASS/FAIL messages

### 2. Multiple Layers
- **Database Tests (SQL):** Schema, RLS, constraints, triggers
- **Edge Function Tests (Deno):** API logic, authentication, error handling
- **Integration Tests:** Full user workflows

### 3. Automated and Reproducible
- All tests run via npm scripts
- Tests can run in CI/CD
- Consistent test data via seed.sql

## Test Coverage

### Current Coverage ✅

- **Profiles Table:** Structure, RLS, constraints, trigger
- **RLS Policies:** General policies across all tables
- **Storage:** Basic bucket and policy tests
- **Connection:** Database connectivity and health

### To Be Added 📋

- **Storage Buckets:** Detailed tests for avatars, public-assets, user-files
- **Realtime:** Subscription and event tests
- **Edge Functions:** API endpoint tests (get-profile, update-profile)
- **Integration:** End-to-end user workflows

## Benefits

### For Development
- Clear roadmap via GitHub issues
- Incremental progress tracking
- Small, testable units of work

### For Quality
- Automated verification
- Regression prevention
- Clear acceptance criteria

### For Collaboration
- Issues can be assigned to team members
- Progress is visible to everyone
- Discussion happens in context

## Next Steps

1. ✅ **Created:** Issue generation script
2. ✅ **Created:** Basic profiles test suite
3. ✅ **Updated:** Documentation
4. 📋 **TODO:** Run issue creation script (requires auth)
5. 📋 **TODO:** Implement high-priority issues
6. 📋 **TODO:** Add remaining test suites

## Testing the Implementation

To verify this implementation works:

```bash
# 1. Check the script exists and is executable
ls -la scripts/create-issues-138.sh

# 2. View the test file
cat tests/profiles_basic_test_suite.sql

# 3. Verify npm script was added
npm run | grep test:profiles

# 4. Run the test (requires Supabase running)
npm run db:start
npm run db:reset
npm run test:profiles
```

## References

- **Original Issue:** https://github.com/SkogAI/supabase/issues/138
- **User Request:** https://github.com/SkogAI/supabase/issues/138#issuecomment-3386228717
- **Analysis Comment:** https://github.com/SkogAI/supabase/issues/138#issuecomment-3386210007

## Questions?

If you have questions about this implementation:

1. Review the issue descriptions in `scripts/create-issues-138.sh`
2. Check the test examples in `tests/profiles_basic_test_suite.sql`
3. Read the testing guide in `tests/README.md`
4. Comment on issue #138 for clarification

---

**Created:** 2025-10-09  
**Purpose:** Implement incremental testing and issue tracking for issue #138  
**Status:** Ready for review and execution
