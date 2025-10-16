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

Automatically create a PR for the current Claude branch.

**Usage:**
```bash
auto-create-pr
```

**Behavior:**
- Checks if current branch is a `claude/*` branch
- Verifies branch has been pushed to remote
- Checks if PR already exists (skips if yes)
- Extracts issue number from branch name
- Creates PR with proper title and body
- Links PR to original issue (if applicable)

**Output:**
- PR URL on success
- Warning messages if PR creation is skipped
- Error if PR creation fails

**Example:**
```bash
# After Claude pushes code to claude/issue-123-20251009-1010
git checkout claude/issue-123-20251009-1010
./scripts/auto-create-pr
# Creates PR titled with issue #123's title, linking back to the issue
```

This script is designed to be integrated into the Claude workflow to automatically create PRs when tasks are completed. See [../docs/auto-pr-implementation.md](../docs/auto-pr-implementation.md) for integration details.

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

View all Claude activity in the repository.

**Usage:**
```bash
claude-status
```

Shows:
- All `claude/*` branches and their status
- Recent issues with @claude mentions
- Recent PRs with @claude mentions
- Summary statistics

---

### claude-sync

Sync all `claude/*` branches with the main branch (master or main) to prevent merge conflicts.

**Usage:**
```bash
claude-sync
```

What it does:
- Detects whether your repo uses `main` or `master`
- Fetches latest changes from remote
- Finds all local `claude/*` branches
- Merges the main branch into each claude branch
- Reports any conflicts that need manual resolution

This helps keep all Claude-created branches up to date with the latest changes, preventing conflicts when creating pull requests.

---

### claude-cleanup

Delete merged `claude/*` branches locally and remotely to keep repository clean.

**Usage:**
```bash
claude-cleanup
```

---

### claude-watch

Monitor Claude workflow runs with real-time status updates.

**Usage:**
```bash
# Watch latest Claude workflow run
claude-watch

# Watch specific run with logs
claude-watch --logs 12345678

# Compact mode for CI/scripts
claude-watch --compact
```

**Options:**
- `--logs`: Follow job logs in real-time after completion
- `--compact`: Use compact output mode (less verbose)

**Features:**
- Real-time status updates with auto-refresh
- Animated spinner during progress
- Color-coded status indicators
- Job-level progress tracking
- Automatic completion detection
- Optional log following

## How It Works

All tools trigger the GitHub workflow defined in `.github/workflows/claude.yml`:
1. You mention @claude via one of these tools
2. GitHub Actions workflow is triggered
3. Claude Code processes the request
4. Claude creates a branch (if needed) and responds with results

See [../docs/workflows.md](../docs/workflows.md) for technical details.
