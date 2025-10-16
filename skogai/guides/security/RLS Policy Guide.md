---
<<<<<<< HEAD
title: RLS Policy Complete Guide
=======
title: RLS Policy Guide
>>>>>>> heutonasueno
type: note
permalink: guides/security/rls-policy-guide
tags:
- security
- rls
- policies
- postgresql
- access-control
<<<<<<< HEAD
- testing
- implementation
- consolidated
---

# RLS Policy Complete Guide

Complete guide to Row Level Security policies with patterns, best practices, implementation details, and comprehensive testing strategies.
=======
---

# RLS Policy Guide

Complete guide to Row Level Security policies with patterns, best practices, and testing strategies.
>>>>>>> heutonasueno

## Overview

[concept] RLS is PostgreSQL feature controlling which rows users can access #security #postgresql
[concept] RLS is primary security mechanism in Supabase for data protection #supabase #security
[benefit] Security enforced at database layer, not application layer #architecture #security
[benefit] Fine-grained control with different policies for SELECT, INSERT, UPDATE, DELETE #granularity #access
[benefit] Role-based access with rules for service_role, authenticated, and anon #roles #access
[benefit] Database-level enforcement cannot be bypassed by application code #security #guarantee

## Current Implementation

[status] All public schema tables have RLS enabled #security #configuration
[implementation] profiles table has RLS with service role, authenticated, and anonymous policies #table #policies
[implementation] posts table has RLS with service role, authenticated, and anonymous policies #table #policies

## Policy Pattern 1: Public Read, Authenticated Write

[usecase] Content viewable by anyone, only authenticated users can create/modify own #access #pattern
[pattern] Enable RLS with `ALTER TABLE table ENABLE ROW LEVEL SECURITY` #sql #security
[pattern] Public read policy uses `FOR SELECT USING (published = true)` #sql #readonly
[pattern] Authenticated create policy uses `FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id)` #sql #create
[pattern] Authenticated update policy uses `FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id)` #sql #modify
[constraint] USING clause checks if user can see existing row #sql #read
[constraint] WITH CHECK clause checks if new values are allowed #sql #write

## Policy Pattern 2: User-Owned Resources

[usecase] Users can only see and modify their own data #access #ownership
[pattern] View own profile policy uses `FOR SELECT TO authenticated USING (auth.uid() = id)` #sql #read
[pattern] Update own profile policy uses `FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id)` #sql #modify
[security] User ID comparison prevents access to other users' data #access #isolation

## Policy Pattern 3: Service Role Bypass

[usecase] Admin operations need to bypass RLS for full access #admin #access
[pattern] Service role policy uses `FOR ALL TO service_role USING (true) WITH CHECK (true)` #sql #admin
[warning] Never expose service_role key to clients - server-side only #security #critical
[usage] Service role used for admin operations, cron jobs, server-side functions #backend #admin

## Policy Pattern 4: Anonymous Read Access

[usecase] Unauthenticated users can view public content #access #public
[pattern] Anonymous policy uses `FOR SELECT TO anon USING (published = true)` #sql #readonly
[restriction] Anonymous role most restrictive, typically read-only #security #access

## Policy Pattern 5: Conditional Access

[usecase] Access based on relationships or specific conditions #access #complex
[pattern] Conditional policy uses EXISTS subquery to check relationships #sql #subquery
[example] Users view followed posts with `EXISTS (SELECT 1 FROM follows WHERE follower_id = auth.uid())` #sql #relation
[pattern] OR condition allows users to also view their own content #sql #logic

## Supabase Roles

[role] service_role has full access bypassing RLS - admin operations only #admin #access
[role] authenticated represents logged-in users subject to RLS policies #user #access
[role] anon represents unauthenticated users with most restrictive access #public #access
[function] `auth.uid()` returns current user's ID for policy checks #supabase #helper
[function] `auth.jwt()` returns JWT claims for metadata access #supabase #helper
[check] `auth.uid() = user_id` verifies user owns resource #security #ownership
[check] `auth.uid() IS NOT NULL` verifies user is authenticated #security #authentication

## Common Policy Examples

