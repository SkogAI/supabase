-- Seed data for local development and testing
-- This file is automatically loaded when running `supabase db reset`
-- DO NOT use this for production data!

-- ============================================================================
-- SEED CONFIGURATION
-- ============================================================================
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- ============================================================================
-- TEST USERS
-- ============================================================================
-- Note: In production, users are created via Supabase Auth
-- For local testing, we'll create profiles directly

-- Test user profiles
INSERT INTO public.profiles (id, username, full_name, avatar_url, bio, created_at)
VALUES
    (
        '00000000-0000-0000-0000-000000000001',
        'alice',
        'Alice Johnson',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=Alice',
        'Software engineer and open source enthusiast. Love building with Supabase!',
        NOW() - INTERVAL '30 days'
    ),
    (
        '00000000-0000-0000-0000-000000000002',
        'bob',
        'Bob Smith',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=Bob',
        'Full-stack developer passionate about web technologies.',
        NOW() - INTERVAL '25 days'
    ),
    (
        '00000000-0000-0000-0000-000000000003',
        'charlie',
        'Charlie Davis',
        'https://api.dicebear.com/7.x/avataaars/svg?seed=Charlie',
        'Designer and developer hybrid. Creating beautiful UX.',
        NOW() - INTERVAL '20 days'
    )
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SAMPLE POSTS
-- ============================================================================

INSERT INTO public.posts (id, user_id, title, content, published, created_at)
VALUES
    -- Alice's posts
    (
        uuid_generate_v4(),
        '00000000-0000-0000-0000-000000000001',
        'Getting Started with Supabase',
        'Supabase is an amazing open-source Firebase alternative. In this post, I''ll share my experience setting up a production-ready application with Row Level Security, Edge Functions, and real-time subscriptions.',
        true,
        NOW() - INTERVAL '15 days'
    ),
    (
        uuid_generate_v4(),
        '00000000-0000-0000-0000-000000000001',
        'Building Secure APIs with RLS',
        'Row Level Security (RLS) is a powerful feature in PostgreSQL that Supabase leverages. Here''s how to implement fine-grained access control for your data.',
        true,
        NOW() - INTERVAL '10 days'
    ),
    (
        uuid_generate_v4(),
        '00000000-0000-0000-0000-000000000001',
        'Draft: Advanced Supabase Patterns',
        'This is a draft post about advanced patterns I''m still working on...',
        false,
        NOW() - INTERVAL '2 days'
    ),

    -- Bob's posts
    (
        uuid_generate_v4(),
        '00000000-0000-0000-0000-000000000002',
        'Deploying Edge Functions',
        'Edge Functions in Supabase are powered by Deno. They''re fast, secure, and globally distributed. Here''s my deployment strategy.',
        true,
        NOW() - INTERVAL '12 days'
    ),
    (
        uuid_generate_v4(),
        '00000000-0000-0000-0000-000000000002',
        'Database Migration Best Practices',
        'Managing database migrations is crucial for team collaboration. Here are the patterns I use to keep migrations clean and reversible.',
        true,
        NOW() - INTERVAL '8 days'
    ),

    -- Charlie's posts
    (
        uuid_generate_v4(),
        '00000000-0000-0000-0000-000000000003',
        'Designing with Realtime in Mind',
        'When your app has real-time features, the UX design needs to account for instant updates. Here are my favorite patterns for handling optimistic updates and conflict resolution.',
        true,
        NOW() - INTERVAL '5 days'
    ),
    (
        uuid_generate_v4(),
        '00000000-0000-0000-0000-000000000003',
        'Authentication UI Patterns',
        'Great authentication UX is invisible. Here''s how I design auth flows that users love.',
        true,
        NOW() - INTERVAL '3 days'
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VERIFY SEED DATA
-- ============================================================================

DO $$
DECLARE
    profile_count INTEGER;
    post_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    SELECT COUNT(*) INTO post_count FROM public.posts;

    RAISE NOTICE '';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE 'Seed Data Summary';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE 'Profiles created: %', profile_count;
    RAISE NOTICE 'Posts created: %', post_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Test Users:';
    RAISE NOTICE '  - alice (ID: 00000000-0000-0000-0000-000000000001)';
    RAISE NOTICE '  - bob (ID: 00000000-0000-0000-0000-000000000002)';
    RAISE NOTICE '  - charlie (ID: 00000000-0000-0000-0000-000000000003)';
    RAISE NOTICE '';
    RAISE NOTICE 'You can use these user IDs for testing RLS policies.';
    RAISE NOTICE 'Set auth context with: SET request.jwt.claim.sub = ''<user_id>'';';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE '';
END $$;
