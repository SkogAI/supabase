---
title: Contributing Guide
type: note
permalink: guides/contributing-guide
tags:
- contributing
- development
- workflow
- guidelines
- bestpractices
---

# Contributing Guide

Complete guide for contributing to the Supabase project with workflows, guidelines, and best practices.

## Quick Start Prerequisites

[prerequisite] Docker Desktop required and must be running #docker #requirement
[prerequisite] Supabase CLI required for database operations #supabase #cli
[prerequisite] Node.js 18+ recommended for TypeScript types #nodejs #typescript
[prerequisite] Deno 2.x required for edge functions development #deno #serverless
[prerequisite] GitHub CLI optional for easier workflow #github #tooling

## Initial Setup

[workflow] Automated setup via `./scripts/setup.sh` checks prerequisites and starts services #automation #setup
[workflow] Manual setup requires npm install, .env creation, db start, and type generation #manual #configuration
[command] `npm install` installs project dependencies #npm
[command] `cp .env.example .env` creates environment configuration file #env #config
[command] `npm run db:start` or `./scripts/dev.sh` starts Supabase services #database #startup
[command] `npm run types:generate` generates TypeScript types from schema #types #codegen
[timeframe] Initial setup takes 5-10 minutes with automation, 10-15 minutes manually #performance

## Branch Naming Conventions

[convention] Feature branches use format `feature/add-user-notifications` #git #naming
[convention] Bug fix branches use format `fix/authentication-redirect` #git #bugfix
[convention] Database change branches use format `database/add-comments-table` #git #schema
[convention] DevOps branches use format `devops/add-backup-workflow` #git #infrastructure
[pattern] Use descriptive, kebab-case names for all branches #bestpractice #naming

## Database Migration Workflow

[workflow] Create migration with `npm run migration:new add_feature_name` #database #migration
[workflow] Edit generated migration file in `supabase/migrations/` directory #sql #development
[workflow] Test locally with `npm run db:reset` to apply all migrations #testing #validation
[workflow] Test RLS policies with `npm run test:rls` if security changed #security #testing
[workflow] Generate types with `npm run types:generate` after schema changes #types #automation
[workflow] Commit migration file and updated types together #git #versioning

## Migration Naming Conventions

[convention] `add_<table>_table` for creating new tables #naming #schema
[convention] `add_<table>_<column>` for adding new columns #naming #schema
[convention] `enable_rls_<table>` for security policies #naming #security
[convention] `add_<table>_index` for performance indexes #naming #optimization
[convention] `alter_<table>_<change>` for schema modifications #naming #schema
[pattern] Use snake_case with clear action verbs for migration names #bestpractice

## Edge Function Development

[workflow] Create function with `npm run functions:new my-function` #serverless #creation
[workflow] Develop in `supabase/functions/my-function/index.ts` #typescript #development
[workflow] Test locally with `npm run functions:serve` #testing #local
[workflow] Test with curl at `http://localhost:54321/functions/v1/my-function` #testing #http
[workflow] Write tests in `test.ts` in function directory #testing #unittest
[workflow] Run tests with `cd supabase/functions/my-function && deno test --allow-all test.ts` #testing #execution
[workflow] Deploy with `supabase functions deploy my-function` #deployment #production
[command] `npm run lint:functions` lints Deno function code #linting #quality
[command] `npm run format:functions` formats Deno function code #formatting #quality

## Testing Workflow

[command] `npm run test:functions` tests all edge functions #testing #serverless
[command] `npm run test:rls` tests Row Level Security policies #testing #security
[command] `supabase db execute --file tests/storage_test_suite.sql` tests storage policies #testing #storage
[command] `npm run db:reset` validates migrations #testing #database
[command] `npm run lint:sql` checks SQL syntax #linting #validation
[workflow] Always test changes locally before pushing #bestpractice #quality

## Commit Message Guidelines

[pattern] Good format: "Add user notifications table with RLS policies" #git #documentation
[pattern] Good format: "Fix authentication redirect loop" #git #bugfix
[pattern] Good format: "Update OpenAI function to use streaming responses" #git #enhancement
[convention] `feat:` prefix for new features #git #conventional
[convention] `fix:` prefix for bug fixes #git #conventional
[convention] `docs:` prefix for documentation changes #git #conventional
[convention] `test:` prefix for test additions or changes #git #conventional
[convention] `refactor:` prefix for code refactoring #git #conventional
[convention] `perf:` prefix for performance improvements #git #conventional
[convention] `chore:` prefix for maintenance tasks #git #conventional

## Pull Request Guidelines

[workflow] Push branch with `git push origin feature/my-feature` #git #collaboration
[workflow] Open PR using `gh pr create --title "Title" --body "Description"` #github #cli
[requirement] PR title must be clear and descriptive #documentation #quality
[requirement] PR description must link to related issues #documentation #traceability
[requirement] PR description must describe what changed and why #documentation #context
[requirement] PR description must include screenshots for UI changes #documentation #visual
[requirement] PR description must list testing performed #documentation #quality
[workflow] Wait for CI checks to pass before requesting review #automation #quality
[workflow] Request review from maintainers after checks pass #collaboration #review
[workflow] Address review feedback promptly #collaboration #communication
[workflow] Maintainers merge PR after approval and passing checks #workflow #deployment
[workflow] Delete feature branch after merge #cleanup #git

