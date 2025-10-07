# Git Worktrees for GitHub Git Flow

This project uses Git worktrees to manage parallel development of features, bugfixes, and hotfixes following GitHub Git Flow.

## Quick Start

```bash
# Create a worktree for an issue
.github/scripts/create-worktree.sh <issue-number> [type]

# List all worktrees
.github/scripts/list-worktrees.sh

# Remove a worktree
.github/scripts/remove-worktree.sh <worktree-name> [--delete-branch]
```

## What are Git Worktrees?

Git worktrees allow you to have multiple working directories attached to the same repository. This is useful for:

- Working on multiple features simultaneously without stashing or committing incomplete work
- Reviewing PRs without disrupting your current work
- Running tests on different branches in parallel
- Keeping your main development environment clean

## Directory Structure

```
/home/skogix/dev/supabase/          # Main repository
├── .dev/
│   ├── worktree/                    # All worktrees live here
│   │   ├── feature-auth-123/
│   │   ├── bugfix-cors-error-124/
│   │   └── hotfix-security-125/
│   └── worktree-templates/          # Templates for auto-configuration
│       ├── feature/
│       ├── bugfix/
│       └── hotfix/
```

## GitHub Git Flow Branch Types

### Feature Branches (`feature/*`)
- Base: `develop`
- Purpose: New features and enhancements
- Example: `feature/user-authentication-123`

```bash
.github/scripts/create-worktree.sh 123 feature
```

### Bugfix Branches (`bugfix/*`)
- Base: `develop`
- Purpose: Bug fixes for the next release
- Example: `bugfix/cors-error-124`

```bash
.github/scripts/create-worktree.sh 124 bugfix
```

### Hotfix Branches (`hotfix/*`)
- Base: `master`
- Purpose: Critical production fixes
- Example: `hotfix/security-patch-125`

```bash
.github/scripts/create-worktree.sh 125 hotfix
```

## Workflow Example

### 1. Create a worktree for issue #42

```bash
# Script automatically fetches issue title from GitHub
.github/scripts/create-worktree.sh 42 feature

# Output:
# Creating worktree:
#   Path: .dev/worktree/feature-add-user-profiles-42
#   Branch: feature/add-user-profiles-42
#   Base: develop
#
# ✓ Worktree created successfully!
#
# Running feature template setup...
# 🚀 Setting up feature worktree...
# ✓ Environment configured
# ✓ Dependencies installed
# ✓ Database ready
# ✓ Types generated
# ✅ Feature Worktree Setup Complete!
```

**What happens automatically:**
- Template files copied to worktree
- `.env` created from `.env.example`
- Dependencies installed (`npm install`)
- Supabase started (if not running)
- Database reset with migrations
- TypeScript types generated
- Feature checklist displayed

### 2. Work in the worktree

```bash
cd .dev/worktree/feature-add-user-profiles-42

# Make changes
npm run migration:new add_user_profiles
# Edit migration file
npm run db:reset
npm run test:rls

# Commit and push
git add .
git commit -m "Add user profiles table with RLS policies"
git push -u origin feature/add-user-profiles-42
```

### 3. Create PR

```bash
# Using GitHub CLI
gh pr create --base develop --title "Add user profiles" --body "Closes #42"

# Or manually on GitHub
```

### 4. Clean up after merge

```bash
# Return to main repo
cd /home/skogix/dev/supabase

# Remove worktree and local branch
.github/scripts/remove-worktree.sh feature-add-user-profiles-42 --delete-branch

# Delete remote branch (if not auto-deleted by GitHub)
git push origin --delete feature/add-user-profiles-42
```

## Advanced Usage

### Multiple worktrees for different issues

```bash
# Work on feature #42
.github/scripts/create-worktree.sh 42 feature

# Meanwhile, work on bugfix #43
.github/scripts/create-worktree.sh 43 bugfix

# Emergency hotfix for #44
.github/scripts/create-worktree.sh 44 hotfix

# All worktrees exist simultaneously
.github/scripts/list-worktrees.sh
```

### Manual worktree creation

```bash
# Create worktree with custom name
git worktree add .dev/worktree/my-feature -b feature/my-feature develop

# Create worktree from existing branch
git worktree add .dev/worktree/existing-feature existing-branch-name
```

### Reviewing PRs

```bash
# Create temporary worktree for PR review
git worktree add .dev/worktree/pr-review-42 origin/feature/some-feature

cd .dev/worktree/pr-review-42
npm run db:reset
npm test

# Clean up after review
cd ../..
git worktree remove .dev/worktree/pr-review-42
```

## Worktree Templates

Worktrees are automatically configured with templates based on their type. See [.dev/worktree-templates/README.md](../.dev/worktree-templates/README.md) for details.

**Available templates:**
- **feature** - Full development setup with workflow guide
- **bugfix** - Testing checklist and debugging guide  
- **hotfix** - Critical deployment checklist with safety checks

Each template includes:
- Automated environment setup
- Dependency installation
- Database initialization
- Type generation
- Type-specific checklists and guides

## Best Practices

1. **Always create worktrees in `.dev/worktree/`** - Keeps them organized and ignored by git
2. **Use meaningful names** - Scripts auto-generate from issue titles
3. **Let templates run** - Auto-setup ensures consistency
4. **Update .env with real values** - Templates use placeholders
5. **Follow type-specific checklists** - They prevent missing steps
6. **Clean up merged branches** - Remove worktrees after PR is merged
7. **One worktree per issue** - Keeps changes isolated and reviewable
8. **Sync regularly** - `git fetch origin` before creating new worktrees

## Troubleshooting

### Worktree removal fails

```bash
# Force remove if directory is locked
git worktree remove --force .dev/worktree/stuck-worktree
```

### List all worktrees

```bash
git worktree list
```

### Prune stale worktrees

```bash
# Remove worktree references for deleted directories
git worktree prune
```

### Check worktree status

```bash
cd .dev/worktree/my-feature
git status
git branch -vv  # See tracking branch
```

## Integration with Supabase Workflow

Worktrees work seamlessly with Supabase development:

```bash
# Each worktree has its own database state
cd .dev/worktree/feature-new-table-42
npm run db:start    # Uses same Docker instance
npm run db:reset    # Applies migrations in THIS worktree
npm run types:generate  # Generates types for THIS worktree's schema

# Main repo is unaffected
cd /home/skogix/dev/supabase
npm run db:status   # Shows different state
```

## Scripts Reference

### create-worktree.sh

Creates a new worktree for a GitHub issue.

**Usage**: `.github/scripts/create-worktree.sh <issue-number> [type]`

**Arguments**:
- `issue-number` (required): GitHub issue number
- `type` (optional): `feature`, `bugfix`, or `hotfix` (default: `feature`)

**Features**:
- Auto-fetches issue title from GitHub CLI
- Creates slug-friendly branch names
- Sets up tracking branch automatically
- Provides next steps guidance

### remove-worktree.sh

Removes a worktree and optionally its branch.

**Usage**: `.github/scripts/remove-worktree.sh <worktree-name> [--delete-branch]`

**Arguments**:
- `worktree-name` (required): Name of worktree directory
- `--delete-branch` (optional): Also delete the local branch

### list-worktrees.sh

Lists all active worktrees.

**Usage**: `.github/scripts/list-worktrees.sh`

## GitHub CLI Integration

Scripts use `gh` CLI for enhanced functionality:

```bash
# Install GitHub CLI if not present
# See: https://cli.github.com/

# Authenticate
gh auth login

# Scripts will automatically:
# - Fetch issue titles for better branch names
# - Create PRs with proper linking
# - Check issue status
```
