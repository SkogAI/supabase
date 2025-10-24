# CLAUDE.md

Project root for SkogAI Supabase development.

## Project Structure

```
/home/skogix/dev/supabase/
├── supabase/           # Actual Supabase project (see supabase/CLAUDE.md)
├── docker/             # Docker Compose overrides (SAML config)
├── scripts/            # Helper bash scripts
├── tests/              # SQL test files
├── volumes/            # Docker volumes and data
├── skogai/             # Personal knowledge base
├── todo/               # Task tracking
├── CONFIG.md           # Comprehensive configuration reference
├── .env                # Local environment variables (not committed)
└── .env.example        # Environment variable template
```

## Quick Start

### Working with Supabase

All Supabase operations happen in the `supabase/` directory:

```bash
cd supabase
# See supabase/CLAUDE.md for Supabase-specific commands
```

### Configuration

- **CONFIG.md** - Complete reference for all configuration settings
- **.env** - Local environment variables (see .env.example for template)

### Helper Scripts

```bash
ls scripts/          # View available scripts
```

### Tests

```bash
ls tests/            # View available SQL tests
```

## Directory Purposes

- **supabase/** - The actual Supabase project with config, migrations, functions
- **docker/** - Docker Compose configuration overrides
- **scripts/** - Automation and helper scripts
- **tests/** - SQL test suites for validation
- **volumes/** - Docker volume mounts and persistent data
- **skogai/** - Personal knowledge base and documentation
- **todo/** - Task and project tracking

## Next Steps

1. Read **CONFIG.md** for comprehensive configuration documentation
2. Go to **supabase/** directory and read supabase/CLAUDE.md
3. Check **.env.example** and create your **.env** if needed