[example] "Anyone can view profiles" uses `FOR SELECT USING (true)` #sql #public
[example] "Users update own profile" uses `FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id)` #sql #ownership
[example] "Users see published + own drafts" uses `USING (published = true OR auth.uid() = user_id)` #sql #conditional
[example] "Prevent changing ownership" uses additional check comparing old and new user_id #sql #immutable
[example] "Time-based access" uses `created_at > NOW() - INTERVAL '1 hour'` #sql #temporal

## Security Best Practices - DO

[bestpractice] Always enable RLS on public tables with `ALTER TABLE table ENABLE ROW LEVEL SECURITY` #security #requirement
[bestpractice] Use role-specific policies with explicit TO clause #security #explicit
[bestpractice] Use USING for read access and WITH CHECK for write access #security #separation
[bestpractice] Test policies with different roles using SET commands #testing #validation
[bestpractice] Document policies with COMMENT ON POLICY #documentation #maintenance
[example] Better: `CREATE POLICY "name" ON table FOR SELECT TO authenticated USING (...)` #sql #explicit
[example] Avoid: `CREATE POLICY "name" ON table FOR SELECT USING (...)` implicit all roles #sql #implicit

## Security Best Practices - DON'T

[warning] Don't disable RLS on public tables - creates security vulnerability #security #critical
[warning] Don't expose service_role key in client-side code or git #security #critical
[warning] Don't use overly permissive policies like `USING (true)` without role restriction #security #risk
[warning] Don't forget WITH CHECK on INSERT/UPDATE operations #security #incomplete
[warning] Don't rely solely on client-side checks - always enforce at database #security #defense

## Policy Naming Convention

[convention] Format: "[Role] [Action] [Condition]" for descriptive names #naming #documentation
[example] Good: "Authenticated users can view own posts" #naming #descriptive
[example] Good: "Service role can manage all profiles" #naming #descriptive
[example] Good: "Anonymous users can view published posts" #naming #descriptive
[example] Bad: "policy_1" - not descriptive #naming #poor
[example] Bad: "select_policy" - too generic #naming #poor

## Testing RLS Policies

[command] `npm run test:rls` runs comprehensive RLS test suite #testing #automation
[test] Test as authenticated user with `SELECT set_config('request.jwt.claim.sub', 'uuid', true)` #testing #simulation
[test] Test as anonymous with `SET ROLE anon` #testing #simulation
[test] Reset to service role with `RESET ROLE` #testing #cleanup
[validation] Verify RLS enabled with query on pg_tables checking rowsecurity column #testing #verification
[validation] View all policies with query on pg_policies table #testing #inspection

## Troubleshooting

[issue] Policy not working - check if RLS is enabled with pg_tables query #troubleshooting #verification
[issue] Policy not working - check policy order, policies are OR'd together #troubleshooting #logic
[issue] Policy not working - test with explicit role using SET ROLE #troubleshooting #isolation
[issue] Policy not working - check for conflicting policies with \d+ command #troubleshooting #inspection
[error] "Row level security is enabled but no policy exists" - create at least one policy per operation #troubleshooting #fix
[error] "Permission denied for table" - check if RLS enabled and policies exist for role #troubleshooting #fix
[error] "Infinite recursion in RLS policy" - avoid circular references in conditions #troubleshooting #fix

## Quick Test Pattern

[snippet] Test as authenticated: `SELECT set_config('request.jwt.claim.sub', 'test-uuid', true); SELECT * FROM profiles;` #testing #sql
[snippet] Test as anonymous: `SET ROLE anon; SELECT * FROM posts; RESET ROLE;` #testing #sql
[snippet] Verify RLS: `SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';` #testing #sql
[snippet] View policies: `SELECT * FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;` #testing #sql

## Policy Structure Components

[component] Policy name in quotes describes purpose #sql #documentation
[component] Table name specifies which table policy applies to #sql #target
[component] Operation (FOR) specifies SELECT, INSERT, UPDATE, DELETE, or ALL #sql #operation
[component] Role (TO) specifies service_role, authenticated, anon, or public #sql #role
[component] USING clause defines conditions for viewing existing rows #sql #read
[component] WITH CHECK clause defines conditions for new or updated values #sql #write

