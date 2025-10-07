# Supabase Edge Functions

Edge Functions are server-side TypeScript functions that run on Deno, distributed globally at the edge for low latency.

## Directory Structure

```
functions/
├── README.md
├── deno.json         # Deno configuration and import maps
├── hello-world/
│   ├── index.ts      # Example: Basic function with auth & database
│   └── test.ts       # Unit tests
├── openai-chat/
│   ├── index.ts      # Example: OpenAI direct integration
│   └── test.ts       # Unit tests
└── openrouter-chat/
    ├── index.ts      # Example: OpenRouter (100+ AI models)
    └── test.ts       # Unit tests
```

## Development

### Configuration

The `deno.json` file provides:

- **Import Maps**: Centralized dependency management with shorthand imports
- **Compiler Options**: TypeScript configuration for strict type checking
- **Linting Rules**: Consistent code quality standards
- **Formatting**: Automated code formatting settings

You can use import maps in your functions:

```typescript
// Instead of: import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { serve } from "std/http/server.ts";

// Instead of: import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createClient } from "@supabase/supabase-js";
```

### Creating a New Function

```bash
supabase functions new <function-name>
```

This creates a new directory with a template `index.ts` file.

### Running Functions Locally

```bash
# Serve all functions
supabase functions serve

# Serve a specific function
supabase functions serve <function-name>

# Serve with custom port
supabase functions serve --port 54322
```

### Testing Functions

```bash
# Run tests for a specific function
cd supabase/functions/<function-name>
deno test --allow-all test.ts

# Run tests with Supabase running
supabase start
deno test --allow-all test.ts
```

### Testing with curl

```bash
# Basic test
curl -i http://localhost:54321/functions/v1/hello-world \
  -H "Content-Type: application/json" \
  -d '{"name": "World"}'

# With authentication
curl -i http://localhost:54321/functions/v1/hello-world \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "User"}'
```

## Deployment

### Deploy All Functions

```bash
supabase functions deploy
```

### Deploy Specific Function

```bash
supabase functions deploy <function-name>
```

### Deploy with No JWT Verification (not recommended for production)

```bash
supabase functions deploy <function-name> --no-verify-jwt
```

## Best Practices

### 1. **Error Handling**

Always wrap your function logic in try-catch blocks:

```typescript
serve(async (req: Request) => {
  try {
    // Your logic here
    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
```

### 2. **CORS Headers**

Always include CORS headers for browser requests:

```typescript
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Handle OPTIONS requests
if (req.method === "OPTIONS") {
  return new Response("ok", { headers: corsHeaders });
}
```

### 3. **Authentication**

Use the Supabase client with the user's JWT:

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseClient = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  {
    global: {
      headers: { Authorization: req.headers.get("Authorization")! },
    },
  },
);

const {
  data: { user },
} = await supabaseClient.auth.getUser();
```

### 4. **Environment Variables**

Access environment variables via Deno.env:

```typescript
const apiKey = Deno.env.get("THIRD_PARTY_API_KEY");
```

Set secrets in Supabase Dashboard or via CLI:

```bash
supabase secrets set THIRD_PARTY_API_KEY=your_key_here
```

### 5. **Keep Functions Small**

- Minimize cold start time
- Keep dependencies minimal
- Use dynamic imports for heavy modules

### 6. **Type Safety**

Define interfaces for request/response:

```typescript
interface RequestBody {
  name: string;
  email: string;
}

interface ResponseBody {
  success: boolean;
  data?: any;
  error?: string;
}
```

### 7. **Logging**

Use console methods for logging (visible in Supabase Dashboard):

```typescript
console.log("Info message");
console.error("Error message");
console.warn("Warning message");
```

View logs:

```bash
# Local
supabase functions logs <function-name>

# Production
supabase functions logs <function-name> --tail
```

## Common Patterns

### Database Operations

```typescript
const supabaseClient = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);

const { data, error } = await supabaseClient
  .from("table_name")
  .select("*")
  .eq("id", userId);
```

### Calling External APIs

```typescript
const response = await fetch("https://api.example.com/data", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  },
  body: JSON.stringify({ data: "example" }),
});

