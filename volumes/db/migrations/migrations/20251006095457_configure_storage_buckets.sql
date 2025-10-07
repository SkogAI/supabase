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

-- Create avatars bucket (public, for profile pictures)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880, -- 5MB in bytes
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

-- Create public-assets bucket (public, for general public files)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'public-assets',
    'public-assets',
    true,
    10485760, -- 10MB in bytes
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
          'application/pdf', 'text/plain', 'text/csv']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
                                'application/pdf', 'text/plain', 'text/csv'];

-- Create user-files bucket (private, for user documents)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-files',
    'user-files',
    false,
    52428800, -- 50MB in bytes
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
          'application/pdf', 'application/msword', 
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'text/plain', 'text/csv', 'application/zip']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 52428800,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
                                'application/pdf', 'application/msword', 
                                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                'application/vnd.ms-excel',
                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                'text/plain', 'text/csv', 'application/zip'];

-- ============================================================================
-- STORAGE RLS POLICIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- AVATARS BUCKET POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view avatars (public bucket)
CREATE POLICY IF NOT EXISTS "Avatars are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Authenticated users can upload their own avatar
CREATE POLICY IF NOT EXISTS "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own avatar
CREATE POLICY IF NOT EXISTS "Users can update their own avatar"
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
CREATE POLICY IF NOT EXISTS "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ----------------------------------------------------------------------------
-- PUBLIC-ASSETS BUCKET POLICIES
-- ----------------------------------------------------------------------------

-- Anyone can view public assets
CREATE POLICY IF NOT EXISTS "Public assets are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'public-assets');

-- Authenticated users can upload to public assets
CREATE POLICY IF NOT EXISTS "Authenticated users can upload public assets"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'public-assets' 
    AND auth.role() = 'authenticated'
);

-- Users can update their own public assets
CREATE POLICY IF NOT EXISTS "Users can update their own public assets"
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
CREATE POLICY IF NOT EXISTS "Users can delete their own public assets"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'public-assets' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ----------------------------------------------------------------------------
-- USER-FILES BUCKET POLICIES
-- ----------------------------------------------------------------------------

-- Users can only view their own files
CREATE POLICY IF NOT EXISTS "Users can view their own files"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'user-files' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can upload their own files
CREATE POLICY IF NOT EXISTS "Users can upload their own files"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'user-files' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own files
CREATE POLICY IF NOT EXISTS "Users can update their own files"
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
CREATE POLICY IF NOT EXISTS "Users can delete their own files"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'user-files' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE storage.buckets IS 'Storage buckets for organizing uploaded files';
COMMENT ON TABLE storage.objects IS 'Metadata for files stored in buckets';

-- Log migration completion
DO $$
BEGIN
    RAISE NOTICE 'Storage buckets configured successfully:';
    RAISE NOTICE '  - avatars: Public bucket for profile pictures (5MB, images only)';
    RAISE NOTICE '  - public-assets: Public bucket for general files (10MB)';
    RAISE NOTICE '  - user-files: Private bucket for user documents (50MB)';
    RAISE NOTICE 'Storage RLS policies created for secure access control';
END $$;
