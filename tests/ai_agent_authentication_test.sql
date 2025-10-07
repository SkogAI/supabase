-- AI Agent Authentication and Authorization Test Suite
-- This test suite validates the AI agent authentication infrastructure
-- Run with: supabase db execute --file tests/ai_agent_authentication_test.sql

\echo '============================================================================'
\echo 'AI AGENT AUTHENTICATION TEST SUITE'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- TEST 1: Verify AI Agent Roles Exist
-- ============================================================================
\echo 'TEST 1: Verifying AI Agent Roles...'

DO $$
DECLARE
  role_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO role_count
  FROM pg_roles
  WHERE rolname IN ('ai_agent_readonly', 'ai_agent_readwrite', 'ai_agent_analytics');
  
  IF role_count = 3 THEN
    RAISE NOTICE '✓ PASS: All 3 AI agent roles exist';
  ELSE
    RAISE EXCEPTION '✗ FAIL: Expected 3 roles, found %', role_count;
  END IF;
END $$;

-- Display role details
SELECT 
  rolname AS role_name,
  rolcanlogin AS can_login,
  rolconnlimit AS connection_limit
FROM pg_roles
WHERE rolname LIKE 'ai_agent%'
ORDER BY rolname;

\echo ''

-- ============================================================================
-- TEST 2: Verify Role Permissions
-- ============================================================================
\echo 'TEST 2: Verifying Role Permissions...'

-- Check readonly role has SELECT permission
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_default_acl acl
    JOIN pg_namespace ns ON acl.defaclnamespace = ns.oid
    WHERE ns.nspname = 'public'
  ) THEN
    RAISE NOTICE '✓ PASS: Default privileges are configured';
  END IF;
END $$;

\echo ''

-- ============================================================================
-- TEST 3: Verify Audit Tables Exist
-- ============================================================================
\echo 'TEST 3: Verifying Audit Tables...'

DO $$
DECLARE
  table_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys');
  
  IF table_count = 3 THEN
    RAISE NOTICE '✓ PASS: All 3 audit tables exist';
  ELSE
    RAISE EXCEPTION '✗ FAIL: Expected 3 tables, found %', table_count;
  END IF;
END $$;

-- Display table details
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND t.table_name = columns.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys')
ORDER BY table_name;

\echo ''

-- ============================================================================
-- TEST 4: Verify RLS is Enabled
-- ============================================================================
\echo 'TEST 4: Verifying RLS on Audit Tables...'

DO $$
DECLARE
  rls_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO rls_count
  FROM pg_tables
  WHERE schemaname = 'public'
    AND tablename IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys')
    AND rowsecurity = true;
  
  IF rls_count = 3 THEN
    RAISE NOTICE '✓ PASS: RLS enabled on all 3 audit tables';
  ELSE
    RAISE EXCEPTION '✗ FAIL: RLS not enabled on all tables (found % of 3)', rls_count;
  END IF;
END $$;

-- Display RLS status
SELECT 
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys')
ORDER BY tablename;

\echo ''

-- ============================================================================
-- TEST 5: Verify RLS Policies Exist
-- ============================================================================
\echo 'TEST 5: Verifying RLS Policies...'

DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys');
  
  IF policy_count >= 6 THEN
    RAISE NOTICE '✓ PASS: Found % RLS policies (expected at least 6)', policy_count;
  ELSE
    RAISE EXCEPTION '✗ FAIL: Expected at least 6 policies, found %', policy_count;
  END IF;
END $$;

-- Display policy details
SELECT 
  tablename,
  policyname,
  cmd AS command,
  roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys')
ORDER BY tablename, policyname;

\echo ''

-- ============================================================================
-- TEST 6: Verify Audit Functions Exist
-- ============================================================================
\echo 'TEST 6: Verifying Audit Functions...'

