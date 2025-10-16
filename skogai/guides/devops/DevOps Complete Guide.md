---
title: DevOps Complete Guide
type: note
permalink: guides/devops/dev-ops-complete-guide
tags:
- devops
- cicd
- deployment
- operations
- automation
---

# DevOps Complete Guide

Comprehensive configuration for CI/CD, secrets management, deployment workflows, and production operations.

## Core Supabase Secrets

[secret] SUPABASE_ACCESS_TOKEN from Dashboard → Account → Access Tokens #secrets #authentication
[secret] SUPABASE_PROJECT_ID from Dashboard → Project Settings → General → Reference ID #secrets #project
[secret] SUPABASE_DB_PASSWORD from Dashboard → Project Settings → Database → Password #secrets #database
[requirement] SUPABASE_ACCESS_TOKEN required for all workflows #secrets #cicd
[requirement] SUPABASE_PROJECT_ID required for deployment and migrations #secrets #cicd
[requirement] SUPABASE_DB_PASSWORD required for database operations #secrets #cicd

## Optional Integration Secrets

[secret] CLAUDE_CODE_OAUTH_TOKEN for PR analysis and automated reviews #secrets #ai
[secret] SUPABASE_OPENAI_API_KEY for Studio AI features in local development #secrets #ai
[secret] OPENAI_API_KEY for Edge Functions custom AI features #secrets #ai
[secret] OPENROUTER_API_KEY for accessing 100+ AI models #secrets #ai

## SAML SSO Secrets (Self-Hosted)

[secret] GOTRUE_SAML_ENABLED enables SAML SSO in GoTrue #secrets #auth
[secret] GOTRUE_SAML_PRIVATE_KEY base64-encoded private key for SAML signing #secrets #auth
[requirement] Required only for self-hosted Supabase with SAML SSO #secrets #condition
[reference] Complete setup guide at docs/SUPABASE_SAML_SP_CONFIGURATION.md #documentation #saml

## Setting Up GitHub Secrets

[command] `gh secret set SUPABASE_ACCESS_TOKEN` sets access token #cli #secrets
[command] `gh secret set SUPABASE_PROJECT_ID` sets project ID #cli #secrets
[command] `gh secret set SUPABASE_DB_PASSWORD` sets database password #cli #secrets
[command] `gh secret set CLAUDE_CODE_OAUTH_TOKEN` sets AI integration token #cli #secrets
[command] `gh secret list` verifies secrets are configured #cli #validation
[location] Configure in GitHub Settings → Secrets and variables → Actions #github #configuration

## Local Environment Variables

[workflow] Copy `.env.example` to `.env` with `cp .env.example .env` #setup #local
[warning] NEVER commit `.env` to git - keep in .gitignore #security #gitignore
[configuration] Edit `.env` for API keys and local settings #configuration #editing

## Project Configuration File

[file] `supabase/config.toml` contains all project configuration #configuration #location
[section] API section defines port 8000 for local development #configuration #api
[section] Database section defines PostgreSQL 17 on port 54322 #configuration #database
[section] Studio section defines UI on port 8000 #configuration #ui
[section] Edge Runtime section defines Deno 2.x with inspector on port 8083 #configuration #functions
[section] Storage section defines 50MiB file size limit #configuration #storage

## Workflow: deploy.yml

[trigger] Push to master/main branches triggers deployment #cicd #trigger
[purpose] Deploy migrations and functions to production #cicd #deployment
[step] Validates credentials and authentication #cicd #validation
[step] Links to Supabase project #cicd #connection
[step] Runs database migrations #cicd #database
[step] Deploys all edge functions #cicd #functions
[step] Generates deployment summary #cicd #reporting
[status] Ready for production use #cicd #status
[manual] Run with `gh workflow run deploy.yml -f environment=staging` #cicd #manual

## Workflow: pr-checks.yml

[trigger] Pull requests trigger validation checks #cicd #trigger
[purpose] Validate PRs and check for security issues #cicd #validation
[step] Validates PR title format #cicd #convention
[step] Checks for migration changes #cicd #database
[step] Scans for hardcoded secrets #cicd #security
[step] Generates comprehensive PR analysis #cicd #analysis
[step] Provides review checklist #cicd #quality
[status] Ready for production use #cicd #status

