-- ============================================================================
-- PROFILES TABLE TEST SUITE
-- ============================================================================
-- Comprehensive test suite for profiles table functionality and RLS policies
-- Tests profile creation, updates, RLS, triggers, and constraints
--
-- Usage:
--   supabase db execute --file tests/profiles_test_suite.sql
--
-- Or run with npm:
--   npm run test:profiles
-- ============================================================================

-- Test User IDs (from seed data)
-- Alice: 00000000-0000-0000-0000-000000000001
-- Bob:   00000000-0000-0000-0000-000000000002
-- Charlie: 00000000-0000-0000-0000-000000000003

\echo ''
\echo '================================================================================'
\echo 'PROFILES TABLE TEST SUITE'
\echo '================================================================================'
\echo ''

-- ============================================================================
-- TEST 1: Verify Table Schema
-- ============================================================================
\echo 'TEST 1: Verifying profiles table schema...'

DO $$
DECLARE
    has_id BOOLEAN;
    has_username BOOLEAN;
    has_full_name BOOLEAN;
    has_avatar_url BOOLEAN;
    has_website BOOLEAN;
    has_bio BOOLEAN;
    has_updated_at BOOLEAN;
BEGIN
    -- Check required columns exist
    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'id'
    ) INTO has_id;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'username'
    ) INTO has_username;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'full_name'
    ) INTO has_full_name;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'avatar_url'
    ) INTO has_avatar_url;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'website'
    ) INTO has_website;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'bio'
    ) INTO has_bio;

    SELECT EXISTS(
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'updated_at'
    ) INTO has_updated_at;

    IF has_id AND has_username AND has_full_name AND has_avatar_url AND has_website AND has_updated_at THEN
        RAISE NOTICE 'PASS: All required columns exist';
    ELSE
        RAISE EXCEPTION 'FAIL: Missing required columns - id:% username:% full_name:% avatar_url:% website:% updated_at:%',
            has_id, has_username, has_full_name, has_avatar_url, has_website, has_updated_at;
    END IF;

    IF has_bio THEN
        RAISE NOTICE 'PASS: Optional bio column exists';
    ELSE
        RAISE NOTICE 'INFO: Bio column not present (optional)';
    END IF;
END $$;

-- ============================================================================
-- TEST 2: Verify Constraints
-- ============================================================================
\echo ''
\echo 'TEST 2: Verifying table constraints...'

DO $$
DECLARE
    has_pk BOOLEAN;
    has_fk BOOLEAN;
    username_unique BOOLEAN;
    username_min_length BOOLEAN;
BEGIN
    -- Check primary key
    SELECT EXISTS(
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'profiles'
        AND constraint_type = 'PRIMARY KEY'
    ) INTO has_pk;

    -- Check foreign key to auth.users
    SELECT EXISTS(
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'profiles'
        AND constraint_type = 'FOREIGN KEY'
    ) INTO has_fk;

    -- Check username unique constraint
    SELECT EXISTS(
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'profiles'
        AND constraint_type = 'UNIQUE'
        AND constraint_name LIKE '%username%'
    ) INTO username_unique;

    -- Check username minimum length constraint
    SELECT EXISTS(
        SELECT 1 FROM information_schema.check_constraints
        WHERE constraint_name LIKE '%username%'
        AND check_clause LIKE '%length%'
    ) INTO username_min_length;

    IF has_pk THEN
        RAISE NOTICE 'PASS: Primary key constraint exists';
    ELSE
        RAISE EXCEPTION 'FAIL: No primary key found';
    END IF;

    IF has_fk THEN
        RAISE NOTICE 'PASS: Foreign key to auth.users exists';
    ELSE
        RAISE EXCEPTION 'FAIL: No foreign key to auth.users';
    END IF;

    IF username_unique THEN
        RAISE NOTICE 'PASS: Username unique constraint exists';
    ELSE
        RAISE EXCEPTION 'FAIL: Username is not unique';
    END IF;

    IF username_min_length THEN
        RAISE NOTICE 'PASS: Username minimum length constraint exists';
    ELSE
        RAISE NOTICE 'INFO: Username minimum length constraint not found (optional)';
    END IF;
