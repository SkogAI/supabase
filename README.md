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

### Seed Data

The `supabase/seed.sql` file contains test data for local development:

```bash
# Seed data is automatically loaded during database reset
npm run db:reset

# What gets seeded:
# - 3 test users with auth credentials
# - User profiles (auto-created via trigger)
# - Sample posts (published and drafts)
```

**Test User Credentials** (local development only):
- `alice@example.com` / `password123`
- `bob@example.com` / `password123`
- `charlie@example.com` / `password123`

**Testing RLS Policies:**
```sql
-- Set auth context as a specific user
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001'; -- Alice

-- Test queries with RLS policies
SELECT * FROM posts; -- Should see published posts + own drafts
UPDATE posts SET title = 'New' WHERE user_id = auth.uid(); -- Should work
```

⚠️ **Warning:** Seed data is for local development only. Never use test credentials in production!

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

- **`profiles`** - User profiles with RLS policies
- **`posts`** - User-generated content
- **Automatic triggers** - `updated_at` timestamp management
- **Auto profile creation** - On user signup via Auth

See `supabase/migrations/` for full schema and `supabase/seed.sql` for test data.

### Example: Using RLS Policies

```sql
-- In migrations: Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own drafts
CREATE POLICY "Users see own drafts"
  ON posts FOR SELECT
  USING (published = true OR auth.uid() = user_id);
```

## 🧪 Testing

```bash
# Test edge functions
npm run test:functions

# Validate migrations and seed data locally
npm run db:reset

# Check for SQL issues
npm run lint:sql

# Test with seed data users
# Login with alice@example.com / password123 in your app
# or use Supabase Studio at http://localhost:8000
```

## 📚 Documentation

- **[DEVOPS.md](DEVOPS.md)** - Complete DevOps guide with secrets, workflows, troubleshooting
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

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and commit: `git commit -m "Add feature"`
3. Push branch: `git push origin feature/my-feature`
4. Open Pull Request
5. Wait for CI checks to pass
6. Request review
7. Merge to main → Auto-deploy!

## 📝 License

MIT

## 🆘 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Supabase**: [supabase.com/support](https://supabase.com/support)

---

**Built with [Supabase](https://supabase.com) | Deployed with [GitHub Actions](https://github.com/features/actions)**
