# Seed Data Documentation

## Overview

The `supabase/seed.sql` file provides comprehensive test data for local development and testing. It's automatically loaded when you run `supabase db reset` or `npm run db:reset`.

## What Gets Seeded

### 1. Authentication Users (auth.users)

Three test users are created with real authentication credentials:

| Email | Password | User ID |
|-------|----------|---------|
| alice@example.com | password123 | `00000000-0000-0000-0000-000000000001` |
| bob@example.com | password123 | `00000000-0000-0000-0000-000000000002` |
| charlie@example.com | password123 | `00000000-0000-0000-0000-000000000003` |

**Important:** These credentials are for **LOCAL DEVELOPMENT ONLY**. Never use them in production.

### 2. User Profiles (public.profiles)

Profiles are automatically created via the `handle_new_user()` trigger when auth users are inserted:

- **Alice Johnson** - Software engineer and open source enthusiast
- **Bob Smith** - Full-stack developer passionate about web technologies
- **Charlie Davis** - Designer and developer hybrid

### 3. Sample Posts (public.posts)

7 posts are created to demonstrate RLS policies:

- **Alice's posts**: 2 published, 1 draft
- **Bob's posts**: 2 published
- **Charlie's posts**: 2 published

## Using Test Users

### Login via Supabase Client

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Login as Alice
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'alice@example.com',
  password: 'password123'
})
```

### Testing RLS Policies in SQL

```sql
-- Set auth context as Alice
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

-- Test viewing posts (should see all published + own drafts)
SELECT id, title, published, user_id 
FROM posts;

-- Test updating own post (should succeed)
UPDATE posts 
SET title = 'Updated Title' 
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- Test updating another user's post (should fail due to RLS)
UPDATE posts 
SET title = 'Hacked Title' 
WHERE user_id = '00000000-0000-0000-0000-000000000002';
```

### Testing in Supabase Studio

1. Navigate to http://localhost:8000
2. Go to "Authentication" → "Users"
3. You should see alice, bob, and charlie
4. Go to "Table Editor" to view profiles and posts
5. Use the SQL Editor to test RLS policies

## How Seed Data Works

### Process Flow

```
db reset
  ↓
1. Drop all tables/data
  ↓
2. Run migrations (create schema)
  ↓
3. Run seed.sql
  ↓
4. Insert into auth.users
  ↓
5. Trigger: handle_new_user()
  ↓
6. Create profiles automatically
  ↓
7. Update profiles with bio
  ↓
8. Insert sample posts
  ↓
9. Display verification summary
```

### Key Features

- **Automatic Profile Creation**: Profiles are created via trigger, not direct insert
- **Real Authentication**: Users have proper encrypted passwords using bcrypt
- **Realistic Data**: Posts are backdated to simulate a real application
- **RLS Testing**: Mix of published/draft posts to test security policies
- **Verification**: Displays summary with counts and helpful testing info

## Configuration

Seed data is configured in `supabase/config.toml`:

```toml
[db.seed]
enabled = true
sql_paths = ["./seed.sql"]
```

## Customizing Seed Data

To add your own test data:

1. Edit `supabase/seed.sql`
2. Add your INSERT statements after the existing ones
3. Follow the same pattern for consistency
4. Run `npm run db:reset` to apply changes

**Best Practices:**
- Use fixed UUIDs for test users (makes testing easier)
- Include both published and draft content
- Add variety to test edge cases
- Document any special test scenarios
- Keep passwords simple for development
- Add verification queries at the end

## Troubleshooting

### Seed data doesn't load

Check that:
- `enabled = true` in `[db.seed]` section of config.toml
- Path is correct: `sql_paths = ["./seed.sql"]`
- No syntax errors in seed.sql
- Migrations run successfully first

### Can't login with test users

Ensure:
- Database has been reset recently
- Using correct email/password
- Supabase is running (`npm run db:start`)
- Check auth.users table has the users

### RLS policies not working

Verify:
- You've set the auth context correctly
- RLS is enabled on the table
- Policies are defined in migrations
- You're testing with the right user ID

## Related Documentation

- [README.md](./README.md) - Development workflow
- [DEVOPS.md](./DEVOPS.md) - Complete DevOps guide
- [supabase/migrations/](./supabase/migrations/) - Database schema
- [Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)
