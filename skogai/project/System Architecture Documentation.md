---
title: System Architecture Documentation
type: note
permalink: project/system-architecture-documentation
tags:
- architecture
- design
- components
- infrastructure
- system
---

# System Architecture Documentation

Comprehensive overview of system architecture, components, technology stack, and design decisions.

## Technology Stack

[component] PostgreSQL version 17 as primary database #database #postgresql
[component] Supabase latest version as backend platform #platform #supabase
[component] Deno 2.x as edge function runtime #serverless #deno
[component] TypeScript 5.3+ as development language #language #typescript
[component] Auto-generated TypeScript types for type safety #codegen #types
[component] GitHub Actions for CI/CD automation #cicd #automation
[component] Docker Latest for containerization #container #docker

## Core Features

[feature] PostgreSQL v17 with 6 working migrations #database #migration
[feature] 4 Edge Functions using Deno v2 runtime #serverless #functions
[feature] Row Level Security policies tested and working #security #rls
[feature] 3 Storage buckets with RLS policies #storage #files
[feature] Realtime subscriptions via WebSockets #realtime #pubsub
[feature] Complete CI/CD pipeline with automated deployment #automation #deployment

## Client Layer Architecture

[layer] Client Layer supports Web, Mobile, Desktop applications #client #platform
[capability] Any HTTP or WebSocket client can connect #protocol #connectivity
[interface] REST API via PostgREST for HTTP requests #api #rest
[interface] GraphQL API via pg_graphql for graph queries #api #graphql
[interface] Realtime API via WebSocket for live updates #api #websocket

## Supabase Platform Component

[purpose] Unified backend-as-a-service platform #platform #paas
[feature] Auto-generated REST API via PostgREST #automation #rest
[feature] Auto-generated GraphQL API via pg_graphql #automation #graphql
[feature] Built-in authentication supporting email, OAuth, SAML #auth #providers
[feature] Row Level Security enforcement at database layer #security #enforcement
[feature] Realtime subscriptions via WebSockets for live data #realtime #subscription
[feature] Storage service with fine-grained permissions #storage #access
[configuration] Primary config file at `supabase/config.toml` #config #location

## PostgreSQL Database Component

[purpose] Primary data store with advanced SQL features #database #storage
[feature] Full SQL support with standard compliance #database #sql
[feature] ACID transactions for data integrity #database #transactions
[feature] Advanced types: JSON, Arrays, custom types #database #types
[feature] Full-text search capabilities #database #search
[feature] Custom functions and triggers #database #extensibility
[feature] Extensions support like pgvector #database #extensions
[schema] `public` schema for main application data #database #organization
[schema] `auth` schema for user authentication (managed by Supabase) #database #authentication
[schema] `storage` schema for file metadata (managed by Supabase) #database #files
[capability] Custom schemas can be added as needed #database #extensibility

## Edge Functions Component

[purpose] Serverless compute for custom business logic #serverless #compute
[feature] TypeScript and JavaScript support #language #support
[feature] Fast cold starts for quick response #performance #latency
[feature] Built-in security with explicit permissions #security #isolation
[feature] Access to Supabase client for database operations #integration #database
[feature] HTTP and WebSocket support for protocols #protocol #flexibility
[location] Functions stored in `supabase/functions/` directory #filesystem #location

## Storage Service Component

[purpose] File storage with security policies and access control #storage #files
[bucket] avatars bucket for public profile pictures with 5MB limit #storage #public
[bucket] public-assets bucket for public files with 10MB limit #storage #public
[bucket] user-files bucket for private documents with 50MB limit #storage #private
[feature] RLS policies for fine-grained access control #security #access
[feature] Size and MIME type restrictions #validation #constraints
[feature] User-scoped paths for organization #organization #structure
[feature] CDN integration for fast delivery #performance #cdn

## Database Schema Organization

[table] profiles table for user profile data with user_id foreign key #schema #users
[table] posts table for user-generated content with status field #schema #content
[relationship] profiles.user_id references auth.users(id) #schema #foreignkey
[relationship] posts.user_id references auth.users(id) #schema #foreignkey
[field] Common fields: id (PK), created_at, updated_at timestamps #schema #convention
[managed] auth.users table for authentication data #schema #managed
[managed] auth.sessions table for active user sessions #schema #managed
[managed] storage.buckets table for bucket definitions #schema #managed
[managed] storage.objects table for file metadata #schema #managed

