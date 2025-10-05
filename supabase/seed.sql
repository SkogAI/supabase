-- ============================================================================
-- SEED DATA FOR LOCAL DEVELOPMENT AND TESTING
-- ============================================================================
-- This file is automatically loaded when running `supabase db reset`
-- Referenced in: supabase/config.toml -> [db.seed] section
--
-- ⚠️  WARNING: DO NOT USE THIS FOR PRODUCTION DATA!
-- This file contains test credentials and mock data for development only.
--
-- ============================================================================
-- WHAT THIS FILE DOES
-- ============================================================================
-- 1. Creates test users in auth.users with authentication credentials
-- 2. Automatically triggers profile creation via handle_new_user() function
-- 3. Seeds sample posts for each user to demonstrate RLS policies
-- 4. Provides verification summary of seeded data
--
-- ============================================================================
-- HOW TO USE TEST USERS
-- ============================================================================
-- Test users can log in with these credentials:
--   alice@example.com    | password123
--   bob@example.com      | password123
--   charlie@example.com  | password123
--
-- For manual RLS testing in SQL, set the auth context:
--   SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001'; -- Alice
--   SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002'; -- Bob
--   SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003'; -- Charlie
--
-- Then run queries to test RLS policies:
--   SELECT * FROM posts; -- Should only see published posts + own drafts
--   UPDATE posts SET title = 'New Title' WHERE id = '...'; -- Should only work on own posts
--
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
-- TEST USERS WITH AUTHENTICATION
-- ============================================================================
-- Creates test users in auth.users which automatically creates profiles via trigger
-- These users can be used for testing authentication and RLS policies
--
-- TEST CREDENTIALS:
-- Email: alice@example.com    | Password: password123
-- Email: bob@example.com      | Password: password123  
-- Email: charlie@example.com  | Password: password123
--
-- IMPORTANT: These are for LOCAL DEVELOPMENT ONLY!
-- Never use these credentials in production.
-- ============================================================================

-- Insert test users into auth.users
-- The handle_new_user() trigger will automatically create their profiles
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES
    (
        '00000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000001',
        'authenticated',
        'authenticated',
        'alice@example.com',
        -- Password: password123 (hashed using crypt function)
        crypt('password123', gen_salt('bf')),
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '1 day',
        '{"provider":"email","providers":["email"]}',
        '{"username":"alice","full_name":"Alice Johnson","avatar_url":"https://api.dicebear.com/7.x/avataaars/svg?seed=Alice"}',
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '30 days',
        '',
        '',
        '',
        ''
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000002',
        'authenticated',
        'authenticated',
        'bob@example.com',
        crypt('password123', gen_salt('bf')),
        NOW() - INTERVAL '25 days',
        NOW() - INTERVAL '25 days',
        NOW() - INTERVAL '2 days',
        '{"provider":"email","providers":["email"]}',
        '{"username":"bob","full_name":"Bob Smith","avatar_url":"https://api.dicebear.com/7.x/avataaars/svg?seed=Bob"}',
        NOW() - INTERVAL '25 days',
        NOW() - INTERVAL '25 days',
        '',
        '',
        '',
        ''
    ),
    (
        '00000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000003',
        'authenticated',
        'authenticated',
        'charlie@example.com',
        crypt('password123', gen_salt('bf')),
        NOW() - INTERVAL '20 days',
        NOW() - INTERVAL '20 days',
        NOW() - INTERVAL '3 days',
        '{"provider":"email","providers":["email"]}',
        '{"username":"charlie","full_name":"Charlie Davis","avatar_url":"https://api.dicebear.com/7.x/avataaars/svg?seed=Charlie"}',
        NOW() - INTERVAL '20 days',
        NOW() - INTERVAL '20 days',
        '',
        '',
        '',
        ''
    )
ON CONFLICT (id) DO NOTHING;

-- Update profiles with additional bio information
-- The profiles should have been created by the trigger, but we'll update them with more details
UPDATE public.profiles SET
    bio = 'Software engineer and open source enthusiast. Love building with Supabase!',
    updated_at = NOW() - INTERVAL '29 days'
WHERE id = '00000000-0000-0000-0000-000000000001';

UPDATE public.profiles SET
    bio = 'Full-stack developer passionate about web technologies.',
    updated_at = NOW() - INTERVAL '24 days'
WHERE id = '00000000-0000-0000-0000-000000000002';

UPDATE public.profiles SET
    bio = 'Designer and developer hybrid. Creating beautiful UX.',
    updated_at = NOW() - INTERVAL '19 days'
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
-- VERIFY SEED DATA
-- ============================================================================
-- Displays a summary of seeded data and helpful testing information

DO $$
DECLARE
    user_count INTEGER;
    profile_count INTEGER;
    post_count INTEGER;
    published_count INTEGER;
    draft_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM auth.users WHERE id IN (
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-000000000003'
    );
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    SELECT COUNT(*) INTO post_count FROM public.posts;
    SELECT COUNT(*) INTO published_count FROM public.posts WHERE published = true;
    SELECT COUNT(*) INTO draft_count FROM public.posts WHERE published = false;

    RAISE NOTICE '';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE '🌱 SEED DATA LOADED SUCCESSFULLY';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Data Summary:';
    RAISE NOTICE '  • Auth Users:      % (with authentication credentials)', user_count;
    RAISE NOTICE '  • User Profiles:   % (auto-created via trigger)', profile_count;
    RAISE NOTICE '  • Total Posts:     % (% published, % drafts)', post_count, published_count, draft_count;
    RAISE NOTICE '';
    RAISE NOTICE '👥 Test User Credentials (LOCAL DEVELOPMENT ONLY):';
    RAISE NOTICE '  ┌─────────────────────────┬──────────────────────────────────────┐';
    RAISE NOTICE '  │ Email                   │ Password                             │';
    RAISE NOTICE '  ├─────────────────────────┼──────────────────────────────────────┤';
    RAISE NOTICE '  │ alice@example.com       │ password123                          │';
    RAISE NOTICE '  │ bob@example.com         │ password123                          │';
    RAISE NOTICE '  │ charlie@example.com     │ password123                          │';
    RAISE NOTICE '  └─────────────────────────┴──────────────────────────────────────┘';
    RAISE NOTICE '';
    RAISE NOTICE '🔐 User IDs for RLS Testing:';
    RAISE NOTICE '  • Alice:   00000000-0000-0000-0000-000000000001';
    RAISE NOTICE '  • Bob:     00000000-0000-0000-0000-000000000002';
    RAISE NOTICE '  • Charlie: 00000000-0000-0000-0000-000000000003';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Quick Testing Tips:';
    RAISE NOTICE '  1. Login via Supabase Studio: http://localhost:8000';
    RAISE NOTICE '  2. Test auth in your app using the credentials above';
    RAISE NOTICE '  3. Test RLS policies with: SET request.jwt.claim.sub = ''<user_id>'';';
    RAISE NOTICE '  4. View Studio tables to see seeded data';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Example RLS Test:';
    RAISE NOTICE '  -- Set context as Alice';
    RAISE NOTICE '  SET request.jwt.claim.sub = ''00000000-0000-0000-0000-000000000001'';';
    RAISE NOTICE '  -- Should see published posts + Alice''s drafts only';
    RAISE NOTICE '  SELECT title, published, user_id FROM posts;';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Remember: This is test data for LOCAL DEVELOPMENT ONLY!';
    RAISE NOTICE '================================================================================';
    RAISE NOTICE '';
END $$;