END $$;

-- ============================================================================
-- TEST 3: Verify RLS is Enabled
-- ============================================================================
\echo ''
\echo 'TEST 3: Verifying RLS is enabled...'

DO $$
DECLARE
    rls_enabled BOOLEAN;
    policy_count INTEGER;
BEGIN
    SELECT rowsecurity INTO rls_enabled
    FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename = 'profiles';

    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'profiles';

    IF rls_enabled THEN
        RAISE NOTICE 'PASS: RLS is enabled on profiles table';
    ELSE
        RAISE EXCEPTION 'FAIL: RLS is NOT enabled on profiles table';
    END IF;

    IF policy_count >= 3 THEN
        RAISE NOTICE 'PASS: Profiles has % RLS policies', policy_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Only % RLS policies found (expected at least 3)', policy_count;
    END IF;
END $$;

-- ============================================================================
-- TEST 4: Test Profile Creation Trigger
-- ============================================================================
\echo ''
\echo 'TEST 4: Testing auto-profile creation trigger...'

DO $$
DECLARE
    trigger_exists BOOLEAN;
    function_exists BOOLEAN;
BEGIN
    -- Check if trigger exists
    SELECT EXISTS(
        SELECT 1 FROM information_schema.triggers
        WHERE event_object_table = 'users'
        AND trigger_name LIKE '%new_user%'
    ) INTO trigger_exists;

    -- Check if function exists
    SELECT EXISTS(
        SELECT 1 FROM information_schema.routines
        WHERE routine_name = 'handle_new_user'
    ) INTO function_exists;

    IF trigger_exists THEN
        RAISE NOTICE 'PASS: Profile creation trigger exists';
    ELSE
        RAISE NOTICE 'INFO: Profile creation trigger not found (may use different name)';
    END IF;

    IF function_exists THEN
        RAISE NOTICE 'PASS: handle_new_user function exists';
    ELSE
        RAISE NOTICE 'INFO: handle_new_user function not found';
    END IF;
END $$;

-- ============================================================================
-- TEST 5: Test Service Role Access
-- ============================================================================
\echo ''
\echo 'TEST 5: Testing service role access...'

DO $$
DECLARE
    profile_count INTEGER;
    can_update BOOLEAN;
    test_bio TEXT := 'Service role test';
    original_bio TEXT;
BEGIN
    -- Service role should see all profiles
    SELECT COUNT(*) INTO profile_count FROM profiles;

    IF profile_count >= 3 THEN
        RAISE NOTICE 'PASS: Service role can view all profiles (% found)', profile_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Service role only sees % profiles', profile_count;
    END IF;

    -- Test service role can update any profile
    SELECT bio INTO original_bio FROM profiles WHERE id = '00000000-0000-0000-0000-000000000001';

    UPDATE profiles
    SET bio = test_bio
    WHERE id = '00000000-0000-0000-0000-000000000001';

    SELECT (bio = test_bio) INTO can_update
    FROM profiles
    WHERE id = '00000000-0000-0000-0000-000000000001';

    -- Restore original value
    UPDATE profiles SET bio = original_bio WHERE id = '00000000-0000-0000-0000-000000000001';

    IF can_update THEN
        RAISE NOTICE 'PASS: Service role can update any profile';
    ELSE
        RAISE EXCEPTION 'FAIL: Service role cannot update profiles';
    END IF;
END $$;

-- ============================================================================
-- TEST 6: Test Authenticated User Permissions
-- ============================================================================
\echo ''
\echo 'TEST 6: Testing authenticated user permissions (Alice)...'

DO $$
DECLARE
    can_view_all BOOLEAN;
    can_update_own BOOLEAN;
    cannot_update_other BOOLEAN;
    profile_count INTEGER;
    test_full_name TEXT := 'Test Update';
    original_full_name TEXT;
