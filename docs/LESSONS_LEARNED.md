# Lessons Learned: The Great Supabase Recovery

**Date**: 2025-10-10
**Context**: Recovered from "database hell" - 7 compounding config issues
**Outcome**: ✅ Fully operational in one session

## 🎯 Key Lessons

### 1. **Version Compatibility is CRITICAL**

**What Happened:**
- CLI v2.34.3 (Arch pacman) vs Docker images expecting v2.48.3
- Config had keys from v2.48.3 docs that v2.34.3 rejected
- Storage container expected migrations that don't exist in older CLI

**The Lesson:**
```
⚠️ NEVER MIX SUPABASE VERSIONS ⚠️

Pick ONE approach and stick to it:
- CLI version determines everything else
- Docker images must match CLI expectations
- Config.toml keys must match CLI version
- Documentation often shows latest, not your version
```

**The Fix:**
- Document YOUR version in CLAUDE.md
- Check compatibility before copying config examples
- Pin Docker image versions if needed
- Update CLI fully or not at all (no half measures)

### 2. **Port Conflicts Are Sneaky**

**What Happened:**
```toml
[api]
port = 8000

[studio]
port = 8000  # BOTH using same port!
```

**Error was cryptic:**
```
Error: Bind for 0.0.0.0:8000 failed: port is already allocated
```

**The Lesson:**
```
🔍 CHECK PORT ASSIGNMENTS IN CONFIG

Don't just fix Docker - check the config file!
Standard ports:
- API: 54321
- Studio: 8000
- Database: 54322
- Realtime: 54323
```

**Prevention:**
- Use standard ports (documented in Supabase docs)
- Grep for port conflicts: `rg "port = " supabase/config.toml`
- Test config parse: `supabase start` will fail fast if invalid

### 3. **Migration Order is Sacred**

**What Happened:**
- `20251005052959_enable_realtime.sql` (early timestamp)
- `20251005065505_initial_schema.sql` (later timestamp)
- Realtime tried to add non-existent tables to publication

**The Lesson:**
```
📅 TIMESTAMPS DETERMINE EXECUTION ORDER

Format: YYYYMMDDHHMMSS_description.sql
- Schema must exist before references
- Never have duplicate migrations (different timestamps, same content)
- Delete duplicates, keep one with correct timestamp
```

**Prevention:**
- Use `npm run migration:new <name>` to auto-generate timestamps
- Never manually create migration files
- Verify order: `ls -1 supabase/migrations/`

### 4. **Docker Zombies Are Real**

**What Happened:**
- Old "SkogAI" project left orphaned volumes
- `supabase stop` didn't clean up everything
- New project couldn't bind to ports

**The Lesson:**
```
🧹 CLEAN UP OLD PROJECTS PROPERLY

Don't just stop - purge:
1. supabase stop --project-id OLD_NAME
2. docker volume ls | grep OLD_NAME
3. docker volume rm <volumes>
4. docker network prune -f
```

**Prevention:**
- One Supabase project per directory
- Use `project_id` in config.toml to avoid conflicts
- When switching projects, fully stop + clean volumes

### 5. **SQL Syntax Varies by PostgreSQL Version**

**What Happened:**
```sql
CREATE POLICY IF NOT EXISTS "name" ...  -- ❌ Not supported!
COMMENT ON TABLE storage.buckets ...    -- ❌ Permission denied!
INSERT INTO storage.buckets (public, file_size_limit, ...) -- ❌ Columns don't exist!
```

**The Lesson:**
```
🗄️ TEST MIGRATIONS AGAINST YOUR ACTUAL PG VERSION

CLI v2.34.3 uses older storage schema:
- No IF NOT EXISTS for policies → Use DROP + CREATE
- No COMMENT on system tables → Skip or use DO blocks
- Fewer columns in storage.buckets → Only (id, name)
```

**Prevention:**
- Check your PG version: `psql ... -c "SHOW server_version;"`
- Test migrations locally first: `supabase db reset`
- Read migration error messages carefully (line numbers!)

### 6. **Seed Data Must Match Schema**

**What Happened:**
```sql
INSERT INTO auth.users (17 columns)
VALUES (
    ...,
    20 values  -- ❌ TOO MANY!
)
```

