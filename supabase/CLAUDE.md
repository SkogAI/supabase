# CLAUDE.md

Quick reference for working with this Supabase project.

## Project Structure (Actual)

```
/home/skogix/dev/supabase/
├── volumes/db/
│   ├── migrations/migrations/  # 9 SQL migrations
│   └── seed.sql               # Test data with 3 users (alice, bob, charlie)
├── docker/
│   └── docker-compose.override.yml  # SAML configuration
├── tests/                      # 8 test SQL files
├── scripts/                    # Bash helper scripts
└── CONFIG.md                   # Complete configuration reference
```

## Essential Commands

### Start/Stop Supabase
```bash
supabase start        # Start all services
supabase stop         # Stop services
supabase status       # Check what's running
```

### Run Migrations
```bash
supabase db reset     # Drop DB, run migrations, load seed data
supabase db diff      # See schema changes
```

### Run Tests
```bash
supabase db execute --file tests/rls_test_suite.sql
supabase db execute --file tests/storage_test_suite.sql
supabase db execute --file tests/profiles_test_suite.sql
```

### Direct Database Access
```bash
# Connection string from CONFIG.md:
# postgresql://postgres:postgres@localhost:54322/postgres
psql -h localhost -p 54322 -U postgres -d postgres
```

## Configuration

See **CONFIG.md** for comprehensive documentation of:
- All environment variables
- config.toml settings
- Connection pooling
- SAML configuration
- Port assignments

## Seed Data

Test users (password: `password123`):
- Alice: `00000000-0000-0000-0000-000000000001` (alice@example.com)
- Bob: `00000000-0000-0000-0000-000000000002` (bob@example.com)
- Charlie: `00000000-0000-0000-0000-000000000003` (charlie@example.com)

## Next Steps

1. Run `supabase start` to verify everything works
2. Check actual database schema with migrations
3. Add features incrementally as needed