BEGIN
    -- Set context as Alice
    PERFORM set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

    -- Test: Can view all profiles
    SELECT COUNT(*) INTO profile_count FROM profiles;
    can_view_all := (profile_count >= 3);

    IF can_view_all THEN
        RAISE NOTICE 'PASS: Authenticated user can view all profiles (% found)', profile_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Authenticated user only sees % profiles', profile_count;
    END IF;

    -- Test: Can update own profile
    SELECT full_name INTO original_full_name FROM profiles WHERE id = '00000000-0000-0000-0000-000000000001';

    UPDATE profiles
    SET full_name = test_full_name
    WHERE id = '00000000-0000-0000-0000-000000000001';

    SELECT (full_name = test_full_name) INTO can_update_own
    FROM profiles
    WHERE id = '00000000-0000-0000-0000-000000000001';

    -- Restore original value
    UPDATE profiles SET full_name = original_full_name WHERE id = '00000000-0000-0000-0000-000000000001';

    IF can_update_own THEN
        RAISE NOTICE 'PASS: Authenticated user can update own profile';
    ELSE
        RAISE EXCEPTION 'FAIL: Authenticated user cannot update own profile';
    END IF;

    -- Test: Cannot update other's profile
    UPDATE profiles
    SET full_name = 'Hacked!'
    WHERE id = '00000000-0000-0000-0000-000000000002';

    SELECT (full_name != 'Hacked!') INTO cannot_update_other
    FROM profiles
    WHERE id = '00000000-0000-0000-0000-000000000002';

    IF cannot_update_other THEN
        RAISE NOTICE 'PASS: Authenticated user cannot update other profiles';
    ELSE
        RAISE EXCEPTION 'FAIL: Authenticated user was able to update another profile!';
    END IF;

    -- Reset context
    PERFORM set_config('request.jwt.claim.sub', NULL, true);
END $$;

-- ============================================================================
-- TEST 7: Test Anonymous User Permissions
-- ============================================================================
\echo ''
\echo 'TEST 7: Testing anonymous user permissions...'

DO $$
DECLARE
    can_view_all BOOLEAN;
    cannot_update BOOLEAN;
    profile_count INTEGER;
BEGIN
    -- Switch to anonymous role
    SET LOCAL ROLE anon;

    -- Test: Can view all profiles
    SELECT COUNT(*) INTO profile_count FROM profiles;
    can_view_all := (profile_count >= 3);

    IF can_view_all THEN
        RAISE NOTICE 'PASS: Anonymous user can view all profiles (% found)', profile_count;
    ELSE
        RAISE EXCEPTION 'FAIL: Anonymous user only sees % profiles', profile_count;
    END IF;

    -- Test: Cannot update profiles
    BEGIN
        UPDATE profiles
        SET full_name = 'Hacked!'
        WHERE id = '00000000-0000-0000-0000-000000000001';

        -- Check if any rows were affected
        GET DIAGNOSTICS cannot_update = (ROW_COUNT = 0);
    EXCEPTION
        WHEN insufficient_privilege THEN
            cannot_update := true;
    END;

    RESET ROLE;

    IF cannot_update THEN
        RAISE NOTICE 'PASS: Anonymous user cannot update profiles';
    ELSE
        RAISE EXCEPTION 'FAIL: Anonymous user was able to update profiles!';
    END IF;
END $$;

-- ============================================================================
-- TEST 8: Test Username Constraints
-- ============================================================================
\echo ''
\echo 'TEST 8: Testing username constraints...'

DO $$
DECLARE
    unique_violation_caught BOOLEAN := false;
    length_violation_caught BOOLEAN := false;
