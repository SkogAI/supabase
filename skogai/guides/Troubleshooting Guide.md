---
title: Troubleshooting Guide
type: note
permalink: guides/troubleshooting-guide
tags:
- troubleshooting
- debugging
- problems
- solutions
- errors
---

# Troubleshooting Guide

Comprehensive guide covering common issues and solutions across all project components.

## Setup Issues

[symptom] Setup script fails immediately #setup #failure
[symptom] Commands not found errors during setup #setup #installation
[solution] Check Docker installed and running with `docker --version` and `docker info` #docker #validation
[solution] Start Docker Desktop application and wait for full startup #docker #startup
[solution] Install Supabase CLI via brew, scoop, or npm #supabase #installation
[solution] Install Node.js from https://nodejs.org/ #nodejs #installation
[solution] Install Deno from https://deno.land/ #deno #installation

[symptom] `.env` file missing #configuration #environment
[symptom] Environment variables not loading #configuration #runtime
[solution] Create `.env` from template with `cp .env.example .env` #configuration #setup
[solution] Verify `.env` exists with `ls -la .env` #validation #filesystem
[solution] Check `.env` not committed with `git status` #security #gitignore
[solution] Edit `.env` and add required values #configuration #editing

## Docker Issues

[symptom] "Cannot connect to Docker daemon" error #docker #connection
[symptom] `docker info` command fails #docker #daemon
[solution] Start Docker Desktop from Applications or Start Menu #docker #startup
[solution] On Linux use `sudo systemctl start docker` #docker #linux
[solution] Wait for Docker icon to show "Docker Desktop is running" #docker #status
[solution] Verify Docker running with `docker info` command #docker #validation

[symptom] "Port already in use" error #docker #networking
[symptom] Services fail to start due to port conflicts #docker #ports
[solution] Check port 8000 usage with `lsof -i :8000` #troubleshooting #ports
[solution] Check port 54322 usage with `lsof -i :54322` #troubleshooting #ports
[solution] Check port 54321 usage with `lsof -i :54321` #troubleshooting #ports
[solution] Kill process using port with `kill -9 <PID>` #troubleshooting #processes
[solution] Stop all Supabase services with `supabase stop` and restart #supabase #reset
[solution] Change ports in `supabase/config.toml` if needed #configuration #ports

[symptom] "No space left on device" error #docker #storage
[symptom] Build failures due to disk space #docker #resources
[solution] Check Docker disk usage with `docker system df` #docker #monitoring
[solution] Remove stopped containers with `docker container prune` #docker #cleanup
[solution] Remove unused images with `docker image prune -a` #docker #cleanup
[solution] Remove unused volumes with `docker volume prune` #docker #cleanup
[solution] Increase Docker Disk Image Size in Settings → Resources #docker #configuration

## Database Issues

[symptom] Connection timeout to database #database #connectivity
[symptom] "Connection refused" error #database #networking
[solution] Check Supabase running with `supabase status` #validation #monitoring
[solution] Verify database port with `lsof -i :54322` #validation #networking
[solution] Test connection with `psql postgresql://postgres:postgres@localhost:54322/postgres` #testing #connectivity
[connection] Connection string format: `postgresql://postgres:postgres@localhost:54322/postgres` #database #configuration

[symptom] Database container keeps restarting #database #stability
[symptom] Database health check fails #database #health
[solution] Check Docker logs with `docker logs supabase_db_<project>` #debugging #logs
[solution] Reset database with `supabase db reset` #database #reset
[solution] Stop and remove all containers then restart #docker #cleanup
[solution] Check disk space with `df -h` #system #resources

## Migration Issues

[symptom] Error during `supabase db reset` #migration #execution
[symptom] Migration stuck or fails to apply #migration #failure
[solution] Validate SQL syntax with psql dry-run flag #validation #sql
[solution] Check for missing dependencies like tables, columns, or functions #migration #dependencies
[solution] Run with debug output using `supabase db reset --debug` #debugging #verbose
[solution] Apply migrations one at a time with version flag #migration #incremental

[symptom] Migrations not applying in correct order #migration #ordering
[symptom] Dependency errors between migrations #migration #dependencies
[solution] Check migration timestamps with `ls -la supabase/migrations/` #validation #filesystem
[solution] Rename migration with correct timestamp if needed #migration #fix
[solution] Create new migration and copy content from old one #migration #recreation
[solution] Reset and reapply with `supabase db reset` #migration #reset

## Edge Function Issues

[symptom] Function deployment error #functions #deployment
[symptom] Function not accessible after deployment #functions #accessibility
[solution] Check function syntax with `deno check supabase/functions/my-function/index.ts` #validation #typescript
[solution] Test locally first with `supabase functions serve my-function` #testing #local
[solution] Verify all imports are valid and URLs accessible #dependencies #imports
[solution] Check function logs with `supabase functions logs my-function` #debugging #logs

