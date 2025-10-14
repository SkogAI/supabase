# CI/CD Integration for Worktree-Based Development

This guide explains how to use CI/CD workflows with Git worktrees for parallel development and testing.

## Overview

The CI/CD integration for worktrees provides:

- **Local validation** before pushing to remote
- **Parallel testing** in GitHub Actions
- **Pre-push hooks** to prevent bad commits
- **Comprehensive test coverage** matching CI pipeline
- **Preview environments** (planned feature)

## Quick Start

### 1. Local CI Validation

Run CI checks locally before pushing:

```bash
# In your worktree directory
.github/scripts/ci-worktree.sh

# Or specify a worktree path
.github/scripts/ci-worktree.sh .dev/worktree/feature-auth-42
```

This runs:
- ✅ TypeScript type checking
- ✅ Database migration validation
- ✅ Edge function linting and tests
- ✅ RLS policy tests
- ✅ Storage policy tests
- ✅ SQL linting

### 2. Install Pre-Push Hook

Automatically validate before every push:

```bash
# Copy the hook
cp .github/hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push

# Now git push will run validation automatically
```

To bypass the hook (use sparingly):
```bash
git push --no-verify
```

### 3. Create Worktree with CI Support

```bash
# Standard worktree creation
.github/scripts/create-worktree.sh 42 feature

# With preview environment (planned)
.github/scripts/create-worktree.sh 42 feature --preview
```

## CI Validation Script

### Usage

```bash
.github/scripts/ci-worktree.sh [worktree-path]
```

**Arguments:**
- `worktree-path` (optional): Path to worktree directory (defaults to current directory)

**Exit codes:**
- `0`: All tests passed
- `1`: One or more tests failed

### What It Checks

#### 1. Pre-flight Checks
- Node.js installed
- npm installed
- Deno installed (for functions)
- Supabase CLI installed (for database tests)
- node_modules present

#### 2. TypeScript Type Checking
- Validates `types/database.ts` syntax
- Ensures types compile without errors

#### 3. Database Migration Validation
- Checks migration naming convention: `YYYYMMDDHHMMSS_description.sql`
- Validates SQL syntax (if Supabase CLI available)
- Tests migration can be applied

#### 4. Edge Functions Testing
- Format checking (`deno fmt --check`)
- Linting (`deno lint`)
- Type checking all function files
- Unit tests (`deno test --allow-all`)

#### 5. Database Tests
- RLS policy tests (`npm run test:rls`)
- Storage policy tests
- Requires Supabase running locally

#### 6. SQL Linting
- Validates SQL syntax with sqlfluff (if installed)

### Example Output

```
════════════════════════════════════════════════════════════
Running CI checks for worktree: feature-auth-42
Branch: feature/user-authentication-42
Path: /path/to/.dev/worktree/feature-auth-42
════════════════════════════════════════════════════════════

1. Pre-flight checks
─────────────────────────────────────────────────────────────
✓ All required tools installed

2. TypeScript Type Checking
─────────────────────────────────────────────────────────────
✓ TypeScript compilation

3. Database Migration Validation
─────────────────────────────────────────────────────────────
✓ Migration naming convention
✓ Migration syntax validation

4. Edge Functions Testing
─────────────────────────────────────────────────────────────
✓ Deno format check
✓ Deno lint
✓ Function type checking
✓ Function unit tests

5. Database Tests
─────────────────────────────────────────────────────────────
✓ RLS policy tests
✓ Storage policy tests

6. SQL Linting
─────────────────────────────────────────────────────────────
✓ SQL linting

════════════════════════════════════════════════════════════
Test Summary
════════════════════════════════════════════════════════════

Tests passed: 10
Tests failed: 0

All checks passed! Safe to push.

Next steps:
  git add .
  git commit -m 'Your commit message'
  git push -u origin feature/user-authentication-42
```

## GitHub Actions Workflow

### Automatic Testing

The `worktree-testing.yml` workflow automatically runs when:

- Pushing to `feature/*`, `bugfix/*`, or `hotfix/*` branches
- Opening or updating pull requests

### Workflow Jobs

#### 1. **detect-worktree**
Determines if the branch is a worktree branch and extracts the type.

#### 2. **validate-worktree**
Runs the full CI validation script in GitHub Actions.

#### 3. **database-tests**
- Starts local Supabase instance
- Runs RLS policy tests
- Runs storage policy tests
- Tests migrations
- Validates type generation

#### 4. **edge-functions**
- Lints Deno code
- Type checks all functions
- Runs function tests

#### 5. **security-scan**
- Checks for hardcoded secrets
- Ensures no `.env` files committed
- Scans for security issues

#### 6. **test-summary**
Aggregates results and fails if any test failed.

### Viewing Results

Results are available in:
1. **GitHub Actions tab** - Full logs for each job
2. **PR checks** - Status checks for each test suite
3. **Job summaries** - Quick overview of test results

## Pre-Push Hook

### Installation

```bash
# One-time setup
cp .github/hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

### How It Works

The pre-push hook:
1. Detects if you're pushing from a worktree
2. Runs `.github/scripts/ci-worktree.sh`
3. Blocks push if tests fail
4. Allows push if all tests pass

### Bypassing the Hook

When necessary (e.g., work-in-progress commits):

```bash
git push --no-verify
```

⚠️ **Warning:** Use sparingly. Failed CI checks will block PR merge.

## Worktree Workflow with CI

### Complete Example

```bash
# 1. Create worktree
.github/scripts/create-worktree.sh 42 feature