## Migration System

[philosophy] Version-controlled schema changes for database evolution #migration #versioning
[format] Migration filename: `YYYYMMDDHHMMSS_description.sql` #migration #naming
[example] `20251005065505_initial_schema.sql` for initial schema #migration #example
[example] `20251006120000_add_posts_table.sql` for new table #migration #example
[example] `20251007093000_enable_rls_posts.sql` for security #migration #example
[workflow] Create migration with `npm run migration:new add_feature` #migration #creation
[workflow] Edit SQL file with schema changes #migration #editing
[workflow] Test locally with `npm run db:reset` #migration #testing
[workflow] Commit migration to git for version control #migration #versioning
[workflow] Deploy via auto-apply on merge to main branch #migration #deployment

## Row Level Security Architecture

[philosophy] Security enforced at database layer, not application #security #architecture
[step] Enable RLS with `ALTER TABLE ENABLE ROW LEVEL SECURITY` #security #sql
[step] Create service role policy for admin full access #security #admin
[step] Create authenticated user policies for own data #security #ownership
[step] Create anonymous policies for published content #security #public
[testing] Test policies with `npm run test:rls` command #security #testing
[pattern] Use USING clause for read access conditions #security #read
[pattern] Use WITH CHECK clause for write validation #security #write

## Index Strategy

[strategy] Index all foreign key columns for join performance #optimization #foreignkeys
[strategy] Index frequently queried columns #optimization #queries
[strategy] Index columns used in WHERE clauses #optimization #filtering
[strategy] Use partial indexes when appropriate for specific conditions #optimization #advanced
[example] Foreign key index: `CREATE INDEX idx_posts_user_id ON posts(user_id)` #sql #index
[example] Compound index: `CREATE INDEX idx_posts_user_status ON posts(user_id, status)` #sql #index
[example] Partial index: `CREATE INDEX idx_posts_published ON posts(status) WHERE status = 'published'` #sql #index

## Edge Functions Runtime

[technology] Deno 2.x runtime for TypeScript and JavaScript #runtime #deno
[feature] Secure by default with explicit permissions #security #sandbox
[feature] Modern JavaScript/TypeScript support #language #modern
[feature] Built-in tooling: test, lint, format #tooling #development
[feature] Web standard APIs for compatibility #standards #web
[feature] Import from URLs for dependencies #dependencies #esm

## Edge Functions Structure

[directory] `supabase/functions/_shared/` for shared utilities #organization #shared
[directory] `supabase/functions/hello-world/` for example function #organization #example
[directory] `supabase/functions/openai-chat/` for OpenAI integration #organization #ai
[directory] `supabase/functions/openrouter-chat/` for multi-model AI #organization #ai
[file] `index.ts` as function entry point #structure #entrypoint
[file] `test.ts` for function tests #structure #testing

## Edge Function Lifecycle

[step] Request arrives as HTTP request to function endpoint #lifecycle #request
[step] Authentication validates JWT token if required #lifecycle #auth
[step] Processing executes function business logic #lifecycle #processing
[step] Response returns HTTP response with appropriate status #lifecycle #response
[config] Environment variables accessed via `Deno.env.get()` #configuration #env
[config] Secrets configured in Supabase Dashboard → Edge Functions → Secrets #configuration #secrets

## Storage Bucket Configuration

[public] avatars bucket for profile pictures - 5MB limit, images only #storage #configuration
[public] public-assets bucket for general assets - 10MB limit, images/PDFs #storage #configuration
[private] user-files bucket for documents - 50MB limit, authenticated only #storage #configuration
[convention] Path structure: `{bucket}/{user_id}/filename.ext` #storage #pattern
[example] Avatar path: `avatars/550e8400-e29b-41d4-a716-446655440000/profile.jpg` #storage #example
[example] Document path: `user-files/550e8400-e29b-41d4-a716-446655440000/document.pdf` #storage #example

## Storage Security Policies

[pattern] Public read, authenticated write for own files #storage #security
[pattern] Extract user ID from path with `storage.foldername(name)[1]` #storage #helper
[pattern] Compare extracted ID with `auth.uid()` for ownership #storage #validation
[example] Public read policy: `FOR SELECT USING (bucket_id = 'avatars')` #sql #policy
[example] User upload policy: `FOR INSERT TO authenticated WITH CHECK (auth.uid()::text = (storage.foldername(name))[1])` #sql #policy

