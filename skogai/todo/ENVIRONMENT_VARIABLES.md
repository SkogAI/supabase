# Environment Variables Reference

Complete reference for all environment variables used in the Supabase project, including sources, usage, and whether they're required or optional.

## Table of Contents

- [File Locations](#file-locations)
- [API & Authentication](#api--authentication)
- [Database Connections](#database-connections)
- [OAuth Providers](#oauth-providers)
- [SAML SSO](#saml-sso)
- [AI & MCP Integration](#ai--mcp-integration)
- [Storage (S3)](#storage-s3)
- [Email Services](#email-services)
- [Infrastructure & Docker](#infrastructure--docker)
- [SSL/TLS Certificates](#ssltls-certificates)
- [Monitoring & Logging](#monitoring--logging)
- [Quick Setup Guide](#quick-setup-guide)

---

## File Locations

### Environment Files

| File | Purpose | Committed to Git |
|------|---------|------------------|
| `.env` | Local development secrets (root) | ❌ No (gitignored) |
| `.env.example` | Template with all variables documented | ✅ Yes |
| `supabase/.env` | Supabase-specific local secrets | ❌ No (gitignored) |
| `supabase/config.toml` | Main Supabase configuration | ✅ Yes |
| `supabase/config2.toml` | Alternative/SkogAI configuration | ✅ Yes |

### Setup Instructions

1. Copy template to create your local environment:
   ```bash
   cp .env.example .env
   ```

2. Fill in required variables (marked with ⚠️ **REQUIRED** below)

3. Optional variables can be left empty or commented out

---

## API & Authentication

### Core Supabase Variables

#### `SUPABASE_URL`
- **Status**: ⚠️ **REQUIRED** (for edge functions)
- **Source**: `.env`, `supabase/.env`
- **Usage**:
  - `supabase/functions/hello-world/index.ts`
  - `supabase/functions/openai-chat/index.ts`
  - `supabase/functions/openrouter-chat/index.ts`
  - `supabase/functions/health-check/index.ts`
  - `supabase/functions/_shared/connection-health.ts`
- **Format**: `http://localhost:54321` (local) or `https://your-project.supabase.co` (production)
- **Description**: Base URL for Supabase API endpoint

#### `SUPABASE_ANON_KEY`
- **Status**: ⚠️ **REQUIRED** (for client-side code)
- **Source**: `supabase/.env`
- **Usage**:
  - All edge functions that create Supabase client
  - Frontend examples in `examples/saml-auth/frontend/`
- **Format**: JWT token (starts with `eyJ`)
- **Description**: Public/anonymous key for client-side database access with RLS enabled
- **Default**: Auto-generated in `supabase/.env` when running `supabase start`

#### `SUPABASE_SERVICE_ROLE_KEY`
- **Status**: ⚠️ **REQUIRED** (for admin operations)
- **Source**: `.env`, `supabase/.env`
- **Usage**:
  - `supabase/functions/hello-world/index.ts` (database operations)
  - `supabase/functions/health-check/index.ts`
  - `supabase/functions/_shared/connection-health.ts`
- **Format**: JWT token (starts with `eyJ`)
- **Description**: Admin key that bypasses RLS - **KEEP SECRET**
- **Security**: Never expose to client-side code

### AI API Keys

#### `OPENAI_API_KEY`
- **Status**: 🔵 **OPTIONAL** (required for OpenAI features)
- **Source**: `.env`, `supabase/.env`, `supabase/config.toml`
- **Usage**:
  - `supabase/functions/openai-chat/index.ts`
  - Supabase Studio AI features
- **Format**: `sk-proj-...` (OpenAI secret key format)
- **Description**: API key for OpenAI GPT models
- **Configuration**: Referenced in `config.toml` as `env(OPENAI_API_KEY)` for Studio integration

#### `OPENROUTER_API_KEY`
- **Status**: 🔵 **OPTIONAL** (required for OpenRouter features)
- **Source**: `.env.example`
- **Usage**: `supabase/functions/openrouter-chat/index.ts`
- **Format**: `sk-or-...` (OpenRouter key format)
- **Description**: API key for OpenRouter multi-model access

---

## Database Connections

### Local Development

#### `DATABASE_URL`
- **Status**: ⚠️ **REQUIRED** (for local development)
- **Source**: `supabase/.env`
- **Usage**: Direct PostgreSQL connections, migration scripts
- **Format**: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
- **Description**: Local PostgreSQL connection string
- **Default**: Auto-configured when running `supabase start`

### Production Connection Pooling

#### `SUPABASE_DIRECT_CONNECTION`
- **Status**: 🔵 **OPTIONAL** (production only)
- **Source**: `.env.example`
- **Usage**:
  - `examples/mcp-direct-connection/health-check.ts`
  - `examples/mcp-direct-connection/retry-logic.ts`
- **Format**: `postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres`
- **Description**: Direct IPv6 connection for persistent AI agents
- **Use Case**: Long-running processes, full PostgreSQL feature support

#### `SUPABASE_SESSION_POOLER`
- **Status**: 🔵 **OPTIONAL** (production only)
- **Source**: `.env.example`
- **Usage**: Connection pooling for persistent applications
- **Format**: `postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres`
- **Port**: 5432 (session mode)
- **Description**: IPv4-compatible session mode pooler
- **Use Case**: Persistent agents without IPv6 support

#### `SUPABASE_TRANSACTION_POOLER`
- **Status**: 🔵 **OPTIONAL** (production only)
- **Source**: `.env.example`
- **Usage**: Serverless/edge function database connections
- **Format**: `postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres`
- **Port**: 6543 (transaction mode)
- **Description**: Transaction mode pooler with auto-cleanup
- **Use Case**: Serverless functions, edge compute, short-lived connections

### Connection Pool Configuration

#### `DB_CONNECTION_TYPE`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `transaction` (for serverless)
- **Options**: `direct`, `session`, `transaction`
- **Usage**: Determines which connection string to use
- **Description**: Selector for connection pooling strategy

#### `DB_POOL_MIN`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `2`
- **Usage**: Connection pool configuration
- **Description**: Minimum number of database connections to maintain

#### `DB_POOL_MAX`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `10`
- **Usage**: Connection pool configuration
- **Description**: Maximum number of database connections allowed

#### `DB_POOL_IDLE_TIMEOUT`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `30000` (30 seconds)
- **Format**: Milliseconds
- **Usage**: Connection pool configuration
- **Description**: Time before idle connections are closed

#### `DB_POOL_CONNECTION_TIMEOUT`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `10000` (10 seconds)
- **Format**: Milliseconds
- **Usage**: Connection pool configuration
- **Description**: Maximum time to wait for connection from pool

### Database Credentials (Docker/Local)

#### `POSTGRES_PASSWORD`
- **Status**: ⚠️ **REQUIRED** (local development)
- **Source**: `supabase/.env`
- **Default**: `postgres`
- **Usage**: Local PostgreSQL container
- **Description**: PostgreSQL superuser password
- **Security**: Only for local development

---

## OAuth Providers

### GitHub OAuth

#### `GITHUB_CLIENT_ID`
- **Status**: 🔵 **OPTIONAL** (required for GitHub auth)
- **Source**: `supabase/.env`, `supabase/config.toml`, `supabase/config2.toml`
- **Usage**: GitHub OAuth authentication flow
- **Configuration**: Referenced as `env(GITHUB_CLIENT_ID)` in TOML files
- **Description**: GitHub OAuth application client ID
- **Setup**: Create at https://github.com/settings/developers

#### `GITHUB_CLIENT_SECRET`
- **Status**: 🔵 **OPTIONAL** (required for GitHub auth)
- **Source**: `supabase/.env`, `supabase/config.toml`, `supabase/config2.toml`
- **Usage**: GitHub OAuth authentication flow
- **Configuration**: Referenced as `env(GITHUB_CLIENT_SECRET)` in TOML files
- **Description**: GitHub OAuth application secret
- **Security**: Keep this secret and never commit to repository

### Apple OAuth

#### `SUPABASE_AUTH_EXTERNAL_APPLE_SECRET`
- **Status**: 🔵 **OPTIONAL** (required for Apple Sign In)
- **Source**: `.env.example`
- **Usage**: Apple OAuth authentication
- **Description**: Apple OAuth secret key

---

## SAML SSO

### Core SAML Configuration

#### `GOTRUE_SAML_ENABLED`
- **Status**: 🔵 **OPTIONAL** (required for SAML)
- **Source**: `.env.example`, `supabase/.env`
- **Default**: `false`
- **Values**: `true` | `false`
- **Usage**: GoTrue authentication service
- **Description**: Enable/disable SAML SSO functionality

#### `GOTRUE_SAML_PRIVATE_KEY`
- **Status**: 🔵 **OPTIONAL** (required if SAML enabled)
- **Source**: `supabase/.env`
- **Format**: Base64-encoded private key
- **Usage**: SAML assertion signing
- **Description**: Base64-encoded RSA private key for SAML signing
- **Generation**: Use `scripts/saml-setup.sh` or manual OpenSSL commands
- **Security**: **CRITICAL** - Keep this secret, never commit

### SAML Authentication Settings

#### `GOTRUE_SITE_URL`
- **Status**: 🔵 **OPTIONAL** (recommended for production)
- **Source**: `.env.example`
- **Default**: `http://localhost:3000`
- **Usage**: Authentication redirects, email templates
- **Description**: Base URL for your application

#### `GOTRUE_URI_ALLOW_LIST`
- **Status**: 🔵 **OPTIONAL** (recommended for production)
- **Source**: `.env.example`
- **Default**: `*`
- **Format**: Comma-separated URLs
- **Example**: `http://localhost:3000,https://app.example.com`
- **Usage**: OAuth redirect validation
- **Description**: Allowed redirect URIs after authentication

#### `GOTRUE_JWT_EXP`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `3600` (1 hour)
- **Format**: Seconds
- **Usage**: JWT token expiration
- **Description**: How long authentication tokens remain valid

#### `GOTRUE_COOKIE_KEY`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Format**: 32-character random string
- **Usage**: Session cookie encryption
- **Description**: Secret key for encrypting session cookies
- **Generation**: Use `openssl rand -hex 16`

#### `GOTRUE_COOKIE_DOMAIN`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Example**: `.example.com`
- **Usage**: Session cookie scope
- **Description**: Domain for session cookies (enables subdomain sharing)

#### `GOTRUE_LOG_LEVEL`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `info`
- **Values**: `debug`, `info`, `warn`, `error`
- **Usage**: GoTrue authentication service logging
- **Description**: Log verbosity level for debugging SAML issues

---

## AI & MCP Integration

### MCP Server Configuration

#### `MCP_SERVER_NAME`
- **Status**: 🔵 **OPTIONAL** (required for MCP)
- **Source**: `.env.example`
- **Default**: `supabase-mcp`
- **Usage**: MCP server identification
- **Description**: Name identifier for Model Context Protocol server

#### `MCP_SERVER_PORT`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `3000`
- **Usage**: MCP server HTTP port
- **Description**: Port for MCP server to listen on

#### `MCP_CONNECTION_TYPE`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `transaction`
- **Values**: `direct`, `session`, `transaction`
- **Usage**: MCP database connection strategy
- **Description**: Which connection pooling mode to use for AI agents

#### `MCP_AUDIT_LOGGING_ENABLED`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `false`
- **Values**: `true` | `false`
- **Usage**: MCP query auditing
- **Description**: Log all database queries executed by AI agents

### AI Agent Connection Strings

#### `SUPABASE_AI_AGENT_READONLY_CONNECTION`
- **Status**: 🔵 **OPTIONAL** (required for read-only AI agents)
- **Source**: `.env.example`
- **Format**: PostgreSQL connection string
- **Usage**: AI agents that only read data
- **Description**: Read-only database connection for AI agents
- **Security**: Uses restricted database role

#### `SUPABASE_AI_AGENT_READWRITE_CONNECTION`
- **Status**: 🔵 **OPTIONAL** (required for read-write AI agents)
- **Source**: `.env.example`
- **Format**: PostgreSQL connection string
- **Usage**: AI agents that modify data
- **Description**: Read-write database connection for AI agents
- **Security**: Uses elevated database role

#### `SUPABASE_AI_AGENT_ANALYTICS_CONNECTION`
- **Status**: 🔵 **OPTIONAL** (required for analytics AI agents)
- **Source**: `.env.example`
- **Format**: PostgreSQL connection string
- **Usage**: AI agents performing analytics queries
- **Description**: Analytics-optimized database connection
- **Use Case**: Complex queries, aggregations, reports

#### `SUPABASE_AI_AGENT_API_KEY`
- **Status**: 🔵 **OPTIONAL** (required for MCP with API auth)
- **Source**: `.env.example`
- **Format**: UUID or random string
- **Usage**: MCP server authentication
- **Description**: API key for authenticating AI agent requests
- **Generation**: Use `uuidgen` or `openssl rand -hex 32`

### MCP Monitoring

#### `ENABLE_MCP_MONITORING`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `false`
- **Values**: `true` | `false`
- **Usage**: MCP performance monitoring
- **Description**: Enable metrics collection for AI agent queries

#### `SUPABASE_CONNECTION_MONITORING_ENABLED`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `false`
- **Values**: `true` | `false`
- **Usage**: Database connection monitoring
- **Description**: Track connection pool health and performance

#### `SUPABASE_CONNECTION_AUDIT_QUERIES`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `false`
- **Values**: `true` | `false`
- **Usage**: Query auditing
- **Description**: Log all SQL queries for security auditing

---

## Storage (S3)

### S3-Compatible Storage Configuration

#### `S3_HOST`
- **Status**: 🔵 **OPTIONAL** (required for custom storage)
- **Source**: `.env.example`, `supabase/.env`, `supabase/config.toml`
- **Example**: `s3.amazonaws.com` or `storage.example.com`
- **Configuration**: Referenced as `env(S3_HOST)` in TOML
- **Usage**: Storage bucket backend
- **Description**: S3-compatible storage host

#### `S3_REGION`
- **Status**: 🔵 **OPTIONAL** (required for custom storage)
- **Source**: `.env.example`, `supabase/.env`, `supabase/config.toml`
- **Example**: `us-east-1`, `eu-west-1`
- **Configuration**: Referenced as `env(S3_REGION)` in TOML
- **Usage**: Storage bucket region
- **Description**: AWS region or S3-compatible region

#### `S3_ACCESS_KEY`
- **Status**: 🔵 **OPTIONAL** (required for custom storage)
- **Source**: `.env.example`, `supabase/.env`, `supabase/config.toml`
- **Format**: AWS access key ID (20 characters)
- **Configuration**: Referenced as `env(S3_ACCESS_KEY)` in TOML
- **Usage**: S3 authentication
- **Description**: S3 access key ID
- **Security**: Keep secret

#### `S3_SECRET_KEY`
- **Status**: 🔵 **OPTIONAL** (required for custom storage)
- **Source**: `.env.example`, `supabase/.env`, `supabase/config.toml`
- **Format**: AWS secret access key (40 characters)
- **Configuration**: Referenced as `env(S3_SECRET_KEY)` in TOML
- **Usage**: S3 authentication
- **Description**: S3 secret access key
- **Security**: **CRITICAL** - Keep secret, never commit

#### `S3_ENDPOINT_URL`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `supabase/.env`
- **Example**: `https://s3.amazonaws.com`
- **Usage**: S3-compatible endpoint
- **Description**: Custom S3 endpoint URL (for non-AWS S3-compatible services)

#### `S3_ENDPOINT_REGION`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `supabase/.env`
- **Usage**: S3-compatible endpoint region
- **Description**: Region for custom S3 endpoint

---

## Email Services

### Twilio SMS

#### `SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN`
- **Status**: 🔵 **OPTIONAL** (required for SMS auth)
- **Source**: `.env.example`, `supabase/config.toml`
- **Configuration**: Referenced as `env(SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN)` in TOML
- **Usage**: SMS authentication (phone number verification)
- **Description**: Twilio authentication token
- **Setup**: Get from https://www.twilio.com/console

### SendGrid Email

#### `SENDGRID_API_KEY`
- **Status**: 🔵 **OPTIONAL** (required for production email)
- **Source**: `.env.example`, `supabase/.env`, `supabase/config.toml`
- **Configuration**: Referenced as `env(SENDGRID_API_KEY)` in TOML under `[auth.email.smtp]` section
- **Usage**: Transactional emails (password reset, confirmation, etc.)
- **Description**: SendGrid API key for email delivery
- **Setup**: Get from https://app.sendgrid.com/settings/api_keys
- **Note**: Local development uses Inbucket (no SendGrid needed)

---

## Infrastructure & Docker

### JWT Configuration

#### `JWT_SECRET`
- **Status**: ⚠️ **REQUIRED**
- **Source**: `.env.example`, `supabase/.env`
- **Format**: 32+ character random string
- **Default**: `your-super-secret-jwt-token-with-at-least-32-characters-long` (local)
- **Usage**: JWT token signing and verification
- **Description**: Secret key for signing JWT tokens
- **Generation**: Use `openssl rand -base64 32`
- **Security**: **CRITICAL** - Use different values for dev/prod

#### `ANON_KEY`
- **Status**: ⚠️ **REQUIRED** (auto-generated)
- **Source**: `supabase/.env`
- **Format**: JWT token
- **Default**: Auto-generated when running `supabase start`
- **Usage**: Public client authentication
- **Description**: Pre-generated anonymous key (derived from JWT_SECRET)

#### `SERVICE_ROLE_KEY`
- **Status**: ⚠️ **REQUIRED** (auto-generated)
- **Source**: `supabase/.env`
- **Format**: JWT token
- **Default**: Auto-generated when running `supabase start`
- **Usage**: Admin operations bypassing RLS
- **Description**: Pre-generated service role key (derived from JWT_SECRET)
- **Security**: **CRITICAL** - Never expose to client-side

### Supabase Studio

#### `DASHBOARD_USERNAME`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `supabase/.env`
- **Default**: `supabase`
- **Usage**: Supabase Studio login
- **Description**: Username for local Studio dashboard
- **Access**: http://localhost:8000 (or configured port)

#### `DASHBOARD_PASSWORD`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `supabase/.env`
- **Default**: `this_password_is_insecure_and_should_be_updated`
- **Usage**: Supabase Studio login
- **Description**: Password for local Studio dashboard
- **Recommendation**: Change for shared development environments

### Docker Configuration

#### `DOCKER_SOCKET_LOCATION`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `supabase/.env`
- **Default**: `/var/run/docker.sock`
- **Usage**: Docker communication
- **Description**: Path to Docker socket
- **Note**: May differ on macOS/Windows Docker Desktop

---

## SSL/TLS Certificates

### Certificate Paths

#### `SSL_CERT_PATH`
- **Status**: 🔵 **OPTIONAL** (required for production with custom SSL)
- **Source**: `.env.example`
- **Example**: `/etc/ssl/certs/production.crt`
- **Usage**: Production database SSL verification
- **Description**: Path to production SSL certificate

#### `STAGING_SSL_CERT_PATH`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Example**: `/etc/ssl/certs/staging.crt`
- **Usage**: Staging environment SSL verification
- **Description**: Path to staging SSL certificate

### SSL Connection Modes

#### `DB_SSL_MODE`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `prefer` (local), `verify-full` (production)
- **Values**: `disable`, `require`, `verify-ca`, `verify-full`
- **Usage**: PostgreSQL connection security
- **Description**: SSL verification level
- **Recommendations**:
  - Local: `disable` or `prefer`
  - Production: `verify-full`

#### `DB_SSL_REJECT_UNAUTHORIZED`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `true` (production), `false` (local)
- **Values**: `true` | `false`
- **Usage**: Node.js database clients
- **Description**: Reject self-signed certificates

#### `PGSSLMODE`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `prefer`
- **Values**: `disable`, `allow`, `prefer`, `require`, `verify-ca`, `verify-full`
- **Usage**: PostgreSQL client library SSL mode
- **Description**: Standard PostgreSQL SSL mode environment variable

#### `PGSSLROOTCERT`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Example**: `/etc/ssl/certs/ca-certificates.crt`
- **Usage**: PostgreSQL SSL certificate verification
- **Description**: Path to root CA certificate bundle

---

## Monitoring & Logging

### Log Levels

#### `LOG_LEVEL`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `info`
- **Values**: `debug`, `info`, `warn`, `error`
- **Usage**: Application-wide logging
- **Description**: Global log verbosity level

#### `SUPABASE_CONNECTION_LOG_LEVEL`
- **Status**: 🔵 **OPTIONAL**
- **Source**: `.env.example`
- **Default**: `info`
- **Values**: `debug`, `info`, `warn`, `error`
- **Usage**: Database connection logging
- **Description**: Log level specifically for database connection events

### Testing Variables

#### `RUN_INTEGRATION_TESTS`
- **Status**: 🔵 **OPTIONAL** (for testing)
- **Source**: Test environment
- **Default**: `false`
- **Values**: `true` | `false`
- **Usage**: Multiple test files in `supabase/functions/*/test.ts`
- **Description**: Enable integration tests that require external services

#### `FUNCTION_URL`
- **Status**: 🔵 **OPTIONAL** (for testing)
- **Source**: Test environment
- **Format**: URL to deployed function
- **Usage**: Edge function integration tests
- **Description**: URL for testing deployed functions

---

## Quick Setup Guide

### Minimal Local Development Setup

1. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Start Supabase (auto-generates keys):**
   ```bash
   npm run db:start
   ```

3. **Required variables are auto-set in `supabase/.env`:**
   - ✅ `SUPABASE_URL`
   - ✅ `SUPABASE_ANON_KEY`
   - ✅ `SUPABASE_SERVICE_ROLE_KEY`
   - ✅ `DATABASE_URL`
   - ✅ `JWT_SECRET`

4. **You're ready to develop!** 🎉

### Adding OpenAI Features

1. **Get API key from:** https://platform.openai.com/api-keys

2. **Add to `.env` (root):**
   ```bash
   OPENAI_API_KEY=sk-proj-your-actual-key-here
   ```

3. **Add to `supabase/.env`:**
   ```bash
   OPENAI_API_KEY=sk-proj-your-actual-key-here
   ```

4. **Restart Supabase:**
   ```bash
   npm run db:stop
   npm run db:start
   ```

### Adding GitHub OAuth

1. **Create OAuth app:** https://github.com/settings/developers

2. **Add to `supabase/.env`:**
   ```bash
   GITHUB_CLIENT_ID=your_client_id
   GITHUB_CLIENT_SECRET=your_client_secret
   ```

3. **Configuration is auto-loaded** from TOML files using `env()` syntax

### Adding SAML SSO

1. **Run automated setup script:**
   ```bash
   ./scripts/saml-setup.sh -d yourcompany.com -m https://idp.example.com/saml/metadata
   ```

2. **Or manually configure in `supabase/.env`:**
   ```bash
   GOTRUE_SAML_ENABLED=true
   GOTRUE_SAML_PRIVATE_KEY=base64-encoded-private-key
   ```

3. **See full guide:** `docs/AUTH_ZITADEL_SAML_SELF_HOSTED.md`

---

## Configuration File References

### Environment Variable Loading in TOML

The `config.toml` files use `env()` syntax to reference environment variables:

```toml
[ai.openai_api_key]
openai_api_key = "env(OPENAI_API_KEY)"

[auth.external.github]
client_id = "env(GITHUB_CLIENT_ID)"
secret = "env(GITHUB_CLIENT_SECRET)"

[storage.s3]
s3_host = "env(S3_HOST)"
s3_region = "env(S3_REGION)"
s3_access_key = "env(S3_ACCESS_KEY)"
s3_secret_key = "env(S3_SECRET_KEY)"
```

### Edge Function Environment Access

Edge functions use Deno's environment access:

```typescript
const apiKey = Deno.env.get("OPENAI_API_KEY")
const supabaseUrl = Deno.env.get("SUPABASE_URL")
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")
```

### Example Connection Strings

**Local Development:**
```bash
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
SUPABASE_URL=http://localhost:54321
```

**Production (Supabase Cloud):**
```bash
# Direct connection (IPv6)
SUPABASE_DIRECT_CONNECTION=postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:5432/postgres

# Session pooler (IPv4)
SUPABASE_SESSION_POOLER=postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:5432/postgres

# Transaction pooler (serverless)
SUPABASE_TRANSACTION_POOLER=postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres

# API URL
SUPABASE_URL=https://[project-ref].supabase.co
```

---

## Security Best Practices

### ⚠️ Never Commit These Files

- `.env` (root)
- `supabase/.env`
- `*.key` (private keys)
- `*.pem` (certificates)
- `signing_keys.json`

### ✅ Safe to Commit

- `.env.example` (templates only)
- `config.toml` (uses `env()` references)
- `config2.toml` (uses `env()` references)

### 🔐 Production Checklist

- [ ] Change default `JWT_SECRET`
- [ ] Use `verify-full` SSL mode
- [ ] Never use `SUPABASE_SERVICE_ROLE_KEY` in client-side code
- [ ] Rotate `GITHUB_CLIENT_SECRET` and other OAuth secrets periodically
- [ ] Use different API keys for dev/staging/production
- [ ] Enable `MCP_AUDIT_LOGGING_ENABLED` for AI agent transparency
- [ ] Set strong `DASHBOARD_PASSWORD` if exposing Studio

---

## Troubleshooting

### "Missing environment variable" errors

**Solution:** Check that variable is set in correct file:
- Edge functions → `supabase/.env`
- Local scripts → `.env` (root)
- TOML configs → Uses `env()` to reference above

### Keys not working after `supabase start`

**Solution:** Regenerate keys:
```bash
npm run db:reset
```

### SAML not working

**Solution:** Check all SAML variables are set:
```bash
grep -E "GOTRUE_SAML|SAML_PRIVATE_KEY" supabase/.env
```

### Database connection refused

**Solution:** Verify Docker is running and Supabase started:
```bash
docker ps
npm run db:status
```

---

## Related Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture overview
- **[AUTH_ZITADEL_SAML_SELF_HOSTED.md](AUTH_ZITADEL_SAML_SELF_HOSTED.md)** - Complete SAML setup guide
- **[MCP_*.md](.)** - AI agent integration guides
- **[DEVOPS.md](DEVOPS.md)** - CI/CD and deployment configuration
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions

---

**Last Updated:** 2025-10-16
**Maintained by:** Supabase Project Team
