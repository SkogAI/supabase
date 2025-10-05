# Contributing to Supabase Project

Thank you for your interest in contributing! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

---

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Desktop** (must be running)
- **Supabase CLI** - [Installation Guide](https://supabase.com/docs/guides/cli/getting-started)
- **Node.js 18+** - For TypeScript types and npm scripts
- **Deno 2.x** - For edge functions development
- **Git** - For version control

### First Time Setup

1. **Fork the repository** on GitHub

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/supabase.git
   cd supabase
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/SkogAI/supabase.git
   ```

4. **Run setup script**
   ```bash
   ./scripts/setup.sh
   ```
   
   This will:
   - Check all prerequisites
   - Create `.env` file
   - Install dependencies
   - Start Supabase services
   - Generate TypeScript types

5. **Verify setup**
   ```bash
   npm run db:status
   # Access Studio at http://localhost:8000
   ```

---

## Development Workflow

### Branching Strategy

- `master`/`main` - Production branch (protected)
- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation updates
- `refactor/*` - Code refactoring

### Creating a New Feature

1. **Update your local repository**
   ```bash
   git checkout master
   git pull upstream master
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-awesome-feature
   ```

3. **Make your changes**
   - Write code
   - Add tests
   - Update documentation

4. **Test locally**
   ```bash
   npm run db:reset          # Test migrations
   npm run test:functions    # Test edge functions
   npm run lint:functions    # Lint your code
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add awesome feature"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/my-awesome-feature
   ```

7. **Open a Pull Request** on GitHub

---

## Coding Standards

### Database Migrations

- **Naming**: Use descriptive names: `YYYYMMDDHHMMSS_description.sql`
- **One purpose per migration**: Keep migrations focused and atomic
- **Always include rollback**: Add comments explaining how to rollback
- **Test locally first**: Run `npm run db:reset` before committing
- **Use transactions**: Wrap in `BEGIN` and `COMMIT` when appropriate
- **Enable RLS**: Always enable Row Level Security on new tables

**Example migration:**
```sql
-- Migration: Add comments table
-- Created: 2025-01-15

BEGIN;

-- Create comments table
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes
CREATE INDEX comments_post_id_idx ON public.comments(post_id);
CREATE INDEX comments_user_id_idx ON public.comments(user_id);

-- Enable RLS
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view all comments"
    ON public.comments FOR SELECT
    USING (true);

CREATE POLICY "Users can create comments"
    ON public.comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

COMMIT;

-- Rollback: DROP TABLE public.comments;
```

### Edge Functions

- **TypeScript**: Use TypeScript for all functions
- **Type safety**: Define interfaces for request/response
- **Error handling**: Always handle errors gracefully
- **CORS**: Include CORS headers in all responses
- **Testing**: Write tests in `test.ts` alongside function
- **Small and focused**: Keep functions under 200 lines

**Example function structure:**
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Define types
interface RequestBody {
  name: string;
}

interface ResponseBody {
  success: boolean;
  data?: any;
  error?: string;
}

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Your logic here
    const body: RequestBody = await req.json();
    
    // Return response
    const response: ResponseBody = {
      success: true,
      data: { message: "Success" },
    };
    
    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    // Error handling
    const response: ResponseBody = {
      success: false,
      error: error.message,
    };
    
    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
```

### Code Style

- **Formatting**: Use Deno formatter for functions: `deno fmt`
- **Linting**: Use Deno linter: `deno lint`
- **SQL**: Use lowercase keywords, 2-space indentation
- **Comments**: Add comments for complex logic
- **Naming**:
  - Tables: `snake_case`, plural
  - Columns: `snake_case`
  - Functions: `camelCase` or `snake_case`
  - TypeScript: `camelCase` for variables, `PascalCase` for types

---

## Commit Guidelines

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, no logic change)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks (deps, config, etc.)
- `perf` - Performance improvements

### Examples

```bash
feat(auth): add password reset functionality

fix(migration): correct posts table RLS policy

docs(readme): update setup instructions

chore(deps): upgrade supabase cli to v1.127.0
```

### Best Practices

- Use imperative mood: "add" not "added" or "adds"
- Keep subject line under 50 characters
- Capitalize subject line
- No period at the end of subject
- Separate subject from body with blank line
- Wrap body at 72 characters
- Explain what and why, not how

---

## Pull Request Process

### Before Opening a PR

1. **Update your branch** with latest upstream changes
   ```bash
   git fetch upstream
   git rebase upstream/master
   ```

2. **Run all checks locally**
   ```bash
   npm run db:reset           # Verify migrations
   npm run test:functions     # Run tests
   npm run lint:functions     # Check linting
   npm run types:generate     # Update types
   ```

3. **Review your changes**
   ```bash
   git diff upstream/master
   ```

### PR Title Format

Use the same format as commit messages:
```
feat(scope): description
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- List of changes
- With bullet points

## Testing
- [ ] Migrations tested locally
- [ ] Functions tested
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
- [ ] All tests passing
```

### Review Process

1. **CI Checks**: All GitHub Actions must pass
   - Migrations validation
   - Function tests
   - Security scans
   - No secrets detected

2. **Code Review**: At least one approval required
   - Review feedback should be addressed
   - Discussions should be resolved

3. **Final Steps**:
   - Squash commits if requested
   - Update PR based on feedback
   - Ensure branch is up to date

4. **Merge**: 
   - Will be merged by maintainers
   - Deployment happens automatically

---

## Testing Guidelines

### Database Testing

Test migrations locally before committing:

```bash
# Reset database (applies all migrations)
npm run db:reset

# Check for errors in Studio
open http://localhost:8000

# Verify RLS policies work
# Try operations as different users in Studio SQL editor
```

### Edge Function Testing

Create tests in `test.ts` alongside your function:

```typescript
import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";

Deno.test("Function returns success", async () => {
  const response = await fetch("http://localhost:54321/functions/v1/my-function", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ test: "data" }),
  });
  
  assertEquals(response.status, 200);
  const data = await response.json();
  assertEquals(data.success, true);
});
```

Run tests:
```bash
npm run test:functions
```

### Manual Testing

Always test your changes manually:

1. **Database changes**: Use Studio to verify tables, policies, data
2. **Functions**: Test with curl or Postman
3. **End-to-end**: Test the complete user flow

---

## Documentation

### When to Update Documentation

Update documentation when you:

- Add new features
- Change existing behavior
- Add new scripts or commands
- Modify configuration
- Fix bugs that users might encounter

### Documentation Files

- **README.md** - Quick start, development workflow
- **DEVOPS.md** - CI/CD, deployment, secrets
- **CONTRIBUTING.md** - This file (contribution guidelines)
- **ARCHITECTURE.md** - System architecture
- **supabase/functions/README.md** - Edge functions guide

### Documentation Style

- Use clear, concise language
- Include code examples
- Add comments to explain non-obvious code
- Keep examples up to date
- Use markdown formatting consistently

---

## Getting Help

### Resources

- **README.md** - Quick start and development guide
- **DEVOPS.md** - DevOps and deployment guide
- **ARCHITECTURE.md** - System architecture overview
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)

### Communication

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Questions and community support
- **Pull Requests** - Code review discussions

### Common Issues

See the [Troubleshooting section](README.md#-troubleshooting) in README.md for common issues and solutions.

---

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information
- Other conduct inappropriate in a professional setting

---

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes for significant contributions
- Project documentation when appropriate

---

## Questions?

If you have questions about contributing, please:
1. Check existing documentation
2. Search GitHub issues
3. Open a new issue with the `question` label

Thank you for contributing! 🎉
