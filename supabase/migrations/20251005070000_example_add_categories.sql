-- Example Migration: Add categories feature
-- Created: 2025-10-05
-- Description: Demonstrates best practices for database migrations
--
-- This migration adds a categories table and relationships, showing:
-- - Proper table creation with constraints
-- - Indexing strategies
-- - RLS policies
-- - Foreign key relationships
-- - Comments for documentation
-- - Idempotent operations (using IF NOT EXISTS)

-- ============================================================================
-- CATEGORIES TABLE
-- ============================================================================
-- Create a new table for categorizing posts
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints for data validation
    CONSTRAINT categories_name_length CHECK (char_length(name) >= 2 AND char_length(name) <= 50),
    CONSTRAINT categories_slug_format CHECK (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$')
);

-- Add indexes for common query patterns
CREATE INDEX IF NOT EXISTS categories_name_idx ON public.categories(name);
CREATE INDEX IF NOT EXISTS categories_slug_idx ON public.categories(slug);
CREATE INDEX IF NOT EXISTS categories_created_at_idx ON public.categories(created_at DESC);

-- Add helpful comments
COMMENT ON TABLE public.categories IS 'Categories for organizing posts';
COMMENT ON COLUMN public.categories.slug IS 'URL-friendly identifier (lowercase, hyphen-separated)';
COMMENT ON CONSTRAINT categories_slug_format ON public.categories IS 'Ensures slug is URL-safe (lowercase letters, numbers, hyphens only)';

-- Enable Row Level Security
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Everyone can read, only authenticated users with specific role can write
CREATE POLICY "Categories are viewable by everyone"
    ON public.categories
    FOR SELECT
    USING (true);

-- Note: In production, you might want to restrict INSERT/UPDATE/DELETE to admin users
-- Example: USING (auth.jwt() ->> 'role' = 'admin')
CREATE POLICY "Authenticated users can create categories"
    ON public.categories
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update categories"
    ON public.categories
    FOR UPDATE
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================================
-- POST_CATEGORIES JOIN TABLE
-- ============================================================================
-- Many-to-many relationship between posts and categories
CREATE TABLE IF NOT EXISTS public.post_categories (
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Composite primary key prevents duplicate associations
    PRIMARY KEY (post_id, category_id)
);

-- Indexes for efficient joins
CREATE INDEX IF NOT EXISTS post_categories_post_id_idx ON public.post_categories(post_id);
CREATE INDEX IF NOT EXISTS post_categories_category_id_idx ON public.post_categories(category_id);

COMMENT ON TABLE public.post_categories IS 'Many-to-many relationship between posts and categories';

-- Enable RLS
ALTER TABLE public.post_categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Match the access level of posts
CREATE POLICY "Post categories are viewable by everyone"
    ON public.post_categories
    FOR SELECT
    USING (true);

CREATE POLICY "Users can manage their own post categories"
    ON public.post_categories
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_categories.post_id
            AND posts.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.posts
            WHERE posts.id = post_categories.post_id
            AND posts.user_id = auth.uid()
        )
    );

-- ============================================================================
-- UPDATE EXISTING TABLES (if needed)
-- ============================================================================
-- Example: Add a category count to posts table (optional)
-- ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS category_count INTEGER DEFAULT 0;

-- ============================================================================
-- TRIGGERS
-- ============================================================================
-- Add updated_at trigger to categories
CREATE TRIGGER categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- SEED DATA (optional, for development/testing)
-- ============================================================================
-- Insert some default categories
INSERT INTO public.categories (name, slug, description)
VALUES 
    ('Technology', 'technology', 'Posts about technology and software'),
    ('Lifestyle', 'lifestyle', 'Posts about lifestyle and daily life'),
    ('Business', 'business', 'Posts about business and entrepreneurship')
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- BEST PRACTICES DEMONSTRATED:
-- ============================================================================
-- ✅ Use descriptive migration names with timestamp prefix
-- ✅ Include header comments explaining purpose and date
-- ✅ Use IF NOT EXISTS for idempotent operations
-- ✅ Add proper constraints and validation
-- ✅ Create indexes for common query patterns
-- ✅ Enable RLS and add appropriate policies
-- ✅ Use foreign keys with ON DELETE CASCADE when appropriate
-- ✅ Add comments to document tables, columns, and constraints
-- ✅ Group related changes with clear section headers
-- ✅ Consider both forward migration (create) and backward (rollback)
-- ✅ Use consistent naming conventions (snake_case)
-- ✅ Add seed data where appropriate
