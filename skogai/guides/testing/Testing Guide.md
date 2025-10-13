---
title: Testing Complete Guide
type: note
permalink: guides/testing/testing-guide
tags:
- testing
- validation
- automation
- rls
- storage
- realtime
- edge-functions
- consolidated
---

# Testing Complete Guide

Comprehensive guide to testing infrastructure, test types, test commands, and test issue management for Supabase features.

## Overview

[overview] Comprehensive testing infrastructure for user profiles, edge functions, storage, and realtime features #testing #infrastructure
[benefit] Tests provide confidence that basic features work before deploying #testing #validation
[benefit] Tests catch breaking changes preventing regression #testing #ci
[benefit] Tests serve as examples of how features work #testing #documentation
[benefit] Tests help new developers verify setup quickly #testing #onboarding
[benefit] GitHub issues provide visibility into test coverage #testing #tracking

## Test Infrastructure Components

[component] SQL test suites for database features (RLS, storage, profiles) #testing #database
[component] Deno/TypeScript tests for edge functions #testing #functions
[component] Integration tests for realtime subscriptions #testing #realtime
[component] NPM scripts provide consistent test commands #testing #automation
[component] GitHub issue tracking for test coverage #testing #management
[component] Automated scripts for issue creation #testing #automation

## Feature Testing Status

### User Profiles ✅

[feature] public.profiles table with user profile data #database #schema
[feature] Profiles automatically created on user signup via trigger #automation #database
[feature] Row Level Security configured for proper access control #security #rls
[feature] 3 test users (alice, bob, charlie) with complete profiles #testing #seed
[test] Comprehensive RLS test suite at tests/rls_test_suite.sql #testing #sql
[command] Run with `npm run test:rls` #testing #workflow
[command] Run with `npm run test:profiles` #testing #workflow

### Edge Functions ✅

[feature] hello-world function with CORS support and auth detection #functions #basic
[feature] health-check function with metrics and database connectivity #functions #monitoring
[feature] openai-chat function with AI integration #functions #ai
[feature] openrouter-chat function with multi-model support #functions #ai
[test] Unit tests in supabase/functions/*/test.ts files #testing #typescript
[command] Run all function tests with `npm run test:functions` #testing #workflow

### Storage Buckets ✅

[feature] avatars bucket: 5MB limit, images only, public access #storage #config
[feature] public-assets bucket: 10MB limit, images/PDFs, public access #storage #config
[feature] user-files bucket: 50MB limit, private, user-scoped #storage #config
[feature] User-scoped RLS policies for storage access control #storage #security
[test] Storage test suite at tests/storage_test_suite.sql #testing #sql
[test] Bucket test suite at tests/storage_buckets_test_suite.sql #testing #sql
[command] Run with `npm run test:storage-buckets` #testing #workflow

### Realtime Subscriptions ✅

[feature] Realtime enabled on profiles and posts tables #realtime #config
[feature] Supabase_realtime publication configured #realtime #database
[feature] Replica identity FULL set for change tracking #realtime #database
[test] Realtime tests in examples/realtime/ directory #testing #integration
[command] Run with `npm run test:realtime` #testing #workflow

## Test Types and Locations

### SQL Tests (Database)

[location] tests/ directory contains all SQL test suites #testing #structure
[file] tests/rls_test_suite.sql verifies RLS policy enforcement #testing #security
[file] tests/profiles_test_suite.sql tests profile functionality #testing #features
[file] tests/storage_test_suite.sql tests storage operations #testing #storage
[file] tests/storage_buckets_test_suite.sql tests bucket configuration #testing #storage
[execution] Run SQL tests with `supabase db execute --file tests/filename.sql` #testing #command

### TypeScript Tests (Edge Functions)

[location] supabase/functions/*/test.ts files for each function #testing #structure
[file] hello-world/test.ts tests basic function behavior #testing #functions
[file] health-check/test.ts tests monitoring endpoints #testing #functions
[file] openai-chat/test.ts tests AI integration #testing #functions
[file] openrouter-chat/test.ts tests multi-model AI #testing #functions
[execution] Run Deno tests with `cd supabase/functions && deno test --allow-all` #testing #command

### Integration Tests

[location] examples/realtime/ directory contains integration tests #testing #structure
[scope] Tests features working together across system boundaries #testing #integration
[execution] Run with `cd examples/realtime && npm install && npm run test` #testing #command

