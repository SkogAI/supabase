-- Enhanced RLS Policies Migration
-- Created: 2025-10-05
-- Description: Comprehensive RLS policies with service role, anonymous access, and enhanced security

-- ============================================================================
-- SERVICE ROLE BYPASS POLICIES
-- ============================================================================
-- Service role (postgres role) can bypass RLS for admin operations
-- These policies allow the service role to perform any operation

-- Service role can manage all profiles
CREATE POLICY "Service role can manage all profiles"
    ON public.profiles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Service role can manage all posts
CREATE POLICY "Service role can manage all posts"
    ON public.posts
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- ANONYMOUS ACCESS POLICIES
-- ============================================================================
-- Allow anonymous users to view published content (read-only)

-- Anonymous users can view all public profiles
CREATE POLICY "Anonymous users can view profiles"
    ON public.profiles
    FOR SELECT
    TO anon
    USING (true);

-- Anonymous users can view published posts
CREATE POLICY "Anonymous users can view published posts"
    ON public.posts
    FOR SELECT
    TO anon
    USING (published = true);

-- ============================================================================
-- AUTHENTICATED USER POLICIES
-- ============================================================================
-- Enhanced policies for authenticated users with better security

-- Authenticated users can view all profiles
CREATE POLICY "Authenticated users can view profiles"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- Authenticated users can only insert their own profile (security enhancement)
CREATE POLICY "Authenticated users can insert own profile"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Authenticated users can only update their own profile (security enhancement)
CREATE POLICY "Authenticated users can update own profile"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Authenticated users can delete their own profile (new policy)
CREATE POLICY "Authenticated users can delete own profile"
    ON public.profiles
    FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- Authenticated users can view published posts and their own drafts
CREATE POLICY "Authenticated users can view posts"
    ON public.posts
    FOR SELECT
    TO authenticated
    USING (published = true OR auth.uid() = user_id);

-- Authenticated users can create posts (must be their own)
CREATE POLICY "Authenticated users can create posts"
    ON public.posts
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Authenticated users can update their own posts
CREATE POLICY "Authenticated users can update own posts"
    ON public.posts
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Authenticated users can delete their own posts
CREATE POLICY "Authenticated users can delete own posts"
    ON public.posts
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- REMOVE OLD GENERIC POLICIES
-- ============================================================================
-- Drop the old generic policies that didn't specify roles
-- The new role-specific policies above provide more granular control

-- Remove old profile policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

-- Remove old post policies
DROP POLICY IF EXISTS "Published posts are viewable by everyone" ON public.posts;
DROP POLICY IF EXISTS "Users can create their own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can delete their own posts" ON public.posts;

-- ============================================================================
-- POLICY DOCUMENTATION
-- ============================================================================
-- Document the purpose and security model of each table's policies

COMMENT ON TABLE public.profiles IS 'User profiles with RLS policies:
- Service role: Full access for admin operations
- Authenticated users: Can view all profiles, manage own profile only
- Anonymous users: Can view all profiles (read-only)
- Users can only modify their own profile data';

COMMENT ON TABLE public.posts IS 'User-generated content with RLS policies:
- Service role: Full access for admin operations
- Authenticated users: Can view published posts + own drafts, manage own posts only
- Anonymous users: Can view published posts only (read-only)
- Users can only modify their own posts';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Use these queries to verify RLS policies are working correctly
-- Run in SQL editor with different auth contexts

/*
-- Test as authenticated user:
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
SELECT * FROM public.profiles; -- Should see all profiles
SELECT * FROM public.posts; -- Should see published + own drafts
UPDATE public.profiles SET bio = 'test' WHERE id = '00000000-0000-0000-0000-000000000001'; -- Should succeed
UPDATE public.profiles SET bio = 'test' WHERE id = '00000000-0000-0000-0000-000000000002'; -- Should fail

-- Test as anonymous user:
SET ROLE anon;
SELECT * FROM public.profiles; -- Should see all profiles
SELECT * FROM public.posts; -- Should see only published posts
INSERT INTO public.profiles (id, username) VALUES (uuid_generate_v4(), 'hacker'); -- Should fail
UPDATE public.posts SET published = true WHERE id = 'some-id'; -- Should fail

-- Reset to service role:
RESET ROLE;
SELECT * FROM public.profiles; -- Should see all profiles
UPDATE public.profiles SET bio = 'admin edit' WHERE id = 'any-id'; -- Should succeed
*/
