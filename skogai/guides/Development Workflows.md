---
title: Development Workflows
type: note
permalink: guides/development-workflows
tags:
- workflow
- development
- procedures
- stepbystep
- commands
---

# Development Workflows

Detailed step-by-step procedures for common development tasks in the Supabase project.

## Initial Setup Workflow (Automated)

[workflow] Clone repository with `git clone https://github.com/SkogAI/supabase.git && cd supabase` #git #setup
[workflow] Run automated setup script `./scripts/setup.sh` #automation #initialization
[step] Automated setup checks prerequisites (Docker, Supabase CLI, Node.js, Deno) #validation #dependencies
[step] Automated setup creates `.env` file from template #configuration #environment
[step] Automated setup installs npm dependencies #nodejs #packages
[step] Automated setup starts Supabase services #database #startup
[step] Automated setup generates TypeScript types #codegen #types
[step] Automated setup displays access URLs for Studio and API #information #urls
[workflow] Verify setup by opening Studio at http://localhost:8000 #validation #ui
[workflow] Check services with `supabase status` #monitoring #validation
[workflow] Review seed data in Studio interface #testing #data
[timeframe] Automated setup takes 5-10 minutes to complete #performance #timing

## Initial Setup Workflow (Manual)

[workflow] Check prerequisites with version commands #validation #dependencies
[command] `docker --version` checks Docker installation #docker #verification
[command] `supabase --version` checks Supabase CLI installation #supabase #verification
[command] `node --version` checks Node.js installation #nodejs #verification
[command] `deno --version` checks Deno installation #deno #verification
[workflow] Install dependencies with `npm install` #nodejs #setup
[workflow] Create environment file with `cp .env.example .env` #configuration #setup
[workflow] Start Supabase with `npm run db:start` or `./scripts/dev-start.sh` #database #startup
[workflow] Generate types with `npm run types:generate` #codegen #types
[timeframe] Manual setup takes 10-15 minutes to complete #performance #timing

## Daily Development Workflow - Starting Work

[workflow] Pull latest changes with `git checkout develop && git pull origin develop` #git #sync
[workflow] Start services with `./scripts/dev-start.sh` or `npm run db:start` #startup #services
[workflow] Verify everything works with `supabase status` #validation #monitoring
[requirement] All services should show "healthy" status #health #requirement
[workflow] Create or switch to feature branch with `git checkout -b feature/my-feature` #git #branching

## Daily Development Workflow - During Development

[workflow] Make code changes and save frequently in IDE #development #iteration
[workflow] Test locally after changes (db: test:rls, functions: functions:serve) #testing #validation
[workflow] Manual testing in Studio for database changes #testing #ui
[workflow] Commit frequently with `git add . && git commit -m "WIP: message"` #git #versioning
[workflow] Generate types if schema changed with `npm run types:generate` #codegen #automation
[pattern] Iterative cycle of edit → test → commit #development #iteration

## Daily Development Workflow - Ending Work

[workflow] Commit final changes with descriptive message #git #versioning
[workflow] Push to remote with `git push origin feature/my-feature` #git #sync
[workflow] Stop services optionally with `supabase stop` #cleanup #services

## Database Development - Adding New Table

[workflow] Create migration with `npm run migration:new add_my_table` #database #migration
[location] Edit migration file at `supabase/migrations/YYYYMMDDHHMMSS_add_my_table.sql` #filesystem #sql
[pattern] Create table with UUID primary key and user_id foreign key #schema #design
[pattern] Add index on user_id for query performance #optimization #indexing
[pattern] Enable RLS with `ALTER TABLE table ENABLE ROW LEVEL SECURITY` #security #rls
[pattern] Create service role policy with full access #security #policy
[pattern] Create authenticated user policies for viewing and managing own data #security #policy
[pattern] Create anonymous user policy for published content #security #policy
[pattern] Add updated_at trigger using `update_updated_at_column()` function #automation #trigger
[pattern] Enable realtime with `ALTER PUBLICATION supabase_realtime ADD TABLE` #realtime #pubsub
[pattern] Set replica identity with `ALTER TABLE REPLICA IDENTITY FULL` #realtime #replication
[workflow] Apply migration with `npm run db:reset` #database #execution
[workflow] Test RLS policies with `npm run test:rls` #testing #security
[workflow] Generate TypeScript types with `npm run types:generate` #codegen #types
[workflow] Commit migration and types with `git add supabase/migrations/ types/database.ts` #git #versioning
[timeframe] Adding new table takes 15-30 minutes #performance #estimate

## Database Development - Modifying Existing Table

[workflow] Create migration with `npm run migration:new update_my_table_add_column` #database #migration
[pattern] Add column with `ALTER TABLE table ADD COLUMN column_name TYPE` #sql #schema
[pattern] Add index if needed with `CREATE INDEX idx_table_column ON table(column)` #optimization #indexing
[pattern] Update existing data with `UPDATE table SET column = 'value'` #sql #datamigration
[workflow] Test migration with `npm run db:reset` #testing #validation
[workflow] Update types with `npm run types:generate` #codegen #types
[workflow] Commit changes with `git add supabase/migrations/ types/` #git #versioning
[timeframe] Modifying table takes 10-20 minutes #performance #estimate

