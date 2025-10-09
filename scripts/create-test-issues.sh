#!/bin/bash

# Script to create unit test issues for Supabase project
# Based on recommendations from issue #138

set -e

echo "Creating unit test issues..."
echo ""

# Issue 1: Profile RLS Tests
echo "Creating Issue 1: Profile RLS Tests..."
gh issue create \
  --title "Unit Test: Verify profile RLS policies (service role, CRUD operations)" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-1.md

# Issue 2: Storage Bucket Tests
echo "Creating Issue 2: Storage Bucket Tests..."
gh issue create \
  --title "Unit Test: Verify storage buckets and RLS policies" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-2.md

# Issue 3: Realtime Tests
echo "Creating Issue 3: Realtime Tests..."
gh issue create \
  --title "Unit Test: Verify realtime subscriptions on profiles table" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-3.md

# Issue 4: Edge Function Tests
echo "Creating Issue 4: Edge Function Tests..."
gh issue create \
  --title "Unit Test: Comprehensive edge function tests (CORS, auth, errors)" \
  --label "test,enhancement" \
  --body-file .github/issue-templates/test-issue-4.md

# Issue 5: Integration Tests
echo "Creating Issue 5: Integration Tests..."
gh issue create \
  --title "Unit Test: End-to-end integration tests (profile creation, storage, realtime)" \
  --label "test,enhancement,integration" \
  --body-file .github/issue-templates/test-issue-5.md

echo ""
echo "✅ All test issues created successfully!"
echo ""
echo "View all issues:"
echo "  gh issue list --label test"
