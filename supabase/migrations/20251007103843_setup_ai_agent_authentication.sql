-- Migration: Setup AI Agent Authentication and Authorization
-- Created: 2025-10-07
-- Description: Create database roles, audit logging, and security infrastructure for AI agents accessing via MCP servers
--
-- Changes:
-- - Create AI agent database roles (readonly, readwrite, analytics)
-- - Set resource limits for AI agent roles
-- - Create audit log tables for authentication attempts and queries
-- - Create audit logging functions
-- - Add RLS policies to audit tables
-- - Create API keys table for AI agent authentication

-- ============================================================================
-- AI AGENT DATABASE ROLES
-- ============================================================================

-- Read-Only AI Agent Role
-- Purpose: For AI agents that only need to read data (e.g., chatbots, analytics viewers)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ai_agent_readonly') THEN
    CREATE ROLE ai_agent_readonly;
  END IF;
END
$$;

GRANT CONNECT ON DATABASE postgres TO ai_agent_readonly;
GRANT USAGE ON SCHEMA public TO ai_agent_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ai_agent_readonly;

-- Set default permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO ai_agent_readonly;

-- Set resource limits for read-only agents
ALTER ROLE ai_agent_readonly SET statement_timeout = '30s';
ALTER ROLE ai_agent_readonly SET work_mem = '64MB';
ALTER ROLE ai_agent_readonly SET idle_in_transaction_session_timeout = '60s';

COMMENT ON ROLE ai_agent_readonly IS 'Read-only role for AI agents accessing via MCP servers';

-- Read-Write AI Agent Role
-- Purpose: For AI agents that need to create and update data (e.g., content generators, data processors)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ai_agent_readwrite') THEN
    CREATE ROLE ai_agent_readwrite;
  END IF;
END
$$;

GRANT CONNECT ON DATABASE postgres TO ai_agent_readwrite;
GRANT USAGE ON SCHEMA public TO ai_agent_readwrite;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO ai_agent_readwrite;

-- Set default permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT, INSERT, UPDATE ON TABLES TO ai_agent_readwrite;

-- Set resource limits for read-write agents (more restrictive)
ALTER ROLE ai_agent_readwrite SET statement_timeout = '45s';
ALTER ROLE ai_agent_readwrite SET work_mem = '128MB';
ALTER ROLE ai_agent_readwrite SET idle_in_transaction_session_timeout = '90s';

COMMENT ON ROLE ai_agent_readwrite IS 'Read-write role for AI agents that need to modify data via MCP servers';

-- Analytical AI Agent Role
-- Purpose: For AI agents performing analytics, reporting, and data science tasks
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ai_agent_analytics') THEN
    CREATE ROLE ai_agent_analytics;
  END IF;
END
$$;

GRANT CONNECT ON DATABASE postgres TO ai_agent_analytics;
GRANT USAGE ON SCHEMA public TO ai_agent_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ai_agent_analytics;

-- Allow materialized view refresh for analytics
GRANT CREATE ON SCHEMA public TO ai_agent_analytics;

-- Set default permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO ai_agent_analytics;

-- Set resource limits for analytics agents (higher limits for complex queries)
ALTER ROLE ai_agent_analytics SET statement_timeout = '120s';
ALTER ROLE ai_agent_analytics SET work_mem = '256MB';
ALTER ROLE ai_agent_analytics SET idle_in_transaction_session_timeout = '120s';

COMMENT ON ROLE ai_agent_analytics IS 'Analytics role for AI agents performing data analysis via MCP servers';

-- ============================================================================
-- AUTHENTICATION AUDIT LOG TABLE
-- ============================================================================

-- Track all authentication attempts by AI agents
CREATE TABLE IF NOT EXISTS public.auth_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  agent_identifier TEXT NOT NULL,
  auth_method TEXT NOT NULL,
  success BOOLEAN NOT NULL,
  ip_address INET,
  user_agent TEXT,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS auth_audit_log_timestamp_idx ON public.auth_audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS auth_audit_log_agent_identifier_idx ON public.auth_audit_log(agent_identifier);
CREATE INDEX IF NOT EXISTS auth_audit_log_success_idx ON public.auth_audit_log(success);

-- Enable RLS
ALTER TABLE public.auth_audit_log ENABLE ROW LEVEL SECURITY;

-- Service role has full access to audit logs
CREATE POLICY "Service role full access to auth audit log"
    ON public.auth_audit_log FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Authenticated users can only view their own auth logs
CREATE POLICY "Users can view own auth audit logs"
    ON public.auth_audit_log FOR SELECT
    TO authenticated
    USING (agent_identifier = auth.jwt() ->> 'sub');

COMMENT ON TABLE public.auth_audit_log IS 'Authentication audit log for AI agents accessing via MCP servers';
COMMENT ON COLUMN public.auth_audit_log.agent_identifier IS 'Unique identifier for the AI agent (user ID, API key hash, etc.)';
COMMENT ON COLUMN public.auth_audit_log.auth_method IS 'Authentication method used (service_role, jwt, api_key, database_credentials)';