## Workflow: migrations-validation.yml

[trigger] Migration file changes trigger validation #cicd #trigger
[purpose] Test migrations in clean environment #cicd #testing
[step] Starts fresh Supabase instance #cicd #isolation
[step] Applies all migrations sequentially #cicd #execution
[step] Checks for timestamp conflicts #cicd #validation
[step] Analyzes breaking changes #cicd #analysis
[step] Validates rollback procedures #cicd #safety
[status] Ready for production use #cicd #status

## Workflow: edge-functions-test.yml

[trigger] Function file changes trigger testing #cicd #trigger
[purpose] Complete function validation #cicd #testing
[step] Deno formatting check for code style #cicd #formatting
[step] Type checking for TypeScript errors #cicd #types
[step] Linting for code quality #cicd #linting
[step] Unit tests execution #cicd #testing
[step] Integration tests with local Supabase #cicd #integration
[step] Security analysis for vulnerabilities #cicd #security
[status] Ready for production use #cicd #status

## Workflow: worktree-ci.yml

[trigger] Feature, bugfix, hotfix branches trigger testing #cicd #trigger
[purpose] Parallel testing for worktree branches #cicd #testing
[step] Auto-detects branch type patterns #cicd #detection
[step] Runs lint, typecheck, unit tests in parallel #cicd #parallel
[step] Validates migrations and RLS policies #cicd #validation
[step] Posts results to PR comments #cicd #feedback
[step] Blocks merge if tests fail #cicd #quality
[status] Ready for production use #cicd #status
[reference] See docs/CI_WORKTREE.md for local integration #documentation #worktrees

## Workflow: schema-lint.yml

[trigger] Database schema changes trigger linting #cicd #trigger
[purpose] Database best practices validation #cicd #quality
[check] Missing indexes on foreign keys #linting #performance
[check] Unbounded text fields without limits #linting #database
[check] Missing RLS policies on tables #linting #security
[check] Naming conventions compliance #linting #standards
[check] Performance anti-patterns detection #linting #optimization
[status] Ready for production use #cicd #status

## Workflow: security-scan.yml

[trigger] All pushes trigger security scanning #cicd #trigger
[purpose] Comprehensive security checks #cicd #security
[check] Dependency vulnerabilities scanning #security #dependencies
[check] Code security issues detection #security #sast
[check] Secret scanning for leaked credentials #security #secrets
[check] OWASP best practices compliance #security #standards
[status] Ready for production use #cicd #status

## Local Development Prerequisites

[requirement] Docker Desktop must be running #prerequisite #docker
[requirement] Supabase CLI from https://supabase.com/docs/guides/cli #prerequisite #cli
[requirement] Node.js 18+ for edge functions #prerequisite #nodejs
[requirement] Deno 2.x for edge functions #prerequisite #deno

## Local Development Quick Start

[command] `git clone <repository>` clones project repository #setup #git
[command] `cd supabase` changes to project directory #setup #navigation
[command] `cp .env.example .env` creates environment file #setup #configuration
[command] `nano .env` or `code .env` edits environment variables #setup #editing
[command] `supabase start` starts all services (requires Docker running) #startup #services
[url] Studio UI at http://localhost:8000 #local #ui
[url] API at http://localhost:8000 #local #api
[url] Database at postgresql://postgres:postgres@localhost:54322/postgres #local #database
[command] `supabase status` views service status #monitoring #status
[command] `supabase stop` stops all services #shutdown #services

## Database Migration Development

[command] `supabase migration new <migration_name>` creates new migration #database #creation
[workflow] Edit the generated migration SQL file #database #editing
[command] `supabase db reset` applies all migrations from scratch #database #testing
[command] `supabase gen types typescript --local > types/database.ts` generates types #codegen #types

## Edge Function Development

[command] `supabase functions new <function_name>` creates new function #functions #creation
[workflow] Edit function in `supabase/functions/<function-name>/index.ts` #functions #editing
[command] `supabase functions serve` tests function locally #functions #testing
[command] `supabase functions deploy <function_name>` deploys to cloud #functions #deployment
[location] View logs with `supabase logs` command #functions #monitoring