## Migration History

[migration] 20251005065505_initial_schema.sql created initial RLS policies for profiles and posts #history #database
[migration] 20251005053101_enhanced_rls_policies.sql enhanced with role-specific policies #history #database

<<<<<<< HEAD
## Implementation Summary

[summary] Comprehensive RLS implementation with 12 policies across 2 tables #implementation #overview
[implementation] Migration 20251005053101_enhanced_rls_policies.sql created role-specific policies #migration #database
[testing] Comprehensive test suite at tests/rls_test_suite.sql validates all policies #testing #automation
[testing] npm script test:rls runs full RLS validation suite #testing #workflow
[documentation] Complete implementation covering service role, authenticated, and anonymous access #security #comprehensive

### Policy Coverage

[coverage-profiles] Profiles table has 6 policies: 1 service_role, 4 authenticated, 1 anon #table #policies
[coverage-posts] Posts table has 6 policies: 1 service_role, 4 authenticated, 1 anon #table #policies
[policy] Service role policies grant full admin access bypassing all restrictions #admin #access
[policy] Authenticated policies allow SELECT all, INSERT/UPDATE/DELETE own only #user #access
[policy] Anonymous policies allow SELECT published content only, no modifications #public #readonly

### Access Control Matrix

[access] Service role can view all profiles, posts (published + drafts) #admin #full-access
[access] Authenticated users can view all profiles, published posts + own drafts #user #conditional
[access] Authenticated users can create/update/delete own profiles and posts only #user #ownership
[access] Anonymous users can view all profiles, published posts only #public #readonly
[access] Anonymous users cannot create/update/delete any data #public #readonly
[restriction] Users cannot view other users' draft posts #security #isolation
[restriction] Users cannot modify other users' profiles or posts #security #ownership

## Testing RLS - Local Testing

[test-local] Start Supabase with `npm run db:start` for local testing #workflow #setup
[test-local] Reset database with `npm run db:reset` to apply migrations and seed data #workflow #setup
[test-local] Access Studio at http://localhost:8000 for SQL Editor testing #workflow #ui
[test-local] SQL Editor runs as service role by default bypassing RLS #testing #context

### Testing Different User Contexts

[test-auth] Set JWT claim to simulate authenticated user: `SELECT set_config('request.jwt.claim.sub', 'uuid', true)` #testing #simulation
[test-auth] Reset JWT claim with `SELECT set_config('request.jwt.claim.sub', NULL, true)` #testing #cleanup
[test-anon] Switch to anonymous role with `SET ROLE anon` #testing #simulation
[test-anon] Reset from anonymous role with `RESET ROLE` #testing #cleanup
[test-service] Service role is default in SQL Editor, has full access #testing #admin

### Seed Data for Testing

[seed] Alice user: 00000000-0000-0000-0000-000000000001 (alice@example.com) #testing #data
[seed] Bob user: 00000000-0000-0000-0000-000000000002 (bob@example.com) #testing #data
[seed] Charlie user: 00000000-0000-0000-0000-000000000003 (charlie@example.com) #testing #data
[seed] All test users have password "password123" #testing #auth
[test-example] Test Alice accessing data: `SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true)` #testing #example

## Testing RLS - Automated Test Suite

[test-suite] Comprehensive SQL test suite at tests/rls_test_suite.sql (11KB+) #testing #automation
[test-suite] Run with `npm run test:rls` command #testing #workflow
[test-validation] Validates RLS enabled on all public tables #testing #verification
[test-validation] Validates service role has full access #testing #admin
[test-validation] Validates authenticated users can view all public data #testing #user
[test-validation] Validates authenticated users can only modify own data #testing #ownership
[test-validation] Validates anonymous users have read-only access #testing #readonly
[test-validation] Validates anonymous users cannot modify any data #testing #restriction
[test-validation] Validates cross-user access restrictions #testing #isolation
[test-validation] Validates service role can bypass restrictions #testing #admin

### Expected Test Output

[output] All tests show "✅ PASS" with descriptions #testing #success
[output] Test suite reports "TEST SUITE COMPLETE - All tests passed!" #testing #validation
[test-failure] Any failures indicate policy misconfiguration requiring investigation #testing #troubleshooting

