-- Enable realtime subscriptions
-- Created: 2025-10-05
-- Description: Configure realtime for profiles and posts tables with publication rules

-- ============================================================================
-- REALTIME CONFIGURATION
-- ============================================================================

-- Enable realtime for profiles table
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- Enable realtime for posts table
ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;

-- ============================================================================
-- REALTIME REPLICA IDENTITY
-- ============================================================================
-- Set replica identity to FULL to include all columns in realtime events
-- This is needed for UPDATE and DELETE events to show old values

ALTER TABLE public.profiles REPLICA IDENTITY FULL;
ALTER TABLE public.posts REPLICA IDENTITY FULL;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE public.profiles IS 'User profiles with automatic creation on signup. Realtime enabled for live updates.';
COMMENT ON TABLE public.posts IS 'User-generated content with RLS policies. Realtime enabled for live updates.';