[symptom] Function request takes too long #functions #performance
[symptom] 504 Gateway Timeout error #functions #timeout
[solution] Optimize function code by reducing database queries #optimization #performance
[solution] Implement caching where possible #optimization #caching
[solution] Use async/await properly for concurrent operations #javascript #async
[solution] Check for infinite loops in logic #debugging #logic
[solution] Add timeouts to external API calls #reliability #timeout

[symptom] Function connection errors to database #functions #database
[symptom] Function authentication failures #functions #auth
[solution] Check Supabase client initialization with correct URL and key #configuration #initialization
[solution] Verify environment variables in Supabase Dashboard → Edge Functions → Secrets #configuration #secrets
[solution] Check RLS policies may be blocking function access #security #rls
[solution] Use service role key for admin access if needed #auth #admin

## Type Generation Issues

[symptom] `npm run types:generate` fails #types #generation
[symptom] Types out of date with schema #types #sync
[solution] Ensure Supabase running with `supabase start` #requirement #services
[solution] Check database connection with `supabase status` #validation #connectivity
[solution] Generate types manually with `supabase gen types typescript --local > types/database.ts` #workaround #manual
[solution] Check for schema errors by connecting to database with psql #validation #schema

[symptom] TypeScript compilation errors after generation #types #compilation
[symptom] Unexpected types in generated file #types #schema
[solution] Regenerate types with `npm run types:generate` #fix #regeneration
[solution] Clear TypeScript cache with `rm -rf node_modules/.cache` #cleanup #cache
[solution] Restart TypeScript server in VS Code with "TypeScript: Restart TS Server" #ide #typescript

## RLS Policy Issues

[symptom] "permission denied" errors #rls #access
[symptom] Cannot read/write data with authenticated user #rls #authorization
[solution] Check if RLS enabled with pg_tables query #validation #rls
[solution] Verify policies exist with pg_policies query #validation #policies
[solution] Test with service role key to verify data exists #testing #bypass
[solution] Run RLS tests with `npm run test:rls` #testing #automation
[solution] Check user authentication with `SELECT auth.uid()` #validation #auth

[symptom] `npm run test:rls` shows failures #testing #rls
[symptom] Policies not working as expected #rls #behavior
[solution] Read test output carefully to identify failing policies #debugging #analysis
[solution] Check policy conditions match expected logic #validation #logic
[solution] Verify test data exists in seed.sql #testing #data
[solution] Test policies manually with SET request.jwt.claim.sub #testing #manual

## Storage Issues

[symptom] Cannot upload files to bucket #storage #upload
[symptom] Permission denied on file upload #storage #access
[solution] Check bucket exists with storage.buckets query #validation #bucket
[solution] Verify RLS policies on storage.objects #validation #rls
[solution] Check file size limits in bucket settings #configuration #limits
[solution] Verify file path format: `{bucket}/{user_id}/filename.ext` #pattern #path
[solution] Test with service role key to verify bucket works #testing #bypass

[symptom] 404 errors when accessing files #storage #notfound
[symptom] Cannot download uploaded files #storage #download
[solution] Check file exists with storage.objects query #validation #data
[solution] Verify bucket is public if should be accessible without auth #configuration #visibility
[solution] Check download policy on storage.objects #validation #policies

## Realtime Issues

[symptom] Not receiving database updates #realtime #subscription
[symptom] Subscription not working for table changes #realtime #events
[solution] Check table in realtime publication with pg_publication_tables query #validation #publication
[solution] Add table to publication with `ALTER PUBLICATION supabase_realtime ADD TABLE` #fix #publication
[solution] Check replica identity with pg_class query #validation #replication
[solution] Set replica identity to FULL with `ALTER TABLE REPLICA IDENTITY FULL` #fix #replication
[solution] Verify RLS allows SELECT permission for user #security #policies
[solution] Check client subscription channel setup correctly #client #configuration

[symptom] "Connection failed" errors in realtime #realtime #connectivity
[symptom] Realtime not connecting from client #realtime #websocket
[solution] Check network connectivity and firewall settings #network #security
[solution] Verify API keys correct and have realtime permissions #auth #keys
[solution] Check browser console for WebSocket errors #debugging #browser
[solution] Check for CORS issues in network tab #security #cors

## Authentication Issues

[symptom] Cannot sign in with credentials #auth #login
[symptom] Invalid credentials error #auth #credentials
[solution] Verify user exists with auth.users query #validation #user
[solution] Check email confirmation may be required #configuration #email
[solution] Reset password with `supabase.auth.resetPasswordForEmail()` #fix #password
[solution] Check rate limits may be triggered by failed attempts #security #ratelimit

