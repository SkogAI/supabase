-- ============================================================================
-- STORAGE POLICY TEST SUITE
-- ============================================================================
-- Comprehensive test suite for Storage buckets and RLS policies
-- Run this after storage migration to verify all policies are working correctly
--
-- Usage:
--   supabase db execute --file tests/storage_test_suite.sql
--
-- Or in Supabase Studio SQL Editor, just copy and paste this file
-- ============================================================================

\echo ''
\echo '================================================================================'
\echo 'STORAGE POLICY TEST SUITE'
\echo '================================================================================'
\echo ''

-- ============================================================================
-- TEST 1: Verify Storage Buckets Exist
-- ============================================================================
\echo 'TEST 1: Verifying storage buckets are created...'

DO $$
DECLARE
    avatars_exists BOOLEAN;
    public_assets_exists BOOLEAN;
    user_files_exists BOOLEAN;
    avatars_public BOOLEAN;
    public_assets_public BOOLEAN;
    user_files_public BOOLEAN;
BEGIN
    -- Check avatars bucket
    SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'avatars') INTO avatars_exists;
    SELECT public FROM storage.buckets WHERE id = 'avatars' INTO avatars_public;
    
    -- Check public-assets bucket
    SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'public-assets') INTO public_assets_exists;
    SELECT public FROM storage.buckets WHERE id = 'public-assets' INTO public_assets_public;
    
    -- Check user-files bucket
    SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'user-files') INTO user_files_exists;
    SELECT public FROM storage.buckets WHERE id = 'user-files' INTO user_files_public;
    
    -- Verify all buckets exist
    IF NOT avatars_exists THEN
        RAISE EXCEPTION 'FAIL: avatars bucket not found!';
    END IF;
    
    IF NOT public_assets_exists THEN
        RAISE EXCEPTION 'FAIL: public-assets bucket not found!';
    END IF;
    
    IF NOT user_files_exists THEN
        RAISE EXCEPTION 'FAIL: user-files bucket not found!';
    END IF;
    
    -- Verify public/private settings
    IF NOT avatars_public THEN
        RAISE EXCEPTION 'FAIL: avatars bucket should be public!';
    END IF;
    
    IF NOT public_assets_public THEN
        RAISE EXCEPTION 'FAIL: public-assets bucket should be public!';
    END IF;
    
    IF user_files_public THEN
        RAISE EXCEPTION 'FAIL: user-files bucket should be private!';
    END IF;
    
    RAISE NOTICE 'PASS: All storage buckets created with correct visibility';
    RAISE NOTICE '  ✓ avatars (public)';
    RAISE NOTICE '  ✓ public-assets (public)';
    RAISE NOTICE '  ✓ user-files (private)';
END $$;

-- ============================================================================
-- TEST 2: Verify File Size Limits
-- ============================================================================
\echo ''
\echo 'TEST 2: Verifying file size limits...'

DO $$
DECLARE
    avatars_limit BIGINT;
    public_assets_limit BIGINT;
    user_files_limit BIGINT;
BEGIN
    SELECT file_size_limit FROM storage.buckets WHERE id = 'avatars' INTO avatars_limit;
    SELECT file_size_limit FROM storage.buckets WHERE id = 'public-assets' INTO public_assets_limit;
    SELECT file_size_limit FROM storage.buckets WHERE id = 'user-files' INTO user_files_limit;
    
    IF avatars_limit != 5242880 THEN
        RAISE EXCEPTION 'FAIL: avatars bucket limit should be 5MB (5242880 bytes), got %', avatars_limit;
    END IF;
    
    IF public_assets_limit != 10485760 THEN
        RAISE EXCEPTION 'FAIL: public-assets bucket limit should be 10MB (10485760 bytes), got %', public_assets_limit;
    END IF;
    
    IF user_files_limit != 52428800 THEN
        RAISE EXCEPTION 'FAIL: user-files bucket limit should be 50MB (52428800 bytes), got %', user_files_limit;
    END IF;
    
    RAISE NOTICE 'PASS: File size limits configured correctly';
    RAISE NOTICE '  ✓ avatars: 5MB';
    RAISE NOTICE '  ✓ public-assets: 10MB';
    RAISE NOTICE '  ✓ user-files: 50MB';
END $$;

-- ============================================================================
-- TEST 3: Verify MIME Type Restrictions
-- ============================================================================
\echo ''
\echo 'TEST 3: Verifying MIME type restrictions...'

DO $$
DECLARE
    avatars_mimes TEXT[];
    public_assets_mimes TEXT[];
    user_files_mimes TEXT[];