# Output:
# Creating worktree:
#   Path: .dev/worktree/feature-add-user-profiles-42
#   Branch: feature/add-user-profiles-42
#   Base: develop
#
# ✓ Worktree created successfully!

# 2. Work in the worktree
cd .dev/worktree/feature-add-user-profiles-42

# 3. Make changes
npm run migration:new add_user_profiles
# Edit migration file
npm run db:reset
npm run types:generate

# 4. Run local CI checks
.github/scripts/ci-worktree.sh

# 5. Commit and push (pre-push hook runs automatically)
git add .
git commit -m "Add user profiles table with RLS policies"
git push -u origin feature/add-user-profiles-42

# 6. Create PR
gh pr create --base develop --title "Add user profiles" --body "Closes #42"

# 7. GitHub Actions runs automatically
# - Parallel tests execute
# - Results posted to PR
# - Merge blocked if tests fail
```

## Preview Environments (Planned)

Future functionality will include:

### Automatic Preview Creation

```bash
.github/scripts/create-worktree.sh 42 feature --preview
```

This will:
- Create worktree as usual
- Provision ephemeral Supabase project
- Run migrations in preview environment
- Deploy edge functions
- Share preview URLs in PR comments

### Preview Environment Features

- **Isolated testing** - Each worktree gets own database
- **Automatic cleanup** - Deleted when worktree removed
- **Preview URLs** - Share with stakeholders
- **Full feature parity** - Same as production environment

### Implementation Status

⚠️ **Preview environments are not yet implemented**

Tracking issue: [Link to issue once created]

Required components:
- [ ] Supabase project provisioning API
- [ ] Environment variable management
- [ ] Automatic cleanup on worktree removal
- [ ] PR comment integration
- [ ] Cost management and limits

## Troubleshooting

### CI Script Fails

**Problem:** Script exits with errors

**Solutions:**
```bash
# Check for missing dependencies
node --version
npm --version
deno --version
supabase --version

# Install missing tools
npm install
# Install Deno: https://deno.land/
# Install Supabase CLI: https://supabase.com/docs/guides/cli

# Ensure Supabase is running for database tests
npm run db:start
```

### Pre-Push Hook Not Running

**Problem:** Hook doesn't execute on push

**Solutions:**
```bash
# Check if hook exists
ls -la .git/hooks/pre-push

# Make it executable
chmod +x .git/hooks/pre-push

# Verify it's the correct hook
cat .git/hooks/pre-push
```

### Tests Pass Locally But Fail in CI

**Problem:** Different results in local vs GitHub Actions

**Possible causes:**
1. **Cached dependencies** - CI uses fresh install
2. **Environment differences** - Different Node/Deno versions
3. **Missing files** - Not committed to git
4. **Flaky tests** - Race conditions or timing issues

**Solutions:**
```bash
# Clean install locally
rm -rf node_modules
npm ci

# Check what's committed
git status
git diff

# Run CI script in clean state
npm run db:reset
.github/scripts/ci-worktree.sh
```

### Slow CI Execution

**Problem:** Tests take too long

**Solutions:**
1. **Run tests in parallel** - Already implemented in GitHub Actions
2. **Skip optional checks locally** - Modify ci-worktree.sh
3. **Use pre-push hook selectively** - Only for important branches

## Configuration

### Customize CI Checks

Edit `.github/scripts/ci-worktree.sh` to:
- Add new test suites
- Skip certain checks
- Adjust strictness
- Change output format

### Customize GitHub Actions

Edit `.github/workflows/worktree-testing.yml` to:
- Add new jobs
- Change trigger conditions
- Modify test matrix
- Add notifications

### Environment Variables

Set in GitHub repository settings:

- `SUPABASE_ACCESS_TOKEN` - For Supabase CLI
- `SUPABASE_PROJECT_ID` - Your project ID
- `SUPABASE_DB_PASSWORD` - Database password

## Best Practices

### 1. Run CI Checks Before Push

Always run local validation:
```bash
.github/scripts/ci-worktree.sh
```

### 2. Keep Worktrees Short-Lived

- Create for specific issue
- Merge quickly
- Delete after merge

### 3. Sync Regularly

```bash
git fetch origin
git merge origin/develop
```

### 4. Use Pre-Push Hook

Install the hook to catch issues early:
```bash
cp .github/hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

### 5. Monitor CI Results

- Check GitHub Actions tab
- Review PR checks
- Address failures promptly

### 6. Don't Bypass Checks

Avoid `--no-verify` unless absolutely necessary. Failed checks indicate real problems.

## Performance Benchmarks

Typical execution times:

| Check | Local | GitHub Actions |
|-------|-------|----------------|
| Pre-flight | 2s | 5s |
| TypeScript | 3s | 5s |
| Migrations | 5s | 10s |
| Functions | 10s | 15s |
| Database Tests | 20s | 30s |
| SQL Linting | 5s | 8s |
| **Total** | **45s** | **73s** |

GitHub Actions runs jobs in parallel, reducing total time to ~90s.

## Related Documentation

- [WORKTREES.md](WORKTREES.md) - Worktree management guide
- [DEVOPS.md](../DEVOPS.md) - Complete DevOps setup
- [ISSUE_MANAGEMENT.md](ISSUE_MANAGEMENT.md) - Issue workflow
- [RLS_POLICIES.md](RLS_POLICIES.md) - RLS testing guide

## Contributing

To improve CI/CD integration:

1. Test changes locally first
2. Update documentation
3. Add tests for new features
4. Follow existing patterns

## Support

For issues or questions:

- Open an issue: https://github.com/SkogAI/supabase/issues
- Check existing documentation
- Review workflow logs in GitHub Actions
