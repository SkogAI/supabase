---
title: [Migration Name]
type: note
permalink: migrations/[migration-name]
tags:
  - "migration"
  - "database"
  - "schema"
  - "[add-specific-tags]"
project: supabase
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# [Migration Name]

**Migration File:** `YYYYMMDDHHMMSS_description.sql`
**Applied:** YYYY-MM-DD
**Status:** ✅ Applied | 🔄 Pending | ❌ Rolled Back

## Purpose

Brief description of what this migration accomplishes and why it was needed.

## Changes Made

### Tables

- [action] Created/Modified/Dropped `table_name` - Description
  - Columns: `column1` (type), `column2` (type)
  - Indexes: Description of any indexes added
  - Constraints: Foreign keys, unique constraints, etc.

### Functions/Triggers

- [action] Created/Modified `function_name()` - Purpose
- [action] Created trigger `trigger_name` - When it fires and what it does

### RLS Policies

- [policy] Service role full access on `table_name`
- [policy] Authenticated users can [action] on `table_name` when [condition]
- [policy] Anonymous users can [action] on `table_name` when [condition]

### Other Changes

- [change] Enabled realtime on `table_name`
- [change] Added storage bucket `bucket_name`
- [change] Updated configuration or extensions

## SQL Overview

```sql
-- Key SQL snippets (not the full migration)
CREATE TABLE public.example (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.example ENABLE ROW LEVEL SECURITY;
```

## Dependencies

- [dependency] Requires migration `YYYYMMDDHHMMSS_previous_migration.sql`
- [dependency] Must run before `YYYYMMDDHHMMSS_next_migration.sql`
- [dependency] Requires extension `extension_name`

## Testing

### RLS Testing

```bash
# Test that RLS policies work correctly
npm run test:rls
```

Expected outcomes:
- Service role has full access
- Users can manage their own data
- Cross-user access is properly restricted

### Manual Testing

```sql
-- Connect as specific user
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

-- Test insert
INSERT INTO public.example (user_id, data) VALUES (auth.uid(), 'test');

-- Test select
SELECT * FROM public.example WHERE user_id = auth.uid();
```

## Impact

- **Performance:** Expected impact on query performance
- **Breaking Changes:** Any breaking changes for existing code
- **Data Migration:** Whether existing data was modified
- **Type Generation:** Run `npm run types:generate` to update TypeScript types

## Related Files

- Schema types: `types/database.ts`
- RLS tests: `tests/rls_test_suite.sql`
- Related functions: `supabase/functions/[function-name]/`
- Documentation: `skogai/concepts/[concept].md`

## Rollback Plan

```sql
-- How to reverse this migration if needed
DROP TABLE IF EXISTS public.example CASCADE;
```

## Production Deployment

- [ ] Reviewed by: [Name]
- [ ] Tested locally with `npm run db:reset`
- [ ] RLS tests passing
- [ ] Types regenerated
- [ ] Deployed to staging
- [ ] Deployed to production

## Notes

Additional context, decisions made, or things to watch for:

- Why certain design choices were made
- Known limitations or future improvements needed
- Links to related issues or discussions

## References

- Related concept: `[[Concept Name]]`
- Related guide: `[[Guide Name]]`
- Related migration: `[[Migration Name]]`
- Official docs: [Supabase Documentation](https://supabase.com/docs)

---

**Template Version:** 1.0
**Template Type:** Migration
**Last Updated:** 2025-10-26
