# Supabase Module Build Plan

Ground-up rebuild: Start with PostgreSQL only, add one module at a time.

## Current Modules (from config.toml)

```
[db]           ✅ PostgreSQL (KEEP - Foundation)
[api]          ⏸️  PostgREST API
[studio]       ⏸️  Supabase Studio UI
[auth]         ⏸️  GoTrue Authentication
[storage]      ⏸️  Storage buckets
[inbucket]     ⏸️  Email testing
[functions]    ⏸️  Edge Functions (Deno)
[realtime]     ⏸️  Realtime subscriptions
[analytics]    ⏸️  Analytics (not in current config)
```

## Phase 0: Strip Down ✅

**Goal:** PostgreSQL only, everything else disabled

**Actions:**
- [ ] Create minimal config.toml with only `[db]` section
- [ ] Disable: api, studio, auth, storage, inbucket, functions
- [ ] Test: `supabase start` with minimal config
- [ ] Verify: Can connect to Postgres directly
- [ ] Document: What works, connection strings, ports

**Success Criteria:**
- PostgreSQL container starts successfully
- Can connect via psql
- Can run basic SQL queries
- No other services running

---

## Phase 1: Add Studio (Database UI)

**Goal:** Visual database management

**Why:** Makes development easier to see tables/data

**Actions:**
- [ ] Enable `[studio]` in config.toml
- [ ] Test: Studio UI accessible at localhost:54323
- [ ] Verify: Can view database schema
- [ ] Document: Studio features that work

**Dependencies:** PostgreSQL only

**Success Criteria:**
- Studio UI loads
- Can see tables and schemas
- Can run SQL queries in Studio
- Table editor works

---

## Phase 2: Add API (PostgREST)

**Goal:** REST API auto-generated from database schema

**Why:** Core feature for accessing database via HTTP

**Actions:**
- [ ] Enable `[api]` in config.toml
- [ ] Test: API accessible at localhost:54321
- [ ] Create test table with RLS
- [ ] Verify: Can query via REST API
- [ ] Document: API endpoints and schemas

**Dependencies:** PostgreSQL

**Success Criteria:**
- API responds to requests
- Tables exposed as REST endpoints
- Can perform CRUD operations
- Schema introspection works

---

## Phase 3: Add Auth (GoTrue)

**Goal:** User authentication and authorization

**Why:** Required for RLS and user management

**Actions:**
- [ ] Enable `[auth]` in config.toml
- [ ] Configure minimal auth (email only)
- [ ] Test: User signup/login
- [ ] Verify: JWT tokens generated
- [ ] Test: RLS policies with auth.uid()
- [ ] Document: Auth flows and RLS integration

**Dependencies:** PostgreSQL, API

**Success Criteria:**
- Can create users
- Can login and get JWT
- RLS policies work with auth.uid()
- Protected endpoints require auth

---

## Phase 4: Add Storage

**Goal:** File storage with RLS

**Why:** Common requirement for user uploads

**Actions:**
- [ ] Enable `[storage]` in config.toml
- [ ] Create test bucket
- [ ] Test: File upload/download
- [ ] Test: Storage RLS policies
- [ ] Document: Bucket configuration and policies

**Dependencies:** PostgreSQL, API, Auth

**Success Criteria:**
- Can create buckets
- Can upload/download files
- Storage RLS works
- File size limits enforced

---

## Phase 5: Add Realtime (Optional)

**Goal:** Live database updates via websockets

**Why:** Real-time features (chat, notifications)

**Actions:**
- [ ] Enable `[realtime]` in config.toml
- [ ] Configure table for realtime
- [ ] Test: Subscribe to changes
- [ ] Document: Realtime configuration

**Dependencies:** PostgreSQL, API, Auth

---

## Phase 6: Add Edge Functions (Optional)

**Goal:** Server-side logic in Deno

**Why:** Custom business logic, integrations

**Actions:**
- [ ] Enable `[functions]` in config.toml
- [ ] Create hello-world function
- [ ] Test: Function invocation
- [ ] Document: Function development workflow

**Dependencies:** PostgreSQL, API, Auth

---

## What Do You Want?

**Answer these to prioritize modules:**

1. **Core features needed?**
   - [ ] Database only
   - [ ] REST API
   - [ ] User authentication
   - [ ] File storage
   - [ ] Realtime updates
   - [ ] Custom functions

2. **Use case?**
   - Learning Supabase
   - Building production app
   - Specific feature testing
   - Other: _______________

3. **Primary language?**
   - TypeScript/JavaScript
   - Python
   - Go
   - Other: _______________

4. **External integrations?**
   - OAuth providers (GitHub, Google, etc.)
   - SAML SSO
   - Email service
   - Other: _______________

---

## Current Status

- [x] Planning document created
- [ ] User priorities defined
- [ ] Phase 0 started (PostgreSQL only)
