-- Storage buckets and policies migration
-- Created: 2025-01-05
-- Description: Setup storage buckets with RLS policies for file uploads

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Create public bucket for publicly accessible assets (avatars, thumbnails, etc.)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'public-assets',
    'public-assets',
    true, -- Files are publicly accessible via URL
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- Create private bucket for user files (documents, private images, etc.)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-files',
    'user-files',
    false, -- Files are private, require authentication
    52428800, -- 50MB limit
    ARRAY[
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain',
        'text/csv'
    ]
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STORAGE RLS POLICIES - PUBLIC ASSETS BUCKET
-- ============================================================================

-- Allow anyone to read public assets
CREATE POLICY "Public assets are viewable by everyone"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'public-assets');

-- Allow authenticated users to upload to their own folder in public assets
CREATE POLICY "Authenticated users can upload public assets to their folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'public-assets' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to update their own public assets
CREATE POLICY "Users can update their own public assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'public-assets' 
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'public-assets' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own public assets
CREATE POLICY "Users can delete their own public assets"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'public-assets' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================================
-- STORAGE RLS POLICIES - USER FILES BUCKET
-- ============================================================================

-- Allow users to read only their own files
CREATE POLICY "Users can view their own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'user-files' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to upload files to their own folder
CREATE POLICY "Users can upload files to their folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'user-files' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to update their own files
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'user-files' 
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'user-files' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own files
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'user-files' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================================
-- HELPER FUNCTION FOR FILE METADATA
-- ============================================================================

-- Function to get file metadata for a user's files
CREATE OR REPLACE FUNCTION public.get_user_files(user_uuid UUID DEFAULT auth.uid())
RETURNS TABLE (
    name TEXT,
    bucket_id TEXT,
    size BIGINT,
    content_type TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Ensure user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Ensure user can only see their own files
    IF user_uuid != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    RETURN QUERY
    SELECT 
        o.name,
        o.bucket_id,
        o.metadata->>'size' AS size,
        o.metadata->>'mimetype' AS content_type,
        o.created_at,
        o.updated_at
    FROM storage.objects o
    WHERE 
        (o.bucket_id = 'user-files' OR o.bucket_id = 'public-assets')
        AND (storage.foldername(o.name))[1] = user_uuid::text
    ORDER BY o.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION public.get_user_files IS 'Returns all files uploaded by a specific user from both buckets';

-- Add comment on buckets configuration
DO $$
BEGIN
    -- Note: Comments on storage.buckets require appropriate permissions
    -- This is informational for developers
    RAISE NOTICE 'Storage buckets configured:';
    RAISE NOTICE '  - public-assets: 5MB limit, images only, publicly accessible';
    RAISE NOTICE '  - user-files: 50MB limit, multiple file types, private access';
END $$;
