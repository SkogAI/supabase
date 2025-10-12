# GitHub Configuration Directory

This directory contains GitHub-specific configuration and CI/CD related scripts.

## Directory Structure

```
.github/
├── README.md                    # This file
├── ISSUE_TEMPLATE/              # GitHub issue templates (managed by GitHub)
├── PULL_REQUEST_TEMPLATE.md     # PR template (if exists)
├── workflows/                   # GitHub Actions workflows (CI/CD)
└── scripts/                     # CI/CD and worktree management scripts
    ├── ci-worktree.sh           # CI integration for worktrees
    ├── create-worktree.sh       # Create git worktrees
    ├── remove-worktree.sh       # Remove git worktrees
    ├── cleanup-worktrees.sh     # Clean up stale worktrees
    ├── list-worktrees.sh        # List active worktrees
    ├── install-hooks.sh         # Install git hooks
    └── _shared_utils.sh         # Shared utilities for scripts
```

## What Goes Here

### ✅ Keep in `.github/`
- **GitHub Actions workflows** (`workflows/`)
- **Issue/PR templates** (managed by GitHub UI)
- **CI/CD scripts** (`scripts/`) - worktree management, hooks
- **GitHub-specific config** (CODEOWNERS, dependabot.yml, etc.)

### ❌ Move to Other Locations
- **User documentation** → `docs/` directory
- **Setup scripts** → `scripts/setup/` directory
- **Test templates** → `docs/` or `tests/` directory
- **General guides** → `docs/` directory

## Documentation

All user-facing documentation has been moved to the `docs/` directory for better organization:

- **Issue Management**: See [`docs/ISSUE_QUICK_START.md`](../docs/ISSUE_QUICK_START.md) and [`docs/ISSUE_MANAGEMENT.md`](../docs/ISSUE_MANAGEMENT.md)
- **Labels Reference**: See [`docs/LABELS.md`](../docs/LABELS.md)
- **Test Issue Templates**: See [`docs/CREATING_TEST_ISSUES.md`](../docs/CREATING_TEST_ISSUES.md)

## Scripts

### Setup Scripts
Setup-related scripts have been moved to `scripts/setup/`:
- **Label Creation**: `scripts/setup/create-labels.sh`

### Worktree Scripts
Worktree management scripts remain in `.github/scripts/` as they're primarily used by CI/CD:
- **Create worktree**: `.github/scripts/create-worktree.sh`
- **Remove worktree**: `.github/scripts/remove-worktree.sh`
- **Cleanup worktrees**: `.github/scripts/cleanup-worktrees.sh`
- **List worktrees**: `.github/scripts/list-worktrees.sh`
- **Install hooks**: `.github/scripts/install-hooks.sh`

See [`docs/WORKTREES.md`](../docs/WORKTREES.md) for complete worktree documentation.

## Workflows

GitHub Actions workflows are in `.github/workflows/`. See [`docs/DEVOPS.md`](../docs/DEVOPS.md) for CI/CD documentation.

---

**Last Updated**: 2025-10-12
**Maintained By**: @Skogix, @Ic0n
