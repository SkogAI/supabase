# Scripts Directory

Command-line tools and utility scripts for managing the Supabase project, including Claude Code integration, database management, SAML SSO configuration, and testing automation.

## Quick Reference

| Category | Scripts |
|----------|---------|
| **Claude Code Integration** | `claude-issue`, `claude-on-issue`, `claude-pr`, `claude-on-pr`, `claude-quick`, `claude-status`, `claude-sync`, `claude-cleanup`, `claude-watch` |
| **Development Setup** | `setup.sh`, `dev.sh`, `reset.sh` |
| **Database Management** | `check-db-health.sh`, `test-connection.sh`, `monitor-session-pool.sh` |
| **SAML SSO** | `saml-setup.sh`, `generate-saml-key.sh`, `test_saml.sh`, `test_saml_endpoints.sh`, `check_saml_logs.sh`, `validate_saml_attributes.sh` |
| **SSL/TLS** | `rotate-ssl-cert.sh`, `verify-ssl-connection.sh` |
| **Automation** | `auto-create-pr`, `auto-merge`, `check-mergeable`, `lint-and-test` |
| **Git Worktrees** | `create-all-worktrees.sh`, `create-all-worktrees-minimal.sh` |
| **Testing** | `create-test-issues.sh`, `verify_npm_scripts.sh` |

## Installation

Make scripts executable:
```bash
chmod +x scripts/*
```