BEGIN
    SELECT allowed_mime_types FROM storage.buckets WHERE id = 'avatars' INTO avatars_mimes;
    SELECT allowed_mime_types FROM storage.buckets WHERE id = 'public-assets' INTO public_assets_mimes;
    SELECT allowed_mime_types FROM storage.buckets WHERE id = 'user-files' INTO user_files_mimes;
    
    -- Verify avatars only allows images
    IF NOT ('image/jpeg' = ANY(avatars_mimes) AND 'image/png' = ANY(avatars_mimes)) THEN
        RAISE EXCEPTION 'FAIL: avatars bucket missing required image MIME types';
    END IF;
    
    -- Verify public-assets allows images and documents
    IF NOT ('image/jpeg' = ANY(public_assets_mimes) AND 'application/pdf' = ANY(public_assets_mimes)) THEN
        RAISE EXCEPTION 'FAIL: public-assets bucket missing required MIME types';
    END IF;
    
    -- Verify user-files allows various document types
    IF NOT ('application/pdf' = ANY(user_files_mimes)) THEN
        RAISE EXCEPTION 'FAIL: user-files bucket missing required document MIME types';
    END IF;
    
    RAISE NOTICE 'PASS: MIME type restrictions configured correctly';
    RAISE NOTICE '  ✓ avatars: % types', array_length(avatars_mimes, 1);
    RAISE NOTICE '  ✓ public-assets: % types', array_length(public_assets_mimes, 1);
    RAISE NOTICE '  ✓ user-files: % types', array_length(user_files_mimes, 1);
END $$;

-- ============================================================================
-- TEST 4: Verify Storage RLS Policies Exist
-- ============================================================================
\echo ''
\echo 'TEST 4: Verifying storage RLS policies...'

DO $$
DECLARE
    policy_count INTEGER;
    avatars_policies INTEGER;
    public_assets_policies INTEGER;
    user_files_policies INTEGER;
BEGIN
    -- Count total policies on storage.objects
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'storage' AND tablename = 'objects';
    
    IF policy_count < 12 THEN
        RAISE EXCEPTION 'FAIL: Expected at least 12 storage policies, found %', policy_count;
    END IF;
    
    -- Count policies per bucket (by checking policy definition)
    SELECT COUNT(*) INTO avatars_policies
    FROM pg_policies 
    WHERE schemaname = 'storage' 
      AND tablename = 'objects'
      AND definition LIKE '%avatars%';
    
    SELECT COUNT(*) INTO public_assets_policies
    FROM pg_policies 
    WHERE schemaname = 'storage' 
      AND tablename = 'objects'
      AND definition LIKE '%public-assets%';
    
    SELECT COUNT(*) INTO user_files_policies
    FROM pg_policies 
    WHERE schemaname = 'storage' 
      AND tablename = 'objects'
      AND definition LIKE '%user-files%';
    
    IF avatars_policies < 4 THEN
        RAISE EXCEPTION 'FAIL: Expected 4 policies for avatars bucket, found %', avatars_policies;
    END IF;
    
    IF public_assets_policies < 4 THEN
        RAISE EXCEPTION 'FAIL: Expected 4 policies for public-assets bucket, found %', public_assets_policies;
    END IF;
    
    IF user_files_policies < 4 THEN
        RAISE EXCEPTION 'FAIL: Expected 4 policies for user-files bucket, found %', user_files_policies;
    END IF;
    
    RAISE NOTICE 'PASS: Storage RLS policies configured correctly';
    RAISE NOTICE '  ✓ Total policies: %', policy_count;
    RAISE NOTICE '  ✓ avatars policies: %', avatars_policies;
    RAISE NOTICE '  ✓ public-assets policies: %', public_assets_policies;
    RAISE NOTICE '  ✓ user-files policies: %', user_files_policies;
END $$;

-- ============================================================================
-- TEST 5: List All Storage Policies
-- ============================================================================
\echo ''
\echo 'TEST 5: Listing all storage policies...'

SELECT 
    policyname as policy_name,
    cmd as operation,
    CASE 
        WHEN definition LIKE '%avatars%' THEN 'avatars'
        WHEN definition LIKE '%public-assets%' THEN 'public-assets'
        WHEN definition LIKE '%user-files%' THEN 'user-files'
        ELSE 'unknown'
    END as bucket
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY bucket, cmd;

-- ============================================================================
-- TEST 6: Verify storage.foldername Function Exists
-- ============================================================================
\echo ''
\echo 'TEST 6: Verifying storage helper functions...'

DO $$
DECLARE
    foldername_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM pg_proc 
        WHERE proname = 'foldername' 
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage')
    ) INTO foldername_exists;
    
    IF NOT foldername_exists THEN
        RAISE EXCEPTION 'FAIL: storage.foldername() function not found - required for RLS policies!';
    END IF;
    
    RAISE NOTICE 'PASS: Required storage functions exist';
    RAISE NOTICE '  ✓ storage.foldername()';
END $$;

-- ============================================================================
-- SUMMARY
-- ============================================================================
\echo ''
\echo '================================================================================'
\echo 'STORAGE TEST SUITE COMPLETE'
\echo '================================================================================'
\echo ''
\echo 'All tests passed! Storage buckets and policies are configured correctly.'
\echo ''
\echo 'Next steps:'
\echo '  1. Test file uploads via Supabase client'
\echo '  2. Verify file size limits are enforced'
\echo '  3. Verify MIME type restrictions are enforced'
\echo '  4. Test access control with different user contexts'
\echo '  5. Review documentation in docs/STORAGE.md'
\echo ''
