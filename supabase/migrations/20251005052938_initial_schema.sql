-- Initial database schema migration
-- Created: 2025-10-05
-- Description: Base schema with RLS policies and essential tables

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
-- Stores user profile information linked to auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles(username);
CREATE INDEX IF NOT EXISTS profiles_created_at_idx ON public.profiles(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles
    FOR SELECT
    USING (true);

CREATE POLICY "Users can insert their own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================================================
-- POSTS TABLE
-- ============================================================================
-- Example content table with user ownership
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    published BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS posts_user_id_idx ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS posts_created_at_idx ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS posts_published_idx ON public.posts(published) WHERE published = true;

-- Enable Row Level Security
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for posts
CREATE POLICY "Published posts are viewable by everyone"
    ON public.posts
    FOR SELECT
    USING (published = true OR auth.uid() = user_id);

CREATE POLICY "Users can create their own posts"
    ON public.posts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts"
    ON public.posts
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts"
    ON public.posts
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers for updated_at
CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER posts_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'username',
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE public.profiles IS 'User profiles with automatic creation on signup';
COMMENT ON TABLE public.posts IS 'User-generated content with RLS policies';
COMMENT ON FUNCTION public.handle_updated_at() IS 'Automatically updates the updated_at timestamp';
COMMENT ON FUNCTION public.handle_new_user() IS 'Creates a profile entry when a new user signs up';