## NPM Test Scripts

[script] test:rls runs RLS policy test suite #testing #npm
[script] test:profiles runs profile functionality tests #testing #npm
[script] test:storage-buckets runs storage bucket tests #testing #npm
[script] test:functions runs all edge function tests #testing #npm
[script] test:realtime runs realtime subscription tests #testing #npm
[definition] All scripts defined in package.json for consistency #testing #configuration

## Test Workflow

[workflow] Start Supabase with `npm run db:start` #testing #setup
[workflow] Reset database with `npm run db:reset` to apply migrations and seed #testing #setup
[workflow] Run specific test suite with npm run test:* commands #testing #execution
[workflow] Verify all tests pass before committing changes #testing #process
[workflow] Stop Supabase with `npm run db:stop` after testing #testing #cleanup

### Quick Test Run

[quickstart] `npm run db:start` - Start local Supabase instance #testing #command
[quickstart] `npm run test:rls` - Test RLS policies #testing #command
[quickstart] `npm run test:profiles` - Test profile features #testing #command
[quickstart] `npm run test:storage-buckets` - Test storage #testing #command
[quickstart] `npm run test:functions` - Test edge functions #testing #command
[quickstart] `npm run test:realtime` - Test realtime subscriptions #testing #command

## Manual Testing via Studio

[manual] Access Supabase Studio at http://localhost:8000 #testing #ui
[manual] SQL Editor for running custom queries and tests #testing #sql
[manual] Table Editor for viewing and modifying data #testing #data
[manual] Storage section for testing file uploads #testing #storage
[manual] Database section for schema inspection #testing #schema
[manual] Authentication section for user management #testing #auth

## The 5 Test Issues

[tracking] 5 comprehensive test issues track coverage systematically #testing #management
[tracking] Issues created via ./scripts/create-test-issues.sh #testing #automation
[tracking] Each issue has detailed checklist and acceptance criteria #testing #specification

### Issue 1: Profile RLS Policies

[issue-1] Tests Row Level Security on profiles table #testing #rls
[issue-1] Service role access: full CRUD operations #testing #admin
[issue-1] Authenticated user access: view all, manage own #testing #user
[issue-1] Anonymous user access: read-only #testing #public
[issue-1] Command: `npm run test:rls` #testing #command

### Issue 2: Storage Buckets

[issue-2] Tests storage configuration and policies #testing #storage
[issue-2] Bucket configuration: size limits, file types #testing #config
[issue-2] Storage RLS policies for access control #testing #security
[issue-2] File type validation #testing #validation
[issue-2] Command: `npm run test:storage-buckets` #testing #command

### Issue 3: Realtime Functionality

[issue-3] Tests realtime subscriptions on profiles #testing #realtime
[issue-3] Realtime configuration verification #testing #config
[issue-3] Subscription events: INSERT, UPDATE, DELETE #testing #events
[issue-3] Authorization for different user roles #testing #security
[issue-3] Command: `npm run test:realtime` #testing #command

### Issue 4: Edge Functions

[issue-4] Tests edge function behavior #testing #functions
[issue-4] hello-world function: CORS, auth, database check #testing #basic
[issue-4] health-check function: metrics, alert levels #testing #monitoring
[issue-4] Error handling and authentication #testing #security
[issue-4] Command: `npm run test:functions` #testing #command

### Issue 5: Integration Tests

[issue-5] Tests features working together #testing #integration
[issue-5] User profile lifecycle end-to-end #testing #workflow
[issue-5] Avatar upload flow across storage and database #testing #workflow
[issue-5] Cross-feature integration scenarios #testing #validation
[issue-5] Command: `npm run test:integration` #testing #command

## Test Issue Management

### Creating Test Issues

[creation] Automated script: ./scripts/create-test-issues.sh #testing #automation
[creation] Manual creation: gh issue create --title "..." --label "test,enhancement" #testing #manual
[creation] Web interface: GitHub Issues UI #testing #manual
[prerequisite] Requires GitHub CLI (gh) installed and authenticated #testing #setup
[output] Script creates all 5 issues with proper labels and descriptions #testing #automation

### Issue Documentation

[documentation] docs/CREATING_TEST_ISSUES.md explains issue creation process #testing #guide
[documentation] docs/PROPOSED_TEST_ISSUES.md contains detailed test specifications #testing #specification
[documentation] Each issue includes implementation guidance and success criteria #testing #requirements
[documentation] Issues reference existing test infrastructure #testing #integration

