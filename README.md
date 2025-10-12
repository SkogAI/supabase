# Supabase Production Backend

Production-ready Supabase backend with PostgreSQL, Row Level Security, Edge Functions, and comprehensive knowledge base documentation.

## 🎯 New: Semantic Knowledge Base

This project now includes a **semantic knowledge base** powered by [Basic Memory](https://github.com/cyanheads/basic-memory), transforming traditional documentation into a searchable, interconnected knowledge graph.

### Why Knowledge Base?

**Traditional Documentation Problems:**
- 📄 Static files scattered across directories
- 🔍 Hard to find related information
- 🔗 No connections between concepts
- 📊 No visibility into what's documented

**Knowledge Base Solution:**
- 🔎 **Semantic Search**: Every observation tagged and searchable
- 🕸️ **Knowledge Graph**: 245+ relations connecting concepts
- 📈 **Coverage Tracking**: Know exactly what's documented (34% complete)
- 🎯 **Discovery**: Find related info through cross-references

### Knowledge Base Structure

```
skogai/
├── concepts/           # 8 core concepts (RLS, Edge Functions, Storage, etc.)
├── guides/
│   ├── mcp/           # 8 MCP AI agent integration guides
│   ├── saml/          # 5 SAML SSO implementation guides
│   ├── security/      # RLS policy patterns
│   ├── storage/       # File storage configuration
│   └── devops/        # CI/CD and operations
├── project/           # Architecture and overview docs
└── gh/issues/160/     # Knowledge base migration tracking
```

**Current Stats:**
- 📝 32 semantic notes
- 🏷️ 1,835 observations
- 🔗 245 relations
- ✅ 100% coverage of core development docs

### How to Use the Knowledge Base

**Search for anything:**
```bash
# Find all commands related to migrations
memory://*/migration #command

# Find troubleshooting for specific symptoms
memory://*/troubleshooting #symptom

# Navigate from concept to implementation
[[Row Level Security]] → [[RLS Policy Guide]] → [[Storage Architecture]]
```

**Query by observation type:**
- `[command]` - CLI commands and usage
- `[symptom]` - Problem indicators
- `[solution]` - Fixes and workarounds
- `[workflow]` - Step-by-step procedures
- `[pattern]` - Best practices
- `[antipattern]` - Things to avoid

**Navigate via relations:**
- Start at [[Supabase Project Overview]]
- Follow WikiLinks to related concepts
- Discover patterns and connections

## 🚀 Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) (required, must be running)
- [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) (required)
- [Node.js 18+](https://nodejs.org/) (recommended)
- [Deno 2.x](https://deno.land/) (for edge functions)

### Setup

```bash
# Automated setup (recommended)
./scripts/setup.sh

# Or manual setup
npm install
cp .env.example .env
npm run db:start
npm run types:generate
```

Access:
- **Studio**: http://localhost:8000
- **API**: http://localhost:8000
- **Database**: `postgresql://postgres:postgres@localhost:54322/postgres`
- **Functions**: http://localhost:54321/functions/v1/

## 📚 Documentation

### Essential Guides (In Knowledge Base)

All of these are now semantic notes with observations, tags, and relations:

**Development:**
- [[Contributing Guide]] - Complete contributor guidelines
- [[Development Workflows]] - Step-by-step procedures
- [[Troubleshooting Guide]] - Problem-solving reference

**Architecture:**
- [[System Architecture Documentation]] - Complete design overview
- [[Project Architecture]] - Component details
- [[Supabase Project Overview]] - Feature overview

**Security:**
- [[Row Level Security]] - Core concept
- [[RLS Policy Guide]] - Patterns and best practices
- [[Storage Configuration Guide]] - Bucket security

**Operations:**
- [[DevOps Complete Guide]] - CI/CD, deployment, monitoring
- [[CI-CD Pipeline]] - Automation details

**Integration:**
- [[MCP AI Agents]] - AI agent integration
- [[ZITADEL SAML]] - SSO authentication

### Traditional Documentation (Still Available)

- **CLAUDE.md** - Claude Code guidance and project setup
- **skogai/** - Knowledge base (semantic notes)
- **docs/** - Additional detailed documentation (to be migrated)
- **supabase/** - Database migrations and functions

## 🗄️ Database

**PostgreSQL 17** with:
- 6 working migrations
- Row Level Security enabled
- Realtime subscriptions
- 3 storage buckets

### Common Operations

```bash
# Database
npm run db:start          # Start Supabase
npm run db:stop           # Stop services
npm run db:reset          # Reset with all migrations
npm run db:status         # Check service health

# Migrations
npm run migration:new <name>    # Create migration
npm run db:diff                 # Generate SQL diff

# Testing
npm run test:rls          # Test RLS policies
npm run test:functions    # Test edge functions

# Types
npm run types:generate    # Generate TypeScript types
npm run types:watch       # Watch and auto-generate
```

## ⚡ Edge Functions

**Deno 2.x** serverless functions:

```bash
# Development
npm run functions:new <name>     # Create function
npm run functions:serve          # Test locally
npm run functions:deploy         # Deploy to production

# Testing
cd supabase/functions/<name>
deno test --allow-all test.ts
```

**Available Functions:**
- `hello-world` - Example function
- `openai-chat` - OpenAI integration
- `openrouter-chat` - Multi-model AI access

## 🔒 Security

**Row Level Security (RLS)** enforced on all tables:

```sql
-- Enable RLS
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;

-- Service role (admin)
CREATE POLICY "Service role" ON my_table FOR ALL TO service_role USING (true);

-- Users manage own data
CREATE POLICY "Users own" ON my_table FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
```

**Storage buckets** with policies:
- `avatars` - Public, 5MB, images only
- `public-assets` - Public, 10MB, images/PDFs
- `user-files` - Private, 50MB, authenticated only

## 🤖 AI Agent Integration (MCP)

Model Context Protocol infrastructure for AI agents:

**Connection Methods:**
- Direct IPv6 (port 5432)
- Supavisor Session (port 5432) - IPv4 persistent
- Supavisor Transaction (port 6543) - Serverless

**Documentation:**
- [[MCP Server Architecture Guide]]
- [[MCP Connection Pooling]]
- [[MCP Authentication Strategies]]

See `docs/MCP_*.md` for complete guides.

## 🔐 SAML SSO Integration

ZITADEL SAML 2.0 implementation:

**Setup Phases:**
- ✅ Phase 1: ZITADEL IdP Setup
- ✅ Phase 2: Supabase Configuration
- ✅ Phase 3: Testing
- ✅ Phase 4: Production Deployment

**Documentation:**
- [[ZITADEL SAML Integration Guide]]
- [[SAML Admin API Reference]]
- [[SAML User Guide]]

See `docs/AUTH_ZITADEL_SAML_SELF_HOSTED.md` for complete guide.

## 🔄 CI/CD

**GitHub Actions Workflows:**
- `deploy.yml` - Automatic deployment on merge to main
- `pr-checks.yml` - PR validation and security scanning
- `migrations-validation.yml` - Migration testing
- `edge-functions-test.yml` - Function testing
- `security-scan.yml` - Vulnerability scanning

**Required Secrets:**
- `SUPABASE_ACCESS_TOKEN` - CLI authentication
- `SUPABASE_PROJECT_ID` - Target project
- `SUPABASE_DB_PASSWORD` - Database access

## 📊 Knowledge Base Progress

**Issue #160**: [Organize and document Supabase CLI knowledge base](gh/issues/160/README.md)

**Current Progress:**
- 32/94 files migrated (34%)
- 1,835 observations extracted
- 245 relations established
- 62 unresolved relations (expansion targets!)

**Migration Priorities:**
1. CLI command references
2. Testing documentation
3. Realtime implementation
4. Additional SAML details

**Track progress:** `skogai/gh/issues/160/README.md`

## 🛠️ Troubleshooting

**Common Issues:**

| Issue | Solution |
|-------|----------|
| Docker not running | `docker info`, start Docker Desktop |
| Port conflicts | `supabase stop`, check `lsof -i :8000` |
| Migration errors | `supabase db reset --debug` |
| Type generation fails | Ensure Supabase running first |

See [[Troubleshooting Guide]] in knowledge base for comprehensive solutions.

## 📖 Contributing

We use a semantic knowledge base approach:

1. **Traditional contributions** still work (PRs, issues, etc.)
2. **Knowledge base updates** happen automatically on push (coming soon!)
3. **Observations extracted** from code, docs, and migrations
4. **Relations discovered** and documented

See [[Contributing Guide]] for complete guidelines.

## 🗺️ Roadmap

**Knowledge Base (Ongoing):**
- [ ] CLI command documentation
- [ ] Testing guides and examples
- [ ] Realtime implementation patterns
- [ ] Automated sync on git push
- [ ] Coverage analyzer tool
- [ ] Visual knowledge graph explorer

**Features:**
- [ ] Additional edge function examples
- [ ] Enhanced monitoring and alerting
- [ ] Performance optimization guides

## 📞 Support

- **Maintainers**: @Skogix, @Ic0n
- **Issues**: https://github.com/SkogAI/supabase/issues
- **Discussions**: https://github.com/SkogAI/supabase/discussions

## 📄 License

MIT License - see LICENSE file for details

---

**🌟 Tip**: Start exploring at [[Supabase Project Overview]] in the knowledge base!

**Last Updated**: 2025-10-12
**Knowledge Base**: 32 notes, 1,835 observations, 245 relations