## Project Directory Structure

[directory] `supabase/migrations/` contains timestamped SQL migration files #organization #migrations
[directory] `supabase/functions/` contains edge functions in subdirectories #organization #functions
[subdirectory] `supabase/functions/<function-name>/index.ts` is main function file #organization #entrypoint
[subdirectory] `supabase/functions/<function-name>/test.ts` contains optional tests #organization #testing
[file] `supabase/seed.sql` contains seed data for local development #organization #data
[file] `supabase/config.toml` contains project configuration #organization #config

## Automatic Deployment Process

[step] Create Pull Request with changes #deployment #workflow
[step] PR checks run automatically validating changes #deployment #validation
[step] Review and merge to master/main branch #deployment #approval
[step] Deploy workflow runs automatically on merge #deployment #automation
[step] Verify deployment in Supabase Dashboard #deployment #verification

## Manual Deployment Options

[option] GitHub CLI: `gh workflow run deploy.yml -f environment=production` #deployment #cli
[option] Local deployment with Supabase CLI #deployment #local
[command] `supabase link --project-ref <your-project-ref>` links local to remote #deployment #link
[command] `supabase db push` pushes database changes #deployment #database
[command] `supabase functions deploy` deploys all functions #deployment #functions

## Deployment Checklist

[checklist] All tests passing in CI #deployment #validation
[checklist] Migrations reviewed and tested locally #deployment #database
[checklist] No breaking changes or communicated to users #deployment #compatibility
[checklist] Secrets configured in GitHub Actions #deployment #configuration
[checklist] Database backup created if needed #deployment #safety
[checklist] Edge functions tested locally #deployment #functions
[checklist] TypeScript types generated and committed #deployment #types
[checklist] Documentation updated for changes #deployment #documentation

## Regular Maintenance Tasks - Daily

[task] Monitor deployment status in GitHub Actions #maintenance #monitoring
[task] Review error logs in Supabase Dashboard #maintenance #debugging

## Regular Maintenance Tasks - Weekly

[task] Review dependency update Pull Requests #maintenance #dependencies
[task] Check performance metrics in dashboard #maintenance #performance
[task] Review security scan results from workflow #maintenance #security

## Regular Maintenance Tasks - Monthly

[task] Database backup verification #maintenance #backup
[task] Performance optimization review #maintenance #optimization
[task] Review and update documentation #maintenance #documentation

## Useful Monitoring Commands

[command] `gh run list --workflow=deploy.yml --limit 5` checks deployment status #monitoring #cicd
[command] `gh run view <run-id> --log` views workflow logs #monitoring #debugging
[command] `gh workflow run backup.yml` triggers database backup #monitoring #backup
[command] `supabase logs --level error` views error logs #monitoring #errors
[command] `supabase db dump --data-only | wc -c` checks database size #monitoring #database

## Troubleshooting Migration Failures

[command] `supabase migration list` checks migration status #troubleshooting #migrations
[command] `supabase db reset` resets local database #troubleshooting #reset
[command] `supabase db push --dry-run` previews remote changes #troubleshooting #preview
[command] `supabase db push --include-all` force pushes migrations #troubleshooting #force

## Troubleshooting Edge Function Failures

[command] `supabase functions logs <function-name>` checks function logs #troubleshooting #functions
[command] `supabase functions serve <function-name>` tests locally #troubleshooting #local
[command] `curl http://localhost:54321/functions/v1/<function-name>` tests function #troubleshooting #testing
[command] `supabase functions deploy <function-name> --no-verify-jwt` redeploys without JWT verification #troubleshooting #deployment

## Troubleshooting Secrets Issues

[command] `gh secret list` verifies secrets configured #troubleshooting #secrets
[command] `gh secret set SUPABASE_ACCESS_TOKEN` updates secret value #troubleshooting #update
[command] `gh run view <run-id> --log | grep -i error` searches for errors #troubleshooting #debugging

## Security Best Practices - DO