## Success Criteria

[success] All database tests pass with ✅ status #testing #validation
[success] All edge function tests pass without errors #testing #validation
[success] Storage tests pass with correct permissions #testing #validation
[success] Realtime tests pass with events broadcast correctly #testing #validation
[success] Manual testing works via Supabase Studio #testing #validation

## Troubleshooting

### Tests Fail After Fresh Clone

[troubleshoot] Run `npm run db:start` to start Supabase #testing #fix
[troubleshoot] Run `npm run db:reset` to reset database with migrations and seed #testing #fix
[troubleshoot] Verify Docker Desktop is running #testing #prerequisite

### Edge Function Tests Fail

[troubleshoot] Start functions locally: `npm run functions:serve` #testing #fix
[troubleshoot] Set environment variable: RUN_INTEGRATION_TESTS=true #testing #fix
[troubleshoot] Run tests with proper flags: `npm run test:functions` #testing #fix

### Storage Tests Fail

[troubleshoot] Verify buckets created via migration #testing #verification
[troubleshoot] Check RLS policies are applied to storage.objects #testing #verification
[troubleshoot] Confirm storage configuration in config.toml #testing #verification

### Realtime Tests Fail

[troubleshoot] Check tables in supabase_realtime publication #testing #verification
[troubleshoot] Verify REPLICA IDENTITY FULL is set #testing #verification
[troubleshoot] Confirm realtime configuration in config.toml #testing #verification

### Docker Not Running

[troubleshoot] Error: "Cannot connect to the Docker daemon" #testing #error
[troubleshoot] Solution: Start Docker Desktop application #testing #fix
[troubleshoot] Verify with: `docker info` #testing #verification

### Port Conflicts

[troubleshoot] Error: "Port already in use" #testing #error
[troubleshoot] Solution: Stop conflicting services or change ports in config.toml #testing #fix
[troubleshoot] Verify ports: `lsof -i :8000` and `lsof -i :54322` #testing #verification

## Next Steps After Tests Pass

[nextsteps] Create issues: Run ./scripts/create-test-issues.sh #testing #workflow
[nextsteps] Assign work: Assign issues to team members #testing #management
[nextsteps] Expand tests: Add more test cases for edge scenarios #testing #enhancement
[nextsteps] CI integration: Tests run automatically in GitHub Actions #testing #ci
[nextsteps] Update documentation: Document new features as added #testing #maintenance

## CI/CD Integration

[ci] Tests run automatically on pull requests #testing #automation
[ci] GitHub Actions workflows in .github/workflows/ #testing #configuration
[ci] Schema validation includes RLS policy checks #testing #validation
[ci] Edge function tests run in CI environment #testing #automation
[ci] Failures block merging to protect main branch #testing #quality

## Key Benefits

[benefit] Confidence: Know features work before deploying #testing #production
[benefit] Regression prevention: Tests catch breaking changes #testing #quality
[benefit] Documentation: Tests show how features work #testing #examples
[benefit] Onboarding: New developers verify setup quickly #testing #dx
[benefit] Tracking: GitHub issues provide test coverage visibility #testing #management

## Testing Documentation Files

[doc] QUICKSTART_TESTING.md - Step-by-step verification guide #documentation #quickstart
[doc] docs/CREATING_TEST_ISSUES.md - Issue creation instructions #documentation #management
[doc] docs/PROPOSED_TEST_ISSUES.md - Detailed test specifications #documentation #specification
[doc] scripts/create-test-issues.sh - Automated issue creation script #documentation #automation
[doc] TESTING_IMPLEMENTATION_SUMMARY.md - Implementation overview #documentation #summary

## Related Documentation

- [[RLS Policy Guide]] - Row Level Security testing details
- [[Storage Configuration Guide]] - Storage testing details
- [[Realtime Guide]] - Realtime testing details
- [[Edge Functions]] - Function testing details
- [[Contributing Guide]] - Development guidelines
- [[Development Workflows]] - Workflow procedures

## Source Files Consolidated

This guide consolidates information from:
- TESTING_IMPLEMENTATION_SUMMARY.md (285 lines) - Complete testing infrastructure overview
- TESTING_INDEX.md (143 lines) - Quick reference to all testing documentation

All source files have been merged into this comprehensive semantic guide.
