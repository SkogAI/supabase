# Integration Tests

Integration tests for validating Supabase functionality.

## Prerequisites

1. **Supabase must be running locally**
   ```bash
   npm run db:start
   # OR
   supabase start
   ```

2. **Deno installed** (for running tests)
   ```bash
   # Install Deno if not already installed
   curl -fsSL https://deno.land/install.sh | sh
   ```

## Running Tests

### Storage Tests

Tests for storage buckets, RLS policies, and file operations:

```bash
# Run storage tests
deno test --allow-all tests/storage-test-example.ts

# Run with verbose output
deno test --allow-all --trace-ops tests/storage-test-example.ts
```

**What's tested:**
- Bucket existence and configuration
- File size and MIME type limits
- RLS policies for authenticated users
- User folder isolation (users can only access their own files)
- Public URL generation
- Signed URL creation for private files
- Helper functions for file metadata

### Edge Function Tests

Edge function tests are located in `supabase/functions/*/test.ts`:

```bash
# Run all function tests
npm run test:functions

# Run specific function tests
cd supabase/functions/hello-world
deno test --allow-all test.ts
```

## Test Coverage

### Current Tests

- ✅ Storage bucket configuration
- ✅ Storage RLS policies
- ✅ Edge function example (hello-world)

### Planned Tests

- Database RLS policies
- Authentication flows
- Realtime subscriptions
- Performance benchmarks

## Writing New Tests

### Storage Test Template

```typescript
import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:8000";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "your-anon-key";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

Deno.test("My storage test", async () => {
  // Your test code here
  const { data, error } = await supabase.storage.listBuckets();
  assertEquals(error, null);
  assertExists(data);
});
```

### Database Test Template

```typescript
import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

Deno.test("My database test", async () => {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .limit(1);
    
  assertEquals(error, null);
  assertExists(data);
});
```

## CI/CD Integration

Tests are automatically run in GitHub Actions:

- **PR Checks**: Run on every pull request
- **Edge Functions Test**: Run on function changes
- **Migrations Validation**: Run on migration changes

See `.github/workflows/` for workflow definitions.

## Troubleshooting

### Tests fail with connection error

**Cause**: Supabase not running
**Solution**: 
```bash
supabase start
# Wait for services to start, then run tests
```

### Tests fail with authentication error

**Cause**: Invalid anon key or expired JWT
**Solution**: 
- Check anon key in test file matches your local setup
- Get fresh anon key from Studio: http://localhost:8000 → Settings → API

### Tests timeout

**Cause**: Database or storage not responding
**Solution**:
```bash
# Restart Supabase
supabase stop
supabase start
```

## Resources

- [Deno Testing Documentation](https://deno.land/manual/testing)
- [Supabase Client Library](https://supabase.com/docs/reference/javascript/introduction)
- [Testing Best Practices](https://deno.land/manual/testing/assertions)
