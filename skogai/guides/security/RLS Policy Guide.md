---
title: RLS Policy Guide
type: note
permalink: guides/security/rls-policy-guide
tags:
- security
- rls
- policies
- postgresql
- access-control
- testing
- implementation
---

# RLS Policy Guide

Complete guide to Row Level Security policies with patterns, best practices, and testing strategies.

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
## Related Documentation

- [[Row Level Security]] - Core RLS concept
- [[Contributing Guide]] - Development guidelines
- [[Development Workflows]] - Workflow procedures
- [[Storage Architecture]] - Storage bucket security
- [[PostgreSQL Database]] - Database configuration
- [[Authentication System]] - User authentication