const result = await response.json();
```

**Example: AI Provider Integration**

We provide two AI integration examples:

1. **openai-chat** - Direct OpenAI integration
   - Uses OpenAI API directly
   - Access to GPT models
   - See function for implementation details

2. **openrouter-chat** - OpenRouter integration
   - Access to 100+ AI models (GPT-4, Claude, Gemini, Llama, etc.)
   - Automatic fallbacks and cost optimization
   - Single API for multiple providers
   - See function for implementation details

Both examples demonstrate:

- External API calls
- Environment variable handling
- Error handling for API failures
- User authentication with Supabase Auth
- CORS configuration

See [OPENAI_SETUP.md](../../OPENAI_SETUP.md) for complete setup instructions

### Scheduled Functions (via cron)

```typescript
// Use GitHub Actions or external cron service to trigger
// See: .github/workflows/ for examples
```

## Performance Tips

1. **Cache Expensive Operations**: Use Deno KV for caching
2. **Minimize Dependencies**: Only import what you need
3. **Use Streaming**: For large responses, use streaming responses
4. **Connection Pooling**: Reuse database connections
5. **Monitor Performance**: Check function logs for execution time

## Debugging

### Local Debugging with Inspector

```bash
# Start with inspector
supabase functions serve --inspect-brk

# Connect Chrome DevTools to chrome://inspect
```

### Common Issues

**Issue**: Function not found

- **Solution**: Ensure function is deployed and name matches exactly

**Issue**: CORS errors

- **Solution**: Add proper CORS headers to all responses

**Issue**: Authentication fails

- **Solution**: Verify JWT is being passed correctly in Authorization header

**Issue**: Environment variables undefined

- **Solution**: Set secrets via `supabase secrets set` or in Dashboard

## Security

- **Never** commit secrets or API keys
- **Always** validate input data
- **Use** RLS policies for database operations
- **Limit** function permissions (use service role key carefully)
- **Implement** rate limiting for public endpoints
- **Validate** JWT tokens for authenticated endpoints

## Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Deno Manual](https://deno.land/manual)
- [Deno Deploy](https://deno.com/deploy/docs)
- [Edge Function Examples](https://github.com/supabase/supabase/tree/master/examples/edge-functions)

## Testing

### Testing Framework

We use Deno's built-in test framework with comprehensive test coverage. See [TESTING.md](./TESTING.md) for complete testing guide.

### Quick Start

```bash
# Run all tests
npm run test:functions

# Run tests with coverage
npm run test:functions:coverage

# Run tests in watch mode
npm run test:functions:watch

# Run integration tests (requires Supabase running)
npm run test:functions:integration
```

### Test Structure

Each function should have a `test.ts` file:

```typescript
import { assertEquals, assertExists } from "std/testing/asserts.ts";
import { testFetch, testCORS } from "../_shared/testing/helpers.ts";

Deno.test("function-name: description", async () => {
  const response = await testFetch("function-name", {
    body: { key: "value" },
  });
  assertEquals(response.status, 200);
});
```

### Shared Testing Utilities

Use shared testing utilities in `_shared/testing/`:

- **fixtures.ts** - Test data, users, messages
- **mocks.ts** - Mock fetch, Supabase client, API responses
- **helpers.ts** - Test helpers, assertions, performance testing

Example:

```typescript
import { testUsers, generateTestJWT } from "../_shared/testing/fixtures.ts";
import { MockFetch, mockOpenAIResponse } from "../_shared/testing/mocks.ts";
import { testFetch, measureResponseTime } from "../_shared/testing/helpers.ts";

Deno.test("authenticated request", async () => {
  const token = generateTestJWT(testUsers.alice.id);
  const response = await testFetch("my-function", {
    body: { name: "test" },
    token,
  });
  assertEquals(response.status, 200);
});
```

### Test Categories

1. **Unit Tests** - Test function logic in isolation
2. **Integration Tests** - Test with real Supabase services (set `RUN_INTEGRATION_TESTS=true`)
3. **Performance Tests** - Measure response times
4. **CORS Tests** - Verify cross-origin headers
5. **Error Handling Tests** - Test edge cases and failures

### Coverage Requirements

Aim for these minimum coverage targets:
- Line Coverage: 80%
- Branch Coverage: 75%
- Function Coverage: 85%

### Best Practices

1. **Keep tests close to code** - `function-name/test.ts`
2. **Use descriptive names** - `"function-name: what it tests"`
3. **Test edge cases** - Empty inputs, special characters, large payloads
4. **Mock external APIs** - Use `MockFetch` for external services
5. **Clean up after tests** - Delete test data in integration tests
6. **Make tests independent** - Each test should run in isolation

See [TESTING.md](./TESTING.md) for comprehensive testing documentation.

## CI/CD

All edge functions are automatically:

- **Linted** on PR (via `deno lint`)
- **Formatted** checked on PR (via `deno fmt --check`)
- **Type-checked** on PR (via `deno check`)
- **Unit tested** on PR (via `deno test`)
- **Integration tested** on PR (with Supabase running)
- **Coverage reported** on PR (via Codecov)
- **Security scanned** on PR (dependency audit)
- **Deployed** on merge to main (via GitHub Actions)

See `.github/workflows/edge-functions-test.yml` and `.github/workflows/deploy.yml` for details.
