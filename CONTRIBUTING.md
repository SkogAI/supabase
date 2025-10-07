# Contributing to Supabase Project

Thank you for your interest in contributing to this project! This guide will help you get started with development and understand our contribution workflow.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Guidelines](#code-guidelines)
- [Database Guidelines](#database-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Management](#issue-management)
- [Communication](#communication)

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **[Docker Desktop](https://www.docker.com/products/docker-desktop)** - Must be running for local development
- **[Supabase CLI](https://supabase.com/docs/guides/cli/getting-started)** - Required for database operations
- **[Node.js 18+](https://nodejs.org/)** - For TypeScript types and npm scripts
- **[Deno 2.x](https://deno.land/)** - For edge functions development
- **[Git](https://git-scm.com/)** - Version control

### Initial Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/supabase.git
   cd supabase
   ```

2. **Run the automated setup**
   ```bash
   ./scripts/setup.sh
   ```
   
   This will:
   - Check all prerequisites
   - Create `.env` file from template
   - Install dependencies
   - Start Supabase services
   - Generate TypeScript types
   - Display access information

3. **Verify the setup**
   - Open Studio UI: http://localhost:8000
   - Check services: `supabase status`
   - Test database connection

## Development Workflow

### Creating a Feature Branch

Always create a new branch for your work:

```bash
# Create and switch to a new branch
git checkout -b feature/my-feature-name

# For bug fixes
git checkout -b fix/bug-description

# For documentation
git checkout -b docs/documentation-update
```

**Branch Naming Conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or updates
- `chore/` - Maintenance tasks

### Making Changes

1. **Start development environment**
   ```bash
   ./scripts/dev-start.sh
   # OR
   npm run db:start
   ```

2. **Make your changes**
   - Write clean, well-documented code
   - Follow existing code style and conventions
   - Add tests for new features
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Run RLS tests
   npm run test:rls
   
   # Test edge functions
   npm run test:functions
   
   # Lint code
   npm run lint:sql
   npm run lint:functions
   ```

4. **Generate types if schema changed**
   ```bash
   npm run types:generate
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: clear description of changes"
   ```

### Commit Message Guidelines

Write clear, descriptive commit messages:

**Good examples:**
- `Add RLS policy for posts table`
- `Fix authentication error in edge function`
- `Update documentation for storage buckets`
- `Refactor database migration helper functions`

**Bad examples:**
- `Fix bug`
- `Update code`
- `WIP`

**Commit Message Format:**
```
<type>: <short summary>

<optional detailed description>

<optional footer>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style/formatting
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

## Code Guidelines

### General Principles

- **KISS (Keep It Simple, Stupid)** - Write simple, readable code
- **DRY (Don't Repeat Yourself)** - Avoid code duplication
- **YAGNI (You Aren't Gonna Need It)** - Don't add unnecessary features
- **Separation of Concerns** - Keep code modular and focused

### SQL/Database Code

- Use descriptive table and column names (snake_case)
- Always add comments for complex logic
- Include RLS policies for all public tables
- Add indexes for frequently queried columns
- Use transactions for multiple related operations

**Example:**
```sql
-- Good
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    display_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for common queries
CREATE INDEX idx_user_profiles_user_id ON public.user_profiles(user_id);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
```

### Edge Functions (TypeScript/Deno)

- Use TypeScript for type safety
- Handle errors gracefully
- Return appropriate HTTP status codes
- Configure CORS for browser access
- Place shared utilities in `supabase/functions/_shared/`

**Example:**
```typescript
// Good
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    // Handle CORS
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }

    // Process request
    const { data } = await req.json();
    
    // Validate input
    if (!data) {
      return new Response(
        JSON.stringify({ error: 'Missing data' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Business logic here
    
    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

### Documentation

- Update relevant documentation when making changes
- Use clear, concise language
- Include code examples where helpful
- Add comments for complex logic
- Keep README and guides up to date

## Database Guidelines

### Creating Migrations

1. **Create a new migration**
   ```bash
   npm run migration:new add_feature_name
   ```

2. **Edit the migration file** in `supabase/migrations/`

3. **Follow migration naming conventions:**
   - `add_<table>_table` - New tables
   - `add_<table>_<column>` - New columns
   - `enable_rls_<table>` - Security policies
   - `add_<table>_index` - Performance indexes
   - `update_<table>_<description>` - Schema changes

4. **Test the migration locally**
   ```bash
   npm run db:reset
   ```

5. **Verify RLS policies**
   ```bash
   npm run test:rls
   ```

### RLS Policy Requirements

All public tables MUST have RLS policies for:

1. **Service role** - Full admin access
   ```sql
   CREATE POLICY "Service role full access" ON public.my_table
       FOR ALL TO service_role USING (true) WITH CHECK (true);
   ```

2. **Authenticated users** - Manage own data
   ```sql
   CREATE POLICY "Users manage own data" ON public.my_table
       FOR ALL TO authenticated
       USING (auth.uid() = user_id)
       WITH CHECK (auth.uid() = user_id);
   ```

3. **Anonymous users** - Read-only published content (if applicable)
   ```sql
   CREATE POLICY "Anonymous read published" ON public.my_table
       FOR SELECT TO anon USING (status = 'published');
   ```

### Storage Guidelines

- Organize files in user-scoped paths: `{bucket}/{user_id}/filename.ext`
- Set appropriate file size limits
- Restrict file types where needed
- Always implement RLS policies for storage buckets

## Testing Guidelines

### RLS Policy Testing

Always test RLS policies after database changes:

```bash
npm run test:rls
```

Expected output should show:
- ✅ RLS enabled on all tables
- ✅ Service role access working
- ✅ Authenticated user permissions correct
- ✅ Anonymous user restrictions enforced

### Edge Function Testing

1. **Create test file** in function directory: `test.ts`

2. **Write tests**
   ```typescript
   import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
   
   Deno.test('Function returns expected response', async () => {
     // Test implementation
     const response = await fetch('http://localhost:54321/functions/v1/my-function', {
       method: 'POST',
       body: JSON.stringify({ test: 'data' }),
     });
     
     assertEquals(response.status, 200);
   });
   ```

3. **Run tests**
   ```bash
   cd supabase/functions/my-function
   deno test --allow-all test.ts
   ```

### Manual Testing Checklist

Before submitting a PR, manually verify:

- [ ] All services start without errors
- [ ] Database migrations apply successfully
- [ ] RLS policies work as expected
- [ ] Edge functions respond correctly
- [ ] TypeScript types are up to date
- [ ] Documentation is accurate
- [ ] No secrets or credentials committed

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass**
   ```bash
   npm run test:rls
   npm run test:functions
   npm run lint:sql
   npm run lint:functions
   ```

2. **Update documentation**
   - Update README if adding new features
   - Add or update relevant guides
   - Update CHANGELOG if present

3. **Commit and push your branch**
   ```bash
   git push origin feature/my-feature-name
   ```

### Creating a Pull Request

1. **Go to GitHub and create a new Pull Request**

2. **Fill out the PR template**
   - Provide clear description of changes
   - Link related issues (e.g., "Closes #123")
   - List any breaking changes
   - Add screenshots for UI changes
   - Note any deployment considerations

3. **PR Title Format**
   ```
   [Type] Brief description of changes
   ```
   
   Examples:
   - `[Feature] Add user profile management`
   - `[Fix] Resolve authentication timeout issue`
   - `[Docs] Update RLS policy documentation`

### PR Review Process

1. **Automated checks run** - CI/CD workflows validate your changes
2. **Wait for review** - Maintainers will review your PR
3. **Address feedback** - Make requested changes
4. **Approval** - Once approved, PR will be merged
5. **Deployment** - Changes deploy automatically on merge to main

### After Merge

- Delete your feature branch
- Pull latest changes: `git pull origin develop`
- Verify deployment succeeded

## Issue Management

### Creating Issues

Use our structured issue templates:

- **🐛 Bug Report** - Report issues and unexpected behavior
- **✨ Feature Request** - Suggest new features
- **🔧 DevOps Task** - Infrastructure and CI/CD work
- **🗄️ Database Task** - Schema changes and migrations

**Create an issue**: https://github.com/SkogAI/supabase/issues/new/choose

### Issue Guidelines

**Good issue titles:**
- "Add RLS policy for comments table"
- "Fix edge function timeout on large requests"
- "Configure automated backups for production"

**Bad issue titles:**
- "Fix bug"
- "Help"
- "Error"

**Issue descriptions should include:**
- Clear problem statement or feature request
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Screenshots or logs when relevant
- Acceptance criteria
- Related issues or PRs

For more details, see [docs/ISSUE_MANAGEMENT.md](docs/ISSUE_MANAGEMENT.md)

## Communication

### Getting Help

- **Documentation** - Check README, DEVOPS.md, and docs/ directory
- **GitHub Issues** - Search existing issues or create new one
- **GitHub Discussions** - For questions and general discussions
- **Maintainers** - Contact @Skogix or @Ic0n for assistance

### Being a Good Community Member

- Be respectful and inclusive
- Help others when you can
- Provide constructive feedback
- Follow the code of conduct
- Keep discussions on topic
- Be patient with reviewers and contributors

## Additional Resources

### Documentation

- [README.md](README.md) - Project overview and quick start
- [DEVOPS.md](DEVOPS.md) - Complete DevOps guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture overview
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [WORKFLOWS.md](WORKFLOWS.md) - Detailed development workflows
- [docs/RLS_POLICIES.md](docs/RLS_POLICIES.md) - RLS patterns and best practices
- [docs/STORAGE.md](docs/STORAGE.md) - Storage bucket guide
- [supabase/functions/README.md](supabase/functions/README.md) - Edge functions guide

### External Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Deno Documentation](https://deno.land/manual)

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing! 🎉**

Questions? Open an issue or contact the maintainers.