-- ============================================================================
-- QUERY AUDIT LOG TABLE
-- ============================================================================

-- Track all database queries executed by AI agents
CREATE TABLE IF NOT EXISTS public.mcp_query_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id TEXT NOT NULL,
  agent_role TEXT,
  operation TEXT NOT NULL,
  query TEXT,
  execution_time_ms INTEGER,
  rows_affected INTEGER,
  error TEXT,
  ip_address INET,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS mcp_query_audit_log_created_at_idx ON public.mcp_query_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS mcp_query_audit_log_agent_id_idx ON public.mcp_query_audit_log(agent_id);
CREATE INDEX IF NOT EXISTS mcp_query_audit_log_operation_idx ON public.mcp_query_audit_log(operation);

-- Enable RLS
ALTER TABLE public.mcp_query_audit_log ENABLE ROW LEVEL SECURITY;

-- Service role has full access to query audit logs
CREATE POLICY "Service role full access to query audit log"
    ON public.mcp_query_audit_log FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Authenticated users can only view their own query logs
CREATE POLICY "Users can view own query audit logs"
    ON public.mcp_query_audit_log FOR SELECT
    TO authenticated
    USING (agent_id = auth.jwt() ->> 'sub');

COMMENT ON TABLE public.mcp_query_audit_log IS 'Query audit log for AI agent database operations via MCP servers';
COMMENT ON COLUMN public.mcp_query_audit_log.agent_id IS 'Unique identifier for the AI agent';
COMMENT ON COLUMN public.mcp_query_audit_log.agent_role IS 'Database role used by the agent (ai_agent_readonly, ai_agent_readwrite, etc.)';
COMMENT ON COLUMN public.mcp_query_audit_log.operation IS 'Type of database operation (SELECT, INSERT, UPDATE, DELETE, etc.)';

-- ============================================================================
-- API KEYS TABLE FOR AI AGENT AUTHENTICATION
-- ============================================================================

-- Store and manage API keys for AI agents
CREATE TABLE IF NOT EXISTS public.ai_agent_api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  key_hash TEXT UNIQUE NOT NULL,
  agent_name TEXT NOT NULL,
  agent_type TEXT NOT NULL,
  agent_role TEXT NOT NULL CHECK (agent_role IN ('ai_agent_readonly', 'ai_agent_readwrite', 'ai_agent_analytics')),
  permissions JSONB DEFAULT '{"read": true, "write": false}'::jsonb,
  rate_limit_per_minute INTEGER DEFAULT 60,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS ai_agent_api_keys_key_hash_idx ON public.ai_agent_api_keys(key_hash);
