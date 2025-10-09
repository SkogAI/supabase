# Test Issue Templates

This directory contains templates for creating unit test issues based on the recommendations from issue #138.

## Quick Commands

Run these commands from the repository root to create all test issues:

### Issue 1: Profile RLS Tests
```bash
gh issue create \
  --title "Unit Test: Verify profile RLS policies (service role, CRUD operations)" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-1.md
```

### Issue 2: Storage Bucket Tests
```bash
gh issue create \
  --title "Unit Test: Verify storage buckets and RLS policies" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-2.md
```

### Issue 3: Realtime Tests
```bash
gh issue create \
  --title "Unit Test: Verify realtime subscriptions on profiles table" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-3.md
```

### Issue 4: Edge Function Tests
```bash
gh issue create \
  --title "Unit Test: Comprehensive edge function tests (CORS, auth, errors)" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-4.md
```

### Issue 5: Integration Tests
```bash
gh issue create \
  --title "Unit Test: End-to-end integration tests (profile creation, storage, realtime)" \
  --label "test,enhancement,integration" \
  --body-file .github/issue-templates/test-issue-5.md
```

## Or Use the Script

```bash
./scripts/create-test-issues.sh
```

## Test Issue Overview

| Issue | Focus | Related To |
|-------|-------|-----------|
| Test 1 | Profile RLS policies (service role, CRUD) | #144 |
| Test 2 | Storage buckets and RLS policies | #142 |
| Test 3 | Realtime subscriptions on profiles | #143 |
| Test 4 | Edge function tests (CORS, auth, errors) | #145 |
| Test 5 | End-to-end integration tests | All above |

## Purpose

These test issues provide small, incremental unit tests to prove that each proposed change from issue #138 is working correctly. Each issue includes:

- Clear objectives
- Specific test coverage requirements
- Implementation guidance
- Success criteria
- Test commands to run

## Next Steps

After creating these issues, you can:
1. Implement the features (#142-145)
2. Implement the corresponding tests
3. Run tests to verify everything works
4. Check off items as they pass
