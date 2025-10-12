# Troubleshooting Guide

This guide covers common issues and their solutions when working with this Supabase project.

## Table of Contents

- [Setup Issues](#setup-issues)
- [Docker Issues](#docker-issues)
- [Database Issues](#database-issues)
- [Migration Issues](#migration-issues)
- [Edge Function Issues](#edge-function-issues)
- [Type Generation Issues](#type-generation-issues)
- [RLS Policy Issues](#rls-policy-issues)
- [Storage Issues](#storage-issues)
- [Realtime Issues](#realtime-issues)
- [Authentication Issues](#authentication-issues)
- [CI/CD Issues](#cicd-issues)
- [Performance Issues](#performance-issues)
- [Getting Help](#getting-help)

## Setup Issues

### Prerequisites Not Met

**Symptoms:**
- Setup script fails immediately
- Commands not found errors

**Solution:**

1. **Check Docker is installed and running**
   ```bash
   docker --version
   docker info
   ```
   
   If Docker is not running:
   - Start Docker Desktop application
   - Wait for Docker to fully start
   - Try again

2. **Check Supabase CLI is installed**
   ```bash
   supabase --version
   ```
   
   If not installed:
   ```bash
   # macOS/Linux
   brew install supabase/tap/supabase
   
   # Windows
   scoop install supabase
   
   # npm (all platforms)
   npm install -g supabase
   ```

3. **Check Node.js is installed** (optional but recommended)
   ```bash
   node --version
   npm --version
   ```
   
   If not installed: Visit https://nodejs.org/

4. **Check Deno is installed** (for edge functions)
   ```bash
   deno --version
   ```
   
   If not installed: Visit https://deno.land/

### Environment File Issues

**Symptoms:**
- `.env` file missing
- Environment variables not loading

**Solution:**

1. **Create `.env` from template**
   ```bash
   cp .env.example .env
   ```

2. **Verify `.env` exists**
   ```bash
   ls -la .env
   ```

3. **Check `.env` is not committed**
   ```bash
   git status
   # .env should not appear in git status
   ```

4. **Edit `.env` and add required values**
   ```bash
   # Open in your editor
   nano .env
   # or
   code .env
   ```

## Docker Issues

### Docker Not Running

**Symptoms:**
- "Cannot connect to Docker daemon" error
- `docker info` fails

**Solution:**

1. **Start Docker Desktop**
   - macOS: Open Docker Desktop from Applications
   - Windows: Open Docker Desktop from Start Menu
   - Linux: `sudo systemctl start docker`

2. **Wait for Docker to be ready**
   - Check the Docker icon in system tray
   - Wait until it shows "Docker Desktop is running"

3. **Verify Docker is running**
   ```bash
   docker info
   ```

### Port Conflicts

**Symptoms:**
- "Port already in use" error
- Services fail to start

**Solution:**

1. **Check what's using the ports**
   ```bash
   # Check Studio port (8000)
   lsof -i :8000
   
   # Check Database port (54322)
   lsof -i :54322
   
   # Check Functions port (54321)
   lsof -i :54321
   ```

2. **Stop conflicting services**
   ```bash
   # Kill process using port (replace PID with actual process ID)
   kill -9 <PID>
   ```

3. **Stop all Supabase services and restart**
   ```bash
   supabase stop
   supabase start
   ```

4. **Change ports** (if needed)
   Edit `supabase/config.toml`:
   ```toml
   [api]
   port = 8001  # Change to available port
   ```

### Docker Out of Space

**Symptoms:**
- "No space left on device" error
- Build failures

**Solution:**

1. **Check Docker disk usage**
   ```bash
   docker system df
   ```

2. **Clean up unused resources**
   ```bash
   # Remove stopped containers
   docker container prune
   
   # Remove unused images
   docker image prune -a
   
   # Remove unused volumes
   docker volume prune
   
   # Remove everything (careful!)
   docker system prune -a --volumes
   ```

3. **Increase Docker resources**
   - Open Docker Desktop
   - Go to Settings → Resources
   - Increase Disk Image Size

## Database Issues

### Cannot Connect to Database

**Symptoms:**
- Connection timeout
- "Connection refused" error

**Solution:**

1. **Check Supabase is running**
   ```bash
   supabase status
   ```

2. **Verify database port**
   ```bash
   lsof -i :54322
   ```

3. **Check connection string**
   ```bash
   # Should be:
   postgresql://postgres:postgres@localhost:54322/postgres
   ```

4. **Test connection**
   ```bash
   psql postgresql://postgres:postgres@localhost:54322/postgres
   ```

### Database Won't Start

**Symptoms:**
- Database container keeps restarting
- Database health check fails

**Solution:**

1. **Check Docker logs**
   ```bash
   docker logs supabase_db_<project>
   ```

2. **Reset database**
   ```bash
   supabase db reset
   ```

3. **Stop and remove all containers**
   ```bash
   supabase stop
   docker ps -a | grep supabase | awk '{print $1}' | xargs docker rm -f
   supabase start
   ```

4. **Check disk space**
   ```bash
   df -h
   ```

## Migration Issues

### Migration Fails to Apply

**Symptoms:**
- Error during `supabase db reset`
- Migration stuck or fails

**Solution:**

1. **Check migration syntax**
   ```bash
   # Validate SQL syntax
   psql postgresql://postgres:postgres@localhost:54322/postgres -f supabase/migrations/XXXXXXX_my_migration.sql --dry-run
   ```

2. **Check for missing dependencies**
   - Ensure migrations run in order
   - Check for missing tables, columns, or functions

3. **Run with debug output**
   ```bash
   supabase db reset --debug
   ```

4. **Apply migrations one at a time**
   ```bash
   supabase db reset --version YYYYMMDDHHMMSS
   ```

### Migration Out of Order

**Symptoms:**
- Migrations not applying in correct order
- Dependency errors

**Solution:**

1. **Check migration timestamps**
   ```bash
   ls -la supabase/migrations/
   ```
   
   Migrations should be in chronological order by timestamp.

2. **Rename migration if needed**
   ```bash
   # Create new migration with correct timestamp
   npm run migration:new fix_my_migration
   # Copy content from old migration
   # Delete old migration
   ```

3. **Reset and reapply**
   ```bash
   supabase db reset
   ```

## Edge Function Issues

### Function Fails to Deploy

**Symptoms:**
- Deployment error
- Function not accessible

**Solution:**

1. **Check function syntax**
   ```bash
   deno check supabase/functions/my-function/index.ts
   ```

2. **Test locally first**
   ```bash
   supabase functions serve my-function
   ```

3. **Check for missing dependencies**
   - Verify all imports are valid
   - Check import URLs are accessible

4. **Check function logs**
   ```bash
   supabase functions logs my-function
   ```

### Function Times Out

**Symptoms:**
- Request takes too long
- 504 Gateway Timeout error

**Solution:**

1. **Optimize function code**
   - Reduce database queries
   - Cache when possible
   - Use async/await properly

2. **Check for infinite loops**
   - Review logic
   - Add timeouts to external calls

3. **Increase timeout** (if supported)
   Check function configuration in Supabase Dashboard

### Function Can't Access Database

**Symptoms:**
- Connection errors
- Authentication failures

**Solution:**

1. **Check Supabase client initialization**
   ```typescript
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
   
   const supabaseUrl = Deno.env.get('SUPABASE_URL')
   const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')
   const supabase = createClient(supabaseUrl!, supabaseKey!)
   ```

2. **Verify environment variables**
   - Check Supabase Dashboard → Edge Functions → Secrets
   - Ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set

3. **Check RLS policies**
   - Function may be blocked by RLS
   - Use service role key for admin access (careful!)

## Type Generation Issues

### Types Won't Generate

**Symptoms:**
- `npm run types:generate` fails
- Types out of date

**Solution:**

1. **Ensure Supabase is running**
   ```bash
   supabase start
   ```

2. **Check database connection**
   ```bash
   supabase status
   ```

3. **Generate types manually**
   ```bash
   supabase gen types typescript --local > types/database.ts
   ```

4. **Check for schema errors**
   ```bash
   # Connect to database and check for issues
   psql postgresql://postgres:postgres@localhost:54322/postgres
   \dt public.*
   ```

### Type Errors After Generation

**Symptoms:**
- TypeScript compilation errors
- Unexpected types

**Solution:**

1. **Regenerate types**
   ```bash
   npm run types:generate
   ```

2. **Clear TypeScript cache**
   ```bash
   rm -rf node_modules/.cache
   ```

3. **Restart TypeScript server**
   - In VS Code: Ctrl+Shift+P → "TypeScript: Restart TS Server"

## RLS Policy Issues

### Access Denied Errors

**Symptoms:**
- "permission denied" errors
- Cannot read/write data

**Solution:**

1. **Check if RLS is enabled**
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public';
   ```

2. **Verify policies exist**
   ```sql
   SELECT * FROM pg_policies WHERE schemaname = 'public';
   ```

3. **Test with service role**
   - Use service role key to verify data exists
   - This bypasses RLS

4. **Run RLS tests**
   ```bash
   npm run test:rls
   ```

5. **Check user authentication**
   ```sql
   -- In psql
   SELECT auth.uid();  -- Should return user ID
   ```

### RLS Tests Fail

**Symptoms:**
- `npm run test:rls` shows failures
- Policies not working as expected

**Solution:**

1. **Read test output carefully**
   - Identifies which policies fail
   - Shows expected vs actual behavior

2. **Check policy conditions**
   ```sql
   -- Example: Users should access own data
   CREATE POLICY "Users manage own data" ON public.my_table
       FOR ALL TO authenticated
       USING (auth.uid() = user_id)
       WITH CHECK (auth.uid() = user_id);
   ```

3. **Verify test data**
   - Check `supabase/seed.sql`
   - Ensure test users exist

4. **Test policies manually**
   ```sql
   -- Set user context
   SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
   
   -- Try query
   SELECT * FROM public.my_table;
   ```

## Storage Issues

### Cannot Upload Files

**Symptoms:**
- Upload fails
- Permission denied

**Solution:**

1. **Check bucket exists**
   ```sql
   SELECT * FROM storage.buckets;
   ```

2. **Verify RLS policies**
   ```sql
   SELECT * FROM pg_policies 
   WHERE schemaname = 'storage' AND tablename = 'objects';
   ```

3. **Check file size limits**
   - Default: 50MB
   - Configure in bucket settings

4. **Verify file path format**
   ```
   Correct: {bucket}/{user_id}/filename.ext
   Wrong: {bucket}/filename.ext
   ```

5. **Test with service role key**
   - Upload using service role to verify bucket works
   - Then fix policy

### Files Not Accessible

**Symptoms:**
- 404 errors
- Cannot download files

**Solution:**

1. **Check file exists**
   ```sql
   SELECT * FROM storage.objects WHERE bucket_id = 'my-bucket';
   ```

2. **Verify bucket is public** (if should be public)
   ```sql
   SELECT * FROM storage.buckets WHERE id = 'my-bucket';
   ```

3. **Check download policy**
   ```sql
   SELECT * FROM pg_policies 
   WHERE schemaname = 'storage' 
   AND tablename = 'objects'
   AND cmd = 'SELECT';
   ```

## Realtime Issues

### Not Receiving Updates

**Symptoms:**
- Client doesn't receive changes
- Subscription not working

**Solution:**

1. **Check table is in realtime publication**
   ```sql
   SELECT * FROM pg_publication_tables 
   WHERE pubname = 'supabase_realtime';
   ```

2. **Add table to publication**
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE public.my_table;
   ```

3. **Check replica identity**
   ```sql
   SELECT relname, relreplident 
   FROM pg_class 
   WHERE relname = 'my_table';
   ```
   
   Should be 'f' (FULL):
   ```sql
   ALTER TABLE public.my_table REPLICA IDENTITY FULL;
   ```

4. **Verify RLS allows SELECT**
   ```sql
   -- User must have SELECT permission
   CREATE POLICY "Users view all" ON public.my_table
       FOR SELECT TO authenticated USING (true);
   ```

5. **Check client subscription**
   ```javascript
   // Verify channel is set up correctly
   const channel = supabase
     .channel('my-channel')
     .on('postgres_changes', 
       { event: '*', schema: 'public', table: 'my_table' },
       (payload) => console.log(payload)
     )
     .subscribe()
   ```

### Connection Issues

**Symptoms:**
- "Connection failed" errors
- Realtime not connecting

**Solution:**

1. **Check network connectivity**
   - Verify internet connection
   - Check firewall settings

2. **Verify API keys**
   - Check anon key is correct
   - Ensure key has realtime permissions

3. **Check browser console**
   - Look for WebSocket errors
   - Check for CORS issues

## Authentication Issues

### Cannot Sign In

**Symptoms:**
- Login fails
- Invalid credentials error

**Solution:**

1. **Verify user exists**
   ```sql
   SELECT * FROM auth.users WHERE email = 'user@example.com';
   ```

2. **Check email confirmation**
   - Email confirmation may be required
   - Check Supabase Dashboard → Authentication → Settings

3. **Reset password**
   ```javascript
   await supabase.auth.resetPasswordForEmail('user@example.com')
   ```

4. **Check rate limits**
   - Too many failed attempts may trigger rate limit
   - Wait and try again

### Session Expires Too Quickly

**Symptoms:**
- User logged out unexpectedly
- Token expires

**Solution:**

1. **Check JWT expiry settings**
   - Supabase Dashboard → Settings → API
   - Default: 1 hour

2. **Implement token refresh**
   ```javascript
   supabase.auth.onAuthStateChange((event, session) => {
     if (event === 'TOKEN_REFRESHED') {
       console.log('Token refreshed')
     }
   })
   ```

## CI/CD Issues

### Workflow Fails

**Symptoms:**
- GitHub Actions workflow fails
- Deployment doesn't work

**Solution:**

1. **Check secrets are set**
   ```bash
   gh secret list
   ```
   
   Required:
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_PROJECT_ID`
   - `SUPABASE_DB_PASSWORD`

2. **Check workflow logs**
   - Go to GitHub Actions tab
   - Click on failed workflow
   - Read error messages

3. **Test locally first**
   ```bash
   # Test migrations
   npm run db:reset
   
   # Test functions
   npm run functions:serve
   ```

4. **Verify credentials**
   ```bash
   # Test Supabase CLI login
   supabase login
   supabase projects list
   ```

### Deployment Hangs

**Symptoms:**
- Deployment takes very long
- No progress in logs

**Solution:**

1. **Cancel and restart workflow**
   - Go to GitHub Actions
   - Cancel running workflow
   - Re-run workflow

2. **Check Supabase status**
   - Visit status.supabase.com
   - Check for service outages

3. **Break into smaller deployments**
   - Deploy migrations separately from functions
   - Deploy one function at a time

## Performance Issues

### Slow Query Performance

**Symptoms:**
- Queries take too long
- Database timeouts

**Solution:**

1. **Add indexes**
   ```sql
   -- Index foreign keys
   CREATE INDEX idx_posts_user_id ON public.posts(user_id);
   
   -- Index frequently queried columns
   CREATE INDEX idx_posts_created_at ON public.posts(created_at);
   ```

2. **Analyze query performance**
   ```sql
   EXPLAIN ANALYZE SELECT * FROM public.posts WHERE user_id = 'xxx';
   ```

3. **Optimize RLS policies**
   - Ensure policies are not too complex
   - Add indexes on columns used in policies

4. **Use pagination**
   ```javascript
   // Instead of fetching all rows
   const { data } = await supabase
     .from('posts')
     .select('*')
     .range(0, 9)  // First 10 items
   ```

### High Memory Usage

**Symptoms:**
- Out of memory errors
- System slow

**Solution:**

1. **Increase Docker memory**
   - Docker Desktop → Settings → Resources
   - Increase Memory limit

2. **Optimize queries**
   - Select only needed columns
   - Use pagination
   - Avoid large JOINs

3. **Clean up Docker**
   ```bash
   docker system prune -a
   ```

## Getting Help

### Before Asking for Help

1. **Search existing issues**
   - GitHub Issues: https://github.com/SkogAI/supabase/issues
   - Supabase Discussions: https://github.com/orgs/supabase/discussions

2. **Check documentation**
   - Project docs: README.md, DEVOPS.md, etc.
   - Supabase docs: https://supabase.com/docs

3. **Try to isolate the problem**
   - What exact steps reproduce the issue?
   - Does it work in a fresh project?
   - What changed before it broke?

### How to Ask for Help

When creating an issue, include:

1. **Clear description**
   - What you're trying to do
   - What you expected to happen
   - What actually happened

2. **Steps to reproduce**
   ```
   1. Run `supabase start`
   2. Execute `npm run db:reset`
   3. See error
   ```

3. **Environment info**
   ```bash
   # Include output of:
   supabase --version
   docker --version
   node --version
   # OS and version
   ```

4. **Error messages**
   - Full error text
   - Stack traces
   - Relevant logs

5. **What you've tried**
   - Solutions already attempted
   - Workarounds tested

### Where to Get Help

- **GitHub Issues**: https://github.com/SkogAI/supabase/issues
- **Maintainers**: @Skogix or @Ic0n
- **Supabase Discord**: https://discord.supabase.com
- **Supabase Support**: https://supabase.com/support

## Quick Reference

### Common Commands

```bash
# Start/Stop
supabase start
supabase stop
supabase status

# Database
npm run db:reset
npm run db:diff
npm run migration:new <name>

# Functions
npm run functions:serve
npm run functions:deploy

# Testing
npm run test:rls
npm run test:functions

# Types
npm run types:generate

# Docker
docker ps
docker logs <container>
docker system prune
```

### Useful SQL Queries

```sql
-- Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- List all policies
SELECT * FROM pg_policies WHERE schemaname = 'public';

-- Check realtime tables
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

-- Check storage buckets
SELECT * FROM storage.buckets;

-- View current user
SELECT auth.uid();
```

---

**Still stuck?** Open an issue with details: https://github.com/SkogAI/supabase/issues/new/choose