## Authentication Methods

[supported] Email/Password authentication #auth #method
[supported] Magic Links for passwordless auth #auth #method
[supported] OAuth Providers like Google, GitHub #auth #method
[supported] SAML SSO with ZITADEL integration available #auth #method

## Authorization Model - Three Roles

[role] anon for unauthenticated users with read-only public access #auth #role
[role] authenticated for logged-in users with own data access #auth #role
[role] service_role for backend services with full database access #auth #role
[security] anon users limited by RLS policies for public data #security #restriction
[security] authenticated users enforced by RLS for owned data #security #enforcement
[security] service_role bypasses RLS - NEVER use client-side #security #warning

## JWT Token Flow

[flow] User authenticates to Supabase Auth service #auth #step
[flow] Supabase issues JWT token with claims #auth #step
[flow] Client includes token in request headers #auth #step
[flow] PostgREST validates JWT token signature #auth #step
[flow] PostgreSQL RLS uses token claims for filtering #auth #step
[flow] Data filtered per user based on policies #auth #step

## CI/CD Workflow Triggers

[trigger] Push to main/master runs deploy.yml for production #cicd #trigger
[trigger] Pull Request runs pr-checks.yml and validations #cicd #trigger
[trigger] Migration changes run migrations-validation.yml #cicd #trigger
[trigger] Function changes run edge-functions-test.yml #cicd #trigger
[trigger] Daily schedule runs backup.yml #cicd #trigger
[trigger] Weekly schedule runs performance-test.yml #cicd #trigger
[trigger] Weekly schedule runs dependency-updates.yml #cicd #trigger

## Deployment Pipeline Flow

[step] Developer commits to feature branch #cicd #development
[step] Opens Pull Request to main branch #cicd #pr
[step] CI runs automated checks: lint SQL/TypeScript, tests, security scan #cicd #validation
[step] Code review by maintainers #cicd #review
[step] PR approved and merged to main #cicd #merge
[step] Deployment workflow applies migrations #cicd #deployment
[step] Deployment workflow deploys edge functions #cicd #deployment
[step] Deployment workflow updates types #cicd #deployment
[step] Deployment workflow verifies deployment #cicd #verification
[step] Production environment updated #cicd #production

## Environment Secrets

[required] SUPABASE_ACCESS_TOKEN for CLI authentication #cicd #secrets
[required] SUPABASE_PROJECT_ID for target project identification #cicd #secrets
[required] SUPABASE_DB_PASSWORD for database access #cicd #secrets
[reference] See DEVOPS.md for complete configuration details #documentation #reference

## Local Development Ports

[service] Studio UI on port 8000 at http://localhost:8000 #local #ui
[service] API (REST/GraphQL) on port 8000 at http://localhost:8000 #local #api
[service] Database on port 54322 with connection string #local #database
[service] Edge Functions on port 54321 at http://localhost:54321/functions/v1/ #local #functions

## Local Development Tools

[script] `scripts/setup.sh` for initial setup automation #tooling #setup
[script] `scripts/dev-start.sh` for starting services #tooling #startup
[script] `scripts/reset.sh` for resetting database #tooling #reset
[command] `npm run db:start` starts Supabase locally #command #database
[command] `npm run db:stop` stops all services #command #database
[command] `npm run db:reset` resets database with migrations #command #database
[command] `npm run migration:new` creates new migration #command #database
[command] `npm run types:generate` generates TypeScript types #command #codegen
[command] `npm run functions:serve` tests functions locally #command #functions

## Docker Container Stack

[container] supabase_db for PostgreSQL database #docker #database
[container] supabase_studio for Admin UI interface #docker #ui
[container] supabase_kong for API gateway routing #docker #gateway
[container] supabase_auth for GoTrue authentication service #docker #auth
[container] supabase_rest for PostgREST API generation #docker #api
[container] supabase_realtime for realtime subscription service #docker #realtime
[container] supabase_storage for file storage service #docker #storage
[container] supabase_imgproxy for image transformation #docker #media
[container] supabase_edge_runtime for Deno functions execution #docker #serverless
[management] Supabase CLI manages all containers automatically #tooling #orchestration

## Production Infrastructure

