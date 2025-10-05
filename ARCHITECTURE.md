# System Architecture

This document provides an overview of the system architecture for this Supabase project.

## Table of Contents

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Components](#components)
- [Data Flow](#data-flow)
- [Security Architecture](#security-architecture)
- [Deployment Architecture](#deployment-architecture)
- [Development Environment](#development-environment)

---

## Overview

This is a production-ready Supabase backend built with:

- **Database**: PostgreSQL 17 with Row Level Security (RLS)
- **Authentication**: Supabase Auth with JWT tokens
- **Storage**: Supabase Storage (optional)
- **Edge Functions**: Deno-based serverless functions
- **API**: Auto-generated REST and GraphQL APIs via PostgREST
- **Real-time**: WebSocket subscriptions via Realtime
- **CI/CD**: GitHub Actions for automated deployment

### Key Features

- 🔒 **Row Level Security (RLS)** on all public tables
- 🚀 **Automated deployments** on merge to main
- 🧪 **Comprehensive testing** (migrations, functions, security)
- 📦 **Type safety** with auto-generated TypeScript types
- 🔄 **Real-time subscriptions** for live data updates
- 📊 **Observability** with built-in logging and monitoring

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                           CLIENT LAYER                          │
│  (Web App, Mobile App, CLI, etc.)                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTPS / WSS
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                      SUPABASE PLATFORM                          │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Kong API   │  │   Realtime   │  │   Storage    │         │
│  │   Gateway    │  │   Server     │  │   Server     │         │
│  │   (Port 8000)│  │  (WebSocket) │  │   (S3-like)  │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                 │                  │                  │
│  ┌──────▼─────────────────▼──────────────────▼───────┐         │
│  │                                                     │         │
│  │              PostgREST API Layer                   │         │
│  │        (Auto-generated REST & GraphQL APIs)        │         │
│  │                                                     │         │
│  └──────────────────────┬──────────────────────────────┘        │
│                         │                                        │
│  ┌──────────────────────▼─────────────────────────┐            │
│  │                                                  │            │
│  │         PostgreSQL 17 Database                  │            │
│  │         (Port 54322 - Local)                    │            │
│  │                                                  │            │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │            │
│  │  │  Public  │  │  Auth    │  │ Storage  │     │            │
│  │  │  Schema  │  │  Schema  │  │ Schema   │     │            │
│  │  │  (Tables)│  │  (Users) │  │ (Files)  │     │            │
│  │  └──────────┘  └──────────┘  └──────────┘     │            │
│  │                                                  │            │
│  └──────────────────────────────────────────────────┘           │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │                                                    │          │
│  │         Edge Functions (Deno Runtime)             │          │
│  │         (Port 54321 - Local)                      │          │
│  │                                                    │          │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐ │          │
│  │  │ Function 1 │  │ Function 2 │  │ Function N │ │          │
│  │  │ (hello-    │  │ (custom)   │  │ (custom)   │ │          │
│  │  │  world)    │  │            │  │            │ │          │
│  │  └────────────┘  └────────────┘  └────────────┘ │          │
│  │                                                    │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                        CI/CD LAYER                               │
│                     (GitHub Actions)                             │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Deploy    │  │  PR Checks  │  │  Security   │             │
│  │  Workflow   │  │  Workflow   │  │   Scans     │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. Database Layer (PostgreSQL 17)

**Purpose**: Primary data store with built-in authentication and authorization.

**Key Features**:
- **Row Level Security (RLS)**: Fine-grained access control at the row level
- **Extensions**: uuid-ossp, pgcrypto for enhanced functionality
- **Schemas**:
  - `public` - Application tables (profiles, posts, etc.)
  - `auth` - User authentication (managed by Supabase)
  - `storage` - File storage metadata (managed by Supabase)

**Tables** (see `supabase/migrations/`):
- `profiles` - User profile information
- `posts` - User-generated content (example)
- Custom tables as needed

**RLS Policies**:
- Policies enforce that users can only access their own data
- Public data viewable by all authenticated users
- Admin roles can bypass certain restrictions

**Indexes**:
- Optimized for common queries
- Username lookups, date ranges, foreign keys

### 2. API Layer (PostgREST)

**Purpose**: Auto-generates RESTful API from database schema.

**Features**:
- **Automatic endpoints**: GET, POST, PATCH, DELETE for each table
- **Query parameters**: Filtering, sorting, pagination
- **GraphQL**: Experimental GraphQL support
- **OpenAPI spec**: Auto-generated API documentation

**Example Endpoints**:
```
GET    /rest/v1/profiles              # List all profiles
GET    /rest/v1/profiles?id=eq.123   # Get specific profile
POST   /rest/v1/profiles              # Create profile
PATCH  /rest/v1/profiles?id=eq.123   # Update profile
DELETE /rest/v1/profiles?id=eq.123   # Delete profile
```

### 3. Edge Functions (Deno Runtime)

**Purpose**: Serverless functions for custom business logic.

**Technology**: 
- **Runtime**: Deno 2.x
- **Language**: TypeScript
- **Deployment**: Global edge network

**Use Cases**:
- Webhook handlers
- Complex business logic
- Third-party API integrations
- Scheduled tasks (via cron triggers)
- Email sending
- Payment processing

**Example Function** (`hello-world`):
```typescript
// Location: supabase/functions/hello-world/index.ts
serve(async (req) => {
  // Handle request
  const body = await req.json();
  
  // Business logic
  const result = processData(body);
  
  // Return response
  return new Response(JSON.stringify(result));
});
```

**Function Communication**:
- Can access database via Supabase client
- Can call external APIs
- Can trigger other functions
- Can be triggered by webhooks, cron, or HTTP requests

### 4. Authentication (Supabase Auth)

**Purpose**: User authentication and session management.

**Features**:
- **JWT tokens**: Secure, stateless authentication
- **Multiple providers**: Email/password, OAuth (Google, GitHub, etc.)
- **Magic links**: Passwordless authentication
- **MFA**: Multi-factor authentication (optional)
- **Session management**: Automatic token refresh

**Auth Flow**:
```
1. User signs up/logs in → Auth service validates
2. Auth service generates JWT token
3. Client stores token (localStorage, cookies)
4. Client includes token in API requests (Authorization header)
5. PostgREST validates JWT and applies RLS policies
6. Database returns only authorized data
```

**JWT Payload**:
```json
{
  "sub": "user-uuid",
  "role": "authenticated",
  "email": "user@example.com",
  "exp": 1234567890
}
```

### 5. Real-time Subscriptions (Supabase Realtime)

**Purpose**: WebSocket-based real-time data updates.

**Features**:
- **Database changes**: Subscribe to INSERT, UPDATE, DELETE
- **Presence**: Track who's online
- **Broadcast**: Send messages between clients

**Example Subscription**:
```javascript
const channel = supabase
  .channel('posts')
  .on('postgres_changes', 
    { event: 'INSERT', schema: 'public', table: 'posts' },
    (payload) => console.log('New post:', payload)
  )
  .subscribe();
```

### 6. Storage (Supabase Storage)

**Purpose**: S3-compatible file storage with RLS.

**Features**:
- **Buckets**: Organize files into buckets
- **RLS policies**: Control access to files
- **Image transformations**: Resize, crop, optimize on-the-fly
- **CDN**: Global content delivery

**Example Usage**:
```javascript
// Upload file
const { data, error } = await supabase
  .storage
  .from('avatars')
  .upload('user-123.png', file);

// Get public URL
const { data } = supabase
  .storage
  .from('avatars')
  .getPublicUrl('user-123.png');
```

---

## Data Flow

### Read Operation (Query)

```
1. Client → API Gateway (Kong)
   ├─ Check JWT token
   └─ Rate limiting

2. API Gateway → PostgREST
   ├─ Parse request
   └─ Generate SQL

3. PostgREST → PostgreSQL
   ├─ Execute query with RLS context
   └─ Apply policies based on JWT claims

4. PostgreSQL → PostgREST
   └─ Return filtered results

5. PostgREST → Client
   └─ JSON response
```

### Write Operation (Insert/Update)

```
1. Client → API Gateway
   ├─ Validate JWT
   └─ Check permissions

2. API Gateway → PostgREST
   └─ Generate INSERT/UPDATE SQL

3. PostgREST → PostgreSQL
   ├─ Execute with RLS context
   ├─ Validate constraints
   ├─ Check RLS policies
   └─ Fire triggers (updated_at, etc.)

4. PostgreSQL → PostgREST
   └─ Return inserted/updated row

5. PostgREST → Realtime
   └─ Broadcast change to subscribers

6. PostgREST → Client
   └─ JSON response with new data
```

### Edge Function Execution

```
1. Client → API Gateway → Edge Functions Runtime

2. Edge Function
   ├─ Parse request
   ├─ Execute business logic
   ├─ Call database (if needed)
   ├─ Call external APIs (if needed)
   └─ Generate response

3. Edge Function → Client
   └─ Return response
```

---

## Security Architecture

### Defense in Depth

1. **Network Level**
   - HTTPS/TLS encryption
   - Rate limiting via API Gateway
   - DDoS protection

2. **Application Level**
   - JWT authentication
   - Row Level Security (RLS)
   - Input validation
   - SQL injection prevention (PostgREST)

3. **Database Level**
   - RLS policies on all tables
   - Foreign key constraints
   - Check constraints
   - Triggers for data validation

### Row Level Security (RLS)

**How it works**:
- RLS policies are PostgreSQL rules that filter rows based on user context
- Policies are evaluated for every query
- Users can only see/modify rows they're authorized for

**Example Policy**:
```sql
-- Users can only update their own profiles
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
```

**Policy Evaluation**:
```
1. User makes request with JWT token
2. PostgREST extracts user ID from JWT
3. PostgreSQL sets session variables (auth.uid())
4. RLS policies filter rows based on auth.uid()
5. Only authorized rows returned/modified
```

### API Security

**Authentication**:
- All requests require `Authorization: Bearer <JWT>` header
- JWTs are signed and verified by Supabase Auth
- Expired tokens automatically rejected

**Authorization**:
- RLS policies enforce fine-grained access control
- Service role key bypasses RLS (use carefully!)
- Anonymous access configurable per table/bucket

**Best Practices**:
- Never expose service role key to clients
- Use anon key for client applications
- Implement additional validation in edge functions
- Rate limit sensitive endpoints

---

## Deployment Architecture

### Local Development

```
┌─────────────────────────────────────┐
│        Developer Machine            │
│                                     │
│  Docker Containers:                 │
│  ├─ PostgreSQL                     │
│  ├─ PostgREST                      │
│  ├─ Realtime                       │
│  ├─ Storage                        │
│  ├─ Kong (API Gateway)             │
│  ├─ GoTrue (Auth)                  │
│  └─ Studio (UI)                    │
│                                     │
│  All accessible on localhost       │
└─────────────────────────────────────┘
```

### Production (Supabase Cloud)

```
┌──────────────────────────────────────────┐
│          Supabase Cloud                  │
│                                          │
│  Global Edge Network                    │
│  ├─ Edge Functions (Deno Deploy)        │
│  └─ CDN (Storage)                       │
│                                          │
│  Regional Deployment                     │
│  ├─ API Gateway (Kong)                  │
│  ├─ PostgREST                           │
│  ├─ Realtime                            │
│  ├─ Storage                             │
│  └─ Auth                                │
│                                          │
│  Database Cluster                        │
│  ├─ Primary (Read/Write)                │
│  └─ Replicas (Read-only)                │
│                                          │
└──────────────────────────────────────────┘
```

### CI/CD Pipeline

```
┌─────────────┐
│   GitHub    │
│  Repository │
└──────┬──────┘
       │
       │ Push to main
       │
       ▼
┌─────────────────┐
│ GitHub Actions  │
│                 │
│ 1. Validate     │ ← migrations-validation.yml
│ 2. Test         │ ← edge-functions-test.yml
│ 3. Security     │ ← security-scan.yml
│ 4. Deploy       │ ← deploy.yml
└──────┬──────────┘
       │
       │ Deploy
       │
       ▼
┌──────────────────┐
│   Supabase      │
│   Production    │
│                 │
│ 1. Migrations   │
│ 2. Functions    │
│ 3. Types        │
└─────────────────┘
```

---

## Development Environment

### Local Stack

When you run `supabase start`, the following services start in Docker:

| Service | Port | Purpose |
|---------|------|---------|
| **Studio** | 8000 | Web UI for managing project |
| **Kong (API Gateway)** | 8000 | Reverse proxy, rate limiting |
| **PostgREST** | 3000 | REST API |
| **PostgreSQL** | 54322 | Database |
| **GoTrue (Auth)** | 9999 | Authentication service |
| **Realtime** | 4000 | WebSocket server |
| **Storage** | 5000 | File storage |
| **Edge Functions** | 54321 | Functions runtime |
| **Inbucket (Email)** | 9000 | Local email testing |

### Environment Configuration

**Local** (`.env`):
```bash
# Optional for local dev
SUPABASE_OPENAI_API_KEY=your-key
```

**Production** (GitHub Secrets):
```bash
SUPABASE_ACCESS_TOKEN=sbp_xxx
SUPABASE_PROJECT_ID=xxx
SUPABASE_DB_PASSWORD=xxx
```

### Development Workflow

```
1. Make changes to code
2. Test locally (npm run db:reset, npm run test:functions)
3. Commit to feature branch
4. Push to GitHub
5. CI runs tests
6. Create PR
7. Review + Merge
8. Auto-deploy to production
```

---

## Scaling Considerations

### Database Scaling

**Vertical Scaling**:
- Upgrade to larger instance (more CPU/RAM)
- Suitable for most applications

**Horizontal Scaling**:
- Read replicas for read-heavy workloads
- Connection pooling (PgBouncer)
- Partitioning large tables

### Edge Functions Scaling

- Automatically scales to zero when not in use
- Scales up based on traffic
- Global distribution for low latency
- Cold start ~50-200ms

### Caching Strategies

1. **Application-level**: Cache in edge functions
2. **CDN**: Supabase Storage uses CDN
3. **Database**: PostgreSQL query cache
4. **Client-side**: Cache responses in browser

---

## Monitoring & Observability

### Available Metrics

**Database**:
- Query performance (via pganalyze or similar)
- Connection pool usage
- Slow query log
- Table sizes

**Edge Functions**:
- Invocation count
- Error rate
- Execution time
- Memory usage

**API**:
- Request rate
- Response time
- Error rate (4xx, 5xx)
- Top endpoints

### Logging

**Supabase Dashboard**:
- Database logs
- Function logs
- API logs

**GitHub Actions**:
- Deployment logs
- CI/CD pipeline logs
- Test results

---

## Technology Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| Database | PostgreSQL | 17 |
| API | PostgREST | Latest |
| Auth | GoTrue | Latest |
| Functions Runtime | Deno | 2.x |
| Language | TypeScript | 5.x |
| API Gateway | Kong | Latest |
| Container Runtime | Docker | Latest |
| CI/CD | GitHub Actions | - |
| CLI | Supabase CLI | Latest |

---

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgREST Documentation](https://postgrest.org/)
- [Deno Documentation](https://deno.land/manual)
- [Row Level Security Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)

---

**Last Updated**: 2025-01-15  
**Maintained By**: Development Team
