# Supabase Project

Production-ready Supabase backend with database migrations, Row Level Security, edge functions, and complete CI/CD pipeline.

## 🚀 Quick Start

### Automated Setup (Recommended)

```bash
# Run the setup script
./scripts/setup.sh
```

This will:
- Check all prerequisites
- Create `.env` file
- Install dependencies
- Start Supabase services
- Generate TypeScript types
- Show access information

### Manual Setup

1. **Prerequisites**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop) (must be running)
   - [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started)
   - [Node.js 18+](https://nodejs.org/) (optional, for TypeScript types)
   - [Deno 2.x](https://deno.land/) (optional, for edge functions)

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Setup environment**
   ```bash
   cp .env.example .env
   # Edit .env and add your API keys (optional for local dev)
   ```

4. **Start Supabase**
   ```bash
   npm run db:start
   # OR
   ./scripts/dev.sh
   ```

5. **Access local services**
   - 🎨 **Studio UI**: http://localhost:8000
   - 🔌 **API**: http://localhost:8000
   - 🗄️ **Database**: `postgresql://postgres:postgres@localhost:54322/postgres`

## 📁 Project Structure

```
.
├── supabase/
│   ├── config.toml              # Supabase configuration
│   ├── migrations/              # Database migrations (timestamped SQL)
│   │   └── 20251005065505_initial_schema.sql
│   ├── functions/               # Edge functions (Deno/TypeScript)
│   │   ├── README.md
│   │   └── hello-world/
│   │       ├── index.ts         # Function code
│   │       └── test.ts          # Function tests
│   └── seed.sql                 # Development seed data
├── types/
│   └── database.ts              # Auto-generated TypeScript types
├── scripts/
│   ├── setup.sh                 # Automated setup script
│   ├── dev.sh                   # Quick dev start
│   └── reset.sh                 # Database reset
├── .github/workflows/           # CI/CD pipelines
│   ├── deploy.yml               # Auto deployment
│   ├── pr-checks.yml            # PR validation
│   ├── migrations-validation.yml
│   ├── edge-functions-test.yml
│   ├── schema-lint.yml
│   ├── security-scan.yml
│   ├── type-generation.yml
│   ├── performance-test.yml
│   ├── backup.yml
│   └── dependency-updates.yml
├── DEVOPS.md                    # Complete DevOps guide
├── package.json                 # npm scripts
└── .env.example                 # Environment template
```

## 💻 Development Workflow

### Database Migrations

```bash
# Create a new migration
npm run migration:new <migration_name>
# OR
supabase migration new <migration_name>

# Apply all migrations (resets database)
npm run db:reset
# OR
./scripts/reset.sh

# Check migration status
npm run db:status

# Generate SQL diff of current changes
npm run db:diff
```

### Edge Functions

```bash
# Create a new function
npm run functions:new <function_name>

# Serve functions locally (with hot reload)
npm run functions:serve

# Test a function
cd supabase/functions/<function-name>
deno test --allow-all test.ts

# Lint functions
npm run lint:functions

# Format functions
npm run format:functions

# Deploy specific function
supabase functions deploy <function_name>

# Deploy all functions
npm run functions:deploy
```

### TypeScript Types

```bash
# Generate types from database schema
npm run types:generate

# Watch for changes and auto-regenerate
npm run types:watch
```

## 🚢 Deployment

### Automatic Deployment (Recommended)

Every push to `master`/`main` automatically:
1. ✅ Validates migrations
2. ✅ Runs tests
3. ✅ Deploys to production
4. ✅ Generates deployment summary

**See [DEVOPS.md](DEVOPS.md) for complete deployment guide.**

### Manual Deployment

```bash
# 1. Link to your Supabase project
supabase link --project-ref <your-project-ref>

# 2. Push database migrations
supabase db push

# 3. Deploy edge functions
supabase functions deploy

# Or use GitHub CLI to trigger deployment
gh workflow run deploy.yml -f environment=production
```

### Required GitHub Secrets

Configure in **Settings → Secrets and variables → Actions**:

| Secret | How to Get |
|--------|------------|
| `SUPABASE_ACCESS_TOKEN` | Supabase Dashboard → Account → Access Tokens |
| `SUPABASE_PROJECT_ID` | Supabase Dashboard → Settings → General → Reference ID |
| `SUPABASE_DB_PASSWORD` | Supabase Dashboard → Settings → Database |
| `CLAUDE_CODE_OAUTH_TOKEN` | (Optional) For AI-powered PR analysis |

```bash
# Set secrets via GitHub CLI
gh secret set SUPABASE_ACCESS_TOKEN
gh secret set SUPABASE_PROJECT_ID
gh secret set SUPABASE_DB_PASSWORD
```

## 🔄 CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **deploy.yml** | Push to main | Deploy migrations & functions |
| **pr-checks.yml** | Pull requests | Validate PRs, check for secrets |
| **migrations-validation.yml** | Migration changes | Test migrations in isolation |
| **edge-functions-test.yml** | Function changes | Lint, type-check, test functions |
| **schema-lint.yml** | Database changes | Check for anti-patterns |
| **security-scan.yml** | All pushes | Scan for vulnerabilities |
| **type-generation.yml** | Schema changes | Generate TypeScript types |
| **performance-test.yml** | Weekly | Run performance benchmarks |
| **backup.yml** | Daily | Create database backups |
| **dependency-updates.yml** | Weekly | Check for updates |

## 🔐 Security Best Practices

✅ **DO**:
- Use environment variables for secrets
- Enable RLS on all tables
- Review dependency updates
- Keep `.env` in `.gitignore`
- Use strong database passwords
- Rotate secrets periodically

❌ **DON'T**:
- Commit `.env` files
- Hardcode API keys
- Disable security scans
- Skip migration testing
- Deploy without reviewing changes

## 📊 Database Schema

Current schema includes:

- **`profiles`** - User profiles with comprehensive RLS policies
- **`posts`** - User-generated content with role-based access
- **Automatic triggers** - `updated_at` timestamp management
- **Auto profile creation** - On user signup via Auth
- **Custom types** - Enums and composite types for better data modeling

See `supabase/migrations/` for full schema and **[SCHEMA_ORGANIZATION.md](SCHEMA_ORGANIZATION.md)** for detailed documentation on schema organization and custom types.

### Row Level Security (RLS)

All tables have comprehensive RLS policies:

- ✅ **Service Role**: Full admin access for backend operations
- ✅ **Authenticated Users**: Can view all public data, manage own resources
- ✅ **Anonymous Users**: Read-only access to published content
- ✅ **Security**: Users cannot access or modify other users' private data

See **[docs/RLS_POLICIES.md](docs/RLS_POLICIES.md)** for complete policy documentation and patterns.

### Example: Using RLS Policies

```sql
-- In migrations: Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own drafts
CREATE POLICY "Users see own drafts"
  ON posts FOR SELECT
  TO authenticated
  USING (published = true OR auth.uid() = user_id);
```

## 🤖 AI Agent Integration (MCP)

This project includes comprehensive infrastructure for AI agents to connect to and interact with the Supabase database using the Model Context Protocol (MCP).

### Supported Agent Types

- **Persistent Agents** - Long-running AI assistants with direct IPv6 connections
- **Serverless Agents** - AWS Lambda, Google Cloud Functions with transaction pooling
- **Edge Agents** - Cloudflare Workers, Vercel Edge with optimized latency
- **High-Performance Agents** - Dedicated poolers for intensive workloads

### Connection Methods

| Method | Use Case | Port | Best For |
|--------|----------|------|----------|
| Direct IPv6 | Persistent agents | 5432 | Full PostgreSQL features, lowest latency |
| Supavisor Session | IPv4 persistent agents | 5432 | Connection persistence, IPv4 compatibility |
| Supavisor Transaction | Serverless/Edge agents | 6543 | Auto cleanup, efficient resources |
| Dedicated Pooler | High-performance | Custom | Maximum throughput, isolated resources |

### Quick Start for AI Agents

```typescript
// Node.js example - Serverless agent
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// Query with automatic connection management
const { data, error } = await supabase
  .from('documents')
  .select('*')
  .limit(10);
```

```python
# Python example - Persistent agent
import asyncpg
import os

pool = await asyncpg.create_pool(
    os.getenv('DATABASE_URL'),
    min_size=5,
    max_size=20
)

async with pool.acquire() as conn:
    rows = await conn.fetch('SELECT * FROM users LIMIT 10')
```

**See [docs/MCP_SERVER_ARCHITECTURE.md](docs/MCP_SERVER_ARCHITECTURE.md) for complete documentation.**

## 🧪 Testing

```bash
# Test edge functions
npm run test:functions

# Test RLS policies
npm run test:rls

# Validate migrations locally
npm run db:reset

# Check for SQL issues
npm run lint:sql
```

## 📚 Documentation

### Core Documentation
- **[DEVOPS.md](DEVOPS.md)** - Complete DevOps guide with secrets, workflows, troubleshooting
- **[docs/RLS_POLICIES.md](docs/RLS_POLICIES.md)** - Complete RLS policy guide with patterns and best practices
- **[docs/RLS_TESTING.md](docs/RLS_TESTING.md)** - RLS testing guidelines for local and CI/CD

### MCP Server Infrastructure (AI Agents)
- **[docs/MCP_SERVER_ARCHITECTURE.md](docs/MCP_SERVER_ARCHITECTURE.md)** - MCP server architecture and design patterns for AI agents
- **[docs/MCP_SERVER_CONFIGURATION.md](docs/MCP_SERVER_CONFIGURATION.md)** - Configuration templates for all agent types and environments
- **[docs/MCP_AUTHENTICATION.md](docs/MCP_AUTHENTICATION.md)** - Authentication strategies and security best practices
- **[docs/MCP_CONNECTION_EXAMPLES.md](docs/MCP_CONNECTION_EXAMPLES.md)** - Code examples in Node.js, Python, Deno, and more
- **[docs/MCP_IMPLEMENTATION_SUMMARY.md](docs/MCP_IMPLEMENTATION_SUMMARY.md)** - Complete MCP implementation overview
- **[supabase/functions/README.md](supabase/functions/README.md)** - Edge functions guide
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Local Development Guide](https://supabase.com/docs/guides/local-development)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)

## 🐛 Troubleshooting

**Docker not running**
```bash
# Make sure Docker Desktop is running
docker info
```

**Port conflicts**
```bash
# Stop Supabase and check ports
supabase stop
lsof -i :8000
lsof -i :54322
```

**Migration errors**
```bash
# Reset and reapply migrations
supabase db reset --debug
```

**Function deployment fails**
```bash
# Check function logs
supabase functions logs <function-name>

# Test locally first
supabase functions serve <function-name>
```

See [DEVOPS.md](DEVOPS.md) for comprehensive troubleshooting.

## 🤝 Contributing

### Development Workflow

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and commit: `git commit -m "Add feature"`
3. Push branch: `git push origin feature/my-feature`
4. Open Pull Request (use issue templates!)
5. Wait for CI checks to pass
6. Request review
7. Merge to main → Auto-deploy!

### Issue Management

We use GitHub Issues with structured templates to track work:

- **Bug Reports** - Report issues and unexpected behavior
- **Feature Requests** - Suggest enhancements
- **DevOps Tasks** - Infrastructure and CI/CD work
- **Database Tasks** - Schema changes and migrations

**Create an issue**: https://github.com/SkogAI/supabase/issues/new/choose

**See [docs/ISSUE_MANAGEMENT.md](docs/ISSUE_MANAGEMENT.md) for complete guide.**

## 📝 License

MIT

## 🆘 Support

- **Maintainers**: Contact @Skogix or @Ic0n for assistance
- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Supabase**: [supabase.com/support](https://supabase.com/support)

---

**Built with [Supabase](https://supabase.com) | Deployed with [GitHub Actions](https://github.com/features/actions)**
