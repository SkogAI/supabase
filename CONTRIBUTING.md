# Contributing to Supabase Project

Thank you for your interest in contributing! This guide will help you get started with development and understand our workflows.

## Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) (required, must be running)
- [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) (required)
- [Node.js 18+](https://nodejs.org/) (recommended for TypeScript types)
- [Deno 2.x](https://deno.land/) (required for edge functions)
- [GitHub CLI](https://cli.github.com/) (optional, for easier workflow)

### Setup Development Environment

The fastest way to get started:

```bash
# Run automated setup
./scripts/setup.sh
```

This will check prerequisites, install dependencies, start Supabase, and generate types.

**Manual setup:**

```bash
# 1. Install dependencies
npm install

# 2. Create environment file
cp .env.example .env

# 3. Start Supabase
npm run db:start
# OR
./scripts/dev.sh

# 4. Generate TypeScript types
npm run types:generate
```

## Development Workflow

### 1. Working with Issues

We use GitHub Issues with structured templates to track all work:

- **Bug Reports** - Report bugs and unexpected behavior
- **Feature Requests** - Suggest new features or enhancements
- **DevOps Tasks** - Infrastructure, CI/CD, and deployment work
- **Database Tasks** - Schema changes, migrations, RLS policies

**Create an issue:** https://github.com/SkogAI/supabase/issues/new/choose

See [docs/ISSUE_MANAGEMENT.md](docs/ISSUE_MANAGEMENT.md) for complete guidelines.

### 2. Creating a Branch

Branch naming conventions:

```bash
# Features
git checkout -b feature/add-user-notifications

# Bugs
git checkout -b fix/authentication-redirect

# Database changes
git checkout -b database/add-comments-table

# DevOps
git checkout -b devops/add-backup-workflow
```

### 3. Making Changes

#### Database Changes

```bash
# Create new migration
npm run migration:new add_feature_name

# Edit the migration file in supabase/migrations/

# Test locally
npm run db:reset

# Test RLS policies (if applicable)
npm run test:rls

# Generate types
npm run types:generate
```

**Migration naming conventions:**
- `add_<table>_table` - New tables
- `add_<table>_<column>` - New columns
- `enable_rls_<table>` - Security policies
- `add_<table>_index` - Performance indexes
- `alter_<table>_<change>` - Schema modifications

See [supabase/migrations/README.md](supabase/migrations/README.md) for detailed guidelines.

#### Edge Functions

```bash
# Create new function
npm run functions:new my-function

# Develop locally
npm run functions:serve

# Test in another terminal
curl http://localhost:54321/functions/v1/my-function

# Write tests in supabase/functions/my-function/test.ts
cd supabase/functions/my-function
deno test --allow-all test.ts

# Lint and format
npm run lint:functions
npm run format:functions
```

See [supabase/functions/README.md](supabase/functions/README.md) for complete guide.

### 4. Testing

```bash
# Test edge functions
npm run test:functions

# Test RLS policies
npm run test:rls

# Test storage policies
supabase db execute --file tests/storage_test_suite.sql

# Validate migrations
npm run db:reset

# Check SQL syntax
npm run lint:sql
```

### 5. Committing Changes

Write clear, descriptive commit messages:

```bash
# Good commit messages
git commit -m "Add user notifications table with RLS policies"
git commit -m "Fix authentication redirect loop"
git commit -m "Update OpenAI function to use streaming responses"

# Use conventional commits format (optional but recommended)
git commit -m "feat: add user notifications table"
git commit -m "fix: resolve authentication redirect loop"
git commit -m "docs: update edge functions guide"
```

**Commit message types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions or changes
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `chore:` - Maintenance tasks

### 6. Opening a Pull Request

```bash
# Push your branch
git push origin feature/my-feature

# Open PR using GitHub CLI (recommended)
gh pr create --title "Add user notifications" --body "Implements issue #123"

# OR use GitHub web interface
```

**PR Guidelines:**

1. **Title**: Clear and descriptive
2. **Description**:
   - Link to related issue(s)
   - Describe what changed and why
   - Include screenshots for UI changes
   - List testing performed
3. **Checks**: Wait for CI checks to pass
4. **Review**: Request review from maintainers
5. **Updates**: Address review feedback promptly

**PR template will include:**
- Summary of changes
- Related issues
- Type of change (feature, bug fix, etc.)
- Testing checklist
- Screenshots (if applicable)

### 7. Code Review Process

- All PRs require at least one approval
- CI/CD checks must pass
- Address all review comments
- Keep PRs focused and reasonably sized
- Be responsive to feedback

### 8. Merging

Once approved and checks pass:
- Maintainers will merge your PR
- Merge to `main` or `develop` triggers auto-deployment
- Delete your feature branch after merge

## Code Style and Standards

### SQL

- Use lowercase for SQL keywords in migrations
- Use snake_case for table and column names
- Always enable RLS on public tables
- Include comments for complex queries
- Add indexes for frequently queried columns

**Example:**

```sql
-- Add comments table for user discussions
create table public.comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid references public.posts(id) on delete cascade not null,
    user_id uuid references auth.users(id) on delete cascade not null,
    content text not null,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Enable RLS
alter table public.comments enable row level security;

-- Add index for common queries
create index comments_post_id_idx on public.comments(post_id);
```

### TypeScript/JavaScript

- Use TypeScript for type safety
- Follow existing code formatting
- Run linter before committing: `npm run lint:functions`
- Use async/await over promises
- Handle errors appropriately

### Documentation

- Update README.md for new features
- Add inline comments for complex logic
- Update relevant docs in `docs/` directory
- Include examples where helpful
- Keep documentation concise and clear

## Common Development Tasks

### Reset Database

```bash
# Interactive reset with confirmation
./scripts/reset.sh

# Direct reset
npm run db:reset
```

### Check Service Status

```bash
npm run db:status
# OR
supabase status
```

### Generate Types After Schema Changes

```bash
npm run types:generate

# OR watch for changes
npm run types:watch
```

### View Logs

```bash
# Database logs
supabase db logs

# Edge function logs
supabase functions logs <function-name>

# All service logs
docker compose logs
```

### Debug Migrations

```bash
# Reset with debug output
supabase db reset --debug

# Generate SQL diff
npm run db:diff
```

## Troubleshooting

### Docker Not Running

```bash
# Check Docker status
docker info

# If not running, start Docker Desktop
```

### Port Conflicts

```bash
# Stop Supabase
supabase stop

# Check what's using ports
lsof -i :8000
lsof -i :54322
```

### Migration Errors

```bash
# Reset database
supabase db reset --debug

# Check migration syntax
npm run lint:sql
```

### Type Generation Fails

```bash
# Ensure Supabase is running
npm run db:start

# Generate types
npm run types:generate
```

### Function Deployment Issues

```bash
# Check function logs
supabase functions logs <function-name>

# Test locally first
npm run functions:serve
curl http://localhost:54321/functions/v1/<function-name>
```

See [DEVOPS.md](DEVOPS.md) for comprehensive troubleshooting.

## Testing Guidelines

### Local Testing

Always test changes locally before pushing:

1. **Database changes**: Run `npm run db:reset`
2. **RLS policies**: Run `npm run test:rls`
3. **Edge functions**: Run `npm run test:functions`
4. **Storage**: Run storage test suite
5. **Manual testing**: Test in Studio UI or with client code

### Writing Tests

**Edge Functions:**
- Create `test.ts` in function directory
- Test success and error cases
- Mock external API calls
- Verify response format

**RLS Policies:**
- Add test cases to `tests/rls_test_suite.sql`
- Test all user roles (service, authenticated, anon)
- Test edge cases (own data, other users' data)
- Verify expected pass/fail behavior

**Storage:**
- Test in `tests/storage_test_suite.sql`
- Verify upload/download permissions
- Test file size limits
- Test MIME type restrictions

## Security Best Practices

### Never Commit Secrets

- Keep `.env` in `.gitignore`
- Use environment variables for API keys
- Never hardcode credentials
- Use GitHub Secrets for CI/CD

### RLS Policies

- Enable RLS on all public tables
- Test policies thoroughly
- Use service role only in backend code
- Implement principle of least privilege

### Input Validation

- Validate all user input in functions
- Sanitize data before database operations
- Use parameterized queries
- Implement rate limiting where appropriate

## Getting Help

- **Documentation**: Check `README.md` and `docs/` directory first
- **Issues**: Search existing issues for similar problems
- **Discussions**: Use GitHub Discussions for questions
- **Maintainers**: Contact @Skogix or @Ic0n for assistance

## Resources

### Project Documentation
- [README.md](README.md) - Quick start and features
- [DEVOPS.md](DEVOPS.md) - Complete DevOps guide
- [CLAUDE.md](CLAUDE.md) - Claude Code guidance
- [docs/](docs/) - Detailed documentation

### External Resources
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Deno Manual](https://deno.land/manual)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on what's best for the project
- Show empathy towards others
- Accept constructive criticism gracefully

---

**Thank you for contributing to make this project better!**
