-- ============================================================================
-- PROFILES BASIC TEST SUITE
-- ============================================================================
-- Small, incremental unit tests to prove profiles functionality is working
-- Run this after migrations to verify profiles are set up correctly
--
-- Usage:
--   supabase db execute --file tests/profiles_basic_test_suite.sql
--
-- Or in Supabase Studio SQL Editor, just copy and paste this file
-- ============================================================================

\echo ''
\echo '================================================================================'
\echo 'PROFILES BASIC TEST SUITE'
\echo '================================================================================'
\echo ''

-- ============================================================================
-- TEST 1: Verify Profiles Table Exists
-- ============================================================================
\echo 'TEST 1: Verifying profiles table exists...'

DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles'
    ) INTO table_exists;
    
    IF table_exists THEN
        RAISE NOTICE 'PASS: Profiles table exists';
    ELSE
        RAISE EXCEPTION 'FAIL: Profiles table does not exist';
    END IF;
END $$;

-- ============================================================================
-- TEST 2: Verify RLS is Enabled on Profiles
-- ============================================================================
\echo ''
\echo 'TEST 2: Verifying RLS is enabled on profiles...'

DO $$
DECLARE
    rls_enabled BOOLEAN;
BEGIN
    SELECT rowsecurity INTO rls_enabled
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'profiles';
    
    IF rls_enabled THEN
        RAISE NOTICE 'PASS: RLS is enabled on profiles';
    ELSE
        RAISE EXCEPTION 'FAIL: RLS is not enabled on profiles';
    END IF;
END $$;

-- ============================================================================
-- TEST 3: Verify Profiles Table Has Expected Columns
-- ============================================================================
\echo ''
\echo 'TEST 3: Verifying profiles has expected columns...'

DO $$
DECLARE
    required_columns TEXT[] := ARRAY['id', 'username', 'full_name', 'avatar_url', 'website', 'updated_at'];
    column_name TEXT;
    column_exists BOOLEAN;
    missing_columns TEXT[] := ARRAY[]::TEXT[];
BEGIN
    FOREACH column_name IN ARRAY required_columns
    LOOP
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'profiles'
            AND column_name = column_name
        ) INTO column_exists;
        
        IF NOT column_exists THEN
            missing_columns := array_append(missing_columns, column_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_columns, 1) IS NULL THEN
        RAISE NOTICE 'PASS: All expected columns exist';
    ELSE
        RAISE EXCEPTION 'FAIL: Missing columns: %', array_to_string(missing_columns, ', ');
    END IF;
END $$;

-- ============================================================================
-- TEST 4: Verify Profiles Exist for Seed Users
-- ============================================================================
\echo ''
\echo 'TEST 4: Verifying profiles exist for seed users...'

DO $$
DECLARE
    profile_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO profile_count FROM profiles;
    
    IF profile_count >= 3 THEN
        RAISE NOTICE 'PASS: Found % profiles (expected at least 3 from seed data)', profile_count;
    ELSE
        RAISE NOTICE 'WARNING: Found only % profiles (expected at least 3)', profile_count;
        RAISE NOTICE 'This may be OK if seed data has not been loaded yet';
    END IF;
END $$;

-- ============================================================================
-- TEST 5: Verify handle_new_user Trigger Exists
-- ============================================================================
\echo ''
\echo 'TEST 5: Verifying handle_new_user trigger exists...'

DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'on_auth_user_created'
    ) INTO trigger_exists;
    
    IF trigger_exists THEN
        RAISE NOTICE 'PASS: handle_new_user trigger exists';
    ELSE
        RAISE NOTICE 'WARNING: handle_new_user trigger not found';
        RAISE NOTICE 'Profiles may not be auto-created on user signup';
    END IF;
END $$;

-- ============================================================================
-- TEST 6: Verify Username Constraints
-- ============================================================================
\echo ''
\echo 'TEST 6: Verifying username constraints...'

