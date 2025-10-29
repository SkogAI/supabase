# Observation Templates

This document provides standardized templates for observations in the skogai semantic knowledge base. Observations are tagged facts, patterns, or insights that make knowledge searchable and relatable.

## What Are Observations?

Observations are bullet points that capture discrete, actionable knowledge about a concept. Each observation is tagged with a type in square brackets (e.g., `[best-practice]`, `[security]`, `[pattern]`) to enable semantic search and cross-referencing.

## Core Principles

1. **One fact per observation** - Each line should contain a single, atomic piece of information
2. **Tag consistently** - Use standardized tags from the categories below
3. **Be specific** - Include concrete details, not vague generalities
4. **Action-oriented** - Focus on what, how, when, why - not just abstract concepts
5. **Link generously** - Use WikiLinks [[Like This]] to connect related concepts

## Observation Categories

### Technical Implementation (380+ observations)

#### `[best-practice]` (108 uses)
Recommended approaches and proven patterns for implementation.

**Examples:**
```markdown
- [best-practice] Always enable RLS on public tables
- [best-practice] Use dedicated poolers for high-throughput workloads
- [best-practice] Store secrets in Supabase vault, not environment variables
```

#### `[security]` (96 uses)
Security requirements, policies, and protective measures.

**Examples:**
```markdown
- [security] JWT token authentication required for all MCP connections
- [security] RLS policies enforced at database layer, cannot be bypassed
- [security] SSL/TLS encryption mandatory for production connections
```

#### `[pattern]` (38 uses)
Reusable code patterns and structural templates.

**Examples:**
```markdown
- [pattern] Enable RLS on table: `ALTER TABLE table ENABLE ROW LEVEL SECURITY`
- [pattern] Users manage own data: `USING (auth.uid() = user_id)`
- [pattern] Service role gets full access with `FOR ALL TO service_role`
```

#### `[testing]` (26 uses)
Testing strategies, test cases, and validation methods.

**Examples:**
```markdown
- [testing] Use `SET request.jwt.claim.sub` to simulate users
- [testing] Test all three roles: anon, authenticated, service_role
- [testing] Automated test suite in `tests/rls_test_suite.sql`
```

#### `[optimization]` (25 uses)
Performance improvements and efficiency techniques.

**Examples:**
```markdown
- [optimization] RLS has minimal performance overhead
- [optimization] Index columns used in policy conditions
- [optimization] Use connection pooling to reduce latency
```

### Features & Capabilities (160+ observations)

#### `[feature]` (60 uses)
Specific features, capabilities, or functionality.

**Examples:**
```markdown
- [feature] Edge Functions support Deno runtime with TypeScript
- [feature] Realtime subscriptions with automatic change notifications
- [feature] Automatic schema migrations with version control
```

#### `[config]` (54 uses)
Configuration options, settings, and parameters.

**Examples:**
```markdown
- [config] Database URL format: postgresql://postgres:[password]@[host]:5432/postgres
- [config] Function timeout: 60 seconds (configurable to 300s)
- [config] Max connection pool size: 100 connections
```

#### `[component]` (35 uses)
System components, modules, or architectural elements.

**Examples:**
```markdown
- [component] Supavisor connection pooler manages database connections
- [component] PostgREST auto-generates REST API from schema
- [component] GoTrue handles authentication and user management
```

#### `[integration]` (18 uses)
Integration points, APIs, and external connections.

**Examples:**
```markdown
- [integration] GitHub Actions for CI/CD deployment
- [integration] ZITADEL for SAML SSO authentication
- [integration] OpenAI API via edge functions
```

### Problem Solving (117+ observations)

#### `[issue]` (44 uses)
Known issues, problems, or challenges.

**Examples:**
```markdown
- [issue] Connection timeouts with serverless functions exceeding 60s
- [issue] SAML metadata refresh required after certificate rotation
- [issue] Type generation fails if database is not running
```

#### `[solution]` (29 uses)
Solutions, fixes, or resolutions to problems.

**Examples:**
```markdown
- [solution] Use transaction mode for serverless to auto-cleanup connections
- [solution] Run `npm run db:reset` to apply new migrations
- [solution] Check Docker Desktop is running if Supabase fails to start
```

#### `[workflow]` (24 uses)
Multi-step processes and operational procedures.