## Database Development - Testing Database Changes

[workflow] Reset database with `./scripts/reset.sh` or `npm run db:reset` #database #testing
[workflow] Run RLS tests with `npm run test:rls` #security #testing
[workflow] Manual testing in Studio - open http://localhost:8000 #testing #ui
[workflow] Navigate to Table Editor to verify table structure #validation #schema
[workflow] Insert test data to verify constraints and triggers #testing #data
[workflow] Verify RLS prevents unauthorized access #security #validation
[pattern] Test with different users using `SET request.jwt.claim.sub = 'uuid'` #testing #simulation
[testdata] Test as Alice with UUID `00000000-0000-0000-0000-000000000001` #testing #user
[testdata] Test as Bob with UUID `00000000-0000-0000-0000-000000000002` #testing #user
[timeframe] Testing database changes takes 10-15 minutes #performance #estimate

## Edge Function Development - Creating New Function

[workflow] Create function with `npm run functions:new my-function` #serverless #creation
[location] Edit function code at `supabase/functions/my-function/index.ts` #filesystem #typescript
[pattern] Import serve from Deno std library #deno #import
[pattern] Import createClient from @supabase/supabase-js #supabase #client
[pattern] Define CORS headers for browser access #security #cors
[pattern] Handle CORS preflight with OPTIONS method check #http #cors
[pattern] Initialize Supabase client with environment variables #initialization #config
[pattern] Get Authorization header from request #authentication #security
[pattern] Parse JSON request body with error handling #parsing #errorhandling
[pattern] Process request with business logic #processing #logic
[pattern] Return JSON response with appropriate headers #http #response
[pattern] Catch errors and return 500 status with error message #errorhandling #http
[workflow] Test function locally with `supabase functions serve my-function` #testing #local
[workflow] Test with curl at `http://localhost:54321/functions/v1/my-function` #testing #http
[location] Write tests at `supabase/functions/my-function/test.ts` #testing #unittest
[workflow] Run tests with `cd supabase/functions/my-function && deno test --allow-all test.ts` #testing #execution
[workflow] Commit function with `git add supabase/functions/my-function/` #git #versioning
[timeframe] Creating new function takes 30-45 minutes #performance #estimate

## Edge Function Development - Updating Existing Function

[workflow] Edit function code in editor #development #editing
[workflow] Test locally with `supabase functions serve my-function` #testing #local
[workflow] Run tests with `cd supabase/functions/my-function && deno test --allow-all test.ts` #testing #validation
[workflow] Commit changes with descriptive message #git #versioning
[timeframe] Updating function takes 15-30 minutes #performance #estimate

## Testing Workflow - Running All Tests

[workflow] Start Supabase with `npm run db:start` #startup #services
[workflow] Test database/RLS with `npm run test:rls` #testing #security
[expectation] All RLS tests should pass with ✅ status #validation #success
[workflow] Test edge functions with `npm run test:functions` #testing #serverless
[expectation] All function tests should pass with ✅ status #validation #success
[workflow] Lint SQL with `npm run lint:sql` #linting #validation
[workflow] Lint functions with `npm run lint:functions` #linting #quality
[workflow] Format functions with `npm run format:functions` #formatting #quality
[workflow] Generate types with `npm run types:generate` #codegen #validation
[expectation] Type generation should complete with no errors #validation #success
[timeframe] Running all tests takes 5-10 minutes #performance #estimate

## Testing Workflow - Testing in Isolation

[workflow] Test database/RLS with `npm run db:reset && npm run test:rls` #testing #database
[workflow] Test single function with `supabase functions serve my-function` #testing #serverless
[workflow] Test storage with `supabase db execute --file tests/storage_test_suite.sql` #testing #storage

## Pull Request Workflow - Preparing Pull Request

[workflow] Ensure branch is up to date by merging develop #git #sync
[command] `git checkout develop && git pull origin develop` pulls latest main branch #git #update
[command] `git checkout feature/my-feature && git merge develop` merges changes into feature #git #merge
[workflow] Run all tests to ensure quality #testing #validation
[workflow] Generate/update types with `npm run types:generate` #codegen #types
[workflow] Review changes with `git diff develop` #git #review
[workflow] Clean up commits optionally with `git rebase -i develop` #git #cleanup
[workflow] Push to remote with `git push origin feature/my-feature` #git #sync
[timeframe] Preparing PR takes 10-15 minutes #performance #estimate

## Pull Request Workflow - Creating Pull Request