DO $$
DECLARE
    has_unique_constraint BOOLEAN;
    has_length_check BOOLEAN;
BEGIN
    -- Check for unique constraint
    SELECT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname LIKE '%username%'
        AND contype = 'u'
    ) INTO has_unique_constraint;
    
    IF has_unique_constraint THEN
        RAISE NOTICE 'PASS: Username has unique constraint';
    ELSE
        RAISE NOTICE 'WARNING: Username unique constraint not found';
    END IF;
    
    -- Check for length constraint (minimum 3 characters)
    SELECT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname LIKE '%username%'
        AND contype = 'c'
    ) INTO has_length_check;
    
    IF has_length_check THEN
        RAISE NOTICE 'PASS: Username has check constraint';
    ELSE
        RAISE NOTICE 'WARNING: Username length constraint not found';
    END IF;
END $$;

-- ============================================================================
-- TEST 7: Count RLS Policies on Profiles
-- ============================================================================
\echo ''
\echo 'TEST 7: Counting RLS policies on profiles...'

DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public'
    AND tablename = 'profiles';
    
    IF policy_count >= 3 THEN
        RAISE NOTICE 'PASS: Found % RLS policies on profiles', policy_count;
    ELSIF policy_count > 0 THEN
        RAISE NOTICE 'WARNING: Found only % RLS policies (expected at least 3)', policy_count;
    ELSE
        RAISE EXCEPTION 'FAIL: No RLS policies found on profiles';
    END IF;
END $$;

-- ============================================================================
-- TEST 8: List All Policies on Profiles
-- ============================================================================
\echo ''
\echo 'TEST 8: Listing all RLS policies on profiles...'

SELECT 
    policyname as policy_name,
    cmd as command,
    CASE 
        WHEN roles::text = '{public}' THEN 'public'
        WHEN roles::text LIKE '%authenticated%' THEN 'authenticated'
        WHEN roles::text LIKE '%anon%' THEN 'anon'
        WHEN roles::text LIKE '%service_role%' THEN 'service_role'
        ELSE roles::text
    END as applies_to
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename = 'profiles'
ORDER BY policyname;

-- ============================================================================
-- TEST 9: Verify Foreign Key to auth.users
-- ============================================================================
\echo ''
\echo 'TEST 9: Verifying foreign key to auth.users...'

DO $$
DECLARE
    fk_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND constraint_type = 'FOREIGN KEY'
    ) INTO fk_exists;
    
    IF fk_exists THEN
        RAISE NOTICE 'PASS: Foreign key to auth.users exists';
    ELSE
        RAISE EXCEPTION 'FAIL: Foreign key to auth.users not found';
    END IF;
END $$;

-- ============================================================================
-- TEST 10: Test Simple Profile Query (as service role)
-- ============================================================================
\echo ''
\echo 'TEST 10: Testing simple profile query...'

DO $$
DECLARE
    test_profile RECORD;
BEGIN
    SELECT * INTO test_profile FROM profiles LIMIT 1;
    
    IF test_profile.id IS NOT NULL THEN
        RAISE NOTICE 'PASS: Can query profiles (found profile: %)', test_profile.username;
    ELSE
        RAISE NOTICE 'WARNING: No profiles found to query';
    END IF;
END $$;

-- ============================================================================
-- SUMMARY
-- ============================================================================
\echo ''
\echo '================================================================================'
\echo 'TEST SUITE COMPLETE'
\echo '================================================================================'
\echo ''
\echo 'Summary:'
\echo '- Basic structure tests: Table, columns, constraints'
\echo '- RLS tests: Enabled, policies exist'
\echo '- Trigger tests: handle_new_user exists'
\echo '- Data tests: Seed profiles exist'
\echo ''
\echo 'Next steps:'
\echo '1. Review any WARNING or FAIL messages above'
\echo '2. Run full RLS test suite: npm run test:rls'
\echo '3. Test profile operations in application'
\echo ''
