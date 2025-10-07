-- Seed data for local development and testing
-- This file is automatically loaded when running `supabase db reset`
-- DO NOT use this for production data!
--
-- For complete documentation, see: supabase/README.md (Seed Data section)

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
-- For local testing, we create auth users with metadata in raw_user_meta_data.
-- The handle_new_user() trigger (defined in migrations) automatically creates
-- corresponding profile entries when users are inserted into auth.users.

-- Create auth users (profiles are auto-created by handle_new_user() trigger)
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    confirmation_token,
    recovery_token
)
VALUES
    (
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'alice@example.com',
        crypt('password123', gen_salt('bf')),
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '30 days',
        '{"provider": "email", "providers": ["email"]}',
        '{"username": "alice", "full_name": "Alice Johnson", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Alice"}',
        false,
        '',
        ''
    ),
    (
        '00000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'bob@example.com',
        crypt('password123', gen_salt('bf')),
        NOW() - INTERVAL '25 days',
        NOW() - INTERVAL '25 days',
        NOW() - INTERVAL '25 days',
        '{"provider": "email", "providers": ["email"]}',
        '{"username": "bob", "full_name": "Bob Smith", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Bob"}',
        false,
        '',
        ''
    ),
    (
        '00000000-0000-0000-0000-000000000003',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'charlie@example.com',
        crypt('password123', gen_salt('bf')),
        NOW() - INTERVAL '20 days',
        NOW() - INTERVAL '20 days',
        NOW() - INTERVAL '20 days',
        '{"provider": "email", "providers": ["email"]}',
        '{"username": "charlie", "full_name": "Charlie Davis", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Charlie"}',
        false,
        '',
        ''
    )
ON CONFLICT (id) DO NOTHING;

-- Update profile bios (profiles are already created by trigger, just add bio field)
UPDATE public.profiles 
SET bio = 'Software engineer and open source enthusiast. Love building with Supabase!'
WHERE id = '00000000-0000-0000-0000-000000000001';

UPDATE public.profiles 
SET bio = 'Full-stack developer passionate about web technologies.'
WHERE id = '00000000-0000-0000-0000-000000000002';

UPDATE public.profiles 
SET bio = 'Designer and developer hybrid. Creating beautiful UX.'
WHERE id = '00000000-0000-0000-0000-000000000003';

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
-- POST-CATEGORY RELATIONSHIPS
-- ============================================================================
-- Note: Categories are seeded in the migration file (20251005070000_example_add_categories.sql)
-- Here we just link posts to categories

-- Link Alice's posts to Technology category
INSERT INTO public.post_categories (post_id, category_id)
SELECT 
    p.id,
    c.id
FROM public.posts p
CROSS JOIN public.categories c
WHERE p.user_id = '00000000-0000-0000-0000-000000000001'
  AND p.title IN ('Getting Started with Supabase', 'Building Secure APIs with RLS')
  AND c.slug = 'technology'
ON CONFLICT DO NOTHING;

-- Link Bob's posts to Technology and Business categories
INSERT INTO public.post_categories (post_id, category_id)
SELECT 
    p.id,
    c.id
FROM public.posts p
CROSS JOIN public.categories c
WHERE p.user_id = '00000000-0000-0000-0000-000000000002'
  AND c.slug IN ('technology', 'business')
ON CONFLICT DO NOTHING;

-- Link Charlie's posts to Lifestyle category
INSERT INTO public.post_categories (post_id, category_id)
SELECT 
    p.id,
    c.id
FROM public.posts p
CROSS JOIN public.categories c
WHERE p.user_id = '00000000-0000-0000-0000-000000000003'
  AND c.slug = 'lifestyle'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VERIFY SEED DATA
-- ============================================================================

DO $$
DECLARE
    profile_count INTEGER;
    post_count INTEGER;
    category_count INTEGER;
    post_category_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    SELECT COUNT(*) INTO post_count FROM public.posts;
    SELECT COUNT(*) INTO category_count FROM public.categories;
    SELECT COUNT(*) INTO post_category_count FROM public.post_categories;

    RAISE NOTICE '';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE 'Seed Data Summary';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE 'Profiles created: %', profile_count;
    RAISE NOTICE 'Posts created: %', post_count;
    RAISE NOTICE 'Categories: %', category_count;
    RAISE NOTICE 'Post-Category links: %', post_category_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Test Users (username / email / password):';
    RAISE NOTICE '  - alice / alice@example.com / password123';
    RAISE NOTICE '    ID: 00000000-0000-0000-0000-000000000001';
    RAISE NOTICE '  - bob / bob@example.com / password123';
    RAISE NOTICE '    ID: 00000000-0000-0000-0000-000000000002';
    RAISE NOTICE '  - charlie / charlie@example.com / password123';
    RAISE NOTICE '    ID: 00000000-0000-0000-0000-000000000003';
    RAISE NOTICE '';
    RAISE NOTICE 'Test Categories:';
    RAISE NOTICE '  - Technology (slug: technology)';
    RAISE NOTICE '  - Lifestyle (slug: lifestyle)';
    RAISE NOTICE '  - Business (slug: business)';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Testing:';
    RAISE NOTICE '  Set auth context: SET request.jwt.claim.sub = ''<user_id>'';';
    RAISE NOTICE '  Run test suite: npm run test:rls';
    RAISE NOTICE '';
    RAISE NOTICE 'See supabase/README.md for complete seed data documentation';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE '';
END $$;
