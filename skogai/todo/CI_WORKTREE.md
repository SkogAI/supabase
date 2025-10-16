# CI/CD Integration for Worktrees

This guide explains how to use CI/CD integration with Git worktrees for local and remote validation.

## Overview

The worktree CI/CD system provides:

- **Local validation** - Run full CI suite before pushing
- **Pre-push hooks** - Automatic validation on `git push`
- **GitHub Actions** - Parallel testing for worktree branches
- **Fast feedback** - Catch issues early in development

## Quick Start

### 1. Install Git Hooks (One-time Setup)

After cloning the repository or creating a new worktree:

```bash
# Install pre-push hooks
npm run hooks:install

# Or directly:
.github/scripts/install-hooks.sh
```

This installs validation hooks that run automatically before pushing.

### 2. Run Local CI Checks

Before committing or pushing, validate your changes:

```bash
# Run full CI suite in current worktree
npm run ci:worktree

# Or directly:
.github/scripts/ci-worktree.sh

# Run CI for a specific worktree
.github/scripts/ci-worktree.sh feature-auth-42
```

### 3. Push with Confidence

The pre-push hook automatically runs CI checks:

```bash
git push -u origin feature/my-feature

# To bypass hooks (not recommended):
git push --no-verify
```

## Local CI Checks

The `ci-worktree.sh` script runs the following checks:

### 1. TypeScript Type Checking
- Generates TypeScript types from database schema
- Validates type generation succeeds
- **Requires:** Node.js, Supabase running

### 2. SQL Linting
- Lints all migration files
- Checks for syntax errors and anti-patterns
- **Requires:** sqlfluff (`pip install -r requirements-dev.txt`)

### 3. Migration Validation
- Verifies migration file syntax
- Checks for common issues
- Counts migration files
- **Requires:** Migration files in `supabase/migrations/`

### 4. Edge Function Linting
- Runs `deno fmt --check` for formatting
- Runs `deno lint` for code quality
- **Requires:** Deno

### 5. Edge Function Type Checking
- Type checks all function `index.ts` files
- Validates TypeScript compilation
- **Requires:** Deno

### 6. Edge Function Unit Tests
- Runs all Deno tests
- Excludes integration tests (for speed)
- **Requires:** Deno

### 7. RLS Policy Tests
- Tests Row Level Security policies
- Validates authentication and authorization
- **Requires:** Supabase running, Docker

### 8. Storage Policy Tests
- Tests storage bucket permissions
- Validates file access controls
- **Requires:** Supabase running, Docker

## CI Check Output

### Success Example
```
======================================
CI Checks for Worktree: feature-auth-42
======================================
ℹ Path: .dev/worktree/feature-auth-42
ℹ Branch: feature/auth-42
ℹ Docker is running (database tests available)

▶ TypeScript Type Checking
✓ TypeScript types validated

▶ SQL Linting
✓ SQL linting passed

▶ Migration Validation
✓ Found 3 migration files
✓ Migration syntax check passed

▶ Edge Function Linting
✓ Deno format check passed
✓ Deno lint passed

▶ Edge Function Type Checking
✓ Edge function type checking passed

▶ Edge Function Unit Tests
✓ Edge function tests passed

▶ RLS Policy Tests
✓ RLS policy tests passed

▶ Storage Policy Tests
✓ Storage policy tests passed

======================================
CI Check Summary
======================================
Tests Passed:  10
Tests Failed:  0
Tests Skipped: 0
Total Tests:   10

✓ All checks passed! Safe to push.
```

### Failure Example
```
▶ SQL Linting
✗ SQL linting failed

▶ RLS Policy Tests
✗ RLS policy tests failed

======================================
CI Check Summary
======================================
Tests Passed:  8
Tests Failed:  2
Tests Skipped: 0
Total Tests:   10

✗ Some checks failed. Please fix issues before pushing.
```

## GitHub Actions Workflow

The `worktree-ci.yml` workflow automatically tests worktree branches in parallel.

### Triggered On

- Push to `feature/**`, `bugfix/**`, `hotfix/**` branches
- Pull requests to `develop`, `master`, or `main`

### Jobs

1. **detect-worktree** - Identifies if branch is from worktree
2. **worktree-lint** - Runs Deno lint and format checks
3. **worktree-typecheck** - Type checks all edge functions
4. **worktree-unit-tests** - Runs unit tests with coverage
5. **worktree-migrations** - Validates and tests migrations
6. **worktree-rls-tests** - Tests RLS policies
7. **worktree-summary** - Aggregates results and reports status

### Viewing Results

Results appear in:
- GitHub Actions tab (workflow summary)
- PR checks (if PR exists)
- GitHub Actions Summary (detailed reports)

## Pre-Push Hook

The pre-push hook (`/.github/hooks/pre-push`) runs CI checks automatically before pushing.

### How It Works

1. Developer runs `git push`
2. Hook triggers and runs `.github/scripts/ci-worktree.sh`
3. If checks pass → Push continues
4. If checks fail → Push is blocked

### Bypassing the Hook

```bash
# Skip validation (use with caution)
git push --no-verify

# Or temporarily disable
rm .git/hooks/pre-push
git push
git checkout .git/hooks/pre-push  # Re-enable
```

