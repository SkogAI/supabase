# Development Conventions

This document defines the conventions and best practices for developing in this Supabase project, particularly when using Git worktrees.

## Table of Contents

- [Branch Naming](#branch-naming)
- [Commit Messages](#commit-messages)
- [Migration Naming](#migration-naming)
- [Testing Requirements](#testing-requirements)
- [Code Review Guidelines](#code-review-guidelines)
- [PR Templates](#pr-templates)
- [Worktree Workflows](#worktree-workflows)

## Branch Naming

Branch names should be descriptive and follow these patterns:

### Feature Branches

**Pattern**: `feature/<description>-<issue-number>`

**Base**: `develop`

**Examples**:
```
feature/user-authentication-42
feature/add-notifications-system-103
feature/implement-search-156
```

**Guidelines**:
- Use lowercase with hyphens
- Keep description concise but clear
- Always include issue number
- Maximum 50 characters

### Bugfix Branches

**Pattern**: `bugfix/<description>-<issue-number>`

**Base**: `develop`

**Examples**:
```
bugfix/cors-error-handling-44
bugfix/login-redirect-loop-87
bugfix/storage-permission-issue-92
```

**Guidelines**:
- Describe what was broken
- Keep it specific
- Include issue number

### Hotfix Branches

**Pattern**: `hotfix/<description>-<issue-number>`

**Base**: `master`

**Examples**:
```
hotfix/security-vulnerability-201
hotfix/critical-data-loss-203
hotfix/production-outage-205
```

**Guidelines**:
- Only for critical production issues
- Must merge to both `master` and `develop`
- Requires expedited review

### Other Branch Types

**Release branches**: `release/v1.2.0`

**Documentation**: `docs/update-api-guide-88`

**DevOps**: `devops/add-backup-workflow-75`

## Commit Messages

Write clear, descriptive commit messages that explain both what changed and why.

### Format

```
<type>: Brief summary (50 chars or less)

More detailed explanation if needed (wrap at 72 chars).
Explain what changed and why, not how.

- Bullet points for multiple changes
- Use present tense ("Add" not "Added")
- Reference related issues

Closes SkogAI/supabase#<issue-number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Commit Types

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `chore:` - Maintenance tasks
- `ci:` - CI/CD changes
- `db:` - Database migrations

### Examples

#### Feature Commit

```
feat: Add user profile management

Implement comprehensive user profile system with:
- Profile creation and editing
- Avatar upload with storage integration
- Privacy settings
- Profile visibility controls

Includes RLS policies for secure data access and
TypeScript types for type-safe client integration.

Closes SkogAI/supabase#42

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

#### Bug Fix Commit

```
fix: Resolve authentication redirect loop

Users were experiencing infinite redirects after logout
due to session validation occurring before cookie cleanup.

- Move session check after cookie middleware
- Add 5-second timeout to prevent loops
- Update logout flow tests

Fixes SkogAI/supabase#87

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

#### Database Migration Commit

```
db: Add notifications table with RLS

Create notifications system for user alerts:
- Notifications table with user_id foreign key
- RLS policies for secure access
- Indexes for performance
- Trigger for auto-updating timestamps

Includes comprehensive RLS tests.

Closes SkogAI/supabase#103

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### What NOT to Do

❌ Bad commits:
```
Update files
Fixed bug
WIP
asdf
Minor changes
```

✅ Good commits:
```
fix: Resolve CORS error in auth endpoint
feat: Add email notification system
docs: Update RLS policy documentation
```

## Migration Naming

Database migrations must follow strict naming conventions for clarity and maintainability.

### Format

```
YYYYMMDDHHMMSS_<action>_<target>_<details>.sql
```

### Timestamp

Use the current timestamp when creating migrations:
```bash
npm run migration:new <description>
```

This automatically generates the correct timestamp prefix.

### Action Verbs

- `add` - Add new tables, columns, or constraints
- `alter` - Modify existing structures
- `drop` - Remove tables, columns, or constraints
- `enable` - Enable features (like RLS)
- `create` - Create functions, triggers, views

### Examples

#### New Tables

```
20240101120000_add_profiles_table.sql
20240102143000_add_comments_table.sql
20240103091500_add_notifications_table.sql
```

#### New Columns

```
20240104102000_add_profiles_avatar_url.sql
20240105134500_add_posts_publish_date.sql
```

#### RLS Policies

```
20240106160000_enable_rls_profiles.sql
20240107110000_enable_rls_comments.sql
```

#### Indexes

```
20240108093000_add_posts_user_id_index.sql
20240109141500_add_comments_post_id_index.sql
```

#### Schema Changes

```
20240110120000_alter_profiles_add_bio.sql
20240111154500_alter_posts_add_metadata.sql
```

#### Functions and Triggers

```
20240112083000_create_update_timestamp_function.sql
20240113131000_create_posts_updated_at_trigger.sql
```

### Migration Best Practices

1. **One logical change per migration**
   - Don't combine unrelated changes
   - Keep migrations focused and atomic

2. **Always include RLS when adding tables**
   ```sql
   -- Bad: Table without RLS
   create table public.data (...);
   
   -- Good: Table with RLS immediately
   create table public.data (...);
   alter table public.data enable row level security;
   create policy "..." on public.data ...;
   ```

3. **Add indexes for foreign keys**
   ```sql
   create index posts_user_id_idx on public.posts(user_id);
   ```

4. **Include rollback notes in comments**
   ```sql
   -- Migration: Add notifications table
   -- Rollback: drop table public.notifications cascade;
   ```

5. **Test before committing**
   ```bash
   npm run db:reset    # Apply migration
   npm run test:rls    # Test policies
   ```

## Testing Requirements

Different branch types have different testing requirements.

### Feature Branches

Required tests:
- [ ] All new tables have RLS policies
- [ ] RLS tests pass: `npm run test:rls`
- [ ] Edge functions have test files
- [ ] Function tests pass: `npm run test:functions`
- [ ] TypeScript types generated: `npm run types:generate`
- [ ] Manual testing completed
- [ ] No regression in existing features

### Bugfix Branches

Required tests:
- [ ] Test that reproduces the bug
- [ ] Test passes after fix
- [ ] Related tests still pass
- [ ] Edge cases covered
- [ ] No new bugs introduced
- [ ] Manual verification of fix

### Hotfix Branches

Required tests (NO SHORTCUTS):
- [ ] All automated tests pass
- [ ] Manual testing in production-like environment
- [ ] Load testing (if applicable)
- [ ] Rollback procedure tested
- [ ] Deployment verified in staging

### Test Commands

```bash
# RLS policies
npm run test:rls

# Edge functions
npm run test:functions

# Storage policies
supabase db execute --file tests/storage_test_suite.sql

# Database reset
npm run db:reset

# SQL syntax validation
npm run lint:sql
```

## Code Review Guidelines

### For Authors

Before requesting review:

1. **Self-review your changes**
   - Read through every line
   - Remove debug code
   - Clean up comments
   - Check formatting

2. **Verify tests pass**
   ```bash
   npm run test:rls
   npm run test:functions
   npm run db:reset
   ```

3. **Update documentation**
   - README if needed
   - Inline comments for complex logic
   - API documentation

4. **Clean commit history**
   - Meaningful commit messages
   - Logical commits
   - No "WIP" or "fix typo" commits

### For Reviewers

Focus on:

1. **Correctness**
   - Logic is sound
   - Edge cases handled
   - Error handling present

2. **Security**
   - RLS policies on all tables
   - Input validation
   - No SQL injection risks
   - Secrets not hardcoded

3. **Performance**
   - Queries are efficient
   - Indexes added where needed
   - No N+1 queries

4. **Maintainability**
   - Code is readable
   - Comments explain why, not what
   - Follows existing patterns
   - No unnecessary complexity

5. **Testing**
   - Tests are comprehensive
   - Tests are meaningful
   - Edge cases covered

### Review Checklist

- [ ] Code follows project conventions
- [ ] Tests are adequate and passing
- [ ] RLS policies properly implemented
- [ ] No security vulnerabilities
- [ ] Documentation updated
- [ ] Performance considerations addressed
- [ ] Error handling appropriate
- [ ] Commit messages are clear

## PR Templates

### Feature PR Template

```markdown
## Summary

Brief description of the feature

## Related Issue

Closes #<issue-number>

## Changes

- List key changes
- Include table/function names
- Mention any breaking changes

## Database Changes

- New tables: `table_name`
- Modified tables: `other_table`
- New RLS policies: Yes/No
- Migrations tested: Yes/No

## Testing

- [ ] RLS tests pass
- [ ] Function tests pass
- [ ] Manual testing completed
- [ ] Edge cases tested

## Documentation

- [ ] README updated
- [ ] Inline comments added
- [ ] API docs updated

## Screenshots (if applicable)

[Add screenshots of UI changes]

## Checklist

- [ ] Tests pass locally
- [ ] Code follows conventions
- [ ] Documentation updated
- [ ] Ready for review
```

### Bugfix PR Template

```markdown
## Bug Description

What was broken and how it manifested

## Root Cause

What caused the bug

## Fix

How the bug was fixed

## Related Issue

Fixes #<issue-number>

## Testing

- [ ] Bug reproduced before fix
- [ ] Bug no longer occurs after fix
- [ ] Test added for bug
- [ ] Related features tested
- [ ] No regression

## Impact

What users/features are affected

## Checklist

- [ ] All tests pass
- [ ] Manual testing completed
- [ ] Documentation updated (if needed)
```

### Hotfix PR Template

```markdown
## 🚨 CRITICAL HOTFIX

## Severity

[Critical/High/Medium]

## Production Impact

Describe the production issue

## Root Cause

What caused the critical issue

## Fix

Minimal change to resolve issue

## Testing

- [ ] All tests pass
- [ ] Manual testing in prod-like environment
- [ ] Load testing (if applicable)
- [ ] Rollback tested

## Deployment Plan

1. Step-by-step deployment
2. Verification steps
3. Rollback procedure

## Rollback Plan

Exact steps to rollback if issues occur

## Related Issue

Fixes #<issue-number>

## Sign-Off

- [ ] Developer
- [ ] Reviewer
- [ ] Team Lead
```

## Worktree Workflows

### Creating a Worktree

```bash
# Using the script (recommended)
.github/scripts/create-worktree.sh <issue-number> [type]

# Examples
.github/scripts/create-worktree.sh 42 feature
.github/scripts/create-worktree.sh 87 bugfix
.github/scripts/create-worktree.sh 201 hotfix
```

The script will:
1. Fetch latest from origin
2. Create worktree with proper naming
3. Set up tracking branch
4. Run template setup script
5. Display next steps

### Template Auto-Setup

Each worktree type has an automatic setup script:

**Feature template** (`.dev/worktree-templates/feature/setup.sh`):
- Copies `.env.example` to `.env`
- Installs npm dependencies
- Starts Supabase if not running
- Resets database
- Generates types
- Shows feature checklist

**Bugfix template** (`.dev/worktree-templates/bugfix/setup.sh`):
- Same setup as feature
- Shows bug testing checklist

**Hotfix template** (`.dev/worktree-templates/hotfix/setup.sh`):
- Same setup as feature
- Shows critical hotfix warnings and deployment checklist

### Working in a Worktree

```bash
# Navigate to worktree
cd .dev/worktree/feature-<name>-<issue>

# Make changes
# ... edit files ...

# Test changes
npm run db:reset
npm run test:rls
npm run test:functions

# Commit
git add .
git commit -m "feat: description"

# Push
git push -u origin feature/<name>-<issue>

# Create PR
gh pr create --base develop
```

### Cleaning Up

```bash
# After PR is merged
.github/scripts/remove-worktree.sh <worktree-name> --delete-branch

# Or manually
cd /path/to/main/repo
git worktree remove .dev/worktree/<worktree-name>
git branch -d feature/<branch-name>
```

## Environment Variables

### Required Variables

```bash
# .env
SUPABASE_OPENAI_API_KEY=sk-...
```

### Worktree-Specific Variables

Each worktree can have its own `.env` file with specific configurations:

```bash
# Feature-specific
TEST_USER_EMAIL=feature-test@example.com

# Bugfix-specific
DEBUG_MODE=true
VERBOSE_LOGGING=true

# Hotfix-specific
PRODUCTION_LIKE_DATA=true
```

### Secrets in Edge Functions

Never put secrets in `.env`. Use Supabase secrets:

```bash
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set OPENROUTER_API_KEY=sk-or-...
```

## Pre-Commit Hooks

### Recommended Checks

1. **SQL Linting**
   ```bash
   npm run lint:sql
   ```

2. **Function Linting**
   ```bash
   npm run lint:functions
   ```

3. **Type Checking**
   ```bash
   npm run types:generate
   ```

### Setting Up Pre-Commit

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook

echo "Running pre-commit checks..."

# Check for secrets in staged files
if git diff --cached --name-only | xargs grep -l "sk-" 2>/dev/null; then
    echo "Error: Potential API key found in staged files!"
    exit 1
fi

# Lint SQL if migrations changed
if git diff --cached --name-only | grep "supabase/migrations"; then
    echo "Linting SQL migrations..."
    npm run lint:sql || exit 1
fi

# Lint functions if changed
if git diff --cached --name-only | grep "supabase/functions"; then
    echo "Linting edge functions..."
    npm run lint:functions || exit 1
fi

echo "Pre-commit checks passed!"
```

## Additional Resources

- [Git Worktrees Guide](WORKTREES.md)
- [RLS Policies](RLS_POLICIES.md)
- [Migration Guidelines](../supabase/migrations/README.md)
- [Edge Functions Guide](../supabase/functions/README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [DevOps Guide](../DEVOPS.md)

## Summary

Following these conventions ensures:
- Consistent development experience
- Clear communication through commits
- Reliable database migrations
- Secure implementations
- Smooth code reviews
- Efficient collaboration

When in doubt, refer to this guide or ask for clarification in PR comments.
