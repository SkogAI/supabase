-- Schema Organization and Custom Types Migration
-- Created: 2025-10-05
-- Description: Configure database schemas and PostgreSQL custom types

-- ============================================================================
-- SCHEMA ORGANIZATION
-- ============================================================================
-- Note: Core schemas (auth, storage, etc.) are managed by Supabase automatically
-- This migration documents the schema organization and adds custom types

-- Ensure public schema exists (should already exist)
CREATE SCHEMA IF NOT EXISTS public;

-- Comment on schemas to document their purpose
COMMENT ON SCHEMA public IS 'Public schema for application tables, exposed via API';

-- ============================================================================
-- CUSTOM ENUM TYPES
-- ============================================================================

-- User role enum for authorization
-- Example: Used to define different permission levels in the application
CREATE TYPE public.user_role AS ENUM (
    'user',          -- Regular user with standard permissions
    'moderator',     -- Can moderate content
    'admin'          -- Full administrative access
);

COMMENT ON TYPE public.user_role IS 'User authorization roles for permission management';

-- Post status enum for content workflow
-- Example: Used to track the lifecycle of posts/content
CREATE TYPE public.post_status AS ENUM (
    'draft',         -- Initial draft state
    'review',        -- Under review
    'published',     -- Published and visible
    'archived'       -- Archived/soft-deleted
);

COMMENT ON TYPE public.post_status IS 'Post lifecycle status for content management';

-- Priority level enum for tasks or issues
-- Example: Can be used for task management or support tickets
CREATE TYPE public.priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);

COMMENT ON TYPE public.priority_level IS 'Priority level for tasks, issues, or tickets';

-- ============================================================================
-- CUSTOM COMPOSITE TYPES
-- ============================================================================

-- Address composite type
-- Example: Reusable structured data for storing addresses
CREATE TYPE public.address_info AS (
    street_line1 TEXT,
    street_line2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT
);

COMMENT ON TYPE public.address_info IS 'Composite type for storing structured address information';

-- Contact details composite type
-- Example: Structured contact information
CREATE TYPE public.contact_details AS (
    email TEXT,
    phone TEXT,
    preferred_method TEXT
);

COMMENT ON TYPE public.contact_details IS 'Composite type for contact information';

-- Geolocation composite type
-- Example: Store location data with coordinates
CREATE TYPE public.geo_location AS (
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    accuracy_meters NUMERIC(10, 2)
);

COMMENT ON TYPE public.geo_location IS 'Composite type for geographic coordinates';

-- ============================================================================
-- EXAMPLE USAGE (COMMENTED OUT)
-- ============================================================================
-- Below are examples of how to use the custom types in tables.
-- Uncomment and adapt as needed for your application.

/*
-- Example 1: Adding role to profiles table
ALTER TABLE public.profiles 
ADD COLUMN role public.user_role DEFAULT 'user' NOT NULL;

-- Example 2: Using post_status in posts table
ALTER TABLE public.posts 
ADD COLUMN status public.post_status DEFAULT 'draft' NOT NULL;

-- Example 3: Creating a table with composite types
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address public.address_info,
    contact public.contact_details,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Example 4: Using array of enums
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    priority public.priority_level DEFAULT 'medium',
    assigned_roles public.user_role[] DEFAULT ARRAY['user']::public.user_role[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
*/

-- ============================================================================
-- SCHEMA PERMISSIONS
-- ============================================================================
-- Configure permissions for custom types
-- By default, types are accessible to authenticated users

-- Grant usage on types to authenticated users
GRANT USAGE ON TYPE public.user_role TO authenticated;
GRANT USAGE ON TYPE public.post_status TO authenticated;
GRANT USAGE ON TYPE public.priority_level TO authenticated;
GRANT USAGE ON TYPE public.address_info TO authenticated;
GRANT USAGE ON TYPE public.contact_details TO authenticated;
GRANT USAGE ON TYPE public.geo_location TO authenticated;

-- Grant usage to service role for server-side operations
GRANT USAGE ON TYPE public.user_role TO service_role;
GRANT USAGE ON TYPE public.post_status TO service_role;
GRANT USAGE ON TYPE public.priority_level TO service_role;
GRANT USAGE ON TYPE public.address_info TO service_role;
GRANT USAGE ON TYPE public.contact_details TO service_role;
GRANT USAGE ON TYPE public.geo_location TO service_role;

-- Anonymous users typically don't need direct access to types
-- Add if needed: GRANT USAGE ON TYPE public.user_role TO anon;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- This migration provides:
-- 1. Documentation of schema organization
-- 2. Common enum types for roles, statuses, and priorities
-- 3. Composite types for structured data (address, contact, location)
-- 4. Proper permissions for authenticated and service role users
-- 5. Examples of usage (commented out)
--
-- To use these types:
-- 1. Uncomment and adapt the example usage section above
-- 2. Create new migrations that reference these types
-- 3. Update TypeScript types: npm run types:generate
-- 4. Reference types in your application code
--
-- See: https://www.postgresql.org/docs/current/sql-createtype.html
