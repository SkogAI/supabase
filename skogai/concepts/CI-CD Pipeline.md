---
title: CI/CD Pipeline
type: note
permalink: concepts/ci-cd-pipeline
tags:
- cicd
- automation
- github-actions
- deployment
---

# CI/CD Pipeline

## Overview

Comprehensive automated testing and deployment pipeline using GitHub Actions for continuous integration and delivery.

## Workflow Triggers

- [trigger] Push to main/master → deploy.yml (production deployment)
- [trigger] Pull requests → pr-checks.yml, migrations-validation.yml
- [trigger] Migration changes → type-generation.yml
- [trigger] Function changes → edge-functions-test.yml
- [trigger] All pushes → security-scan.yml
- [trigger] Daily schedule → backup.yml
- [trigger] Weekly schedule → performance-test.yml, dependency-updates.yml

## Core Workflows

- [workflow] **deploy.yml** - Deploy migrations and functions to production
- [workflow] **pr-checks.yml** - Validate PRs, check for secrets
- [workflow] **migrations-validation.yml** - Test migrations in isolation
- [workflow] **edge-functions-test.yml** - Lint, type-check, test functions
- [workflow] **schema-lint.yml** - Check for SQL anti-patterns
- [workflow] **security-scan.yml** - Scan for vulnerabilities
- [workflow] **type-generation.yml** - Generate TypeScript types
- [workflow] **performance-test.yml** - Run performance benchmarks
- [workflow] **backup.yml** - Create database backups

## Required Secrets

- [secret] SUPABASE_ACCESS_TOKEN - CLI authentication
- [secret] SUPABASE_PROJECT_ID - Target project identifier
- [secret] SUPABASE_DB_PASSWORD - Database access credential
- [secret] CLAUDE_CODE_OAUTH_TOKEN - (Optional) AI-powered PR analysis

## Deployment Flow

- [flow] Developer commits to feature branch
- [flow] Opens Pull Request to main
- [flow] Automated checks run (lint, test, security)
- [flow] Code review by maintainers
- [flow] PR approved and merged
- [flow] Deployment workflow executes
- [flow] Migrations applied to production
- [flow] Edge functions deployed
- [flow] Types regenerated and committed
- [flow] Production verification

## Testing Strategy

- [testing] RLS policy tests via `npm run test:rls`
- [testing] Storage policy tests via SQL suite
- [testing] Edge function unit tests with Deno.test()
- [testing] Migration validation in isolated environment
- [testing] SQL syntax validation with sqlfluff
- [testing] Security scanning with automated tools

## Quality Gates

- [gate] All tests must pass
- [gate] No security vulnerabilities
- [gate] No secrets in code
- [gate] SQL syntax valid
- [gate] TypeScript types generated successfully
- [gate] Code review approval required

## Automation Features

- [automation] Automatic type generation on schema changes
- [automation] Dependency updates via Dependabot
- [automation] Security scanning on every push
- [automation] Daily database backups
- [automation] PR conflict detection and notification

## Best Practices

- [best-practice] Run tests locally before pushing
- [best-practice] Keep secrets in GitHub Secrets, never in code
- [best-practice] Review CI logs when builds fail
- [best-practice] Test migrations locally with `db:reset`
- [best-practice] Keep workflows fast (<5 minutes)
- [best-practice] Use workflow concurrency limits

## Relations

- part_of [[Project Architecture]]
- part_of [[Supabase Project Overview]]
- tests [[Row Level Security]]
- tests [[Edge Functions Architecture]]
- tests [[Database Schema Organization]]
- deploys_to [[Production Environment]]
- documented_in [[DEVOPS.md]]
- documented_in [[CI_WORKTREE_INTEGRATION.md]]