## Code Review Process

[requirement] All PRs require at least one approval #quality #governance
[requirement] CI/CD checks must pass before merge #automation #quality
[requirement] All review comments must be addressed #collaboration #quality
[pattern] Keep PRs focused and reasonably sized #bestpractice #review
[pattern] Be responsive to feedback during review #collaboration #communication

## SQL Code Style

[convention] Use lowercase for SQL keywords in migrations #style #sql
[convention] Use snake_case for table and column names #naming #sql
[requirement] Always enable RLS on public tables #security #database
[pattern] Include comments for complex queries #documentation #readability
[pattern] Add indexes for frequently queried columns #optimization #performance

## TypeScript/JavaScript Code Style

[requirement] Use TypeScript for type safety #typescript #quality
[pattern] Follow existing code formatting conventions #style #consistency
[workflow] Run linter before committing with `npm run lint:functions` #linting #quality
[pattern] Use async/await over promises for asynchronous code #javascript #modern
[pattern] Handle errors appropriately with try-catch #javascript #errorhandling

## Documentation Standards

[requirement] Update README.md for new features #documentation #maintenance
[requirement] Add inline comments for complex logic #documentation #readability
[requirement] Update relevant docs in `docs/` directory #documentation #maintenance
[pattern] Include examples where helpful #documentation #usability
[pattern] Keep documentation concise and clear #documentation #quality

## Common Development Tasks

[command] `./scripts/reset.sh` performs interactive database reset with confirmation #database #reset
[command] `npm run db:reset` performs direct database reset #database #reset
[command] `npm run db:status` or `supabase status` checks service status #monitoring #status
[command] `npm run types:generate` generates types after schema changes #types #codegen
[command] `npm run types:watch` watches for changes and auto-regenerates types #types #automation
[command] `supabase db logs` views database logs #monitoring #debugging
[command] `supabase functions logs <function-name>` views edge function logs #monitoring #debugging
[command] `docker compose logs` views all service logs #monitoring #debugging
[command] `supabase db reset --debug` resets database with debug output #debugging #troubleshooting
[command] `npm run db:diff` generates SQL diff of current schema changes #database #comparison

## Troubleshooting

[troubleshooting] Docker not running - verify with `docker info` #docker #diagnostics
[troubleshooting] Port conflicts - stop Supabase and check with `lsof -i :8000` or `lsof -i :54322` #networking #debugging
[troubleshooting] Migration errors - use `supabase db reset --debug` for detailed output #database #debugging
[troubleshooting] Function deployment fails - check logs with `supabase functions logs` #serverless #debugging
[troubleshooting] Type generation fails - ensure Supabase is running first #typescript #dependencies

## Test User Accounts

[testdata] Alice: `00000000-0000-0000-0000-000000000001`, alice@example.com, password: `password123` #testing #credentials
[testdata] Bob: `00000000-0000-0000-0000-000000000002`, bob@example.com, password: `password123` #testing #credentials
[testdata] Charlie: `00000000-0000-0000-0000-000000000003`, charlie@example.com, password: `password123` #testing #credentials
[pattern] Use fixed UUIDs in RLS tests with `SET request.jwt.claim.sub = 'uuid'` #testing #security

## Security Best Practices

[security] Never commit secrets - keep `.env` in `.gitignore` #secrets #git
[security] Use environment variables for API keys #configuration #secrets
[security] Never hardcode credentials in code #security #bestpractice
[security] Use GitHub Secrets for CI/CD credentials #automation #secrets
[security] Enable RLS on all public tables #database #access
[security] Test policies thoroughly before deployment #testing #security
[security] Use service role only in backend code #security #access
[security] Implement principle of least privilege #security #access
[security] Validate all user input in functions #security #validation
[security] Sanitize data before database operations #security #injection
[security] Use parameterized queries to prevent SQL injection #security #database
[security] Implement rate limiting where appropriate #security #protection

## Issue Management

[workflow] Create issues using structured templates at GitHub #issue #tracking
[template] Bug Report template for issues and unexpected behavior #issue #bug
[template] Feature Request template for suggesting new features #issue #enhancement
[template] DevOps Task template for infrastructure and CI/CD work #issue #devops
[template] Database Task template for schema changes and migrations #issue #database
[pattern] Use clear, descriptive issue titles #documentation #communication
[pattern] Include problem statement, reproduction steps, expected vs actual behavior #documentation #quality
[pattern] Add screenshots or logs when relevant #documentation #visual
[pattern] Define acceptance criteria for issues #documentation #requirements
[pattern] Link related issues or PRs #documentation #traceability

## Communication Guidelines

[pattern] Be respectful and constructive in all interactions #community #culture
[pattern] Welcome newcomers to the project #community #inclusion
[pattern] Focus on what's best for the project #community #collaboration
[pattern] Show empathy towards others #community #culture
[pattern] Accept constructive criticism gracefully #community #growth

## Related Documentation

- [[Project Architecture]] - System architecture overview
- [[Development Workflows]] - Detailed workflow procedures
- [[Row Level Security]] - RLS patterns and policies
- [[Storage Architecture]] - Storage bucket configuration
- [[Edge Functions Architecture]] - Edge function development
- [[PostgreSQL Database]] - Database configuration
- [[CI-CD Pipeline]] - Continuous integration and deployment