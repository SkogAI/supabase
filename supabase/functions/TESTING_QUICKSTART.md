# Testing Quick Start Guide

Quick reference for testing edge functions. See [TESTING.md](./TESTING.md) for comprehensive guide.

## Run Tests

```bash
# All tests
npm run test:functions

# Specific function
cd supabase/functions/hello-world && deno test --allow-all test.ts

# With coverage
npm run test:functions:coverage

# Watch mode
npm run test:functions:watch

# Integration tests (requires Supabase running)
supabase start
npm run test:functions:integration
```

## Basic Test Template

```typescript
import { assertEquals, assertExists } from "std/testing/asserts.ts";
import { testFetch } from "../_shared/testing/helpers.ts";

const FUNCTION_URL = Deno.env.get("FUNCTION_URL") || 
  "http://localhost:54321/functions/v1/my-function";

Deno.test("my-function: basic request", async () => {
  const response = await testFetch("my-function", {
    body: { key: "value" },
  });
  
  assertEquals(response.status, 200);
  const data = await response.json();
  assertExists(data);
});

Deno.test("my-function: CORS headers", async () => {
  const response = await fetch(FUNCTION_URL, { method: "OPTIONS" });
  
  assertEquals(response.status, 200);
  assertExists(response.headers.get("Access-Control-Allow-Origin"));
});
```

## Common Patterns

### 1. Test with Authentication

```typescript
import { testUsers, generateTestJWT } from "../_shared/testing/fixtures.ts";

Deno.test("authenticated request", async () => {
  const token = generateTestJWT(testUsers.alice.id);
  const response = await testFetch("my-function", {
    body: { data: "test" },
    token,
  });
  assertEquals(response.status, 200);
});
```

### 2. Mock External API

```typescript
import { MockFetch, mockOpenAIResponse } from "../_shared/testing/mocks.ts";

Deno.test("mock API call", () => {
  const mockFetch = new MockFetch();
  mockFetch.addJsonMock(
    "https://api.openai.com/v1/chat/completions",
    mockOpenAIResponse("Hello!")
  );
  
  // Use in your function
  const response = await mockFetch.fetch("https://api.openai.com/v1/chat/completions");
  assertEquals(response.status, 200);
});
```

### 3. Performance Test

```typescript
import { measureResponseTime } from "../_shared/testing/helpers.ts";

Deno.test("response time", async () => {
  const { duration, response } = await measureResponseTime(
    "my-function",
    { data: "test" }
  );
  
  assertEquals(response.status, 200);
  assertEquals(duration < 1000, true, `Took ${duration}ms`);
});
```

### 4. Integration Test

```typescript
Deno.test({
  name: "integration: database operation",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await testFetch("my-function", {
      body: { data: "test" },
    });
    
    assertEquals(response.status, 200);
    // Verify database state, etc.
  },
});
```

### 5. Error Handling

```typescript
Deno.test("handles invalid input", async () => {
  const response = await testFetch("my-function", {
    body: { invalid: "data" },
  });
  
  // Should return error
  const data = await response.json();
  assertExists(data.error);
});
```

## Test Categories Checklist

For each function, test:

- [ ] Basic request/response (200 OK)
- [ ] CORS headers (OPTIONS request)
- [ ] Invalid JSON handling
- [ ] Missing required fields
- [ ] Authentication (if required)
- [ ] Error handling
- [ ] Performance (response time < 1s)
- [ ] Edge cases (empty, null, special characters)

## Test Utilities Summary

### Fixtures (`_shared/testing/fixtures.ts`)
- `testUsers` - Pre-defined test users
- `testMessages` - Sample messages
- `testHeaders` - HTTP headers
- `generateTestJWT()` - Create JWT tokens

### Mocks (`_shared/testing/mocks.ts`)
- `MockFetch` - Mock HTTP requests
- `MockSupabaseClient` - Mock database
- `mockOpenAIResponse()` - Mock OpenAI
- `mockOpenRouterResponse()` - Mock OpenRouter

### Helpers (`_shared/testing/helpers.ts`)
- `testFetch()` - Make test requests
- `testCORS()` - Test CORS
- `measureResponseTime()` - Performance
- `assertResponse()` - Response assertions

## Coverage Targets

- Line Coverage: 80%
- Branch Coverage: 75%
- Function Coverage: 85%

## CI/CD

Tests run automatically on PR:
1. Lint check
2. Format check
3. Type check
4. Unit tests
5. Integration tests
6. Coverage report
7. Security scan

See `.github/workflows/edge-functions-test.yml`

## Resources

- [TESTING.md](./TESTING.md) - Full testing guide
- [example_test.ts](./_shared/testing/example_test.ts) - Example tests
- [hello-world/test.ts](./hello-world/test.ts) - Real-world example
- [Deno Testing](https://deno.land/manual/testing) - Deno docs
