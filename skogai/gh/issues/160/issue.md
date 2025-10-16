---
title: Organize and document Supabase CLI knowledge base (./skogai/)
number: 160
state: CLOSED
author: Skogix
created: 2025-10-10 06:57:55+00:00
updated: 2025-10-10 16:09:41+00:00
permalink: gh/issues/160/issue
---

# Issue #160: Organize and document Supabase CLI knowledge base (./skogai/)

## Overview

Create a structured knowledge base in `./skogai/` that mirrors the Supabase CLI command structure. This will provide quick-reference documentation for commands, workflows, and concepts based on proven working patterns in this project.

## Context

We have a solid basic Supabase setup now:
- PostgreSQL v17 with 6 working migrations
- 4 Edge Functions (Deno v2)
- RLS policies tested and working
- TypeScript type generation pipeline
- Seed data with 3 test users
- CI/CD workflows configured

It's time to document this knowledge systematically so it's:
1. Easy to find (mirrors CLI structure)
2. AI-friendly (structured, scannable)
3. Grows organically (add as we learn)
4. Complements existing `docs/` (personal knowledge base vs official docs)

## Proposed Structure

```
skogai/
├── README.md                    # Navigation guide and philosophy
├── BASIC_CLI_REFERENCE.md       # Quick reference (DONE ✓)
├── TEMPLATE.md                  # Doc template for consistency (DONE ✓)
│
├── db/                          # Database management
│   ├── README.md
│   ├── reset.md                # START HERE - most used
│   ├── diff.md
│   ├── push.md
│   ├── pull.md
│   └── lint.md
│
├── migration/                   # Migration workflow
│   ├── README.md
│   ├── new.md                  # Critical workflow
│   ├── list.md
│   └── up.md
│
├── functions/                   # Edge Functions
│   ├── README.md
│   ├── new.md
│   ├── serve.md
│   └── deploy.md
│
├── gen/                         # Code generation
│   ├── README.md
│   └── types.md                # TypeScript generation
│
├── lifecycle/                   # Project lifecycle
│   ├── start.md
│   ├── stop.md
│   ├── status.md
│   └── link.md
│
├── concepts/                    # Cross-cutting topics
│   ├── rls-policies.md
│   ├── config-toml.md
│   ├── seed-data.md
│   ├── storage-buckets.md
│   ├── realtime.md
│   └── auth.md
│
└── workflows/                   # Multi-command sequences
    ├── new-feature.md
    ├── schema-change.md
    ├── testing.md
    └── deployment.md
```

## Tasks

### Phase 1: Foundation (Priority)
- [x] Create `BASIC_CLI_REFERENCE.md` (done)
- [x] Create `TEMPLATE.md` (done)
- [ ] Create `skogai/README.md` with navigation guide
- [ ] Document most-used commands:
  - [ ] `db/reset.md`
  - [ ] `migration/new.md`
  - [ ] `gen/types.md`
  - [ ] `functions/serve.md`
  - [ ] `lifecycle/start.md` and `status.md`

### Phase 2: Concepts & Workflows
- [ ] Create `concepts/` folder
  - [ ] `rls-policies.md` - Document RLS patterns from `tests/rls_test_suite.sql`
  - [ ] `seed-data.md` - Explain test users and fixtures
  - [ ] `config-toml.md` - Document key config sections
- [ ] Create `workflows/` folder
  - [ ] `new-feature.md` - End-to-end feature workflow
  - [ ] `testing.md` - How to run and interpret tests
  - [ ] `schema-change.md` - Migration workflow

### Phase 3: Expand Command Coverage
- [ ] Complete `db/` documentation (pull, push, lint)
- [ ] Complete `functions/` documentation (deploy, download)
- [ ] Complete `migration/` documentation (list, up, down)
- [ ] Add troubleshooting sections to each doc

### Additional Ideas
- [ ] Add CLI version comparison notes (v2.34.3 vs v2.48.3)
- [ ] Document npm scripts from package.json
- [ ] Create quick-start checklist for new developers
- [ ] Add visual diagrams for complex workflows
- [ ] Link to official Supabase docs for deeper dives

## Documentation Principles

1. **Mirror CLI structure** - If command is `supabase db reset`, doc is `skogai/db/reset.md`
2. **One file, one topic** - Each doc covers exactly one command/concept
3. **Project-specific** - Include YOUR setup, YOUR data, YOUR common patterns
4. **Template consistency** - Use `TEMPLATE.md` for all command docs
5. **Version tracking** - Note CLI version tested in each doc
6. **Living docs** - Add troubleshooting as you encounter issues
7. **Complement, don't duplicate** - `docs/` is official, `skogai/` is personal knowledge

## Benefits

- ✅ **Faster onboarding** - New team members can navigate by CLI commands they know
- ✅ **AI-assisted development** - Claude/Copilot can quickly find exact info
- ✅ **Searchable** - `grep -r "keyword" skogai/` finds everything
- ✅ **Scalable** - Add one file per command as needed
- ✅ **Maintainable** - Small focused files easier to keep updated
- ✅ **Reference material** - Quick lookup without scrolling huge docs

## Related Files

- `CLAUDE.md` - Should reference this structure for quick lookups
- `docs/WORKFLOWS.md` - Official workflows (for contributors)
- `skogai/workflows/` - Personal workflow notes (daily use)

## Success Criteria

- [ ] Can find any command docs in <5 seconds
- [ ] New developer can set up project using skogai docs alone
- [ ] Troubleshooting sections capture real issues encountered
- [ ] All daily-use commands documented
- [ ] Templates used consistently
- [ ] Cross-references working (concepts ↔ commands ↔ workflows)

## Notes

- Start small: Document the 5 most-used commands first
- Grow organically: Add docs when you need to look something up twice
- Keep it practical: Real examples, real output, real problems/solutions
- This is YOUR knowledge base - make it work for YOUR workflow