[workflow] Go to GitHub repository at https://github.com/SkogAI/supabase #github #web
[workflow] Click "New Pull Request" button #github #ui
[workflow] Select base branch (develop) and compare branch (feature/my-feature) #github #branching
[requirement] Fill PR description with summary, changes, testing, related issues #documentation #quality
[section] Description section provides brief overview of changes #documentation #structure
[section] Changes Made section lists specific modifications #documentation #structure
[section] Testing section with checklist of completed tests #documentation #validation
[section] Related Issues section links to issue numbers #documentation #traceability
[section] Screenshots section for UI changes #documentation #visual
[section] Deployment Notes section for production considerations #documentation #deployment
[workflow] Create Pull Request to submit for review #github #submission
[workflow] Wait for CI checks to complete #automation #validation
[workflow] Fix any failures in CI checks #debugging #quality
[workflow] Request review from maintainers #collaboration #review
[workflow] Tag reviewers for faster response #communication #collaboration
[workflow] Respond to feedback promptly #communication #collaboration
[timeframe] Creating PR takes 10-20 minutes #performance #estimate

## Pull Request Workflow - Addressing Review Feedback

[workflow] Read review comments carefully to understand requested changes #review #communication
[workflow] Ask questions if feedback is unclear #communication #clarification
[workflow] Make changes to address feedback #development #iteration
[workflow] Push updates with `git push origin feature/my-feature` #git #sync
[workflow] Reply to comments explaining changes made #communication #documentation
[workflow] Mark resolved comments as done #github #organization
[workflow] Wait for re-review from maintainers #collaboration #validation
[timeframe] Addressing feedback is variable depending on complexity #performance #variable

## Deployment Workflow - Automatic Deployment

[workflow] PR merged to develop or main triggers GitHub Actions #automation #cicd
[workflow] Deployment workflow applies migrations to production #database #deployment
[workflow] Deployment workflow deploys edge functions #serverless #deployment
[workflow] Deployment workflow generates types #codegen #automation
[workflow] Deployment workflow verifies successful deployment #validation #monitoring
[monitoring] Watch GitHub Actions tab for workflow progress #cicd #tracking
[monitoring] Check workflow logs for errors or issues #debugging #logs
[monitoring] Verify deployment in Supabase Dashboard #validation #ui

## Deployment Workflow - Manual Deployment

[workflow] Login to Supabase with `supabase login` #authentication #cli
[workflow] Link project with `supabase link --project-ref YOUR_PROJECT_ID` #configuration #cli
[workflow] Deploy migrations with `supabase db push` #database #deployment
[workflow] Deploy all functions with `supabase functions deploy` #serverless #deployment
[workflow] Deploy specific function with `supabase functions deploy my-function` #serverless #deployment
[workflow] Verify deployment by checking Supabase Dashboard #validation #monitoring
[workflow] Test production endpoints for functionality #testing #validation
[workflow] Monitor logs for errors #monitoring #debugging
[timeframe] Manual deployment takes 10-15 minutes #performance #estimate

## Maintenance Workflow - Weekly

[checklist] Review open issues for updates #maintenance #tracking
[checklist] Check CI/CD status for failures #monitoring #automation
[checklist] Review dependency updates for security #security #updates
[checklist] Check database performance metrics #monitoring #performance
[checklist] Review error logs for issues #debugging #monitoring
[checklist] Update documentation for accuracy #documentation #maintenance

## Maintenance Workflow - Monthly

[checklist] Backup production database #backup #disaster-recovery
[checklist] Review and archive old branches #cleanup #git
[checklist] Update dependencies to latest versions #maintenance #updates
[checklist] Security audit of code and dependencies #security #audit
[checklist] Performance review of database and functions #optimization #monitoring
[checklist] Documentation review for completeness #documentation #quality

## Maintenance Workflow - Updating Dependencies

[workflow] Check for updates with `npm outdated` #nodejs #packages
[workflow] Update packages with `npm update` #nodejs #maintenance
[workflow] Test everything after updates #testing #validation
[workflow] Commit updates with package.json and package-lock.json #git #versioning
[timeframe] Updating dependencies takes 15-30 minutes #performance #estimate

## Maintenance Workflow - Database Backup

[workflow] Export schema with `supabase db dump -f backup-schema.sql --schema public` #backup #schema
[workflow] Export data with `supabase db dump -f backup-data.sql --data-only` #backup #data
[workflow] Store backups securely with encryption for sensitive data #security #storage
[workflow] Document backup date and location #documentation #tracking
[timeframe] Database backup takes 5-10 minutes #performance #estimate

## Quick Reference Commands

[sequence] Start fresh: `supabase stop && supabase start && npm run db:reset && npm run types:generate` #startup #reset
[sequence] New feature setup: `git checkout develop && git pull origin develop && git checkout -b feature/my-feature && npm run db:start` #git #development
[sequence] Pre-PR checklist: `npm run test:rls && npm run test:functions && npm run lint:sql && npm run lint:functions && npm run types:generate && git push origin feature/my-feature` #testing #validation

## Related Documentation

- [[Contributing Guide]] - Contribution guidelines and best practices
- [[Project Architecture]] - System architecture overview
- [[Row Level Security]] - RLS policy patterns
- [[Edge Functions Architecture]] - Edge function development guide
- [[PostgreSQL Database]] - Database configuration
- [[CI-CD Pipeline]] - Continuous integration and deployment