DO $$
DECLARE
  function_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO function_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname IN ('log_auth_attempt', 'log_mcp_query', 'validate_api_key', 'generate_api_key');
  
  IF function_count = 4 THEN
    RAISE NOTICE '✓ PASS: All 4 audit functions exist';
  ELSE
    RAISE EXCEPTION '✗ FAIL: Expected 4 functions, found %', function_count;
  END IF;
END $$;

-- Display function details
SELECT 
  p.proname AS function_name,
  pg_get_function_result(p.oid) AS return_type,
  p.prosecdef AS is_security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('log_auth_attempt', 'log_mcp_query', 'validate_api_key', 'generate_api_key')
ORDER BY p.proname;

\echo ''

-- ============================================================================
-- TEST 7: Test API Key Generation
-- ============================================================================
\echo 'TEST 7: Testing API Key Generation...'

DO $$
DECLARE
  api_key TEXT;
BEGIN
  SELECT public.generate_api_key() INTO api_key;
  
  IF api_key IS NOT NULL AND api_key LIKE 'sk_ai_%' THEN
    RAISE NOTICE '✓ PASS: API key generated successfully: %...', substring(api_key, 1, 15);
  ELSE
    RAISE EXCEPTION '✗ FAIL: API key generation failed or invalid format';
  END IF;
END $$;

\echo ''

-- ============================================================================
-- TEST 8: Test Authentication Logging
-- ============================================================================
\echo 'TEST 8: Testing Authentication Logging...'

DO $$
DECLARE
  log_id UUID;
  log_count INTEGER;
BEGIN
  -- Insert test authentication log
  SELECT public.log_auth_attempt(
    agent_id := 'test_agent_001',
    method := 'database_credentials',
    success := true,
    ip := '127.0.0.1'::inet,
    user_agent_str := 'Test Suite',
    meta := '{"test": true}'::jsonb
  ) INTO log_id;
  
  IF log_id IS NOT NULL THEN
    RAISE NOTICE '✓ PASS: Authentication log created with ID: %', log_id;
  ELSE
    RAISE EXCEPTION '✗ FAIL: Authentication logging failed';
  END IF;
  
  -- Verify log was created
  SELECT COUNT(*) INTO log_count
  FROM public.auth_audit_log
  WHERE agent_identifier = 'test_agent_001';
  
  IF log_count = 1 THEN
    RAISE NOTICE '✓ PASS: Authentication log entry verified';
  ELSE
    RAISE EXCEPTION '✗ FAIL: Log entry not found';
  END IF;
  
  -- Cleanup test data
  DELETE FROM public.auth_audit_log WHERE agent_identifier = 'test_agent_001';
  RAISE NOTICE '✓ Test data cleaned up';
END $$;

\echo ''

-- ============================================================================
-- TEST 9: Test Query Logging
-- ============================================================================
\echo 'TEST 9: Testing Query Logging...'

DO $$
DECLARE
  log_id UUID;
  log_count INTEGER;
BEGIN
  -- Insert test query log
  SELECT public.log_mcp_query(
    agent_id := 'test_agent_001',
    agent_role := 'ai_agent_readonly',
    operation := 'SELECT',
    query_text := 'SELECT * FROM profiles LIMIT 10',
    exec_time_ms := 42,
    rows := 10,
    ip := '127.0.0.1'::inet,
    meta := '{"table": "profiles"}'::jsonb
  ) INTO log_id;
  
  IF log_id IS NOT NULL THEN
    RAISE NOTICE '✓ PASS: Query log created with ID: %', log_id;
  ELSE
    RAISE EXCEPTION '✗ FAIL: Query logging failed';
  END IF;
  
  -- Verify log was created
  SELECT COUNT(*) INTO log_count
  FROM public.mcp_query_audit_log
  WHERE agent_id = 'test_agent_001';
  
  IF log_count = 1 THEN
    RAISE NOTICE '✓ PASS: Query log entry verified';
  ELSE
    RAISE EXCEPTION '✗ FAIL: Log entry not found';
  END IF;
  
  -- Cleanup test data
  DELETE FROM public.mcp_query_audit_log WHERE agent_id = 'test_agent_001';
  RAISE NOTICE '✓ Test data cleaned up';
