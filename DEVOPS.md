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

## Realtime Configuration

### Overview

Supabase Realtime enables WebSocket connections for live database updates, presence tracking, and broadcast messaging.

### Enabling Realtime on Tables

Realtime is enabled via the `supabase_realtime` publication:

```sql
-- Enable realtime for a table
ALTER PUBLICATION supabase_realtime ADD TABLE your_table;

-- Set replica identity to FULL (required for UPDATE/DELETE events)
ALTER TABLE your_table REPLICA IDENTITY FULL;

-- Verify realtime is enabled
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

### Currently Enabled Tables

- ✅ `public.profiles`
- ✅ `public.posts`

### Configuration

Realtime settings in `supabase/config.toml`:

```toml
[realtime]
enabled = true
max_connections = 100              # Max concurrent connections per client
max_channels_per_client = 100      # Max channels per connection
max_joins_per_second = 500         # Max joins per second per client
max_messages_per_second = 1000     # Max messages per second per client
max_events_per_second = 100        # Max events per second per channel
```

### Security Considerations

1. **RLS Policies Required**: Users must have SELECT permission to receive realtime updates
2. **Filter Server-Side**: Use filters to reduce data exposure
3. **Rate Limiting**: Configure appropriate limits based on your use case
4. **Connection Management**: Always clean up subscriptions when done

### Testing Realtime

```bash
# Run the realtime test suite
node examples/realtime/test-realtime.js

# Test with individual examples
node examples/realtime/basic-subscription.js
node examples/realtime/table-changes.js
node examples/realtime/filtered-subscription.js
node examples/realtime/presence.js
node examples/realtime/broadcast.js

# Browser testing
open examples/realtime/rate-limiting.html
```

### Monitoring

```bash
# Check realtime connections
supabase logs realtime

# Monitor in Supabase Dashboard
# Dashboard → Database → Realtime
```

### Troubleshooting

**Problem**: Not receiving realtime updates

**Solutions**:
1. Check table is in publication:
   ```sql
   SELECT * FROM pg_publication_tables 
   WHERE pubname = 'supabase_realtime' AND tablename = 'your_table';
   ```

2. Verify RLS policies allow SELECT:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'your_table';
   ```

3. Check replica identity:
   ```sql
   SELECT relname, relreplident 
   FROM pg_class 
   WHERE relname = 'your_table';
   -- 'f' = FULL, 'd' = DEFAULT
   ```

4. Verify API keys are correct in client

**Problem**: Too many connections

**Solutions**:
- Reduce number of active subscriptions
- Share channels between components
- Implement connection pooling
- Adjust `max_connections` in config.toml

**Problem**: Performance issues

**Solutions**:
- Use filters to reduce payload size
- Implement client-side debouncing
- Consider using broadcast for high-frequency updates
- Check `max_events_per_second` setting

### Production Recommendations

1. **Set appropriate rate limits** based on expected load
2. **Monitor connection count** and adjust limits as needed
3. **Implement reconnection logic** with exponential backoff
4. **Use filters** to minimize data transfer
5. **Test under load** before going to production
6. **Document realtime patterns** for your team

### Migration Checklist

When enabling realtime on a new table:

- [ ] Add table to `supabase_realtime` publication
- [ ] Set replica identity to FULL
- [ ] Update RLS policies to allow SELECT
- [ ] Test with example code
- [ ] Document expected events for the table
- [ ] Update client code to handle new events
- [ ] Test rate limits under expected load

---

## Additional Resources

- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Database Migrations](https://supabase.com/docs/guides/database/migrations)
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Realtime Documentation](https://supabase.com/docs/guides/realtime)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## Support

- **Issues**: Open a GitHub issue
- **Supabase Support**: https://supabase.com/support
- **Community**: https://github.com/supabase/supabase/discussions

---

**Last Updated**: 2025-10-05
**Maintained By**: DevOps Team
