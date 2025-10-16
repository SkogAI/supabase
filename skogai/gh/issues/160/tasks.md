---
title: Issue 160 Task List
type: tasks
updated: 2025-10-12
permalink: gh/issues/160/tasks
---

# Task Breakdown for Issue #160

## Phase 1: Foundation (Priority)

- [x] Create `BASIC_CLI_REFERENCE.md`
- [x] Create `TEMPLATE.md`
- [ ] Create `skogai/README.md` with navigation guide
- [ ] Document most-used commands:
  - [ ] `db/reset.md`
  - [ ] `migration/new.md`
  - [ ] `gen/types.md`
  - [ ] `functions/serve.md`
  - [ ] `lifecycle/start.md`
  - [ ] `lifecycle/status.md`

## Phase 2: Concepts & Workflows

### Concepts Folder
- [ ] Create `concepts/` directory
- [ ] `concepts/rls-policies.md` - Document RLS patterns from `tests/rls_test_suite.sql`
- [ ] `concepts/seed-data.md` - Explain test users and fixtures
- [ ] `concepts/config-toml.md` - Document key config sections

### Workflows Folder
- [ ] Create `workflows/` directory
- [ ] `workflows/new-feature.md` - End-to-end feature workflow
- [ ] `workflows/testing.md` - How to run and interpret tests
- [ ] `workflows/schema-change.md` - Migration workflow

## Phase 3: Expand Command Coverage

### Database Commands
- [ ] `db/README.md`
- [ ] `db/pull.md`
- [ ] `db/push.md`
- [ ] `db/lint.md`
- [ ] `db/diff.md` (if not already done)

### Functions Commands
- [ ] `functions/README.md`
- [ ] `functions/deploy.md`
- [ ] `functions/download.md`
- [ ] Add troubleshooting to function docs

### Migration Commands
- [ ] `migration/README.md`
- [ ] `migration/list.md`
- [ ] `migration/up.md`
- [ ] `migration/down.md`

## Additional Ideas (Backlog)

- [ ] Add CLI version comparison notes (v2.34.3 vs v2.48.3)
- [ ] Document npm scripts from package.json
- [ ] Create quick-start checklist for new developers
- [ ] Add visual diagrams for complex workflows
- [ ] Link to official Supabase docs for deeper dives

## Success Criteria

- [ ] Can find any command docs in <5 seconds
- [ ] New developer can set up project using skogai docs alone
- [ ] Troubleshooting sections capture real issues encountered
- [ ] All daily-use commands documented
- [ ] Templates used consistently
- [ ] Cross-references working (concepts ↔ commands ↔ workflows)