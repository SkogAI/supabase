---
title: Row Level Security
type: note
permalink: concepts/row-level-security
tags:
- security
- rls
- postgresql
- access-control
---

# Row Level Security (RLS)

## Overview

PostgreSQL Row Level Security provides fine-grained access control at the database layer, ensuring data security that cannot be bypassed by client applications.

## Core Concepts

- [concept] Security enforced at database layer, not application layer
- [concept] Policies define who can access which rows
- [concept] Works with all access methods (REST, GraphQL, direct SQL)
- [concept] Single source of truth for security rules
- [concept] Uses JWT claims for user identification via auth.uid()

## Three-Tier Role System

- [role] **anon** - Unauthenticated users, read-only access to public data
- [role] **authenticated** - Logged-in users, can manage own data
- [role] **service_role** - Backend services, full admin access, bypasses RLS

## Policy Structure

- [pattern] Enable RLS on table: `ALTER TABLE table ENABLE ROW LEVEL SECURITY`
- [pattern] Service role gets full access with `FOR ALL TO service_role`
- [pattern] Authenticated users get filtered access with `auth.uid() = user_id`
- [pattern] Anonymous users get public-only with status checks
- [pattern] Separate USING (read) and WITH CHECK (write) clauses

## Common Policy Patterns

- [pattern] Users manage own data: `USING (auth.uid() = user_id)`
- [pattern] View all, manage own: Two policies for SELECT and INSERT/UPDATE/DELETE
- [pattern] Published content only: `USING (status = 'published')`
- [pattern] Role-based access: Check user role from profiles table
- [pattern] Time-based access: Check timestamps for validity

## Testing Strategy

- [testing] Use `SET request.jwt.claim.sub` to simulate users
- [testing] Test all three roles: anon, authenticated, service_role
- [testing] Verify cross-user access prevention
- [testing] Check both read and write operations
- [testing] Automated test suite in `tests/rls_test_suite.sql`

## Best Practices

- [best-practice] Always enable RLS on public tables
- [best-practice] Create service role policy first for admin access
- [best-practice] Test policies thoroughly before deployment
- [best-practice] Use helper functions for complex logic
- [best-practice] Document policy intent in comments
- [best-practice] Keep policies simple and readable

## Performance Considerations

- [optimization] RLS has minimal performance overhead
- [optimization] Index columns used in policy conditions
- [optimization] Avoid complex subqueries in policies
- [optimization] Use security definer functions for expensive checks

## Security Benefits

- [benefit] Cannot be bypassed by malicious clients
- [benefit] Centralized security logic
- [benefit] Works automatically with auto-generated APIs
- [benefit] Audit trail at database level
- [benefit] Defence in depth security model

## Relations

- part_of [[Project Architecture]]
- part_of [[Supabase Project Overview]]
- implements [[Security Model]]
- tested_by [[RLS Test Suite]]
- documented_in [[RLS_POLICIES.md]]
- documented_in [[RLS_TESTING.md]]
- applies_to [[Database Schema Organization]]
- applies_to [[Storage Architecture]]
- uses [[JWT Authentication]]
