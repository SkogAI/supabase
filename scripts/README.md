# Claude GitHub Workflow Tools

Command-line tools for working with Claude Code through GitHub issues and pull requests.

## Installation

Make scripts executable:
```bash
chmod +x scripts/*
```

Add to your PATH for easy access:
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/github-flow/scripts"
```

Or use directly:
```bash
./scripts/claude-issue "your task"
```

## Requirements

- [GitHub CLI (gh)](https://cli.github.com/) - installed and authenticated
- Git repository with remote access
- `jq` (for claude-status only)

## Tools

### claude-issue

Create GitHub issues that automatically trigger @claude.

**Usage:**
```bash
claude-issue "fix the auth bug in login flow"
```

Creates an issue with @claude mentioned in the body, triggering the Claude workflow immediately.

---

### claude-on-issue

Add @claude comments to existing issues.

**Usage:**
```bash
claude-on-issue <issue-number> <task-description>
```

**Example:**
```bash
claude-on-issue 123 "analyze the root cause of this bug"
```

---

### claude-pr

Create pull requests from your current branch with @claude mention.

**Usage:**
```bash
claude-pr "review this refactoring for security issues"
```

Creates a PR from current branch to main/master with @claude mentioned, triggering the workflow.

---

### claude-on-pr

Add @claude comments to existing pull requests.

**Usage:**
```bash
claude-on-pr <pr-number> <task-description>
```

**Example:**
```bash
claude-on-pr 42 "check if this handles edge cases properly"
```

---

### claude-quick

Intelligent wrapper that automatically chooses between creating an issue or PR based on your git state.

**Usage:**
```bash
claude-quick "your task description"
```

**Behavior:**
- **Unstaged/uncommitted changes exist** → Creates issue with `claude-issue`
- **Clean branch (not main/master)** → Creates PR with `claude-pr`
- **Clean branch (on main/master)** → Creates issue with `claude-issue`

**Examples:**
```bash
# With uncommitted changes - creates issue
claude-quick "fix authentication bug"

# On clean feature branch - creates PR
claude-quick "review this refactoring"

# On main with clean state - creates issue
claude-quick "add new feature"
```

This tool makes it easy to quickly trigger Claude without thinking about whether you need an issue or PR.

---

### auto-create-pr

Automatically create a PR for automated branches when changes are pushed.

**Usage:**
```bash
# Create PR for any branch
auto-create-pr

# Create PR only if on claude/* branch
auto-create-pr --prefix claude/

