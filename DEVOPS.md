# DevOps Setup Guide

Complete configuration guide for CI/CD, secrets management, and deployment workflows.

## Table of Contents

- [Required Secrets](#required-secrets)
- [Environment Setup](#environment-setup)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Local Development](#local-development)
- [Deployment Process](#deployment-process)
- [Monitoring & Maintenance](#monitoring--maintenance)

---

## Required Secrets

Configure these secrets in GitHub Settings → Secrets and variables → Actions

### Core Supabase Secrets

| Secret Name | Description | How to Obtain | Required For |
|------------|-------------|---------------|--------------|
| `SUPABASE_ACCESS_TOKEN` | Supabase CLI access token | [Supabase Dashboard](https://supabase.com/dashboard) → Account → Access Tokens | All workflows |
| `SUPABASE_PROJECT_ID` | Your Supabase project reference ID | Supabase Dashboard → Project Settings → General → Reference ID | Deployment, migrations |
| `SUPABASE_DB_PASSWORD` | Database password | Supabase Dashboard → Project Settings → Database → Password | Database operations |

### Optional Secrets

| Secret Name | Description | Required For |
|------------|-------------|--------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | Claude Code integration token | PR analysis, automated reviews |
| `SUPABASE_OPENAI_API_KEY` | OpenAI API key for Studio AI features | Local development (optional) |

### Setting Up Secrets

```bash
# Using GitHub CLI
gh secret set SUPABASE_ACCESS_TOKEN
gh secret set SUPABASE_PROJECT_ID
gh secret set SUPABASE_DB_PASSWORD
gh secret set CLAUDE_CODE_OAUTH_TOKEN

# Verify secrets are set
gh secret list
```

---

## Environment Setup

### Local Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

**NEVER commit `.env` to git!**

### Project Configuration

The `supabase/config.toml` file contains all project configuration. Key sections:

- **API**: Port 8000 for local development
- **Database**: PostgreSQL 17 on port 54322
- **Studio**: UI on port 8000
- **Edge Runtime**: Deno 2.x with inspector on port 8083
- **Storage**: 50MiB file size limit

---

## GitHub Actions Workflows

### Workflow Overview

| Workflow | Trigger | Purpose | Status |
|----------|---------|---------|--------|
| **deploy.yml** | Push to `master`/`main` | Deploy migrations and functions | ✅ Ready |
| **pr-checks.yml** | Pull requests | Validate PRs, check for secrets | ✅ Ready |
| **migrations-validation.yml** | Migration changes | Test migrations in isolated environment | ✅ Ready |
| **edge-functions-test.yml** | Function changes | Lint, type-check, and test functions | ✅ Ready |
| **schema-lint.yml** | Database changes | Check schema for anti-patterns | ✅ Ready |
| **security-scan.yml** | All pushes | Scan for vulnerabilities | ✅ Ready |
| **type-generation.yml** | Database changes | Generate TypeScript types | ✅ Ready |
| **performance-test.yml** | Schedule/manual | Run performance benchmarks | ✅ Ready |
| **backup.yml** | Schedule/manual | Create database backups | ✅ Ready |
| **dependency-updates.yml** | Schedule | Keep dependencies updated | ✅ Ready |

### Workflow Details

#### 1. **Deployment Workflow** (`deploy.yml`)

Automatically deploys to production on merge to `master`/`main`:

- Validates credentials
- Links to Supabase project
- Runs database migrations
- Deploys all edge functions
- Generates deployment summary

**Manual deployment:**
```bash
gh workflow run deploy.yml -f environment=staging
```

#### 2. **PR Checks** (`pr-checks.yml`)

Runs on every pull request:

- Validates PR title format
- Checks for migration changes
- Scans for hardcoded secrets
- Generates comprehensive PR analysis
- Provides review checklist

#### 3. **Migration Validation** (`migrations-validation.yml`)

Tests migrations in clean environment:

- Starts fresh Supabase instance
- Applies all migrations
- Checks for timestamp conflicts
- Analyzes breaking changes
- Validates rollback procedures

#### 4. **Edge Function Testing** (`edge-functions-test.yml`)

Complete function validation:

- Deno formatting check
- Type checking
- Linting
- Unit tests
- Integration tests with local Supabase
- Security analysis

#### 5. **Schema Linting** (`schema-lint.yml`)

Database best practices:

- Missing indexes
- Unbounded text fields
- Missing RLS policies
- Naming conventions
- Performance anti-patterns

#### 6. **Security Scanning** (`security-scan.yml`)

Comprehensive security checks:

- Dependency vulnerabilities
- Code security issues
- Secret scanning
- OWASP best practices

---

## Local Development

### Prerequisites

```bash
# Required tools
- Docker Desktop (must be running)
- Supabase CLI: https://supabase.com/docs/guides/cli
- Node.js 18+ (for edge functions)
- Deno 2.x (for edge functions)
```

### Quick Start

```bash
# 1. Clone and setup
git clone <repository>
cd supabase
cp .env.example .env

# 2. Edit .env with your API keys
nano .env

# 3. Start Supabase (Docker must be running!)
supabase start

# 4. Access services
# Studio: http://localhost:8000
# API: http://localhost:8000
# Database: postgresql://postgres:postgres@localhost:54322/postgres

# 5. View status
supabase status

# 6. Stop services
supabase stop
```

### Development Workflow

```bash
# Database migrations
supabase migration new <migration_name>
# Edit the migration file
supabase db reset  # Apply migrations

# Edge functions
supabase functions new <function_name>
# Edit the function
supabase functions serve  # Test locally
supabase functions deploy <function_name>  # Deploy to cloud

# Generate TypeScript types
supabase gen types typescript --local > types/database.ts

# View logs
supabase logs
```

### Directory Structure

```
supabase/
├── migrations/          # Database migrations (timestamped SQL files)
├── functions/           # Edge functions (Deno/TypeScript)
│   └── <function-name>/
│       ├── index.ts     # Main function file
│       └── test.ts      # Tests (optional)
├── seed.sql            # Seed data for local dev
└── config.toml         # Project configuration
```

---

## Deployment Process

### Automatic Deployment

1. **Create PR** with your changes
2. **PR Checks** run automatically (migrations, functions, security)
3. **Review and merge** to `master`/`main`
4. **Deploy workflow** runs automatically
5. **Verify deployment** in Supabase Dashboard

### Manual Deployment

```bash
# Option 1: GitHub CLI
gh workflow run deploy.yml -f environment=production

# Option 2: Local deployment
supabase link --project-ref <your-project-ref>
supabase db push
supabase functions deploy
```

### Deployment Checklist

- [ ] All tests passing in CI
- [ ] Migrations reviewed and tested
- [ ] No breaking changes (or communicated)
- [ ] Secrets configured in GitHub
- [ ] Database backup created (if needed)
- [ ] Edge functions tested locally
- [ ] TypeScript types generated and committed
- [ ] Documentation updated

---

## Monitoring & Maintenance

### Regular Tasks

**Daily:**
- Monitor deployment status
- Review error logs in Supabase Dashboard

**Weekly:**
- Review dependency update PRs
- Check performance metrics
- Review security scan results

**Monthly:**
- Database backup verification
- Performance optimization review
- Review and update documentation

### Useful Commands

```bash
# Check deployment status
gh run list --workflow=deploy.yml --limit 5

# View workflow logs
gh run view <run-id> --log

# Trigger backup
gh workflow run backup.yml

# View Supabase logs
supabase logs --level error

# Check database size
supabase db dump --data-only | wc -c
```

### Troubleshooting

#### Migration Failures

```bash
# Check migration status
supabase migration list

# Reset local database
supabase db reset

# Manual migration repair (remote)
supabase db push --dry-run  # Preview changes
supabase db push --include-all  # Force push
```

#### Edge Function Deployment Failures

```bash
# Check function logs
supabase functions logs <function-name>

# Test locally first
supabase functions serve <function-name>
curl http://localhost:54321/functions/v1/<function-name>

# Redeploy
supabase functions deploy <function-name> --no-verify-jwt
```

#### Secrets Not Working

```bash
# Verify secrets are set
gh secret list

# Update secret
gh secret set SUPABASE_ACCESS_TOKEN

# Check workflow logs for specific error
gh run view <run-id> --log | grep -i error
```

---

## Security Best Practices

### ✅ DO

- Use environment variables for all secrets
- Enable RLS on all public tables
- Use `env(VARIABLE_NAME)` syntax in `config.toml`
- Review dependency updates before merging
- Keep `.env` in `.gitignore`
- Use strong database passwords
- Rotate secrets periodically
- Enable MFA on GitHub and Supabase accounts

### ❌ DON'T

- Commit `.env` files
- Hardcode API keys or passwords
- Disable security scans
- Skip migration testing
- Deploy without reviewing changes
- Use `--no-verify` flags without reason
- Share access tokens publicly

---

## Performance Optimization

### Database

- Add indexes on frequently queried columns
- Use `EXPLAIN ANALYZE` for slow queries
- Implement proper RLS policies (not overly complex)
- Use connection pooling for high traffic
- Monitor database size and plan upgrades

### Edge Functions

- Minimize cold start time (keep functions small)
- Use proper error handling
- Implement caching where appropriate
- Monitor function execution time
- Use Deno's built-in performance tools

### Monitoring

```bash
# Database performance
supabase db logs --level warning

# Function performance
supabase functions logs <name> --tail

# Check resource usage in Supabase Dashboard
# Settings → Usage
```

---

## Quick Reference

### Essential Commands

```bash
# Local Development
supabase start                     # Start all services
supabase stop                      # Stop all services
supabase status                    # View service status
supabase db reset                  # Reset database with migrations

# Migrations
supabase migration new <name>      # Create new migration
supabase migration list            # List all migrations
supabase db diff                   # Generate migration from changes
supabase db push                   # Deploy migrations to remote

# Edge Functions
supabase functions new <name>      # Create new function
supabase functions serve           # Serve functions locally
supabase functions deploy <name>   # Deploy specific function
supabase functions logs <name>     # View function logs

# Types
supabase gen types typescript --local > types/database.ts

# Links and Projects
supabase link --project-ref <ref>  # Link to remote project
supabase projects list             # List all projects
```

### NPM Scripts

```bash
# Database
npm run db:start          # Start Supabase
npm run db:stop           # Stop Supabase
npm run db:reset          # Reset with migrations + seed
npm run db:status         # Check status
npm run db:diff           # Show schema changes

# Migrations
npm run migration:new <name>  # Create new migration

# Functions
npm run functions:serve       # Start function server
npm run functions:new <name>  # Create new function
npm run functions:deploy      # Deploy all functions
npm run lint:functions        # Lint functions
npm run format:functions      # Format functions
npm run test:functions        # Run function tests

# Types
npm run types:generate    # Generate TypeScript types
npm run types:watch       # Watch and regenerate
```

### Helper Scripts

```bash
./scripts/setup.sh    # Initial environment setup
./scripts/dev.sh      # Quick start development
./scripts/reset.sh    # Reset database (interactive)
```

### Access URLs (Local)

- **Studio UI**: http://localhost:8000
- **API**: http://localhost:8000
- **Database**: `postgresql://postgres:postgres@localhost:54322/postgres`
- **Functions**: `http://localhost:54321/functions/v1/<function-name>`
- **Email Testing**: http://localhost:9000

### GitHub Actions Quick Commands

```bash
# Trigger workflows manually
gh workflow run deploy.yml
gh workflow run backup.yml

# View workflow runs
gh run list --workflow=deploy.yml --limit 5

# View logs
gh run view <run-id> --log

# Manage secrets
gh secret set SECRET_NAME
gh secret list
gh secret delete SECRET_NAME
```

### Common Troubleshooting

```bash
# Docker issues
docker info                        # Check Docker status
docker ps | grep supabase         # List Supabase containers
docker logs <container-id>         # View container logs

# Port conflicts
lsof -i :8000                     # Check port 8000
kill -9 $(lsof -ti:8000)          # Kill process on port

# Reset everything
supabase stop
docker system prune -a            # Clean Docker (careful!)
supabase start

# Database connection
supabase db push --dry-run        # Preview changes
supabase db reset --debug         # Reset with debug info

# Function deployment
supabase functions deploy <name> --no-verify-jwt
```

---

## Additional Resources

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture overview
- **[README.md](README.md)** - Quick start and workflows
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Database Migrations](https://supabase.com/docs/guides/database/migrations)
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## Support

- **Issues**: Open a GitHub issue
- **Supabase Support**: https://supabase.com/support
- **Community**: https://github.com/supabase/supabase/discussions

---

**Last Updated**: 2025-01-15
**Maintained By**: DevOps Team
