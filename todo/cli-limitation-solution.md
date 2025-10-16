# Supabase CLI SAML Limitation - Solution Options

## Problem
The Supabase CLI doesn't respect `docker-compose.override.yml` files and doesn't pass custom environment variables (like GOTRUE_SAML_*) to the auth container.

**Confirmed**:
- ❌ `.env` with GOTRUE_SAML_* → Not passed to containers
- ❌ `docker-compose.override.yml` → Not picked up by CLI
- ❌ `config.toml` → No SAML configuration options
- ✅ SAML is supported by GoTrue (auth service), just not by the CLI

## Solutions

### Option 1: Manual Container Restart (Temporary)

**Pros**: Quick, minimal changes
**Cons**: Lost on every `supabase stop/start`

```bash
# Stop the auth container
docker stop supabase_auth_SkogAI

# Remove it
docker rm supabase_auth_SkogAI

# Recreate with SAML env vars (need to get all original env vars + networks)
# This is complex and error-prone
```

**Status**: Not recommended - too fragile

---

### Option 2: Fork/Modify Supabase CLI (Advanced)

**Pros**: Permanent solution
**Cons**: Requires maintaining a fork, complex

**Status**: Too much overhead

---

### Option 3: Switch to Full Docker Compose Setup ⭐ RECOMMENDED

**Pros**:
- Full control over all configuration
- Well-documented approach
- Works with all Supabase features including SAML
- Proven by community (Calvin Chan's guide)

**Cons**:
- More initial setup
- Need to manage docker-compose.yml ourselves
- Can't use `supabase start/stop` commands

**How to implement**:

1. Clone official Supabase docker setup
```bash
cd /home/skogix/dev
git clone --depth 1 https://github.com/supabase/supabase.git supabase-docker
cd supabase-docker/docker
```

2. Copy your existing migrations and config
```bash
cp -r /home/skogix/dev/supabase/supabase/migrations ./volumes/db/migrations/
cp /home/skogix/dev/supabase/supabase/seed.sql ./volumes/db/seed.sql
```

3. Configure .env with SAML
```bash
cp .env.example .env
# Add:
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<your-base64-key>
```

4. Update docker-compose.yml auth service
```yaml
auth:
  environment:
    GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED}
    GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY}
```

5. Configure Kong (see Calvin Chan's guide)

6. Start with docker compose
```bash
docker compose up -d
```

---

### Option 4: Hybrid Approach - CLI + Manual Auth Container

**Pros**: Keep using CLI for most things
**Cons**: Requires manual restart of auth container after each CLI restart

**Steps**:

1. Use Supabase CLI normally
```bash
supabase start
```

2. After start, manually recreate auth container with SAML vars

This requires a script to:
- Get all env vars from current auth container
- Add GOTRUE_SAML_* vars
- Stop and recreate container with new env vars
- Reconnect to same networks

**Status**: Complex, error-prone

---

### Option 5: Wait for CLI Support + Use Alternative Auth

**Pros**: No workarounds needed
**Cons**: Delays SAML integration indefinitely

GitHub Issue: https://github.com/supabase/cli/issues/1335

**Status**: Not viable for immediate needs

---

## Recommendation

**Go with Option 3: Full Docker Compose Setup**

Why:
1. ✅ Complete control and flexibility
2. ✅ Well-documented by community
3. ✅ No fragile workarounds
4. ✅ Can migrate existing work easily
5. ✅ Future-proof (no dependency on CLI feature additions)

## Next Steps

1. Decide which option to pursue
2. If Option 3, I can help you:
   - Set up the full docker-compose environment
   - Migrate your existing migrations/config
   - Configure SAML properly
   - Update documentation

3. If another option, we can explore that path

## Files We Have

- ✅ SAML Private Key: `tmp/private_key.base64`
- ✅ Integration Plan: `tmp/zitadel-supabase-integration-plan.md`
- ✅ ZITADEL Todo: `tmp/zitadel-todo.md`
- ✅ Your existing migrations: `supabase/migrations/`
- ✅ Your config: `supabase/config.toml`
