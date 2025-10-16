---
title: Quick Reference - Supabase CLI Basics
type: index
permalink: supabase/quick-reference
tags:
  - "reference"
  - "documentation"
  - "cli"
  - "overview"
  - "supabase"
project: supabase
---

# Supabase CLI Basics - Quick Reference

**CLI Version:** v2.34.3 | **Last Updated:** 2025-10-10

This is a quick reference map of the basic Supabase CLI commands you'll use daily in local development.

## File Tree Structure (Mirrors CLI)

```
skogai/
├── README.md                          # Navigation guide and documentation philosophy
│
├── db/                                # Database management (supabase db)
│   ├── README.md                     # Overview of all db commands
│   ├── reset.md                      # Drop, recreate, run migrations + seed
│   ├── diff.md                       # Generate SQL diff of schema changes
│   ├── push.md                       # Deploy migrations to remote
│   ├── pull.md                       # Pull schema from remote database
│   ├── lint.md                       # Check SQL for typing errors
│   └── start.md                      # Start local Postgres only
│
├── migration/                         # Migration management (supabase migration)
│   ├── README.md                     # Overview of migration workflow
│   ├── new.md                        # Create new timestamped migration file
│   ├── list.md                       # Show local and remote migrations
│   ├── up.md                         # Apply pending migrations
│   └── down.md                       # Revert migrations
│
├── functions/                         # Edge Functions (supabase functions)
│   ├── README.md                     # Overview of Deno functions
│   ├── new.md                        # Create new function directory
│   ├── serve.md                      # Local dev server with hot reload
│   ├── deploy.md                     # Deploy to production
│   └── download.md                   # Download deployed function
│
├── gen/                              # Code generation (supabase gen)
│   ├── README.md                     # Overview of generators
│   └── types.md                      # Generate TypeScript types from schema
│
├── lifecycle/                         # Project lifecycle commands
│   ├── init.md                       # Initialize new Supabase project
│   ├── start.md                      # Start all Docker containers
│   ├── stop.md                       # Stop all containers
│   ├── status.md                     # Show running services and URLs
│   ├── link.md                       # Connect to remote project
│   └── unlink.md                     # Disconnect from remote
│
├── concepts/                          # Cross-cutting topics (not CLI commands)
│   ├── rls-policies.md              # Row Level Security patterns
│   ├── config-toml.md               # Understanding supabase/config.toml
│   ├── seed-data.md                 # Test data and user fixtures
│   ├── storage-buckets.md           # File storage configuration
│   ├── realtime.md                  # Live subscription setup
│   └── auth.md                      # Authentication configuration
│
└── workflows/                         # Multi-command sequences
    ├── new-feature.md               # Migration → code → types → test
    ├── schema-change.md             # Diff → migrate → reset → test
    ├── testing.md                   # RLS, storage, function tests
    └── deployment.md                # Link → push → deploy functions
```

## Essential Commands at a Glance

### Daily Development

```bash
supabase start          # Start everything
supabase status         # Check what's running
supabase db reset       # Fresh slate with seed data
supabase gen types      # Update TypeScript types
supabase functions serve # Local function testing
```

### Migration Workflow

```bash
supabase migration new add_feature  # Create migration
supabase db reset                   # Apply locally
supabase db push                    # Deploy to remote
```

### Type Generation

```bash
supabase gen types typescript --local > types/database.ts
```

### Edge Functions

```bash
supabase functions new my-function   # Create
supabase functions serve            # Test locally
supabase functions deploy my-function # Deploy
```

## Documentation Philosophy

- **Each folder** = One CLI command group
- **README.md** in folder = Overview of that command group
- **Individual files** = One subcommand, thoroughly documented
- **concepts/** = Topics that don't map to CLI structure
- **workflows/** = Multi-step procedures using multiple commands

## Local URLs (when running)

```
Studio:     http://127.0.0.1:8000
API:        http://127.0.0.1:54321
Database:   postgresql://postgres:postgres@127.0.0.1:54322/postgres
Functions:  http://127.0.0.1:54321/functions/v1/<name>
```

## Your Project Context

- **Project ID:** SkogAI
- **PostgreSQL:** v17
- **Deno:** v2 (Edge Functions)
- **Test Users:** alice, bob, charlie (password: `password123`)
- **Schemas:** public, graphql_public
- **Migrations:** 6 files in `supabase/migrations/`
- **Functions:** hello-world, health-check, openai-chat, openrouter-chat

## Quick Troubleshooting

| Problem                   | Solution                                       |
| ------------------------- | ---------------------------------------------- |
| Docker not running        | `docker info` to verify, start Docker Desktop  |
| Port conflicts            | `supabase stop`, check with `lsof -i :8000`    |
| Migration errors          | `supabase db reset --debug`                    |
| Type generation fails     | Ensure Supabase running: `supabase status`     |
| Function deployment fails | Test locally first: `supabase functions serve` |

## Next Steps

1. Start documenting commands you use most (db reset, migration new, etc.)
2. Add troubleshooting notes as you encounter issues
3. Expand concepts/ as you learn RLS, storage, etc.
4. Build workflows/ for your common multi-command sequences

---

**Note:** This structure mirrors the Supabase CLI so your muscle memory transfers directly to documentation navigation. If you know the command, you know where to find the docs.