## Testing RLS - JavaScript/TypeScript

[test-js] Use @supabase/supabase-js client for integration testing #testing #client
[test-js] Create anonymous client with anon key for public access tests #testing #anonymous
[test-js] Create authenticated client after signInWithPassword for user tests #testing #authenticated
[test-js] Create service client with service_role key for admin tests #testing #admin
[test-example] Test anonymous read: `supabase.from('posts').select().eq('published', true)` #testing #sql
[test-example] Test authenticated update: `supabase.from('profiles').update({bio}).eq('id', user.id)` #testing #sql
[test-assertion] Expect error=null for allowed operations #testing #validation
[test-assertion] Expect data=[] (empty array) for blocked operations #testing #validation

## Testing RLS - CI/CD Integration

[ci] GitHub Actions workflow schema-lint.yml includes RLS validation #ci #automation
[ci] Workflow checks for tables without RLS policies #ci #validation
[ci] Workflow runs test suite with `supabase db execute --file tests/rls_test_suite.sql` #ci #testing
[ci] CI fails if any tables lack RLS or tests fail #ci #security
[integration] Add custom RLS tests to migration validation workflow #ci #customization

## Testing Scenarios - Common Patterns

[scenario] User registration creates profile via trigger, user can update own profile #testing #workflow
[scenario] Post creation as draft, user sees own draft, others cannot #testing #privacy
[scenario] Post publishing makes content visible to anonymous users #testing #access
[scenario] Data breach attempts blocked by RLS at database level #testing #security
[test-breach] Anonymous user attempts INSERT on posts table - should fail #testing #attack
[test-breach] Authenticated user attempts UPDATE on other user's post - should affect 0 rows #testing #attack
[test-breach] Anonymous user attempts to view auth.users emails - should error #testing #attack

## Production Readiness

[production] Review all policies before deployment to prevent data exposure #deployment #security
[production] Test with real user scenarios not just unit tests #deployment #validation
[production] Monitor for unauthorized access attempts in production logs #deployment #monitoring
[production] Regularly audit policy effectiveness and coverage #deployment #maintenance

### Adding New Tables

[workflow] Enable RLS: `ALTER TABLE table ENABLE ROW LEVEL SECURITY` #workflow #setup
[workflow] Add service role policy with `FOR ALL TO service_role USING (true) WITH CHECK (true)` #workflow #admin
[workflow] Add authenticated policies with appropriate USING/WITH CHECK conditions #workflow #user
[workflow] Add anonymous policy if public read access needed #workflow #public
[workflow] Document policies with `COMMENT ON TABLE` statements #workflow #documentation
[workflow] Add table to tests/rls_test_suite.sql for validation #workflow #testing

## Key Takeaways

[takeaway] RLS enforced at database level, cannot be bypassed by application code #security #guarantee
[takeaway] Role-based policies for service_role, authenticated, and anon #security #roles
[takeaway] Comprehensive automated test suite validates all policies #testing #automation
[takeaway] Complete documentation guides understanding and extending policies #documentation #maintenance
[takeaway] Clear patterns and examples for adding new tables #documentation #scalability
[takeaway] Defense in depth with multiple validation layers #security #architecture

=======
>>>>>>> heutonasueno
## Related Documentation

- [[Row Level Security]] - Core RLS concept
- [[Contributing Guide]] - Development guidelines
- [[Development Workflows]] - Workflow procedures
- [[Storage Architecture]] - Storage bucket security
- [[PostgreSQL Database]] - Database configuration
- [[Authentication System]] - User authentication
<<<<<<< HEAD

## Source Files Consolidated

This guide consolidates information from:
- RLS_POLICIES.md (428 lines) - Policy patterns, best practices, troubleshooting
- RLS_IMPLEMENTATION_SUMMARY.md (242 lines) - Implementation details, policy coverage, access matrix
- RLS_TESTING.md (591 lines) - Testing guidelines, test suite details, CI/CD integration

All source files have been merged into this comprehensive semantic guide.
=======
>>>>>>> heutonasueno