CREATE INDEX IF NOT EXISTS ai_agent_api_keys_agent_name_idx ON public.ai_agent_api_keys(agent_name);
CREATE INDEX IF NOT EXISTS ai_agent_api_keys_is_active_idx ON public.ai_agent_api_keys(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS ai_agent_api_keys_expires_at_idx ON public.ai_agent_api_keys(expires_at) WHERE expires_at IS NOT NULL;

-- Enable RLS
ALTER TABLE public.ai_agent_api_keys ENABLE ROW LEVEL SECURITY;

-- Service role can manage all API keys
CREATE POLICY "Service role manages all API keys"
    ON public.ai_agent_api_keys FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Authenticated users can only view their own created API keys
CREATE POLICY "Users can view own API keys"
    ON public.ai_agent_api_keys FOR SELECT
    TO authenticated
    USING (created_by = auth.uid());

-- Authenticated users can create API keys
CREATE POLICY "Users can create API keys"
    ON public.ai_agent_api_keys FOR INSERT
    TO authenticated
    WITH CHECK (created_by = auth.uid());

-- Authenticated users can update their own API keys (e.g., revoke)
CREATE POLICY "Users can update own API keys"
    ON public.ai_agent_api_keys FOR UPDATE
    TO authenticated
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

COMMENT ON TABLE public.ai_agent_api_keys IS 'API keys for authenticating AI agents via MCP servers';
COMMENT ON COLUMN public.ai_agent_api_keys.key IS 'Plain text API key (only stored temporarily during creation)';
COMMENT ON COLUMN public.ai_agent_api_keys.key_hash IS 'Hashed API key for secure storage and validation';
COMMENT ON COLUMN public.ai_agent_api_keys.agent_role IS 'Database role to use when authenticating with this API key';

-- ============================================================================
-- AUDIT LOGGING FUNCTIONS
-- ============================================================================

-- Function to log authentication attempts
CREATE OR REPLACE FUNCTION public.log_auth_attempt(
  agent_id TEXT,
  method TEXT,
  success BOOLEAN,
  ip INET DEFAULT NULL,
  user_agent_str TEXT DEFAULT NULL,
  error TEXT DEFAULT NULL,
  meta JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO public.auth_audit_log (
    agent_identifier,
    auth_method,
    success,
    ip_address,
    user_agent,
    error_message,
    metadata
  ) VALUES (
    agent_id,
    method,
    success,
    ip,
    user_agent_str,
    error,
    meta
  ) RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$;

COMMENT ON FUNCTION public.log_auth_attempt IS 'Log authentication attempts for AI agents';

-- Function to log query execution
CREATE OR REPLACE FUNCTION public.log_mcp_query(
  agent_id TEXT,
  agent_role TEXT,
  operation TEXT,
  query_text TEXT DEFAULT NULL,
  exec_time_ms INTEGER DEFAULT NULL,
  rows INTEGER DEFAULT NULL,
  error_msg TEXT DEFAULT NULL,
  ip INET DEFAULT NULL,
  meta JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO public.mcp_query_audit_log (
    agent_id,
    agent_role,
    operation,
    query,
    execution_time_ms,
    rows_affected,
    error,
    ip_address,
    metadata
  ) VALUES (
    agent_id,
    agent_role,
    operation,
    query_text,
    exec_time_ms,
    rows,
    error_msg,
    ip,
    meta
  ) RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$;

COMMENT ON FUNCTION public.log_mcp_query IS 'Log query executions by AI agents via MCP servers';

-- Function to validate and update API key usage
CREATE OR REPLACE FUNCTION public.validate_api_key(
  api_key_input TEXT
)
RETURNS TABLE (
  valid BOOLEAN,
  agent_name TEXT,
  agent_type TEXT,
  agent_role TEXT,
  permissions JSONB,
  rate_limit INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  key_record RECORD;
BEGIN
  -- Find the API key and check if it's valid
  SELECT 
    k.id,
    k.agent_name,
    k.agent_type,
    k.agent_role,
    k.permissions,
    k.rate_limit_per_minute,
    k.is_active,
    k.expires_at
  INTO key_record
  FROM public.ai_agent_api_keys k
  WHERE k.key_hash = encode(digest(api_key_input, 'sha256'), 'hex')
    AND k.is_active = true
    AND (k.expires_at IS NULL OR k.expires_at > NOW());
  
  IF key_record.id IS NULL THEN
    -- Invalid or expired key
    RETURN QUERY SELECT false, NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::JSONB, NULL::INTEGER;
  ELSE
    -- Valid key - update last used timestamp
    UPDATE public.ai_agent_api_keys
    SET last_used_at = NOW()
    WHERE id = key_record.id;
    
    RETURN QUERY SELECT 
      true,
      key_record.agent_name,
      key_record.agent_type,
      key_record.agent_role,
      key_record.permissions,
      key_record.rate_limit_per_minute;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.validate_api_key IS 'Validate API key and return agent information';

-- Function to generate API key
CREATE OR REPLACE FUNCTION public.generate_api_key()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  key_prefix TEXT := 'sk_ai_';
  random_bytes BYTEA;
  api_key TEXT;
BEGIN
  -- Generate 32 random bytes
  random_bytes := gen_random_bytes(32);
  
  -- Create API key with prefix
  api_key := key_prefix || encode(random_bytes, 'base64');
  
  -- Replace URL-unsafe characters
  api_key := replace(replace(replace(api_key, '+', ''), '/', ''), '=', '');
  
  RETURN api_key;
END;
$$;

COMMENT ON FUNCTION public.generate_api_key IS 'Generate secure API key for AI agents';

-- ============================================================================
-- SECURITY VIEWS FOR MONITORING
-- ============================================================================

-- View recent authentication attempts
CREATE OR REPLACE VIEW public.recent_auth_attempts AS
SELECT 
  agent_identifier,
  auth_method,
  success,
  timestamp,
  ip_address,
  error_message
FROM public.auth_audit_log
WHERE timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

COMMENT ON VIEW public.recent_auth_attempts IS 'Recent authentication attempts in the last 24 hours';

-- View active API keys
CREATE OR REPLACE VIEW public.active_api_keys AS
SELECT 
  id,
  agent_name,
  agent_type,
  agent_role,
  rate_limit_per_minute,
  expires_at,
  created_at,
  last_used_at
FROM public.ai_agent_api_keys
WHERE is_active = true
  AND (expires_at IS NULL OR expires_at > NOW());

COMMENT ON VIEW public.active_api_keys IS 'Currently active API keys for AI agents';

-- View query statistics by agent
CREATE OR REPLACE VIEW public.mcp_query_stats AS
SELECT 
  agent_id,
  agent_role,
  operation,
  COUNT(*) as query_count,
  AVG(execution_time_ms) as avg_execution_time_ms,
  MAX(execution_time_ms) as max_execution_time_ms,
  SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) as error_count,
  DATE_TRUNC('hour', created_at) as hour
FROM public.mcp_query_audit_log
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY agent_id, agent_role, operation, DATE_TRUNC('hour', created_at)
ORDER BY hour DESC, query_count DESC;

COMMENT ON VIEW public.mcp_query_stats IS 'Query statistics for AI agents in the last 24 hours';