**Examples:**
```markdown
- [workflow] Create migration → Apply locally → Test RLS → Generate types → Commit
- [workflow] Pull changes → Reset database → Update types → Run tests
- [workflow] Edit function → Serve locally → Test → Deploy to production
```

#### `[troubleshooting]` (5 uses)
Diagnostic steps and debugging guidance.

**Examples:**
```markdown
- [troubleshooting] Check logs with `docker logs supabase-auth`
- [troubleshooting] Verify port availability with `lsof -i :8000`
- [troubleshooting] Test connection with `psql postgresql://...`
```

### Architecture & Design (103+ observations)

#### `[use-case]` (31 uses)
Practical applications and usage scenarios.

**Examples:**
```markdown
- [use-case] AI assistants querying user data with RLS protection
- [use-case] Edge functions for API integration without backend
- [use-case] Realtime for collaborative editing features
```

#### `[concept]` (17 uses)
Core concepts and mental models.

**Examples:**
```markdown
- [concept] Security enforced at database layer, not application layer
- [concept] Connection pooling for efficient resource usage
- [concept] Declarative migrations for reproducible deployments
```

#### `[design]` (21 uses)
Design decisions and architectural choices.

**Examples:**
```markdown
- [design] Three-tier role system: anon, authenticated, service_role
- [design] Edge functions isolated with Deno runtime
- [design] Realtime uses PostgreSQL logical replication
```

#### `[principle]` (5 uses)
Guiding principles and philosophies.

**Examples:**
```markdown
- [principle] Connection pooling for efficient resource usage
- [principle] Security through RLS and authentication
- [principle] Defence in depth security model
```

### Operations & Maintenance (90+ observations)

#### `[monitoring]` (20 uses)
Monitoring, metrics, and observability.

**Examples:**
```markdown
- [monitoring] Track connection pool usage with Prometheus
- [monitoring] Function logs available via Supabase dashboard
- [monitoring] Database metrics: CPU, memory, connections, queries
```

#### `[metric]` (27 uses)
Specific measurements and quantitative data.

**Examples:**
```markdown
- [metric] Function cold start: 200-500ms
- [metric] Database connection overhead: ~1-2ms per connection
- [metric] Max payload size: 50MB for storage, 6MB for functions
```

#### `[automation]` (14 uses)
Automated processes and scripted operations.

**Examples:**
```markdown
- [automation] GitHub Actions deploy on merge to main
- [automation] Type generation runs after schema changes
- [automation] Test suite runs on every PR
```

#### `[maintenance]` (13 uses)
Ongoing maintenance tasks and requirements.

**Examples:**
```markdown
- [maintenance] Rotate SSL certificates every 90 days
- [maintenance] Vacuum database monthly for performance
- [maintenance] Review logs weekly for security issues
```

### Status & Planning (61+ observations)

#### `[status]` (15 uses)
Current state and implementation status.

**Examples:**
```markdown
- [status] Feature implemented and tested in production
- [status] Migration pending review
- [status] Documentation outdated, needs update
```

#### `[todo]` (6 uses)
Planned work and future tasks.

**Examples:**
```markdown
- [todo] Add automated backup validation
- [todo] Implement connection pool monitoring alerts
- [todo] Document disaster recovery procedure
```

#### `[next]` (11 uses) / `[next-step]` (6 uses)
Immediate next actions.

**Examples:**
```markdown
- [next] Test RLS policies with edge cases
- [next-step] Deploy to staging environment
- [next] Document configuration options
```

### Documentation Types (40+ observations)

#### `[doc-area]` (13 uses)
Documentation sections and content areas.

**Examples:**
```markdown
- [doc-area] Setup and installation procedures
- [doc-area] API reference and examples
- [doc-area] Troubleshooting common issues
```

#### `[guide]` (13 uses)
Step-by-step guides and tutorials.

**Examples:**
```markdown
- [guide] Complete SAML setup walkthrough
- [guide] Edge function development guide
- [guide] RLS policy implementation guide
```

#### `[example]` (12 uses)
Code examples and demonstrations.

**Examples:**
```markdown
- [example] User authentication flow with code samples
- [example] RLS policy for multi-tenant application
- [example] Edge function with OpenAI integration
```

### Specialized Categories (150+ observations)

#### Database & Storage
- `[query]` (15) - SQL queries and database operations
- `[table]` (6) - Database table definitions
- `[schema]` (5) - Schema organization
- `[index]` (5) - Database indexes
- `[migration]` (5) - Schema migrations

#### Infrastructure
- `[connection]` (7) / `[connection-type]` (4) - Connection types and modes
- `[deployment]` (4) - Deployment processes
- `[environment]` (2) - Environment configurations
- `[scaling]` (8) - Scalability considerations

#### Authentication & Authorization
- `[auth]` (3) - Authentication mechanisms
- `[role]` (3) - User roles and permissions
- `[saml]` (5) - SAML SSO integration
- `[mfa]` (5) - Multi-factor authentication

#### Quality & Validation
- `[checklist]` (18) - Validation checklists
- `[criteria]` (4) - Acceptance criteria
- `[compliance]` (7) - Compliance requirements
- `[verification]` (3) - Verification steps

## Creating New Observations

### Step 1: Choose the Right Tag

Ask yourself:
- Is this a **how-to**? → `[best-practice]`, `[pattern]`, `[workflow]`
- Is this about **security**? → `[security]`
- Is this a **feature**? → `[feature]`, `[capability]`
- Is this a **problem**? → `[issue]`, `[solution]`, `[troubleshooting]`
- Is this **structural**? → `[concept]`, `[design]`, `[component]`
- Is this **operational**? → `[monitoring]`, `[maintenance]`, `[automation]`

### Step 2: Write Concisely

Good observation:
```markdown
- [best-practice] Enable RLS on public tables to prevent unauthorized access
```

Poor observation:
```markdown
- [misc] You should probably think about enabling row level security on your tables because it's important for security and you don't want people accessing data they shouldn't see
```

### Step 3: Add Context When Needed

Include commands, file paths, or specifics:
```markdown
- [testing] Run `npm run test:rls` to validate RLS policies
- [config] Function timeout set in `supabase/config.toml`
- [metric] Cold start latency: 200-500ms for edge functions
```

### Step 4: Link Related Concepts

Use WikiLinks to create connections:
```markdown
- [integration] Works with [[GitHub Actions]] for automated deployment
- [security] Enforces [[Row Level Security]] policies at database layer
- [component] Uses [[Supavisor]] for connection pooling
```

## Quality Checklist

Before committing new observations:
- [ ] Tag is from established categories (see above)
- [ ] One fact per line
- [ ] Specific and actionable
- [ ] Includes concrete details (commands, paths, numbers)
- [ ] Links to related concepts where appropriate
- [ ] No duplicate information
- [ ] Grammatically correct
- [ ] Adds value to existing knowledge

## Common Mistakes to Avoid

❌ **Too vague**: `[feature] Has good performance`
✅ **Specific**: `[metric] Query latency < 100ms for indexed lookups`

❌ **Multiple facts**: `[best-practice] Enable RLS and test policies and add indexes`
✅ **Atomic**: Three separate observations with appropriate tags

❌ **No context**: `[config] Set to 60 seconds`
✅ **Complete**: `[config] Function timeout: 60 seconds (configurable in supabase/config.toml)`

❌ **Generic tag**: `[info] Database uses PostgreSQL`
✅ **Precise tag**: `[component] PostgreSQL 15.x database with extensions enabled`

## Usage Statistics

Current knowledge base contains **1,835+ observations** across **32 semantic notes**:

- Technical Implementation: 380+ observations (security, patterns, testing, optimization)
- Features & Capabilities: 160+ observations (features, configs, components)
- Problem Solving: 117+ observations (issues, solutions, workflows)
- Architecture & Design: 103+ observations (use-cases, concepts, design)
- Operations: 90+ observations (monitoring, metrics, automation)
- Documentation: 40+ observations (guides, examples, doc areas)
- Specialized: 150+ observations (database, infra, auth, quality)

## Contributing

When adding observations to existing notes:
1. Read existing observations to understand the note's scope
2. Choose appropriate tags from established categories
3. Follow the one-fact-per-line principle
4. Add WikiLinks to connect related concepts
5. Run `scripts/validate-memory.sh` to check formatting

When creating new notes:
1. Use `scripts/memory-add-concept.sh` for concept notes
2. Use `scripts/memory-add-guide.sh` for how-to guides
3. Follow the YAML frontmatter format in `TEMPLATE.md`
4. Start with 5-10 high-quality observations
5. Build out incrementally based on actual usage

---

**Last Updated:** 2025-10-26
**Observation Count:** 1,835+
**Notes Count:** 32
**Tag Types:** 100+