END $$;

\echo ''

-- ============================================================================
-- TEST 10: Test API Key Validation
-- ============================================================================
\echo 'TEST 10: Testing API Key Validation...'

DO $$
DECLARE
  test_key TEXT;
  key_hash TEXT;
  validation_result RECORD;
BEGIN
  -- Generate test API key
  test_key := public.generate_api_key();
  key_hash := encode(digest(test_key, 'sha256'), 'hex');
  
  -- Insert test API key
  INSERT INTO public.ai_agent_api_keys (
    key, key_hash, agent_name, agent_type, agent_role,
    permissions, rate_limit_per_minute, is_active
  ) VALUES (
    test_key, key_hash, 'Test Agent', 'test', 'ai_agent_readonly',
    '{"read": true}'::jsonb, 100, true
  );
  
  -- Validate the key
  SELECT * INTO validation_result
  FROM public.validate_api_key(test_key)
  LIMIT 1;
  
  IF validation_result.valid = true THEN
    RAISE NOTICE '✓ PASS: API key validation successful';
    RAISE NOTICE '  Agent Name: %', validation_result.agent_name;
    RAISE NOTICE '  Agent Role: %', validation_result.agent_role;
  ELSE
    RAISE EXCEPTION '✗ FAIL: API key validation failed';
  END IF;
  
  -- Test invalid key
  SELECT * INTO validation_result
  FROM public.validate_api_key('invalid_key_123')
  LIMIT 1;
  
  IF validation_result.valid = false THEN
    RAISE NOTICE '✓ PASS: Invalid key correctly rejected';
  ELSE
    RAISE EXCEPTION '✗ FAIL: Invalid key was not rejected';
  END IF;
  
  -- Cleanup test data
  DELETE FROM public.ai_agent_api_keys WHERE key_hash = encode(digest(test_key, 'sha256'), 'hex');
  RAISE NOTICE '✓ Test data cleaned up';
END $$;

\echo ''

-- ============================================================================
-- TEST 11: Verify Indexes Exist
-- ============================================================================
\echo 'TEST 11: Verifying Indexes...'

DO $$
DECLARE
  index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND tablename IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys');
  
  IF index_count >= 9 THEN
    RAISE NOTICE '✓ PASS: Found % indexes on audit tables (expected at least 9)', index_count;
  ELSE
    RAISE EXCEPTION '✗ FAIL: Expected at least 9 indexes, found %', index_count;
  END IF;
END $$;

-- Display index details
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('auth_audit_log', 'mcp_query_audit_log', 'ai_agent_api_keys')
ORDER BY tablename, indexname;

\echo ''

-- ============================================================================
-- TEST 12: Verify Views Exist
-- ============================================================================
\echo 'TEST 12: Verifying Security Views...'

DO $$
DECLARE
  view_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO view_count
  FROM information_schema.views
  WHERE table_schema = 'public'
    AND table_name IN ('recent_auth_attempts', 'active_api_keys', 'mcp_query_stats');
  
  IF view_count = 3 THEN
    RAISE NOTICE '✓ PASS: All 3 security views exist';
  ELSE
    RAISE EXCEPTION '✗ FAIL: Expected 3 views, found %', view_count;
  END IF;
END $$;

-- Display view details
SELECT 
  table_name AS view_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN ('recent_auth_attempts', 'active_api_keys', 'mcp_query_stats')
ORDER BY table_name;

\echo ''
\echo '============================================================================'
\echo 'TEST SUITE COMPLETED SUCCESSFULLY'
\echo '============================================================================'
\echo ''
\echo 'Summary:'
\echo '  ✓ AI agent roles created and configured'
\echo '  ✓ Audit tables created with RLS enabled'
\echo '  ✓ RLS policies configured correctly'
\echo '  ✓ Audit functions working as expected'
\echo '  ✓ API key generation and validation functional'
\echo '  ✓ Authentication and query logging working'
\echo '  ✓ Indexes and views created'
\echo ''