[bestpractice] Use environment variables for all secrets #security #configuration
[bestpractice] Enable RLS on all public tables #security #database
[bestpractice] Use `env(VARIABLE_NAME)` syntax in config.toml #security #configuration
[bestpractice] Review dependency updates before merging #security #updates
[bestpractice] Keep `.env` in `.gitignore` always #security #gitignore
[bestpractice] Use strong database passwords #security #passwords
[bestpractice] Rotate secrets periodically #security #rotation
[bestpractice] Enable MFA on GitHub and Supabase accounts #security #mfa
[bestpractice] Use HTTPS in production environments #security #tls
[bestpractice] Enable audit logging for authentication events #security #auditing

## Security Best Practices - DON'T

[antipattern] Don't commit `.env` files to git #security #gitignore
[antipattern] Don't hardcode API keys or passwords in code #security #secrets
[antipattern] Don't disable security scans in CI #security #validation
[antipattern] Don't skip migration testing before deployment #security #testing
[antipattern] Don't deploy without reviewing changes #security #process
[antipattern] Don't use `--no-verify` flags without reason #security #flags
[antipattern] Don't share access tokens publicly #security #credentials
[antipattern] Don't use HTTP for production SAML endpoints #security #tls

## SAML SSO Production Deployment

[phase] Phase 1: ZITADEL Setup - Complete #saml #progress
[phase] Phase 2: Supabase Config - Complete (Issue #70) #saml #progress
[phase] Phase 3: Testing - Complete (Issue #71) #saml #progress
[phase] Phase 4: Production - Complete #saml #progress
[reference] ZITADEL IdP Setup guide at docs/ZITADEL_SAML_IDP_SETUP.md #documentation #saml
[reference] Production Deployment guide at docs/ZITADEL_SAML_PRODUCTION_DEPLOYMENT.md #documentation #saml

## SAML Production Deployment Checklist

[checklist] SSL/TLS certificates obtained and configured #saml #security
[checklist] Domain name configured with DNS records #saml #networking
[checklist] Production ZITADEL instance configured #saml #idp
[checklist] SAML private keys generated and secured #saml #security
[checklist] Environment variables configured from .env.example #saml #configuration
[checklist] Firewall rules configured for ports 80 and 443 #saml #networking
[checklist] Reverse proxy (nginx/Traefik) configured #saml #infrastructure
[checklist] Monitoring and alerting set up #saml #operations
[checklist] Backup procedures tested #saml #disaster-recovery
[checklist] Rollback plan documented #saml #operations

## SAML Environment Variables

[envvar] GOTRUE_SAML_ENABLED=true enables SAML SSO #saml #configuration
[envvar] GOTRUE_SAML_PRIVATE_KEY=<base64-encoded-key> for signing #saml #security
[envvar] GOTRUE_SITE_URL=https://your-domain.com for site URL #saml #configuration
[envvar] GOTRUE_URI_ALLOW_LIST=https://your-domain.com for allowed redirects #saml #security

## SAML Security Requirements

[requirement] HTTPS Only for all production SAML endpoints #saml #security
[requirement] Certificate Rotation monitoring for SAML certificate expiration #saml #maintenance
[requirement] Session Timeouts with appropriate JWT expiration (GOTRUE_JWT_EXP=3600) #saml #security
[requirement] Rate Limiting enabled on Kong API Gateway #saml #security
[requirement] Audit Logging enabled for authentication in ZITADEL #saml #compliance

## Performance Optimization - Database

[optimization] Add indexes on frequently queried columns #performance #database
[optimization] Use `EXPLAIN ANALYZE` for analyzing slow queries #performance #debugging
[optimization] Implement proper RLS policies without over-complexity #performance #security
[optimization] Use connection pooling for high traffic #performance #scaling
[optimization] Monitor database size and plan upgrades #performance #capacity

## Performance Optimization - Edge Functions

[optimization] Minimize cold start time by keeping functions small #performance #serverless
[optimization] Use proper error handling to prevent crashes #performance #reliability
[optimization] Implement caching where appropriate #performance #caching
[optimization] Monitor function execution time #performance #monitoring
[optimization] Use Deno's built-in performance tools #performance #tooling

## Performance Monitoring Commands

[command] `supabase db logs --level warning` checks database performance #monitoring #database
[command] `supabase functions logs <name> --tail` monitors function performance #monitoring #functions
[location] Check resource usage in Supabase Dashboard → Settings → Usage #monitoring #resources

## Realtime Configuration

[feature] Supabase Realtime enables WebSocket connections for live updates #realtime #feature
[feature] Supports presence tracking and broadcast messaging #realtime #capability
[sql] Enable realtime: `ALTER PUBLICATION supabase_realtime ADD TABLE your_table` #realtime #configuration
[sql] Set replica identity: `ALTER TABLE your_table REPLICA IDENTITY FULL` #realtime #configuration
[sql] Verify realtime: `SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime'` #realtime #validation

## Realtime Enabled Tables

[table] public.profiles has realtime enabled #realtime #configuration
[table] public.posts has realtime enabled #realtime #configuration

## Realtime Configuration Settings

[setting] max_connections = 100 concurrent connections per client #realtime #limits
[setting] max_channels_per_client = 100 channels per connection #realtime #limits
[setting] max_joins_per_second = 500 joins per second per client #realtime #limits
[setting] max_messages_per_second = 1000 messages per second per client #realtime #limits
[setting] max_events_per_second = 100 events per second per channel #realtime #limits
[location] Configure in supabase/config.toml [realtime] section #realtime #configuration

## Realtime Security

[requirement] RLS Policies required for users to receive updates #realtime #security
[recommendation] Filter server-side to reduce data exposure #realtime #security
[recommendation] Configure appropriate limits based on use case #realtime #configuration
[recommendation] Always clean up subscriptions when done #realtime #cleanup

## Realtime Testing

[command] `node examples/realtime/test-realtime.js` runs test suite #realtime #testing
[command] `node examples/realtime/basic-subscription.js` tests basic subscription #realtime #testing
[command] `node examples/realtime/table-changes.js` tests table changes #realtime #testing
[command] `node examples/realtime/filtered-subscription.js` tests filtering #realtime #testing
[command] `node examples/realtime/presence.js` tests presence #realtime #testing
[command] `node examples/realtime/broadcast.js` tests broadcast #realtime #testing
[command] `open examples/realtime/rate-limiting.html` tests browser rate limiting #realtime #testing

## Realtime Monitoring

[command] `supabase logs realtime` checks realtime connection logs #realtime #monitoring
[location] Dashboard → Database → Realtime shows realtime metrics #realtime #monitoring

## Realtime Troubleshooting - Not Receiving Updates

[check] Table in publication: `SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'your_table'` #realtime #troubleshooting
[check] RLS policies allow SELECT: `SELECT * FROM pg_policies WHERE tablename = 'your_table'` #realtime #troubleshooting
[check] Replica identity FULL: `SELECT relname, relreplident FROM pg_class WHERE relname = 'your_table'` #realtime #troubleshooting
[check] API keys correct in client configuration #realtime #troubleshooting

## Realtime Troubleshooting - Too Many Connections

[solution] Reduce number of active subscriptions #realtime #optimization
[solution] Share channels between components #realtime #optimization
[solution] Implement connection pooling strategy #realtime #optimization
[solution] Adjust max_connections in config.toml #realtime #configuration

## Realtime Production Recommendations

[recommendation] Set appropriate rate limits based on expected load #realtime #production
[recommendation] Monitor connection count and adjust limits #realtime #production
[recommendation] Implement reconnection logic with exponential backoff #realtime #reliability
[recommendation] Use filters to minimize data transfer #realtime #optimization
[recommendation] Test under load before going to production #realtime #testing
[recommendation] Document realtime patterns for team #realtime #documentation

## MCP AI Agent Integration

[feature] Model Context Protocol (MCP) server infrastructure for AI agents #mcp #ai
[documentation] MCP_SERVER_ARCHITECTURE.md for architecture overview #mcp #docs
[documentation] MCP_SERVER_CONFIGURATION.md for configuration templates #mcp #docs
[documentation] MCP_SESSION_MODE_SETUP.md for session mode setup #mcp #docs
[documentation] MCP_SESSION_VS_TRANSACTION.md for connection mode guide #mcp #docs
[documentation] MCP_AUTHENTICATION.md for authentication strategies #mcp #docs
[documentation] MCP_CONNECTION_EXAMPLES.md for code examples #mcp #docs
[documentation] MCP_IMPLEMENTATION_SUMMARY.md for implementation overview #mcp #docs

## MCP Supported Agent Types

[agenttype] Persistent Agents with Direct IPv6 connection #mcp #agents
[agenttype] Serverless Agents with Transaction pooling #mcp #agents
[agenttype] Edge Agents optimized for low latency #mcp #agents
[agenttype] High-Performance Agents with Dedicated pooler #mcp #agents

## MCP Connection Methods

[connection] Direct Connection via IPv6/IPv4 #mcp #connectivity
[connection] Supavisor Session Mode on port 5432 #mcp #connectivity
[connection] Supavisor Transaction Mode on port 6543 #mcp #connectivity
[connection] Dedicated Pooler with custom configuration #mcp #connectivity

## MCP Authentication Methods

[auth] Service Role Key for full database access #mcp #authentication
[auth] Database User Credentials for limited permissions #mcp #authentication
[auth] JWT Token for RLS-aware access #mcp #authentication
[auth] API Key for rate-limited access #mcp #authentication
[auth] OAuth 2.0 for delegated access #mcp #authentication

## MCP Environment Variables

[envvar] MCP_SERVER_NAME=supabase-mcp-server sets server name #mcp #configuration
[envvar] MCP_SERVER_PORT=3000 sets server port #mcp #configuration
[envvar] DATABASE_URL=postgresql://user:password@host:5432/database for connection #mcp #configuration
[envvar] DB_CONNECTION_TYPE=supavisor_transaction sets connection type #mcp #configuration
[envvar] SUPABASE_SERVICE_ROLE_KEY=your-service-role-key for authentication #mcp #configuration
[envvar] JWT_SECRET=your-jwt-secret for token validation #mcp #configuration
[envvar] ENABLE_MCP_MONITORING=true enables monitoring #mcp #configuration
[envvar] LOG_LEVEL=info sets logging level #mcp #configuration

## External Documentation Resources

[resource] Supabase CLI Reference at https://supabase.com/docs/reference/cli #documentation #official
[resource] Edge Functions Guide at https://supabase.com/docs/guides/functions #documentation #official
[resource] Database Migrations at https://supabase.com/docs/guides/database/migrations #documentation #official
[resource] Row Level Security at https://supabase.com/docs/guides/database/postgres/row-level-security #documentation #official
[resource] Realtime Documentation at https://supabase.com/docs/guides/realtime #documentation #official
[resource] Auth & SSO at https://supabase.com/docs/guides/auth/sso/auth-sso-saml #documentation #official
[resource] Supavisor Documentation at https://supabase.com/docs/guides/database/supavisor #documentation #official

## Project-Specific Documentation

[internal] Contributing Guide at CONTRIBUTING.md #documentation #internal
[internal] Development Workflows at WORKFLOWS.md #documentation #internal
[internal] Troubleshooting Guide at TROUBLESHOOTING.md #documentation #internal
[internal] Architecture Overview at ARCHITECTURE.md #documentation #internal
[internal] ZITADEL SAML IdP Setup at docs/ZITADEL_SAML_IDP_SETUP.md #documentation #internal

## Support Contacts

[contact] Maintainers: @Skogix and @Ic0n for assistance #support #team
[contact] Issues: Open GitHub issue for problems #support #github
[contact] Supabase Support at https://supabase.com/support #support #official
[contact] Community at https://github.com/supabase/supabase/discussions #support #community

## Related Documentation

- [[CI-CD Pipeline]] - Automation and deployment
- [[System Architecture Documentation]] - Architecture overview
- [[Development Workflows]] - Development procedures
- [[Troubleshooting Guide]] - Common issues and solutions
- [[Contributing Guide]] - Contribution guidelines
- [[ZITADEL SAML]] - SAML SSO integration
- [[MCP AI Agents]] - AI agent integration