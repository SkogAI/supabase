# Testing Utilities

Shared testing utilities, fixtures, and mocks for edge function testing.

## Files

### `fixtures.ts`
Test data and fixtures including:
- Test users matching seed data
- Sample messages and API responses
- Test request bodies and headers
- Helper functions for JWT generation, retry logic, etc.

### `mocks.ts`
Mock utilities for testing:
- `MockFetch` - Mock fetch responses
- `MockSupabaseClient` - Mock Supabase client
- Mock API responses (OpenAI, OpenRouter)
- Mock request/response creators

### `helpers.ts`
Test helper functions:
- `testFetch()` - Make test requests to functions
- `testCORS()` - Test CORS headers
- `measureResponseTime()` - Performance testing
- `testConcurrent()` - Concurrent request testing
- Response assertion utilities
- Data generators and cleanup utilities

## Usage

### Import in your test files

```typescript
import {
  testUsers,
  testMessages,
  generateTestJWT,
} from "../_shared/testing/fixtures.ts";

import {
  MockFetch,
  mockOpenAIResponse,
} from "../_shared/testing/mocks.ts";

import {
  testFetch,
  testCORS,
  assertResponse,
} from "../_shared/testing/helpers.ts";
```

### Example: Test with fixtures

```typescript
Deno.test("authenticated request", async () => {
  const token = generateTestJWT(testUsers.alice.id);
  const response = await testFetch("my-function", {
    body: { name: "test" },
    token,
  });
  assertEquals(response.status, 200);
});
```

### Example: Mock external API

```typescript
Deno.test("mocked API call", () => {
  const mockFetch = new MockFetch();
  mockFetch.addJsonMock(
    "https://api.openai.com/v1/chat/completions",
    mockOpenAIResponse("Hello!")
  );

  // Use mockFetch.fetch() in your function
  // or pass it as a parameter
});
```

### Example: Use test helpers

```typescript
Deno.test("CORS headers", async () => {
  const cors = await testCORS("my-function");
  assertEquals(cors.hasOrigin, true);
  assertEquals(cors.status, 200);
});

Deno.test("performance check", async () => {
  const { duration, response } = await measureResponseTime(
    "my-function",
    { test: "data" }
  );
  assertEquals(response.status, 200);
  assertEquals(duration < 1000, true);
});
```

## Best Practices

1. **Use fixtures** for consistent test data
2. **Mock external APIs** to avoid real API calls in tests
3. **Use helpers** to reduce boilerplate code
4. **Clean up** test data after integration tests
5. **Retry flaky tests** with the retry helper
6. **Test edge cases** using the provided test data generators

## Adding New Utilities

When adding new testing utilities:

1. Put reusable test data in `fixtures.ts`
2. Put mock implementations in `mocks.ts`
3. Put helper functions in `helpers.ts`
4. Update this README with usage examples
5. Export all public utilities from each file

## See Also

- [TESTING.md](../TESTING.md) - Comprehensive testing guide
- [hello-world/test.ts](../hello-world/test.ts) - Example tests