[symptom] User logged out unexpectedly #auth #session
[symptom] Token expires too quickly #auth #jwt
[solution] Check JWT expiry settings in Supabase Dashboard → Settings → API #configuration #jwt
[solution] Implement token refresh with onAuthStateChange listener #client #refresh
[default] Default JWT expiry is 1 hour #configuration #jwt

## CI/CD Issues

[symptom] GitHub Actions workflow fails #cicd #failure
[symptom] Deployment doesn't work #cicd #deployment
[solution] Check secrets set with `gh secret list` #validation #secrets
[requirement] Required secrets: SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_ID, SUPABASE_DB_PASSWORD #configuration #secrets
[solution] Check workflow logs in GitHub Actions tab #debugging #logs
[solution] Read error messages in failed workflow details #debugging #analysis
[solution] Test locally first with db reset and functions serve #testing #local
[solution] Verify credentials with `supabase login` and `supabase projects list` #validation #auth

[symptom] Deployment hangs without progress #cicd #timeout
[symptom] No progress in deployment logs #cicd #stuck
[solution] Cancel and restart workflow from GitHub Actions #fix #retry
[solution] Check Supabase status at status.supabase.com #monitoring #status
[solution] Break into smaller deployments for migrations and functions separately #strategy #incremental
[solution] Deploy one function at a time if batch fails #strategy #isolation

## Performance Issues

[symptom] Queries take too long to execute #performance #database
[symptom] Database timeouts #performance #timeout
[solution] Add indexes on foreign keys and frequently queried columns #optimization #indexes
[solution] Analyze query performance with `EXPLAIN ANALYZE` #debugging #analysis
[solution] Optimize RLS policies to not be too complex #optimization #security
[solution] Add indexes on columns used in RLS policies #optimization #performance
[solution] Use pagination with range() instead of fetching all rows #optimization #pagination

[symptom] Out of memory errors #performance #resources
[symptom] System slow due to high memory usage #performance #memory
[solution] Increase Docker memory in Settings → Resources #configuration #docker
[solution] Select only needed columns instead of SELECT * #optimization #queries
[solution] Use pagination for large result sets #optimization #pagination
[solution] Avoid large JOINs that multiply rows #optimization #queries
[solution] Clean up Docker with `docker system prune -a` #maintenance #cleanup

## Getting Help Resources

[resource] GitHub Issues at https://github.com/SkogAI/supabase/issues #support #github
[resource] Supabase Discussions at https://github.com/orgs/supabase/discussions #support #community
[resource] Project docs: README.md, DEVOPS.md, etc. #documentation #local
[resource] Supabase docs at https://supabase.com/docs #documentation #official
[resource] Maintainers: @Skogix and @Ic0n #support #contacts
[resource] Supabase Discord at https://discord.supabase.com #community #chat
[resource] Supabase Support at https://supabase.com/support #support #official

## Issue Reporting Best Practices

[requirement] Include clear description of what you're trying to do #documentation #clarity
[requirement] Include what you expected to happen vs what actually happened #documentation #comparison
[requirement] Provide steps to reproduce the issue #documentation #reproduction
[requirement] Include environment info: versions of supabase, docker, node, OS #documentation #environment
[requirement] Include full error text, stack traces, and relevant logs #documentation #errors
[requirement] Document solutions already attempted and workarounds tested #documentation #attempts

## Quick Reference Commands

[command] `supabase start` starts local Supabase services #startup #local
[command] `supabase stop` stops local Supabase services #shutdown #local
[command] `supabase status` shows service status #monitoring #status
[command] `npm run db:reset` resets database with all migrations #database #reset
[command] `npm run db:diff` generates SQL diff of changes #database #comparison
[command] `npm run migration:new <name>` creates new migration #database #creation
[command] `npm run functions:serve` serves functions locally #functions #development
[command] `npm run functions:deploy` deploys functions to production #functions #deployment
[command] `npm run test:rls` tests RLS policies #testing #security
[command] `npm run test:functions` tests edge functions #testing #functions
[command] `npm run types:generate` generates TypeScript types #types #codegen
[command] `docker ps` lists running containers #docker #monitoring
[command] `docker logs <container>` shows container logs #docker #debugging
[command] `docker system prune` cleans up Docker resources #docker #maintenance

## Useful SQL Queries

[query] Check RLS: `SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public'` #sql #rls
[query] List policies: `SELECT * FROM pg_policies WHERE schemaname = 'public'` #sql #policies
[query] Check realtime: `SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime'` #sql #realtime
[query] Check buckets: `SELECT * FROM storage.buckets` #sql #storage
[query] View current user: `SELECT auth.uid()` #sql #auth

## Related Documentation

- [[Development Workflows]] - Step-by-step procedures
- [[Contributing Guide]] - Development guidelines
- [[Project Architecture]] - System architecture
- [[Row Level Security]] - RLS patterns
- [[Storage Architecture]] - Storage configuration
- [[CI-CD Pipeline]] - Deployment automation