# Create PR only if on copilot/* branch
auto-create-pr --prefix copilot/
```

**Options:**
- `--prefix PREFIX`: Optional filter to only create PR if branch has specific prefix

**Requirements:**
- Branch must be pushed to remote
- GitHub CLI (gh) must be installed and authenticated

**What it does:**
- Checks if you're on a matching branch (if prefix specified)
- Verifies branch exists on remote
- Checks if PR already exists (skips if yes)
- Extracts issue number from branch name pattern (issue-123-*)
- Creates PR with issue reference
- Links PR to original issue with "Closes #N"

**Note:** Works on any branch by default. Use `--prefix` to filter to specific branch patterns.

**Integration:**

Add to `.github/workflows/*.yml`:

```yaml
- name: Create PR automatically
  if: github.ref != 'refs/heads/master'
  run: ./scripts/auto-create-pr
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### auto-merge

Automatically merge approved PRs when CI passes.

**Usage:**
```bash
auto-merge
```

**Behavior:**
- Checks all open PRs in the repository
- For each PR, verifies:
  - Review status (must be APPROVED)
  - CI checks (must all pass or be skipped)
  - Merge conflicts (must be MERGEABLE)
- Auto-merges PRs that meet all conditions
- Uses squash merge and deletes the branch
- Comments on PRs with merge status

**Output:**
- Detailed status for each PR
- Summary of merged and skipped PRs

**Example:**
```bash
./scripts/auto-merge
# Checks all open PRs and merges those that are approved with passing CI
```

This script is also integrated into the `.github/workflows/auto-merge.yml` workflow which runs automatically when:
- A PR receives a review
- CI checks complete
- Status checks succeed

**Auto-merge Conditions:**
1. ✅ PR has been approved by a reviewer
2. ✅ All CI checks have passed (or no checks required)
3. ✅ No merge conflicts exist

**Why Auto-merge?**
- Keeps the workflow moving without manual intervention
- Prevents approved PRs from sitting idle
- Reduces context switching for developers
- Ensures PRs are merged as soon as they're ready

---

### claude-status

View branch activity and status across the repository.

**Usage:**
```bash
# Show all branches
claude-status

# Show only claude/* branches
claude-status --prefix claude/

# Show only copilot/* branches
claude-status --prefix copilot/
```

**Options:**
- `--prefix PREFIX`: Optional filter to show only branches with specific prefix

Shows:
- All branches (or filtered by prefix) and their status
- Recent issues with @claude mentions
- Recent PRs with @claude mentions
- Summary statistics

**Note:** Works on all branches by default. Use `--prefix` to filter to specific branch patterns.

---

### claude-sync

Sync branches with the main branch (master or main) to prevent merge conflicts.

**Usage:**
```bash
# Sync all branches
claude-sync

# Sync only claude/* branches
claude-sync --prefix claude/

# Sync only copilot/* branches
claude-sync --prefix copilot/
```

**Options:**
- `--prefix PREFIX`: Optional filter to sync only branches with specific prefix

What it does:
- Detects whether your repo uses `main` or `master`
- Fetches latest changes from remote
- Finds all local branches (or filtered by prefix)
- Merges the main branch into each branch
- Reports any conflicts that need manual resolution

**Note:** Works on all branches by default. Use `--prefix` to filter to specific branch patterns.

---

### claude-cleanup

Delete merged branches locally and remotely to keep repository clean.

**Usage:**
```bash
# Clean up all merged branches
claude-cleanup

# Clean up only claude/* merged branches
claude-cleanup --prefix claude/

# Clean up only copilot/* merged branches
claude-cleanup --prefix copilot/
```

**Options:**
- `--prefix PREFIX`: Optional filter to clean only branches with specific prefix

What it does:
- Fetches latest remote state
- Checks which branches are merged into main/master
- Deletes merged branches locally and remotely
- Skips unmerged branches

**Note:** Works on all branches by default. Use `--prefix` to filter to specific branch patterns.

---

### claude-watch

Monitor workflow runs with real-time status updates.

**Usage:**
```bash
# Watch latest workflow run
claude-watch

# Watch latest copilot.yml workflow
claude-watch --workflow copilot.yml

# Watch specific run with logs
claude-watch --logs 12345678

# Watch specific workflow in compact mode
claude-watch --workflow feature.yml --compact
```

**Options:**
- `--workflow NAME`: Optional filter to watch specific workflow file
- `--logs`: Follow job logs in real-time after completion
- `--compact`: Use compact output mode (less verbose)

**Features:**
- Real-time status updates with auto-refresh
- Animated spinner during progress
- Color-coded status indicators
- Job-level progress tracking
- Automatic completion detection
- Optional log following

**Note:** Watches latest workflow run by default. Use `--workflow` to filter to specific workflow file.

---

### check-db-health.sh

[TODO: Add description for database health checking script]

---

### check-mergeable

[TODO: Add description for PR merge conflict checking script]

---

### check_saml_logs.sh

[TODO: Add description for SAML authentication logs checking script]

---

### create-all-worktrees-minimal.sh

[TODO: Add description for minimal worktree creation script]

---

### create-all-worktrees.sh

[TODO: Add description for comprehensive worktree creation script]

---

### create-test-issues.sh

[TODO: Add description for test issue creation script]

---

### dev.sh

[TODO: Add description for development startup script]

---

### generate-saml-key.sh

[TODO: Add description for SAML key generation script]

---

### lint-and-test

[TODO: Add description for linting and testing script]

---

### monitor-session-pool.sh

[TODO: Add description for database session pool monitoring script]

---

### reset.sh

[TODO: Add description for database reset script]

---

### rotate-ssl-cert.sh

[TODO: Add description for SSL certificate rotation script]

---

### saml-setup.sh

[TODO: Add description for SAML setup automation script]

---

### setup.sh

[TODO: Add description for project setup script]

---

### test-connection.sh

[TODO: Add description for database connection testing script]

---

### test_saml_endpoints.sh

[TODO: Add description for SAML endpoint testing script]

---

### test_saml.sh

[TODO: Add description for SAML integration testing script]

---

### validate_saml_attributes.sh

[TODO: Add description for SAML attribute validation script]

---

### verify_npm_scripts.sh

[TODO: Add description for npm scripts verification script]

---

### verify-ssl-connection.sh

[TODO: Add description for SSL connection verification script]

---

## How It Works

All tools trigger the GitHub workflow defined in `.github/workflows/claude.yml`:
1. You mention @claude via one of these tools
2. GitHub Actions workflow is triggered
3. Claude Code processes the request
4. Claude creates a branch (if needed) and responds with results

See [../docs/workflows.md](../docs/workflows.md) for technical details.
