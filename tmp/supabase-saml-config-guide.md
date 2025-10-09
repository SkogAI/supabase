# Self-Hosted Supabase SAML Configuration Guide
## Supabase CLI Limitations & Workarounds

**Status**: Supabase CLI doesn't natively support SAML SSO configuration yet (Issue #1335)

**Generated Files**:
- ✅ SAML Private Key: `tmp/private_key.base64` (1588 bytes)
- Location: `/home/skogix/dev/supabase/tmp/`

---

## Option 1: Environment Variable Configuration (Recommended)

### Step 1: Add to `.env` file

Since the `.env` file is protected, you'll need to manually add these lines:

```bash
# SAML SSO Configuration
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<PASTE_CONTENT_FROM_tmp/private_key.base64_HERE>
```

**How to get the private key:**
```bash
# View the base64 encoded key
cat tmp/private_key.base64

# Or copy to clipboard (if you have xclip)
cat tmp/private_key.base64 | xclip -selection clipboard
```

### Step 2: Check Current Supabase Setup

```bash
# Check if Supabase is running
supabase status

# If not running, start it
supabase start
```

### Step 3: Find Docker Compose File

The CLI generates docker-compose.yml internally. Find it:

```bash
# Find the generated docker-compose.yml
find ~/.supabase -name "docker-compose.yml" 2>/dev/null | head -1

# Common location:
ls ~/.supabase/docker/docker-compose.yml
```

---

## Option 2: Docker Compose Override (If CLI doesn't pass env vars)

If the Supabase CLI doesn't pass the env vars to GoTrue, you'll need a docker-compose override.

### Create `docker-compose.override.yml`

**Location**: Project root (`/home/skogix/dev/supabase/`)

```yaml
version: '3.8'

services:
  auth:
    environment:
      GOTRUE_SAML_ENABLED: "${GOTRUE_SAML_ENABLED}"
      GOTRUE_SAML_PRIVATE_KEY: "${GOTRUE_SAML_PRIVATE_KEY}"
```

### Restart Supabase

```bash
supabase stop
supabase start
```

---

## Option 3: Manual Docker Modification (Advanced)

### Step 1: Stop Supabase

```bash
supabase stop
```

### Step 2: Find and Edit Generated docker-compose.yml

```bash
# Find the file
find ~/.supabase -name "docker-compose.yml"

# Edit it (example path)
nano ~/.supabase/docker/docker-compose.yml
```

### Step 3: Add to `auth` service

Find the `auth:` service section and add:

```yaml
auth:
  image: supabase/gotrue:...
  environment:
    # ... existing vars ...
    GOTRUE_SAML_ENABLED: "true"
    GOTRUE_SAML_PRIVATE_KEY: "<your-base64-key-here>"
```

### Step 4: Kong Configuration

This is the **tricky part**. The CLI manages Kong config internally.

**Option A**: Wait for CLI support
**Option B**: Use custom Kong configuration (requires modifying CLI-generated files)

---

## Kong Routes Configuration (Required for SAML)

Kong needs these routes added to allow SAML endpoints without API keys:

```yaml
# Add to Kong services configuration
services:
  - name: auth-v1-open-sso-acs
    url: "http://auth:9999/sso/saml/acs"
    routes:
      - name: auth-v1-open-sso-acs
        strip_path: true
        paths:
          - /auth/v1/sso/saml/acs
    plugins:
      - name: cors

  - name: auth-v1-open-sso-metadata
    url: "http://auth:9999/sso/saml/metadata"
    routes:
      - name: auth-v1-open-sso-metadata
        strip_path: true
        paths:
          - /auth/v1/sso/saml/metadata
    plugins:
      - name: cors
```

**Kong config location** (CLI-managed):
```bash
# Find Kong config
find ~/.supabase -name "kong.yml"
```

---

## Verification Steps

### 1. Check if SAML is enabled

```bash
# Check GoTrue health endpoint
curl http://localhost:54321/auth/v1/health

# Look for saml_enabled: true in settings
curl http://localhost:54321/auth/v1/settings
```

### 2. Test metadata endpoint

```bash
# Should return XML metadata (if Kong routes configured)
curl http://localhost:54321/auth/v1/sso/saml/metadata?download=true

# Alternative port (API gateway)
curl http://localhost:8000/auth/v1/sso/saml/metadata?download=true
```

### 3. Check Docker logs

```bash
# Find auth container name
docker ps | grep gotrue

# Check logs for SAML initialization
docker logs <auth-container-id> 2>&1 | grep -i saml
```

---

## Recommended Approach

Given the CLI limitations, here's what I recommend:

### 1. Add env vars to `.env` (you'll do this manually)

```bash
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<content-from-tmp/private_key.base64>
```

### 2. Start Supabase and check if env vars are passed

```bash
supabase start
docker exec -it supabase_auth_SkogAI env | grep SAML
```

### 3. If env vars aren't passed, create override file

See Option 2 above.

### 4. Kong configuration might require:
- Waiting for official CLI support
- Using a full docker-compose setup (not CLI-managed)
- Manually modifying CLI-generated files (not recommended, will be overwritten)

---

## Alternative: Full Docker Compose Setup

If the CLI doesn't work, consider using the official Supabase docker-compose setup:

```bash
# Clone Supabase docker setup
git clone --depth 1 https://github.com/supabase/supabase.git supabase-docker
cd supabase-docker/docker

# Follow self-hosting guide
# This gives you full control over docker-compose.yml and kong.yml
```

---

## Next Steps

1. **Manual**: Add env vars to `.env`
2. **Test**: Start Supabase and verify
3. **Decide**: CLI override OR full docker-compose setup
4. **Configure Kong**: Required for SAML endpoints

---

## Files Generated

- `tmp/private_key.der` - Private key (binary)
- `tmp/private_key.base64` - Private key (base64 encoded) ← **Use this**

## References

- [GitHub Issue #1335](https://github.com/supabase/cli/issues/1335) - CLI SAML support discussion
- [Calvin Chan's Guide](https://calvincchan.com/blog/self-hosted-supabase-enable-sso) - Full docker-compose SAML setup
