# Supabase Project

Local development setup for Supabase backend with database, auth, storage, and edge functions.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) installed
- Docker Desktop running (required for local development)
- Node.js 18+ (for edge functions)

## Quick Start

1. **Clone and setup environment**
   ```bash
   cp .env.example .env
   # Edit .env and add your API keys
   ```

2. **Start Supabase local development**
   ```bash
   supabase start
   ```

3. **Access local services**
   - Studio: http://localhost:8000
   - API: http://localhost:8000
   - Database: postgresql://postgres:postgres@localhost:54322/postgres

4. **Stop local services**
   ```bash
   supabase stop
   ```

## Project Structure

```
.
├── supabase/
│   ├── config.toml          # Supabase configuration
│   ├── migrations/          # Database migrations
│   ├── functions/           # Edge functions
│   └── seed.sql            # Database seed data
├── .github/
│   └── workflows/          # CI/CD workflows
└── .env.example            # Environment template
```

## Database Migrations

Create a new migration:
```bash
supabase migration new <migration_name>
```

Apply migrations:
```bash
supabase db reset
```

## Edge Functions

Create a new function:
```bash
supabase functions new <function_name>
```

Serve functions locally:
```bash
supabase functions serve
```

Deploy functions:
```bash
supabase functions deploy <function_name>
```

## Deployment

This project uses GitHub Actions for automated deployment. See `.github/workflows/` for details.

### Manual Deployment

1. **Link to your Supabase project**
   ```bash
   supabase link --project-ref <your-project-ref>
   ```

2. **Push database changes**
   ```bash
   supabase db push
   ```

3. **Deploy edge functions**
   ```bash
   supabase functions deploy
   ```

## Environment Variables

Required environment variables (see `.env.example`):
- `SUPABASE_OPENAI_API_KEY` - OpenAI API key for Studio AI features

## CI/CD Workflows

This project includes several GitHub Actions workflows:
- **Migration Validation**: Validates database migrations on PRs
- **Schema Linting**: Checks database schema for issues
- **Edge Functions Testing**: Tests edge functions
- **Deployment**: Automated deployment to Supabase
- **Dependency Updates**: Automated dependency updates

## Security

⚠️ **Never commit sensitive data:**
- API keys and secrets belong in `.env` (gitignored)
- Use `env(VARIABLE_NAME)` syntax in `config.toml`
- Review `.gitignore` to ensure secrets are excluded

## Useful Commands

```bash
# Reset database to migrations
supabase db reset

# Generate TypeScript types
supabase gen types typescript --local > types/database.ts

# View logs
supabase logs

# Check status
supabase status
```

## Documentation

- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Local Development Guide](https://supabase.com/docs/guides/local-development)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
