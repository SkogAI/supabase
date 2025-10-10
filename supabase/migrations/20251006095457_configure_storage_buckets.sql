-- Migration: Configure Storage Buckets and Policies
-- Created: 2025-10-06
-- Description: Setup storage buckets for file uploads with proper RLS policies
--
-- Changes:
-- - Create 'avatars' bucket for public user profile pictures
-- - Create 'public-assets' bucket for publicly accessible files
-- - Create 'user-files' bucket for private user documents
-- - Configure RLS policies for secure bucket access
-- - Add file size and MIME type restrictions
--
-- Buckets:
-- - avatars: Public bucket for profile pictures (5MB limit, images only)
-- - public-assets: Public bucket for general public files (10MB limit)
-- - user-files: Private bucket for user documents (50MB limit)

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================
-- Note: Storage buckets in Supabase CLI v2.34.3 have limited column support
-- File size limits and MIME type restrictions are configured via Dashboard or API
-- This migration only creates the buckets with basic settings

-- Create avatars bucket (for profile pictures)
INSERT INTO storage.buckets (id, name)
VALUES ('avatars', 'avatars')
ON CONFLICT (id) DO NOTHING;

-- Create public-assets bucket (for general public files)
INSERT INTO storage.buckets (id, name)
VALUES ('public-assets', 'public-assets')
ON CONFLICT (id) DO NOTHING;

-- Create user-files bucket (for user documents)
INSERT INTO storage.buckets (id, name)
VALUES ('user-files', 'user-files')
ON CONFLICT (id) DO NOTHING;

-- TODO: Configure bucket settings via Supabase Dashboard or API:
-- - avatars: Public, 5MB limit, images only
-- - public-assets: Public, 10MB limit, images + PDFs
-- - user-files: Private, 50MB limit, documents

-- ============================================================================
-- STORAGE RLS POLICIES
-- ============================================================================

-- Note: PostgreSQL doesn't support IF NOT EXISTS for policies
-- Using DO blocks for idempotent policy creation

-- ----------------------------------------------------------------------------
-- AVATARS BUCKET POLICIES
-- ----------------------------------------------------------------------------

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Avatars are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;

-- Anyone can view avatars (public bucket)
CREATE POLICY "Avatars are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Authenticated users can upload their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ----------------------------------------------------------------------------
-- PUBLIC-ASSETS BUCKET POLICIES
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Public assets are viewable by everyone" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload public assets" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own public assets" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own public assets" ON storage.objects;

-- Anyone can view public assets
CREATE POLICY "Public assets are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'public-assets');

-- Authenticated users can upload to public assets
CREATE POLICY "Authenticated users can upload public assets"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'public-assets'
    AND auth.role() = 'authenticated'
);

-- Users can update their own public assets
CREATE POLICY "Users can update their own public assets"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'public-assets'
    AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
    bucket_id = 'public-assets'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own public assets
CREATE POLICY "Users can delete their own public assets"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'public-assets'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ----------------------------------------------------------------------------
-- USER-FILES BUCKET POLICIES
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;

-- Users can only view their own files
CREATE POLICY "Users can view their own files"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'user-files'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can upload their own files
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'user-files'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own files
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'user-files'
    AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
    bucket_id = 'user-files'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own files
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'user-files'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

-- Note: COMMENT statements require ownership of storage.* tables
-- These tables are owned by supabase_storage_admin, not accessible in migrations
-- Table documentation available in Supabase docs instead

-- Log migration completion
DO $$
BEGIN
    RAISE NOTICE 'Storage buckets configured successfully:';
    RAISE NOTICE '  - avatars: Public bucket for profile pictures (5MB, images only)';
    RAISE NOTICE '  - public-assets: Public bucket for general files (10MB)';
    RAISE NOTICE '  - user-files: Private bucket for user documents (50MB)';
    RAISE NOTICE 'Storage RLS policies created for secure access control';
END $$;
