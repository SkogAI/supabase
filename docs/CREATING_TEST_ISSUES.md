# Creating Test Issues

This guide explains how to create GitHub issues for unit tests to verify that basic Supabase features are working correctly.

## Overview

The repository includes 5 comprehensive unit test issues that validate:

1. **Profile RLS Policies** - Verify Row Level Security works correctly
2. **Storage Buckets** - Verify storage configuration and permissions
3. **Realtime Subscriptions** - Verify realtime events work on profiles
4. **Edge Functions** - Verify edge functions handle all scenarios
5. **Integration Tests** - Verify features work together end-to-end

## Prerequisites

Before creating issues, ensure you have:

1. **GitHub CLI** installed
   ```bash
   # macOS
   brew install gh
   
   # Linux
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update
   sudo apt install gh
   
   # Windows
   winget install --id GitHub.cli
   ```

2. **GitHub Authentication**
   ```bash
   gh auth login
   ```

## Creating Issues

### Option 1: Automated Script (Recommended)

Run the provided script to create all 5 issues at once:

```bash
./scripts/create-test-issues.sh
```

The script will:
- Check for GitHub CLI installation and authentication
- Create all 5 issues with proper labels and descriptions
- Provide a summary of created issues

### Option 2: Manual Creation

If you prefer to create issues manually, you can use the GitHub CLI with the content from `docs/PROPOSED_TEST_ISSUES.md`:

```bash
# Issue 1: Profile RLS Tests
gh issue create --title "Unit Test: Verify profile RLS policies (service role, CRUD operations)" --label "test,enhancement"

# Issue 2: Storage Bucket Tests
gh issue create --title "Unit Test: Verify storage buckets and RLS policies" --label "test,enhancement"

# Issue 3: Realtime Tests
gh issue create --title "Unit Test: Verify realtime subscriptions on profiles table" --label "test,enhancement"

# Issue 4: Edge Function Tests
gh issue create --title "Unit Test: Comprehensive edge function tests (CORS, auth, errors)" --label "test,enhancement"

# Issue 5: Integration Tests
gh issue create --title "Unit Test: End-to-end integration tests (profile creation, storage, realtime)" --label "test,enhancement,integration"
```

For each issue, copy the corresponding body content from `docs/PROPOSED_TEST_ISSUES.md`.

### Option 3: GitHub Web Interface

1. Go to your repository on GitHub
2. Click "Issues" tab
3. Click "New Issue"
4. Copy title and body from `docs/PROPOSED_TEST_ISSUES.md`
5. Add appropriate labels
6. Click "Submit new issue"

## What Gets Created

Each issue includes:

- **Clear objective** - What the test aims to verify
- **Test coverage checklist** - Specific items to test
- **Implementation guidance** - Where to add tests
- **Success criteria** - How to know tests are working
- **Test commands** - How to run the tests

## After Creating Issues

Once issues are created, you can:

1. **View all issues**:
   ```bash
   gh issue list --label test
   ```

2. **Assign issues** to team members:
   ```bash
   gh issue edit <issue-number> --add-assignee <username>
   ```

3. **Track progress** using GitHub Projects or milestones

4. **Close issues** as tests are implemented and passing:
   ```bash
   gh issue close <issue-number>
   ```

## Existing Test Infrastructure

The repository already has test infrastructure in place:

### Database Tests (SQL)
- `tests/rls_test_suite.sql` - RLS policy tests
- `tests/profiles_test_suite.sql` - Profile-specific tests
- `tests/storage_test_suite.sql` - Storage tests
- `tests/storage_buckets_test_suite.sql` - Storage bucket tests

**Run with:**
```bash
npm run test:rls
npm run test:profiles
npm run test:storage
npm run test:storage-buckets
```

### Edge Function Tests (Deno/TypeScript)
- `supabase/functions/hello-world/test.ts`
- `supabase/functions/health-check/test.ts`
- `supabase/functions/openai-chat/test.ts`
- `supabase/functions/openrouter-chat/test.ts`

**Run with:**
```bash
npm run test:functions
# or
cd supabase/functions/hello-world && deno test --allow-all test.ts
```

### Realtime Tests
- `examples/realtime/` - Contains realtime example and tests

**Run with:**
```bash
npm run test:realtime
```

## Verifying Tests Work

After implementing tests from the issues:

1. **Start Supabase locally**:
   ```bash
   npm run db:start
   ```

2. **Run specific test suites**:
   ```bash
   npm run test:rls        # RLS policies
   npm run test:storage    # Storage buckets
   npm run test:functions  # Edge functions
   npm run test:realtime   # Realtime events
   ```

3. **Check results**:
   - SQL tests show PASS/FAIL for each test case
   - Deno tests show passed/failed test count
   - All tests should pass with green checkmarks

## Need Help?

- **Script issues**: Check GitHub CLI is installed and you're authenticated
- **Test failures**: Review test output and corresponding implementation
- **Questions**: Open a discussion or ask in team chat

## Summary

Creating these test issues helps ensure:
- ✅ User profiles work correctly with proper security
- ✅ Storage buckets are configured with right permissions
- ✅ Realtime updates broadcast to subscribers
- ✅ Edge functions handle all scenarios properly
- ✅ All features integrate together seamlessly

By implementing tests from these issues, we prove that the basic Supabase infrastructure is working as expected.