Add to your PATH for easy access:
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/supabase/scripts"
```

Or use directly:
```bash
./scripts/setup.sh
```

---

## Claude Code Integration Scripts

Tools for working with Claude Code through GitHub issues and pull requests.

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

---

### claude-status

View all Claude activity in the repository.

**Usage:**
```bash
claude-status
```

**Shows:**
- All `claude/*` branches and their status
- Recent issues with @claude mentions
- Recent PRs with @claude mentions
- Summary statistics

**Requirements:** `jq`

---

### claude-sync

Sync all `claude/*` branches with the main branch (master or main) to prevent merge conflicts.

**Usage:**
```bash
claude-sync
```

**What it does:**
- Detects whether your repo uses `main` or `master`
- Fetches latest changes from remote
- Finds all local `claude/*` branches
- Merges the main branch into each claude branch
- Reports any conflicts that need manual resolution

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

---

## Automation Scripts

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

**Example:**
```bash
# After Claude pushes code to claude/issue-123-20251009-1010
git checkout claude/issue-123-20251009-1010
./scripts/auto-create-pr
# Creates PR titled with issue #123's title, linking back to the issue
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

**Auto-merge Conditions:**
1. ✅ PR has been approved by a reviewer
2. ✅ All CI checks have passed (or no checks required)
3. ✅ No merge conflicts exist

---

### check-mergeable

Check PR mergeability and auto-resolve conflicts when possible.

**Usage:**
```bash
check-mergeable
```

**Behavior:**
- Gets all open PRs
- Categorizes PRs by merge status
- Calls @claude to:
  - Fast-forward branches that are behind but clean
  - Resolve merge conflicts when possible
- Creates/updates a sync status issue

---

### lint-and-test

Run linting and testing checks for Python and TypeScript projects.

**Usage:**
```bash
lint-and-test
```

**Checks:**
- Python: `ruff` linting and `pytest` tests
- TypeScript: `tsc` type checking
- Non-blocking: always exits 0

---

## Development Setup Scripts

### setup.sh

Supabase Project Setup Script - sets up your local development environment.

**Usage:**
```bash
./scripts/setup.sh
```

**What it does:**
1. Checks prerequisites (Docker, Supabase CLI, Node.js, Deno)
2. Creates `.env` file from `.env.example`
3. Installs npm packages
4. Starts Supabase services
5. Generates TypeScript types from database schema
6. Shows access information and useful commands

**Requirements:**
- Docker Desktop (running)
- Supabase CLI
- Node.js/npm (optional but recommended)
- Deno (for edge functions)

---

### dev.sh

Quick development start script - faster than full setup.

**Usage:**
```bash
./scripts/dev.sh
```

**What it does:**
- Starts Supabase services
- Shows service URLs and connection info

---

### reset.sh

Reset database with fresh migrations and seed data.

**Usage:**
```bash
./scripts/reset.sh
```

**What it does:**
- Prompts for confirmation (destructive operation)
- Runs `supabase db reset`
- Reapplies all migrations and seed data

⚠️ **Warning:** This will delete all data!

---

## Database Management Scripts

### check-db-health.sh

Comprehensive database health check and monitoring script.

**Usage:**
```bash
./scripts/check-db-health.sh <connection_string>
# or
export DATABASE_URL='<connection_string>' && ./scripts/check-db-health.sh
```

**Checks:**
1. Basic connectivity
2. Database version and uptime
3. Connection statistics and pool usage
4. Connection breakdown by state
5. Active queries
6. Long-running queries (>30 seconds)
7. Idle in transaction connections
8. Database locks and blocking queries
9. Database size
10. Largest tables
11. Cache performance (buffer and index hit ratios)
12. Recent errors and conflicts
13. SSL status

**Requirements:** `psql` (PostgreSQL client)

---

### test-connection.sh

AI Agent Database Connection Test Script - comprehensive connectivity and diagnostics.

**Usage:**
```bash
./scripts/test-connection.sh <connection_string>
# or
export DATABASE_URL='<connection_string>' && ./scripts/test-connection.sh
```

**Tests:**
- Network connectivity (DNS, port, latency)
- SSL/TLS connection and certificate validation
- Database connection and query execution
- Prepared statements support (session vs transaction mode)
- RLS policies configuration
- IPv4/IPv6 detection

**Requirements:** `psql`, `openssl` (optional), `nc` or `telnet` (optional)

---

### monitor-session-pool.sh

Session Pool Monitoring Script for Supabase MCP Server.

**Usage:**
```bash
./scripts/monitor-session-pool.sh
```

**Monitors:**
- Connection pool status
- MCP agent connections
- Connection duration and age
- Long-running queries
- Database metrics and utilization
- Provides recommendations for optimization

**Environment Variables:**
- `SUPABASE_SESSION_POOLER`: Session pooler connection string
- Falls back to local connection if not set

**Requirements:** `psql`, `jq` (optional)

---

## SAML SSO Scripts

Complete toolset for setting up and testing SAML SSO with ZITADEL Identity Provider.

### saml-setup.sh

Automated SAML SSO setup script for self-hosted Supabase.

**Usage:**
```bash
./scripts/saml-setup.sh -d example.com -m https://instance.zitadel.cloud/saml/v2/metadata

# Skip certificate generation (if already have certs)
./scripts/saml-setup.sh -d example.com -m https://metadata-url -s
```

**Options:**
- `-d, --domain DOMAIN`: Email domain for SSO (required)
- `-m, --metadata-url URL`: ZITADEL metadata URL (required)
- `-s, --skip-certs`: Skip certificate generation
- `-h, --help`: Show help message

**What it does:**
1. Checks prerequisites (Docker, OpenSSL, curl, jq)
2. Generates SAML certificates (RSA 2048-bit, valid 10 years)
3. Updates environment configuration
4. Restarts Supabase services
5. Creates SAML provider via Admin API
6. Verifies configuration

**Environment Variables:**
- `SUPABASE_URL`: Supabase instance URL (default: http://localhost:8000)
- `SERVICE_ROLE_KEY`: Supabase service role key (required)

---

### generate-saml-key.sh

Generate SAML private key in DER format and encode to base64.

**Usage:**
```bash
./scripts/generate-saml-key.sh [output_directory]
```

**What it does:**
1. Generates 2048-bit RSA private key in DER format
2. Encodes key to base64 (single line, no spaces)
3. Verifies key structure and encoding
4. Provides next steps for configuration

**Output:**
- `private_key.der`: RSA private key in DER format
- `private_key.base64`: Base64-encoded key for Supabase configuration

**Default location:** `~/supabase-saml-keys/`

**Requirements:** `openssl`, `base64`

---

### test_saml.sh

Master test suite for SAML integration.

**Usage:**
```bash
./scripts/test_saml.sh

# Skip specific tests
./scripts/test_saml.sh --skip-endpoints
./scripts/test_saml.sh --skip-attributes
./scripts/test_saml.sh --skip-logs

# Test with specific user
./scripts/test_saml.sh --user-email testuser@example.com
```

**Options:**
- `--skip-endpoints`: Skip endpoint tests
- `--skip-attributes`: Skip attribute validation
- `--skip-logs`: Skip log analysis
- `--user-email EMAIL`: Specify user for attribute testing
- `-h, --help`: Show help

**What it tests:**
1. Endpoint accessibility and configuration
2. SAML attribute mapping
3. Docker logs analysis
4. Manual test instructions

**Environment Variables:**
- `SUPABASE_URL`: Supabase URL (default: http://localhost:8000)
- `SERVICE_ROLE_KEY`: Service role key (required for most tests)
- `SSO_DOMAIN`: SSO domain for testing

---

### test_saml_endpoints.sh

Test SAML endpoints accessibility and configuration.

**Usage:**
```bash
./scripts/test_saml_endpoints.sh
```

**Tests:**
1. SAML Metadata Endpoint (`/auth/v1/sso/saml/metadata`)
2. SSO Providers listing (`/auth/v1/admin/sso/providers`)
3. SSO Initiation URL (`/auth/v1/sso?domain=...`)
4. SAML ACS Endpoint (`/auth/v1/sso/saml/acs`)

**Requirements:** `curl`, `jq` (optional), `xmllint` (optional)

---

### validate_saml_attributes.sh

Validate that SAML attributes are correctly mapped to Supabase user metadata.

**Usage:**
```bash
./scripts/validate_saml_attributes.sh <user-email>
```

**Example:**
```bash
./scripts/validate_saml_attributes.sh testuser1@example.com
```

**Validates:**
- Email
- Provider (should be 'saml')
- First name / Given name / FirstName
- Last name / Family name / Surname / SurName
- Full name / Name / FullName
- Username / Preferred username / UserName
- User ID / Subject (sub)

**Requirements:** `curl`, `jq`, `SERVICE_ROLE_KEY`

---

### check_saml_logs.sh

Check Docker logs for SAML-related entries and errors.

**Usage:**
```bash
./scripts/check_saml_logs.sh

# Follow logs in real-time
./scripts/check_saml_logs.sh -f

# Show last 200 lines
./scripts/check_saml_logs.sh -t 200

# Check specific service
./scripts/check_saml_logs.sh -s auth
./scripts/check_saml_logs.sh -s kong
```

**Options:**
- `-f, --follow`: Follow logs in real-time
- `-t, --tail N`: Show last N lines (default: 100)
- `-s, --service`: Specific service (auth, kong, all)

**Analyzes:**
- Auth service logs (GoTrue)
- Kong gateway logs
- Error counts and warnings
- Endpoint access patterns

---

## SSL/TLS Scripts

### rotate-ssl-cert.sh

Automate SSL certificate rotation for Supabase database connections.

**Usage:**
```bash
./scripts/rotate-ssl-cert.sh

# Custom certificate directory
./scripts/rotate-ssl-cert.sh --cert-dir /etc/ssl/supabase

# Test connection after rotation
TEST_DB_HOST=db.xxx.supabase.co ./scripts/rotate-ssl-cert.sh

# Custom certificate name
./scripts/rotate-ssl-cert.sh --cert-name staging-ca.crt --url https://example.com/staging-ca.crt
```

**Options:**
- `-d, --cert-dir DIR`: Certificate directory (default: ./certs)
- `-n, --cert-name NAME`: Certificate filename (default: prod-ca-2021.crt)
- `-u, --url URL`: Certificate download URL
- `-t, --test-host HOST`: Test connection to database host

**What it does:**
1. Backs up existing certificate
2. Downloads new certificate
3. Validates certificate format and expiry
4. Installs new certificate with secure permissions
5. Tests SSL connection (optional)
6. Cleans up old backups (keeps last 10)

**Requirements:** `openssl`, `curl`

---

### verify-ssl-connection.sh

Verify SSL/TLS certificate and connection to Supabase database.

**Usage:**
```bash
./scripts/verify-ssl-connection.sh

# Verify with database connection test
./scripts/verify-ssl-connection.sh --host db.xxx.supabase.co

# Use environment variable
DATABASE_URL="postgresql://..." ./scripts/verify-ssl-connection.sh

# Custom certificate path
./scripts/verify-ssl-connection.sh --cert /path/to/custom-ca.crt --host db.xxx.supabase.co
```

**Options:**
- `-c, --cert PATH`: Path to SSL certificate (default: ./certs/prod-ca-2021.crt)
- `-H, --host HOST`: Database hostname
- `-p, --port PORT`: Database port (default: 5432)

**Tests:**
1. Certificate file exists and is readable
2. Certificate format validation (X.509)
3. Certificate expiration
4. Certificate details (subject, issuer, validity)
5. Network connectivity to database host
6. SSL handshake
7. Certificate chain validation

**Requirements:** `openssl`, `curl`

---

## Git Worktree Scripts

### create-all-worktrees.sh

Create sparse worktrees for all GitHub issues, PRs, and branches.

**Usage:**
```bash
./scripts/create-all-worktrees.sh

# Only create worktrees for issues
./scripts/create-all-worktrees.sh --issues-only

# Only create worktrees for PRs
./scripts/create-all-worktrees.sh --prs-only

# Only create worktrees for existing branches
./scripts/create-all-worktrees.sh --branches-only
```

**Environment Variables:**
- `WORKTREE_BASE`: Base directory for worktrees (default: /home/skogix/dev/supabase/.dev/worktree)
- `PARSE_TEMPLATE`: Sparse checkout template (default: .github/sparse-checkouts/default.txt)

**Features:**
- Creates sparse worktrees (only checks out files matching template)
- Processes GitHub issues, PRs, and existing branches
- Tracks statistics (created, skipped, failed)
- Color-coded output

**Requirements:** `gh` (GitHub CLI), authenticated with GitHub

---

### create-all-worktrees-minimal.sh

Minimal version of worktree creation script - faster, less verbose.

**Usage:**
```bash
./scripts/create-all-worktrees-minimal.sh
```

Same functionality as `create-all-worktrees.sh` but with minimal output and faster execution.

---

## Testing Scripts

### create-test-issues.sh

Create GitHub issues for unit tests based on PROPOSED_TEST_ISSUES.md.

**Usage:**
```bash
./scripts/create-test-issues.sh
```

**Creates 5 test issues:**
1. Profile RLS policy tests (service role, CRUD operations)
2. Storage bucket configuration tests
3. Realtime subscriptions tests
4. Edge function comprehensive tests
5. End-to-end integration tests

**Requirements:** `gh` (GitHub CLI), authenticated with GitHub

---

### verify_npm_scripts.sh

Verification script for all npm run commands - tests and verifies that all npm scripts defined in package.json are functioning correctly.

**Usage:**
```bash
./scripts/verify_npm_scripts.sh
```

**Verifies:**
- Script syntax in package.json
- Database scripts (db:*, migration:*)
- Edge function scripts (functions:*, lint:functions, format:functions)
- Type generation scripts (types:generate, types:watch)
- Testing scripts (test:rls, test:functions*, test:realtime, test:saml*)
- Linting and formatting scripts (lint:sql, lint:functions, format:functions)
- Utility scripts (dev, setup, examples:*)
- Function execution (safe tests only)

**Provides:**
- Success rate statistics
- Detailed results for each script
- Installation instructions for missing dependencies

**Requirements:** `npm`, `jq`

---

## Requirements

### Common Tools
- **Docker & Docker Desktop**: Required for all database and Supabase operations
- **Supabase CLI**: Required for most database, migration, and function scripts
- **GitHub CLI (`gh`)**: Required for all Claude Code integration scripts
- **Node.js & npm**: Required for most scripts
- **jq**: Required for JSON parsing in many scripts
- **curl**: Required for API calls and downloads

### Language-Specific Tools
- **Deno**: Required for edge function scripts
- **PostgreSQL Client (`psql`)**: Required for database connection scripts
- **OpenSSL**: Required for SSL/TLS and SAML certificate scripts
- **Python & pip**: Required for SQL linting (sqlfluff)

### Installation Commands

**macOS (Homebrew):**
```bash
brew install gh jq deno supabase/tap/supabase
brew install --cask docker
brew install postgresql openssl curl
pip install sqlfluff
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install gh jq curl postgresql-client openssl
curl -fsSL https://deno.land/install.sh | sh
npm install -g supabase
pip install sqlfluff
```

---

## Common Workflows

### Getting Started
```bash
# 1. Initial setup
./scripts/setup.sh

# 2. Quick start for development
./scripts/dev.sh

# 3. Reset database when needed
./scripts/reset.sh
```

### Working with Claude Code
```bash
# Create an issue for Claude
./scripts/claude-issue "implement user authentication"

# Quick shortcut - auto-detects issue vs PR
./scripts/claude-quick "fix authentication bug"

# Check Claude's progress
./scripts/claude-status

# Keep Claude branches up to date
./scripts/claude-sync

# Clean up merged branches
./scripts/claude-cleanup
```

### SAML SSO Setup
```bash
# 1. Generate SAML private key
./scripts/generate-saml-key.sh

# 2. Complete SAML setup
./scripts/saml-setup.sh -d example.com -m https://instance.zitadel.cloud/saml/v2/metadata

# 3. Test SAML integration
./scripts/test_saml.sh

# 4. Validate user attributes after login
./scripts/validate_saml_attributes.sh user@example.com
```

### Database Health Monitoring
```bash
# Check overall database health
./scripts/check-db-health.sh "$DATABASE_URL"

# Test connectivity and diagnostics
./scripts/test-connection.sh "$DATABASE_URL"

# Monitor session pool
./scripts/monitor-session-pool.sh
```

### SSL Certificate Management
```bash
# Verify current SSL certificate
./scripts/verify-ssl-connection.sh --host db.xxx.supabase.co

# Rotate SSL certificate
./scripts/rotate-ssl-cert.sh
```

---

## Troubleshooting

### Script Permissions
If you get "Permission denied":
```bash
chmod +x scripts/<script-name>
```

### Missing Dependencies
Run the verification script to check what's missing:
```bash
./scripts/verify_npm_scripts.sh
```

### Docker Not Running
```bash
# Check Docker status
docker info

# Start Docker Desktop (macOS/Windows)
open -a Docker

# Start Docker daemon (Linux)
sudo systemctl start docker
```

### Supabase Not Running
```bash
# Check Supabase status
npm run db:status

# Start Supabase
npm run db:start
```

### GitHub CLI Not Authenticated
```bash
gh auth login
```

### PostgreSQL Client Missing
```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql-client

# Arch Linux
sudo pacman -S postgresql-libs
```

---

## Documentation

For more detailed information, see:
- **[CLAUDE.md](../CLAUDE.md)** - Project overview and quick reference
- **[docs/WORKFLOWS.md](../docs/WORKFLOWS.md)** - Detailed development workflows
- **[docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)** - Comprehensive troubleshooting guide
- **[docs/AUTH_ZITADEL_SAML_SELF_HOSTED.md](../docs/AUTH_ZITADEL_SAML_SELF_HOSTED.md)** - Complete SAML SSO guide
- **[docs/SAML_ADMIN_API.md](../docs/SAML_ADMIN_API.md)** - SAML provider management API
- **[docs/USER_GUIDE_SAML.md](../docs/USER_GUIDE_SAML.md)** - End-user SAML authentication guide
- **[docs/MCP_*.md](../docs/)** - AI agent integration guides

---

## Contributing

When adding new scripts:

1. **Make them executable:** `chmod +x scripts/your-script.sh`
2. **Add a header comment** with:
   - Purpose description
   - Usage examples
   - Required environment variables
   - Dependencies
3. **Use consistent formatting:**
   - Bash shebang: `#!/bin/bash` or `#!/usr/bin/env bash`
   - Error handling: `set -e` for critical scripts
   - Color output: Use the standard color variables (RED, GREEN, YELLOW, BLUE, NC)
4. **Update this README** with:
   - Script description
   - Usage examples
   - Requirements
5. **Test thoroughly** before committing

---

## License

This project is part of the Supabase implementation. See the main project README for license information.