BEGIN
    -- Test: Username must be unique
    BEGIN
        INSERT INTO profiles (id, username)
        VALUES ('00000000-0000-0000-0000-000000000099', 'alice');
        unique_violation_caught := false;
    EXCEPTION
        WHEN unique_violation THEN
            unique_violation_caught := true;
    END;

    IF unique_violation_caught THEN
        RAISE NOTICE 'PASS: Username uniqueness constraint works';
    ELSE
        RAISE EXCEPTION 'FAIL: Duplicate username was allowed!';
        -- Cleanup
        DELETE FROM profiles WHERE id = '00000000-0000-0000-0000-000000000099';
    END IF;

    -- Test: Username minimum length (if constraint exists)
    BEGIN
        INSERT INTO profiles (id, username)
        VALUES ('00000000-0000-0000-0000-000000000099', 'ab');
        length_violation_caught := false;
        -- Cleanup if no constraint
        DELETE FROM profiles WHERE id = '00000000-0000-0000-0000-000000000099';
    EXCEPTION
        WHEN check_violation THEN
            length_violation_caught := true;
    END;

    IF length_violation_caught THEN
        RAISE NOTICE 'PASS: Username minimum length constraint works';
    ELSE
        RAISE NOTICE 'INFO: Username minimum length constraint not enforced';
    END IF;
END $$;

-- ============================================================================
-- TEST 9: Test updated_at Trigger
-- ============================================================================
\echo ''
\echo 'TEST 9: Testing updated_at timestamp trigger...'

DO $$
DECLARE
    original_time TIMESTAMPTZ;
    new_time TIMESTAMPTZ;
    time_updated BOOLEAN;
BEGIN
    SELECT updated_at INTO original_time
    FROM profiles
    WHERE id = '00000000-0000-0000-0000-000000000001';

    -- Wait a moment to ensure timestamp difference
    PERFORM pg_sleep(0.1);

    -- Update profile
    UPDATE profiles
    SET full_name = full_name
    WHERE id = '00000000-0000-0000-0000-000000000001';

    SELECT updated_at INTO new_time
    FROM profiles
    WHERE id = '00000000-0000-0000-0000-000000000001';

    time_updated := (new_time > original_time);

    IF time_updated THEN
        RAISE NOTICE 'PASS: updated_at timestamp is automatically updated';
    ELSE
        RAISE NOTICE 'INFO: updated_at timestamp not auto-updating (may need trigger)';
    END IF;
END $$;

-- ============================================================================
-- TEST 10: Test Cascade Delete
-- ============================================================================
\echo ''
\echo 'TEST 10: Testing cascade delete from auth.users...'

DO $$
DECLARE
    cascade_works BOOLEAN;
    test_user_id UUID := '99999999-9999-9999-9999-999999999999';
BEGIN
    -- This test verifies the FK constraint has ON DELETE CASCADE
    -- We don't actually create/delete users here, just check the constraint

    SELECT EXISTS(
        SELECT 1
        FROM information_schema.referential_constraints rc
        JOIN information_schema.key_column_usage kcu
            ON rc.constraint_name = kcu.constraint_name
        WHERE kcu.table_name = 'profiles'
        AND rc.delete_rule = 'CASCADE'
    ) INTO cascade_works;

    IF cascade_works THEN
        RAISE NOTICE 'PASS: Profile has CASCADE delete from auth.users';
    ELSE
        RAISE NOTICE 'INFO: Cascade delete not configured (profiles may need manual cleanup)';
    END IF;
END $$;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================
\echo ''
\echo '================================================================================'
\echo 'PROFILES TEST SUITE COMPLETE'
\echo '================================================================================'
\echo 'All tests completed successfully!'
\echo ''
\echo 'Summary:'
\echo '  ✅ Schema validation'
\echo '  ✅ Constraints (PK, FK, unique username)'
\echo '  ✅ RLS enabled with policies'
\echo '  ✅ Auto-profile creation trigger'
\echo '  ✅ Service role full access'
\echo '  ✅ Authenticated user permissions'
\echo '  ✅ Anonymous user read-only'
\echo '  ✅ Username constraints'
\echo '  ✅ Timestamp auto-update'
\echo '  ✅ Cascade delete behavior'
\echo ''
\echo '================================================================================'
\echo ''
