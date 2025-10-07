# Development Workflows

This guide documents common development workflows and step-by-step procedures for working with this project.

## Table of Contents

- [Initial Setup Workflow](#initial-setup-workflow)
- [Daily Development Workflow](#daily-development-workflow)
- [Database Development](#database-development)
- [Edge Function Development](#edge-function-development)
- [Testing Workflow](#testing-workflow)
- [Pull Request Workflow](#pull-request-workflow)
- [Deployment Workflow](#deployment-workflow)
- [Maintenance Workflows](#maintenance-workflows)

## Initial Setup Workflow

### First Time Setup (Automated)

**Goal:** Get a working local environment

**Steps:**

1. **Clone repository**
   ```bash
   git clone https://github.com/SkogAI/supabase.git
   cd supabase
   ```

2. **Run setup script**
   ```bash
   ./scripts/setup.sh
   ```
   
   This automatically:
   - ✅ Checks prerequisites (Docker, Supabase CLI, Node.js, Deno)
   - ✅ Creates `.env` file
   - ✅ Installs npm dependencies
   - ✅ Starts Supabase services
   - ✅ Generates TypeScript types
   - ✅ Shows access URLs

3. **Verify setup**
   - Open Studio: http://localhost:8000
   - Check services: `supabase status`
   - Review seed data in Studio

4. **Configure environment** (optional)
   ```bash
   # Edit .env for API keys (OpenAI, etc.)
   nano .env
   ```

**Expected Time:** 5-10 minutes

### First Time Setup (Manual)

If you prefer manual setup or the script fails:

1. **Check prerequisites**
   ```bash
   docker --version
   supabase --version
   node --version
   deno --version
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Create environment file**
   ```bash
   cp .env.example .env
   # Edit .env as needed
   ```

4. **Start Supabase**
   ```bash
   npm run db:start
   # OR
   ./scripts/dev-start.sh
   ```

5. **Generate types**
   ```bash
   npm run types:generate
   ```

**Expected Time:** 10-15 minutes

## Daily Development Workflow

### Starting Work

**Morning routine:**

1. **Pull latest changes**
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. **Start services**
   ```bash
   ./scripts/dev-start.sh
   # OR
   npm run db:start
   ```

3. **Verify everything works**
   ```bash
   supabase status
   ```
   
   All services should be "healthy"

4. **Create/switch to feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

### During Development

**Iterative development cycle:**

1. **Make code changes**
   - Edit files in your IDE
   - Save frequently

2. **Test locally**
   - For database: `npm run test:rls`
   - For functions: `npm run functions:serve`
   - Manual testing in Studio

3. **Commit frequently**
   ```bash
   git add .
   git commit -m "WIP: descriptive message"
   ```

4. **Generate types if schema changed**
   ```bash
   npm run types:generate
   ```

### Ending Work

**Before stopping for the day:**

1. **Commit final changes**
   ```bash
   git add .
   git commit -m "Complete: feature description"
   ```

2. **Push to remote**
   ```bash
   git push origin feature/my-feature
   ```

3. **Stop services** (optional)
   ```bash
   supabase stop
   ```

## Database Development

### Adding a New Table

**Goal:** Create new table with proper RLS policies

**Steps:**

1. **Create migration**
   ```bash
   npm run migration:new add_my_table
   ```

2. **Edit migration file**
   
   Location: `supabase/migrations/YYYYMMDDHHMMSS_add_my_table.sql`
   
   ```sql
   -- Create table
   CREATE TABLE public.my_table (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
       title TEXT NOT NULL,
       content TEXT,
       status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
       created_at TIMESTAMPTZ DEFAULT NOW(),
       updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   
   -- Add index
   CREATE INDEX idx_my_table_user_id ON public.my_table(user_id);
   
   -- Enable RLS
   ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;
   
   -- Service role policy
   CREATE POLICY "Service role full access" ON public.my_table
       FOR ALL TO service_role USING (true) WITH CHECK (true);
   
   -- Authenticated user policies
   CREATE POLICY "Users view all" ON public.my_table
       FOR SELECT TO authenticated USING (true);
   
   CREATE POLICY "Users manage own" ON public.my_table
       FOR ALL TO authenticated
       USING (auth.uid() = user_id)
       WITH CHECK (auth.uid() = user_id);
   
   -- Anonymous user policy (if needed)
   CREATE POLICY "Anonymous read published" ON public.my_table
       FOR SELECT TO anon USING (status = 'published');
   
   -- Updated_at trigger
   CREATE TRIGGER set_updated_at
       BEFORE UPDATE ON public.my_table
       FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
   
   -- Enable realtime (if needed)
   ALTER PUBLICATION supabase_realtime ADD TABLE public.my_table;
   ALTER TABLE public.my_table REPLICA IDENTITY FULL;
   ```

3. **Apply migration**
   ```bash
   npm run db:reset
   ```

4. **Test RLS policies**
   ```bash
   npm run test:rls
   ```

5. **Generate TypeScript types**
   ```bash
   npm run types:generate
   ```

6. **Commit migration**
   ```bash
   git add supabase/migrations/
   git add types/database.ts
   git commit -m "Add my_table with RLS policies"
   ```

**Expected Time:** 15-30 minutes

### Modifying Existing Table

**Goal:** Add column or change table structure

**Steps:**

1. **Create migration**
   ```bash
   npm run migration:new update_my_table_add_column
   ```

2. **Write migration**
   ```sql
   -- Add column
   ALTER TABLE public.my_table ADD COLUMN new_column TEXT;
   
   -- Add index if needed
   CREATE INDEX idx_my_table_new_column ON public.my_table(new_column);
   
   -- Update existing data if needed
   UPDATE public.my_table SET new_column = 'default_value';
   ```

3. **Test migration**
   ```bash
   npm run db:reset
   ```

4. **Update types**
   ```bash
   npm run types:generate
   ```

5. **Commit changes**
   ```bash
   git add supabase/migrations/ types/
   git commit -m "Add new_column to my_table"
   ```

**Expected Time:** 10-20 minutes

### Testing Database Changes

**Goal:** Verify migrations and RLS work correctly

**Steps:**

1. **Reset database**
   ```bash
   ./scripts/reset.sh
   # OR
   npm run db:reset
   ```

2. **Run RLS tests**
   ```bash
   npm run test:rls
   ```

3. **Manual testing in Studio**
   - Open http://localhost:8000
   - Navigate to Table Editor
   - Verify table structure
   - Insert test data
   - Verify RLS prevents unauthorized access

4. **Test with different users**
   ```sql
   -- In SQL Editor
   -- Test as Alice
   SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
   SELECT * FROM public.my_table;
   
   -- Test as Bob
   SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
   SELECT * FROM public.my_table;
   ```

**Expected Time:** 10-15 minutes

## Edge Function Development

### Creating New Function

**Goal:** Create and test a new edge function

**Steps:**

1. **Create function**
   ```bash
   npm run functions:new my-function
   ```

2. **Edit function code**
   
   Location: `supabase/functions/my-function/index.ts`
   
   ```typescript
   import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
   
   const corsHeaders = {
     'Access-Control-Allow-Origin': '*',
     'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
   };
   
   serve(async (req) => {
     // Handle CORS preflight
     if (req.method === 'OPTIONS') {
       return new Response('ok', { headers: corsHeaders });
     }
   
     try {
       // Initialize Supabase client
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_ANON_KEY') ?? '',
         { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
       );
   
       // Your logic here
       const { data } = await req.json();
       
       // Process request
       const result = { message: 'Success', data };
       
       return new Response(
         JSON.stringify(result),
         { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
       );
     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
       );
     }
   });
   ```

3. **Test function locally**
   ```bash
   supabase functions serve my-function
   ```

4. **Test with curl**
   ```bash
   curl -i --location --request POST 'http://localhost:54321/functions/v1/my-function' \
     --header 'Authorization: Bearer YOUR_ANON_KEY' \
     --header 'Content-Type: application/json' \
     --data '{"key":"value"}'
   ```

5. **Write tests**
   
   Location: `supabase/functions/my-function/test.ts`
   
   ```typescript
   import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
   
   Deno.test('Function returns success', async () => {
     const response = await fetch('http://localhost:54321/functions/v1/my-function', {
       method: 'POST',
       headers: {
         'Content-Type': 'application/json',
       },
       body: JSON.stringify({ test: 'data' }),
     });
     
     assertEquals(response.status, 200);
     const data = await response.json();
     assertEquals(data.message, 'Success');
   });
   ```

6. **Run tests**
   ```bash
   cd supabase/functions/my-function
   deno test --allow-all test.ts
   ```

7. **Commit function**
   ```bash
   git add supabase/functions/my-function/
   git commit -m "Add my-function edge function"
   ```

**Expected Time:** 30-45 minutes

### Updating Existing Function

**Goal:** Modify and redeploy function

**Steps:**

1. **Edit function code**
   ```bash
   # Open in your editor
   code supabase/functions/my-function/index.ts
   ```

2. **Test locally**
   ```bash
   supabase functions serve my-function
   ```

3. **Run tests**
   ```bash
   cd supabase/functions/my-function
   deno test --allow-all test.ts
   ```

4. **Commit changes**
   ```bash
   git add supabase/functions/my-function/
   git commit -m "Update my-function: add new feature"
   ```

**Expected Time:** 15-30 minutes

## Testing Workflow

### Running All Tests

**Goal:** Verify everything works before PR

**Steps:**

1. **Start Supabase**
   ```bash
   npm run db:start
   ```

2. **Test database/RLS**
   ```bash
   npm run test:rls
   ```
   
   Expected: All tests pass ✅

3. **Test edge functions**
   ```bash
   npm run test:functions
   ```
   
   Expected: All tests pass ✅

4. **Lint SQL**
   ```bash
   npm run lint:sql
   ```

5. **Lint/format functions**
   ```bash
   npm run lint:functions
   npm run format:functions
   ```

6. **Generate types**
   ```bash
   npm run types:generate
   ```
   
   Expected: No errors

**Expected Time:** 5-10 minutes

### Testing in Isolation

**Goal:** Test specific component

**Database/RLS:**
```bash
npm run db:reset
npm run test:rls
```

**Single function:**
```bash
supabase functions serve my-function
# In another terminal
cd supabase/functions/my-function
deno test --allow-all test.ts
```

**Storage:**
```bash
supabase db execute --file tests/storage_test_suite.sql
```

## Pull Request Workflow

### Preparing Pull Request

**Goal:** Create PR ready for review

**Steps:**

1. **Ensure branch is up to date**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout feature/my-feature
   git merge develop
   ```

2. **Run all tests**
   ```bash
   npm run test:rls
   npm run test:functions
   npm run lint:sql
   npm run lint:functions
   ```

3. **Generate/update types**
   ```bash
   npm run types:generate
   ```

4. **Review your changes**
   ```bash
   git diff develop
   ```

5. **Clean up commits** (optional)
   ```bash
   git rebase -i develop
   # Squash/fixup commits as needed
   ```

6. **Push to remote**
   ```bash
   git push origin feature/my-feature
   ```

**Expected Time:** 10-15 minutes

### Creating Pull Request

**Goal:** Open PR on GitHub

**Steps:**

1. **Go to GitHub repository**
   https://github.com/SkogAI/supabase

2. **Click "New Pull Request"**

3. **Select branches**
   - Base: `develop`
   - Compare: `feature/my-feature`

4. **Fill PR description**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Changes Made
   - Added new table `my_table`
   - Implemented RLS policies
   - Created edge function `my-function`
   
   ## Testing
   - [x] RLS tests pass
   - [x] Function tests pass
   - [x] Manual testing complete
   
   ## Related Issues
   Closes #123
   
   ## Screenshots (if UI changes)
   [Add screenshots]
   
   ## Deployment Notes
   None
   ```

5. **Create Pull Request**

6. **Wait for CI checks**
   - All workflows must pass
   - Fix any failures

7. **Request review**
   - Tag reviewers
   - Respond to feedback

**Expected Time:** 10-20 minutes

### Addressing Review Feedback

**Goal:** Update PR based on review

**Steps:**

1. **Read review comments**
   - Understand requested changes
   - Ask questions if unclear

2. **Make changes**
   ```bash
   # Edit files
   git add .
   git commit -m "Address review feedback"
   ```

3. **Push updates**
   ```bash
   git push origin feature/my-feature
   ```

4. **Reply to comments**
   - Mark resolved
   - Explain changes made

5. **Wait for re-review**

**Expected Time:** Variable

## Deployment Workflow

### Automatic Deployment

**How it works:**

1. PR merged to `develop` or `main`
2. GitHub Actions triggers deployment workflow
3. Migrations applied to production
4. Edge functions deployed
5. Types generated
6. Deployment verified

**Monitoring:**
- Watch GitHub Actions tab
- Check workflow logs
- Verify in Supabase Dashboard

### Manual Deployment (if needed)

**Goal:** Deploy manually if automation fails

**Steps:**

1. **Login to Supabase**
   ```bash
   supabase login
   ```

2. **Link project**
   ```bash
   supabase link --project-ref YOUR_PROJECT_ID
   ```

3. **Deploy migrations**
   ```bash
   supabase db push
   ```

4. **Deploy functions**
   ```bash
   supabase functions deploy
   # OR deploy specific function
   supabase functions deploy my-function
   ```

5. **Verify deployment**
   - Check Supabase Dashboard
   - Test production endpoints
   - Monitor logs

**Expected Time:** 10-15 minutes

## Maintenance Workflows

### Weekly Maintenance

**Goal:** Keep project healthy

**Checklist:**

- [ ] Review open issues
- [ ] Check CI/CD status
- [ ] Review dependency updates
- [ ] Check database performance
- [ ] Review error logs
- [ ] Update documentation

### Monthly Maintenance

**Goal:** Long-term health

**Checklist:**

- [ ] Backup production database
- [ ] Review and archive old branches
- [ ] Update dependencies
- [ ] Security audit
- [ ] Performance review
- [ ] Documentation review

### Updating Dependencies

**Goal:** Keep packages up to date

**Steps:**

1. **Check for updates**
   ```bash
   npm outdated
   ```

2. **Update packages**
   ```bash
   npm update
   ```

3. **Test everything**
   ```bash
   npm run test:rls
   npm run test:functions
   ```

4. **Commit updates**
   ```bash
   git add package.json package-lock.json
   git commit -m "Update dependencies"
   ```

**Expected Time:** 15-30 minutes

### Database Backup

**Goal:** Create manual backup

**Steps:**

1. **Export schema**
   ```bash
   supabase db dump -f backup-schema.sql --schema public
   ```

2. **Export data**
   ```bash
   supabase db dump -f backup-data.sql --data-only
   ```

3. **Store backups securely**
   - Encrypt if contains sensitive data
   - Store in secure location
   - Document backup date

**Expected Time:** 5-10 minutes

## Quick Reference

### Common Command Sequences

**Start fresh:**
```bash
supabase stop
supabase start
npm run db:reset
npm run types:generate
```

**New feature setup:**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
npm run db:start
```

**Pre-PR checklist:**
```bash
npm run test:rls
npm run test:functions
npm run lint:sql
npm run lint:functions
npm run types:generate
git push origin feature/my-feature
```

---

**Questions?** See [CONTRIBUTING.md](CONTRIBUTING.md) or open an issue.
