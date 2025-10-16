# System Architecture

This document provides a comprehensive overview of the system architecture, components, and design decisions.

## Table of Contents

- [Overview](#overview)
- [High-Level Architecture](#high-level-architecture)
- [Core Components](#core-components)
- [Database Architecture](#database-architecture)
- [Edge Functions Architecture](#edge-functions-architecture)
- [Storage Architecture](#storage-architecture)
- [Authentication & Authorization](#authentication--authorization)
- [CI/CD Pipeline](#cicd-pipeline)
- [Local Development](#local-development)
- [Production Environment](#production-environment)
- [Design Decisions](#design-decisions)

## Overview

This project is a production-ready Supabase backend featuring:

- **PostgreSQL Database** - Version 17 with full SQL support
- **Row Level Security (RLS)** - Fine-grained access control
- **Edge Functions** - Serverless functions using Deno
- **Storage Buckets** - File storage with RLS policies
- **Realtime Subscriptions** - Live data updates
- **Complete CI/CD** - Automated testing and deployment

### Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Database | PostgreSQL | 17 |
| Backend | Supabase | Latest |
| Edge Runtime | Deno | 2.x |
| Language | TypeScript | 5.3+ |
| Type Safety | TypeScript types | Auto-generated |
| CI/CD | GitHub Actions | - |
| Container | Docker | Latest |

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│  (Web, Mobile, Desktop - Any HTTP/WebSocket client)         │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     Supabase API Layer                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │  REST API    │ │  GraphQL     │ │  Realtime    │        │
│  │  (PostgREST) │ │  (pg_graphql)│ │  (Realtime)  │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
└─────────────────────────┬───────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Storage    │  │  PostgreSQL  │  │    Edge      │
│   Buckets    │  │   Database   │  │  Functions   │
│              │  │              │  │   (Deno)     │
│  - avatars   │  │ - Schemas    │  │              │
│  - assets    │  │ - Tables     │  │ - hello-world│
│  - files     │  │ - RLS        │  │ - openai     │
│              │  │ - Migrations │  │ - openrouter │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │   Data Layer     │
                │  (Persistent)    │
                └──────────────────┘
```

## Core Components

### 1. Supabase Platform

**Purpose:** Unified backend-as-a-service platform

**Key Features:**
- Auto-generated REST API via PostgREST
- Auto-generated GraphQL API via pg_graphql
- Built-in authentication (email, OAuth, SAML)
- Row Level Security enforcement
- Realtime subscriptions via WebSockets
- Storage with fine-grained permissions

**Configuration:** `supabase/config.toml`

### 2. PostgreSQL Database

**Purpose:** Primary data store with advanced features

**Key Features:**
- Full SQL support
- ACID transactions
- Advanced types (JSON, Arrays, etc.)
- Full-text search
- Custom functions and triggers
- Extensions (pgvector, etc.)

**Organization:**
- `public` schema - Main application data
- `auth` schema - User authentication (managed by Supabase)
- `storage` schema - File metadata (managed by Supabase)
- Custom schemas as needed

### 3. Edge Functions (Deno)

**Purpose:** Serverless compute for custom logic

**Key Features:**
- TypeScript/JavaScript support
- Fast cold starts
- Built-in security
- Access to Supabase client
- HTTP/WebSocket support

**Location:** `supabase/functions/`

### 4. Storage Service

**Purpose:** File storage with security policies

**Pre-configured Buckets:**
- `avatars` - Public profile pictures (5MB limit)
- `public-assets` - Public files (10MB limit)
- `user-files` - Private user documents (50MB limit)

**Features:**
- RLS policies for access control
- Size and type restrictions
- User-scoped paths
- CDN integration

## Database Architecture

### Schema Organization

```
public schema
├── profiles          # User profiles
│   ├── id (PK)
│   ├── user_id (FK → auth.users)
│   ├── display_name
│   ├── avatar_url
│   └── timestamps
├── posts            # User-generated content
│   ├── id (PK)
│   ├── user_id (FK → auth.users)
│   ├── title
│   ├── content
│   ├── status (draft/published)
│   └── timestamps
└── [other tables]

auth schema (managed)
├── users            # Authentication data
├── sessions         # Active sessions
└── [other tables]

storage schema (managed)
├── buckets          # Storage bucket definitions
└── objects          # File metadata
```

### Migration System

**Philosophy:** Version-controlled schema changes

**File Format:** `YYYYMMDDHHMMSS_description.sql`

**Example:**
```
20251005065505_initial_schema.sql
20251006120000_add_posts_table.sql
20251007093000_enable_rls_posts.sql
```

**Process:**
1. Create migration: `npm run migration:new add_feature`
2. Edit SQL file
3. Test locally: `npm run db:reset`
4. Commit to git
5. Deploy: Auto-applies on merge to main

### Row Level Security (RLS)

**Philosophy:** Security at the database layer

**Policy Structure:**
```sql
-- 1. Enable RLS
ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;

-- 2. Service role (admin)
CREATE POLICY "Service role full access" ON public.my_table
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- 3. Authenticated users
CREATE POLICY "Users manage own data" ON public.my_table
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4. Anonymous users (if applicable)
CREATE POLICY "Anonymous read published" ON public.my_table
    FOR SELECT TO anon USING (status = 'published');
```

**Testing:** `npm run test:rls`

### Indexes & Performance

**Strategy:**
- Index foreign keys
- Index frequently queried columns
- Index columns used in WHERE clauses
- Use partial indexes when appropriate

**Example:**
```sql
-- Foreign key index
CREATE INDEX idx_posts_user_id ON public.posts(user_id);

-- Compound index for common queries
CREATE INDEX idx_posts_user_status ON public.posts(user_id, status);

-- Partial index for published posts
CREATE INDEX idx_posts_published ON public.posts(status) 
    WHERE status = 'published';
```

## Edge Functions Architecture

### Runtime Environment

**Technology:** Deno 2.x (TypeScript/JavaScript)

**Features:**
- Secure by default (explicit permissions)
- Modern JavaScript/TypeScript support
- Built-in tooling (test, lint, format)
- Web standard APIs
- Import from URLs

### Function Structure

```
supabase/functions/
├── _shared/              # Shared utilities
│   ├── cors.ts
│   ├── supabase.ts
│   └── utils.ts
├── hello-world/          # Example function
│   ├── index.ts          # Entry point
│   └── test.ts           # Tests
├── openai-chat/          # OpenAI integration
│   ├── index.ts
│   └── test.ts
└── openrouter-chat/      # Multi-model AI
    ├── index.ts
    └── test.ts
```

### Function Lifecycle

1. **Request** - HTTP request to function endpoint
2. **Authentication** - JWT token validation (if required)
3. **Processing** - Function business logic
4. **Response** - HTTP response with appropriate status

### Environment Variables

Functions access secrets via `Deno.env.get()`:

```typescript
const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
const supabaseUrl = Deno.env.get('SUPABASE_URL');
```

**Configuration:** Set in Supabase Dashboard → Edge Functions → Secrets

## Storage Architecture

### Bucket Configuration

**Public Buckets:**
- `avatars` - Profile pictures (5MB, images only)
- `public-assets` - General assets (10MB, images/PDFs)

**Private Buckets:**
- `user-files` - User documents (50MB, authenticated only)

### Path Structure

**Convention:** `{bucket}/{user_id}/filename.ext`

**Example:**
```
avatars/550e8400-e29b-41d4-a716-446655440000/profile.jpg
user-files/550e8400-e29b-41d4-a716-446655440000/document.pdf
```

### Security Policies

Storage buckets use RLS policies similar to tables:

```sql
-- Public read, authenticated write (own files)
CREATE POLICY "Public read access" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users upload own files" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## Authentication & Authorization

### Authentication Methods

Supported by Supabase:
- Email/Password
- Magic Links
- OAuth Providers (Google, GitHub, etc.)
- SAML SSO (ZITADEL integration available)

### Authorization Model

**Three Roles:**

1. **anon** - Unauthenticated users
   - Read-only access to public data
   - Limited by RLS policies

2. **authenticated** - Logged-in users
   - Read/write own data
   - Read public data
   - Enforced by RLS policies

3. **service_role** - Backend services
   - Full database access
   - Bypasses RLS
   - NEVER use client-side

### JWT Token Flow

```
1. User authenticates → Supabase Auth
2. Supabase issues JWT token
3. Client includes token in requests
4. PostgREST validates token
5. PostgreSQL RLS uses token claims
6. Data filtered per user
```

## CI/CD Pipeline

### Workflow Triggers

| Event | Workflows |
|-------|-----------|
| Push to main/master | deploy.yml (deploy to production) |
| Pull Request | pr-checks.yml, migrations-validation.yml, edge-functions-test.yml |
| Migration changes | migrations-validation.yml, type-generation.yml |
| Function changes | edge-functions-test.yml |
| Schedule (daily) | backup.yml |
| Schedule (weekly) | performance-test.yml, dependency-updates.yml |

### Deployment Pipeline

```
1. Developer commits to feature branch
2. Opens Pull Request to main
3. CI runs automated checks:
   - Lint SQL and TypeScript
   - Run tests (RLS, functions)
   - Security scan
   - Secret detection
4. Code review by maintainers
5. PR approved and merged
6. Deployment workflow runs:
   - Apply migrations
   - Deploy edge functions
   - Update types
   - Verify deployment
7. Production updated
```

### Environment Secrets

Required in GitHub Actions:
- `SUPABASE_ACCESS_TOKEN` - CLI authentication
- `SUPABASE_PROJECT_ID` - Target project
- `SUPABASE_DB_PASSWORD` - Database access

See [DEVOPS.md](DEVOPS.md) for details.

## Local Development

### Service Ports

| Service | Port | URL |
|---------|------|-----|
| Studio UI | 8000 | http://localhost:8000 |
| API (REST/GraphQL) | 8000 | http://localhost:8000 |
| Database | 54322 | postgresql://postgres:postgres@localhost:54322/postgres |
| Edge Functions | 54321 | http://localhost:54321/functions/v1/ |

### Development Tools

**Scripts:**
- `scripts/setup.sh` - Initial setup
- `scripts/dev-start.sh` - Start services
- `scripts/reset.sh` - Reset database

**npm Commands:**
- `npm run db:start` - Start Supabase
- `npm run db:stop` - Stop services
- `npm run db:reset` - Reset database
- `npm run migration:new` - Create migration
- `npm run types:generate` - Generate TypeScript types
- `npm run functions:serve` - Test functions locally

### Docker Containers

Supabase CLI manages these containers:
- `supabase_db` - PostgreSQL database
- `supabase_studio` - Admin UI
- `supabase_kong` - API gateway
- `supabase_auth` - Auth service
- `supabase_rest` - PostgREST API
- `supabase_realtime` - Realtime service
- `supabase_storage` - Storage service
- `supabase_imgproxy` - Image transformation
- `supabase_edge_runtime` - Deno functions

## Production Environment

### Infrastructure

**Hosting:** Supabase Cloud Platform

**Regions:** Configurable per project

**Resources:**
- Database with automated backups
- CDN for static assets
- Global edge network
- DDoS protection

### Scaling Strategy

**Database:**
- Vertical scaling (upgrade instance size)
- Connection pooling (Supavisor)
- Read replicas (for high-traffic)

**Edge Functions:**
- Auto-scaling based on demand
- Global distribution
- Cold start optimization

**Storage:**
- CDN caching
- Multi-region replication (enterprise)

### Monitoring

**Built-in Supabase Metrics:**
- Database performance
- API request rates
- Function invocations
- Storage usage

**Custom Monitoring:**
- Application logs
- Error tracking
- Performance metrics
- User analytics

## Design Decisions

### Why Supabase?

**Pros:**
- Rapid development with auto-generated APIs
- Built-in authentication and authorization
- Real-time subscriptions out of the box
- PostgreSQL with full SQL support
- Serverless edge functions
- Open source with self-hosting option

**Trade-offs:**
- Platform lock-in (mitigated by PostgreSQL)
- Less control than custom backend
- Learning curve for RLS policies

### Why PostgreSQL?

**Pros:**
- Mature and reliable
- Rich feature set (JSON, full-text search, etc.)
- Strong consistency (ACID)
- Extensible (custom functions, types, extensions)
- Large ecosystem and community

**Trade-offs:**
- Vertical scaling primary strategy
- More complex than NoSQL for some use cases

### Why Deno for Edge Functions?

**Pros:**
- Secure by default
- Modern JavaScript/TypeScript support
- Fast cold starts
- Built-in tooling
- Web standard APIs

**Trade-offs:**
- Smaller ecosystem than Node.js
- Some npm packages incompatible
- Newer technology (less mature)

### Why Row Level Security?

**Pros:**
- Security at database layer
- Can't be bypassed by client
- Single source of truth
- Works with any client (REST, GraphQL, direct SQL)
- Centralized security logic

**Trade-offs:**
- Learning curve
- Testing complexity
- Performance overhead (minimal)

### Why TypeScript?

**Pros:**
- Type safety
- Better IDE support
- Fewer runtime errors
- Auto-generated from schema
- Excellent refactoring tools

**Trade-offs:**
- Build step required
- More verbose than JavaScript
- Learning curve for beginners

## Conclusion

This architecture balances:
- **Developer Experience** - Fast development with automated tooling
- **Security** - Multiple layers of protection
- **Scalability** - Grows with your application
- **Maintainability** - Clear patterns and structure
- **Performance** - Optimized for common use cases

For detailed guides on specific components:
- [DEVOPS.md](DEVOPS.md) - CI/CD and deployment
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development workflow
- [docs/RLS_POLICIES.md](docs/RLS_POLICIES.md) - Security patterns
- [docs/STORAGE.md](docs/STORAGE.md) - File storage
- [supabase/functions/README.md](supabase/functions/README.md) - Edge functions

---

**Questions?** Open an issue or contact the maintainers.