**The Lesson:**
```
🌱 SEED DATA IS REAL SQL

- Count columns vs values carefully
- Test seed separately: `psql ... -f supabase/seed.sql`
- Use explicit column lists, not SELECT *
```

**Prevention:**
- Run `supabase db reset` after seed changes
- Check row counts: `SELECT COUNT(*) FROM auth.users;`
- Keep seed data simple for development

### 7. **Smaller Steps = Faster Recovery**

**What You Said:**
> "smaller steps"

**The Truth:**
```
✅ FIX ONE THING, TEST, COMMIT, REPEAT

Not:
1. Fix everything
2. Hope it works
3. ???
4. Profit

But:
1. Fix config ports → Test
2. Fix migration order → Test
3. Fix SQL syntax → Test
4. Fix seed data → Test
```

**Your Wins This Session:**
- We fixed 7 issues incrementally
- Each fix was verified before moving on
- When one failed, we didn't break the previous fixes

## 📋 The "ONE TRUE WAY" for Supabase

**Based on this recovery, here's the canonical approach:**

### Setup (Once)
```bash
# 1. Use system package manager (Arch)
sudo pacman -Sy supabase  # Version determined by pacman

# 2. Document the version
supabase --version >> CLAUDE.md

# 3. Init project ONCE
supabase init

# 4. Set project_id in config.toml
project_id = "supabase"  # Not "SkogAI" or random names
```

### Daily Workflow
```bash
# Start
npm run db:start

# Make changes (ONE AT A TIME)
npm run migration:new add_feature_x
# Edit the migration file
# Test it
npm run db:reset

# Verify
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres

# Commit
git add supabase/migrations/
git commit -m "Add feature X migration"
```

### Never Do This
```bash
❌ Mix CLI versions (upgrade partially)
❌ Copy config from different CLI version docs
❌ Manually create migrations (wrong timestamps)
❌ Skip testing migrations locally
❌ Have multiple Supabase projects with same project_id
❌ Trust that "it should work" without testing
```

### Always Do This
```bash
✅ Test every change: npm run db:reset
✅ One migration per feature
✅ Commit working state before new changes
✅ Document your CLI version
✅ Use standard ports
✅ Clean up old projects completely
```

## 🎓 Meta-Lesson: AI Automation Needs Solid Foundation

**Your Goal:**
> "98% AI automation - this is not even my languages"

**Why This Matters:**
- AI can write migrations ✅
- AI can review PRs ✅
- AI can deploy ✅
- **BUT AI needs a working foundation to build on** ⚠️

**The Recovery Shows:**
1. Foundation issues compound (7 small issues = complete failure)
2. Each fix enabled the next step
3. Tests verify AI-generated code works
4. Automation is only as good as the base system

**Your Next Phase:**
- Foundation is now solid ✅
- GitHub workflows can now work (no random failures)
- AI agents will have stable environment
- 98% automation is achievable with this base

## 🚀 Immediate Next Steps

1. **Commit this working state**
   - All 6 modified files
   - Both deleted duplicates
   - New VICTORY.md and LESSONS_LEARNED.md

2. **Set GitHub secrets** (your action item)
   ```bash
   gh secret set SUPABASE_ACCESS_TOKEN --org skogai
   gh secret set SUPABASE_PROJECT_ID --org skogai
   gh secret set SUPABASE_DB_PASSWORD --org skogai
   gh secret set CLAUDE_CODE_OAUTH_TOKEN --org skogai
   ```

3. **Activate workflows** (move from proposals)
   - Start with `deploy.yml`
   - Then `pr-checks.yml`
   - Test with a small PR

4. **Document "ONE TRUE WAY"**
   - Update CLAUDE.md with canonical workflow
   - Add version compatibility section
   - Link to this lessons learned doc

## 🎉 What You Did Right

- ✅ Recognized when to ask for help (before making it worse)
- ✅ Provided good context ("database not working, won't shut down")
- ✅ Accepted comprehensive fixes over quick hacks
- ✅ Tested as we went
- ✅ Understood the goal (AI automation needs stability)

**You said:** *"rather have way too much than the other way around"*

**Result:** We fixed 7 issues thoroughly, not just surface-level. That's why it's solid now.

---

**Bottom line:** This wasn't just fixing bugs - it was learning how to **keep a Supabase project stable long-term for AI automation**. These lessons will prevent the next "dragged to hell" moment. 💪
