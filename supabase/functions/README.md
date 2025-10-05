# Supabase Edge Functions

Edge Functions are server-side TypeScript functions that run on Deno, distributed globally at the edge for low latency.

## Directory Structure

```
functions/
├── README.md                 # This file
├── TESTING.md                # Comprehensive testing guide
├── deno.json                 # Deno configuration
├── _shared/                  # Shared utilities
│   ├── README.md             # Shared utilities documentation
│   ├── test-utils/           # Test helper functions
│   │   └── test-helpers.ts
│   └── test-fixtures/        # Mock data and fixtures
│       └── mock-data.ts
└── hello-world/              # Example function
    ├── index.ts              # Function implementation
    └── test.ts               # Function tests
```

## Development

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
# Run all tests
cd supabase/functions
deno test --allow-all

# Run tests for a specific function
cd supabase/functions/<function-name>
deno test --allow-all test.ts

# Run tests with coverage
cd supabase/functions
deno test --allow-all --coverage=coverage
deno coverage coverage --lcov --output=coverage.lcov

# Run tests with Supabase running
supabase start
cd supabase/functions
deno test --allow-all

# Run tests in watch mode
deno test --allow-all --watch
```

📖 **See [TESTING.md](./TESTING.md) for comprehensive testing guide**

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
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
```

### 2. **CORS Headers**

Always include CORS headers for browser requests:

```typescript
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
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
  }
);

const { data: { user } } = await supabaseClient.auth.getUser();
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
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
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
    "Authorization": `Bearer ${apiKey}`,
  },
  body: JSON.stringify({ data: "example" }),
});

const result = await response.json();
```

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

## CI/CD

All edge functions are automatically:
- **Linted** on PR (via `deno lint`)
- **Type-checked** on PR (via `deno check`)
- **Tested** on PR (via `deno test`)
- **Deployed** on merge to main (via GitHub Actions)

See `.github/workflows/edge-functions-test.yml` and `.github/workflows/deploy.yml` for details.
