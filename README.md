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

### Daily Development

```bash
# Start development environment
./scripts/dev.sh
# OR
npm run db:start

# Access services
# Studio UI: http://localhost:8000
# Database: postgresql://postgres:postgres@localhost:54322/postgres

# Check status
supabase status

# Stop services
supabase stop
```

### Database Migrations

```bash
# Create a new migration
npm run migration:new <migration_name>
# OR
supabase migration new <migration_name>

# Edit the generated migration file in supabase/migrations/

# Apply all migrations (resets database)
npm run db:reset
# OR
./scripts/reset.sh

# Check migration status
npm run db:status

# Generate SQL diff of current changes
npm run db:diff

# View migration history
supabase migration list
```

**Migration Best Practices**:
- Always test migrations locally before committing
- One logical change per migration
- Include rollback instructions in comments
- Enable RLS on all new tables
- Add indexes for foreign keys and frequently queried columns

### Edge Functions

```bash
# Create a new function
npm run functions:new <function_name>
# OR
supabase functions new <function_name>

# Serve functions locally (with hot reload)
npm run functions:serve
# Functions available at: http://localhost:54321/functions/v1/<function-name>

# Test a function with curl
curl -i --location --request POST \
  'http://localhost:54321/functions/v1/<function-name>' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"key":"value"}'

# Run function tests
cd supabase/functions/<function-name>
deno test --allow-all test.ts

# Lint functions
npm run lint:functions

# Format functions
npm run format:functions

# Type check functions
cd supabase/functions/<function-name>
deno check index.ts

# Deploy specific function
supabase functions deploy <function_name>

# Deploy all functions
npm run functions:deploy

# View function logs
supabase functions logs <function-name> --tail
```

**Function Development Tips**:
- Use TypeScript for type safety
- Always handle CORS in responses
- Add error handling for all operations
- Test with both authenticated and anonymous requests
- Keep functions focused and under 200 lines

### TypeScript Types

```bash
# Generate types from database schema
npm run types:generate

# Watch for changes and auto-regenerate
npm run types:watch

# Verify types compile
tsc --noEmit
```

**Using Generated Types**:
```typescript
import { Database } from './types/database';

type Profile = Database['public']['Tables']['profiles']['Row'];
type NewPost = Database['public']['Tables']['posts']['Insert'];
```

### Testing Changes

```bash
# Test database changes
npm run db:reset           # Apply migrations
# Verify in Studio: http://localhost:8000

# Test edge functions
npm run test:functions     # Run all function tests
npm run lint:functions     # Check code quality

# Manual testing
npm run functions:serve    # Start function server
# Test with curl or Postman
```

### Working with Seeds

```bash
# Edit seed data
nano supabase/seed.sql

# Apply seeds
npm run db:reset           # Resets DB and applies seeds

# Verify seed data in Studio
open http://localhost:8000
```

### Common Workflows

**Adding a New Table**:
```bash
1. supabase migration new add_table_name
2. Edit migration file with CREATE TABLE
3. Add RLS policies
4. npm run db:reset (test locally)
5. npm run types:generate (update types)
6. Commit and push
```

**Modifying a Table**:
```bash
1. supabase migration new modify_table_name
2. Edit migration with ALTER TABLE
3. npm run db:reset (test locally)
4. Verify data is preserved/migrated
5. npm run types:generate
6. Commit and push
```

**Creating a New Function**:
```bash
1. npm run functions:new my-function
2. Edit supabase/functions/my-function/index.ts
3. Add tests in test.ts
4. npm run functions:serve (test locally)
5. curl test the endpoint
6. npm run test:functions (run tests)
7. Commit and push
```

**Fixing a Bug**:
```bash
1. git checkout -b fix/bug-description
2. Make code changes
3. Test locally (db:reset, functions:serve)
4. npm run lint:functions
5. git commit -m "fix: description"
6. git push origin fix/bug-description
7. Open PR and wait for CI checks
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

See `supabase/migrations/` for full schema.

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

# Validate migrations locally
npm run db:reset

# Check for SQL issues
npm run lint:sql
```

## 📚 Documentation

### Project Documentation

- **[README.md](README.md)** - This file: Quick start and development workflows
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contributing guidelines and coding standards
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and design decisions
- **[DEVOPS.md](DEVOPS.md)** - Complete DevOps guide with secrets, workflows, troubleshooting
- **[supabase/functions/README.md](supabase/functions/README.md)** - Edge functions development guide

### External Resources

- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Local Development Guide](https://supabase.com/docs/guides/local-development)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)

## 🐛 Troubleshooting

### Common Issues and Solutions

**Docker not running**
```bash
# Make sure Docker Desktop is running
docker info

# If Docker daemon is not running
# Start Docker Desktop application
```

**Port conflicts**
```bash
# Stop Supabase and check ports
supabase stop
lsof -i :8000    # Studio/API port
lsof -i :54322   # Database port
lsof -i :54321   # Functions port

# Kill process using the port (if needed)
kill -9 $(lsof -ti:8000)
```

**Migration errors**
```bash
# Reset and reapply migrations
supabase db reset --debug

# Check migration status
supabase migration list

# Manually repair migration (if needed)
supabase db push --dry-run
```

**Function deployment fails**
```bash
# Check function logs
supabase functions logs <function-name>

# Test locally first
supabase functions serve <function-name>

# Check for syntax errors
cd supabase/functions/<function-name>
deno check index.ts
```

**Supabase CLI not found**
```bash
# Install Supabase CLI
# macOS/Linux
brew install supabase/tap/supabase

# Windows
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# npm (alternative)
npm install -g supabase
```

**Permission denied on scripts**
```bash
# Make scripts executable
chmod +x scripts/setup.sh
chmod +x scripts/dev.sh
chmod +x scripts/reset.sh
```

**Database connection refused**
```bash
# Ensure Supabase is running
supabase status

# Restart Supabase
supabase stop
supabase start

# Check Docker containers
docker ps | grep supabase
```

**TypeScript types not generating**
```bash
# Make sure database is running
supabase status

# Generate manually
npm run types:generate

# Or use CLI directly
supabase gen types typescript --local > types/database.ts
```

**Node modules issues**
```bash
# Clear and reinstall
rm -rf node_modules package-lock.json
npm install

# Or use npm ci for clean install
npm ci
```

**Environment variables not loading**
```bash
# Ensure .env file exists
ls -la .env

# Copy from example if missing
cp .env.example .env

# Check file contents
cat .env
```

See [DEVOPS.md](DEVOPS.md) for comprehensive troubleshooting.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Contribution Workflow

1. **Fork and clone** the repository
2. **Create feature branch**: `git checkout -b feature/my-feature`
3. **Make changes** and test locally
4. **Commit changes**: `git commit -m "feat: add feature"`
5. **Push branch**: `git push origin feature/my-feature`
6. **Open Pull Request** on GitHub
7. **Wait for CI checks** to pass
8. **Request review** from maintainers
9. **Merge to main** → Auto-deploy! 🚀

### Before Contributing

- Read [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines
- Check [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system
- Review open issues and PRs to avoid duplicates
- Test your changes locally: `npm run db:reset && npm run test:functions`

### What to Contribute

- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🧪 Tests
- 🎨 UI/UX enhancements
- ⚡ Performance improvements

## 📝 License

MIT

## 🆘 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Supabase**: [supabase.com/support](https://supabase.com/support)

---

**Built with [Supabase](https://supabase.com) | Deployed with [GitHub Actions](https://github.com/features/actions)**