## Best Practices

### 1. Run CI Before Committing

```bash
# Make changes
vim supabase/migrations/new_migration.sql

# Run CI to catch issues early
npm run ci:worktree

# If passed, commit
git add .
git commit -m "Add new migration"
```

### 2. Keep Supabase Running During Development

```bash
# Start Supabase once
supabase start

# Run CI multiple times (faster with Supabase already running)
npm run ci:worktree
# ... make changes ...
npm run ci:worktree
```

### 3. Fix Issues Locally

Don't push failing code. Fix issues locally:

```bash
# If Deno format fails:
cd supabase/functions
deno fmt

# If RLS tests fail:
supabase db reset
npm run test:rls

# Then re-run CI
npm run ci:worktree
```

### 4. Use Worktree-Specific Testing

Test only the worktree you're working on:

```bash
# In main repo, test a specific worktree
.github/scripts/ci-worktree.sh feature-auth-42

# Or cd into worktree and run
cd .dev/worktree/feature-auth-42
npm run ci:worktree
```

## Troubleshooting

### "Docker not running" Error

**Problem:** CI skips database tests because Docker isn't running.

**Solution:**
```bash
# Start Docker Desktop
open -a Docker  # macOS
# Or start Docker Desktop from applications

# Verify Docker is running
docker info

# Start Supabase
supabase start
```

### "Supabase not running" Error

**Problem:** RLS tests fail because Supabase isn't started.

**Solution:**
```bash
# Start Supabase
supabase start

# Check status
supabase status

# Re-run CI
npm run ci:worktree
```

### "sqlfluff not found" Warning

**Problem:** SQL linting is skipped.

**Solution:**
```bash
# Install Python development dependencies
pip install -r requirements-dev.txt

# Or install sqlfluff directly
pip install sqlfluff

# Or with pipx
pipx install sqlfluff
```

### "Deno not installed" Warning

**Problem:** Edge function tests are skipped.

**Solution:**
```bash
# Install Deno
curl -fsSL https://deno.land/install.sh | sh

# Or with Homebrew
brew install deno
```

### Pre-push Hook Not Running

**Problem:** Hooks weren't installed.

**Solution:**
```bash
# Install hooks
npm run hooks:install

# Verify hook exists
ls -la .git/hooks/pre-push

# Verify it's executable
chmod +x .git/hooks/pre-push
```

### Tests Take Too Long

**Problem:** CI checks are slow (especially with Supabase start/stop).

**Solution:**
```bash
# Keep Supabase running in background
supabase start

# Run tests (much faster now)
npm run ci:worktree

# Optional: Stop when done for the day
supabase stop
```

## Advanced Usage

### Running Specific Test Categories

The CI script runs all tests, but you can run subsets manually:

```bash
# Only type checking
npm run types:generate

# Only SQL linting
npm run lint:sql

# Only edge function tests
npm run test:functions

# Only RLS tests
npm run test:rls
```

### Custom CI Script

Create a custom validation script for your needs:

```bash
#!/bin/bash
# my-quick-check.sh

# Only run fast checks (no database)
cd supabase/functions
deno lint && deno fmt --check && deno test --allow-all
```

### CI in CI/CD Pipelines

The same script runs locally and in GitHub Actions:

```yaml
# Custom workflow
- name: Run worktree CI
  run: .github/scripts/ci-worktree.sh
```

## Integration with Development Workflow

### Typical Workflow with CI

```bash
# 1. Create worktree (hooks auto-installed)
.github/scripts/create-worktree.sh 42 feature

# 2. Enter worktree
cd .dev/worktree/feature-add-auth-42

# 3. Start Supabase (once)
supabase start

# 4. Make changes
npm run migration:new add_auth
vim supabase/migrations/[timestamp]_add_auth.sql

# 5. Test changes
supabase db reset
npm run test:rls

# 6. Run full CI locally
npm run ci:worktree

# 7. Commit (if CI passed)
git add .
git commit -m "Add authentication system"

# 8. Push (pre-push hook runs CI again)
git push -u origin feature/add-auth-42

# 9. Create PR
gh pr create --base develop --title "Add authentication" --body "Closes #42"

# 10. GitHub Actions runs parallel CI tests
# View results in PR checks
```

## Performance Tips

1. **Keep Supabase running** - Avoid start/stop overhead
2. **Run specific tests first** - Quick feedback before full CI
3. **Use `--no-verify`** carefully - Only when you know tests will pass remotely
4. **Install all tools** - Avoid skipped tests (sqlfluff, Deno, etc.)

## Related Documentation

- [WORKTREES.md](./WORKTREES.md) - Worktree management guide
- [DEVOPS.md](../DEVOPS.md) - Complete DevOps and CI/CD guide
- [supabase/functions/TESTING.md](../supabase/functions/TESTING.md) - Edge function testing details

## Summary

The CI/CD integration for worktrees provides:

- ✅ Local validation before pushing
- ✅ Automatic pre-push checks
- ✅ Parallel GitHub Actions testing
- ✅ Fast feedback on code quality
- ✅ Consistent checks locally and remotely
- ✅ Prevents bad code from reaching remote

Install hooks once, then develop with confidence knowing your code is validated before it leaves your machine.