[hosting] Supabase Cloud Platform for managed hosting #production #platform
[configuration] Regions configurable per project deployment #production #geography
[resource] Database with automated backups for disaster recovery #production #backup
[resource] CDN for static asset delivery #production #performance
[resource] Global edge network for low latency #production #distribution
[resource] DDoS protection for security #production #security

## Database Scaling Strategy

[strategy] Vertical scaling by upgrading instance size #scaling #database
[strategy] Connection pooling via Supavisor for efficiency #scaling #pooling
[strategy] Read replicas for high-traffic scenarios #scaling #replication

## Edge Functions Scaling

[capability] Auto-scaling based on demand #scaling #serverless
[capability] Global distribution across regions #scaling #geography
[optimization] Cold start optimization for fast response #scaling #performance

## Storage Scaling

[capability] CDN caching for static files #scaling #performance
[capability] Multi-region replication for enterprise #scaling #availability

## Design Decision: Why Supabase

[pro] Rapid development with auto-generated APIs #decision #velocity
[pro] Built-in authentication and authorization #decision #feature
[pro] Real-time subscriptions out of the box #decision #feature
[pro] PostgreSQL with full SQL support #decision #database
[pro] Serverless edge functions for flexibility #decision #serverless
[pro] Open source with self-hosting option #decision #vendor
[tradeoff] Platform lock-in mitigated by PostgreSQL standard #decision #risk
[tradeoff] Less control than custom backend #decision #tradeoff
[tradeoff] Learning curve for RLS policies #decision #complexity

## Design Decision: Why PostgreSQL

[pro] Mature and reliable database system #decision #stability
[pro] Rich feature set: JSON, full-text search, extensions #decision #features
[pro] Strong consistency with ACID guarantees #decision #integrity
[pro] Extensible with custom functions, types, extensions #decision #flexibility
[pro] Large ecosystem and active community #decision #support
[tradeoff] Vertical scaling primary strategy #decision #scaling
[tradeoff] More complex than NoSQL for some use cases #decision #complexity

## Design Decision: Why Deno for Edge Functions

[pro] Secure by default with explicit permissions #decision #security
[pro] Modern JavaScript/TypeScript support #decision #language
[pro] Fast cold starts for serverless #decision #performance
[pro] Built-in tooling reduces dependencies #decision #tooling
[pro] Web standard APIs for compatibility #decision #standards
[tradeoff] Smaller ecosystem than Node.js #decision #ecosystem
[tradeoff] Some npm packages incompatible #decision #compatibility
[tradeoff] Newer technology with less maturity #decision #risk

## Design Decision: Why Row Level Security

[pro] Security at database layer cannot be bypassed #decision #security
[pro] Single source of truth for access control #decision #centralization
[pro] Works with any client: REST, GraphQL, direct SQL #decision #universality
[pro] Centralized security logic reduces duplication #decision #maintainability
[tradeoff] Learning curve for developers #decision #complexity
[tradeoff] Testing complexity requires specialized tools #decision #testing
[tradeoff] Performance overhead minimal but present #decision #performance

## Design Decision: Why TypeScript

[pro] Type safety prevents runtime errors #decision #quality
[pro] Better IDE support with autocomplete #decision #dx
[pro] Fewer runtime errors in production #decision #reliability
[pro] Auto-generated from schema for accuracy #decision #automation
[pro] Excellent refactoring tools #decision #maintainability
[tradeoff] Build step required for compilation #decision #complexity
[tradeoff] More verbose than JavaScript #decision #verbosity
[tradeoff] Learning curve for beginners #decision #learning

## Architecture Balance

[balance] Developer Experience with fast development and automated tooling #design #dx
[balance] Security with multiple layers of protection #design #security
[balance] Scalability that grows with application needs #design #growth
[balance] Maintainability with clear patterns and structure #design #maintenance
[balance] Performance optimized for common use cases #design #performance

## Related Documentation

- [[Project Architecture]] - High-level architecture overview
- [[PostgreSQL Database]] - Database configuration details
- [[Edge Functions Architecture]] - Serverless functions guide
- [[Row Level Security]] - Security policy patterns
- [[Storage Architecture]] - File storage configuration
- [[CI-CD Pipeline]] - Deployment automation
- [[Development Workflows]] - Development procedures
- [[Contributing Guide]] - Contribution guidelines