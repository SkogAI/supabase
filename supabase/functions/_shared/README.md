# Shared Test Utilities

This directory contains shared utilities, helpers, and fixtures for testing edge functions.

## Directory Structure

```
_shared/
├── README.md
├── test-utils/
│   └── test-helpers.ts    # Common test utilities and helpers
└── test-fixtures/
    └── mock-data.ts       # Mock data and fixtures
```

## Test Utilities

### test-helpers.ts

Provides common testing utilities:

- **`getTestConfig()`** - Get test configuration from environment
- **`testRequest()`** - Create a test request with common defaults
- **`assertResponseStatus()`** - Assert response has expected status
- **`assertCorsHeaders()`** - Assert CORS headers are present
- **`parseJsonResponse()`** - Parse JSON response with error handling
- **`assertResponseTime()`** - Assert response time is within acceptable range
- **`waitFor()`** - Wait for a condition to be true with timeout
- **`retry()`** - Retry a function with exponential backoff
- **`createMockSupabaseClient()`** - Create a mock Supabase client
- **`randomString()`** - Generate random test data
- **`generateTestToken()`** - Generate test JWT tokens

### Usage Example

```typescript
import {
  testRequest,
  assertResponseStatus,
  parseJsonResponse,
} from "../_shared/test-utils/test-helpers.ts";

Deno.test("My function returns correct response", async () => {
  const response = await testRequest("my-function", {
    body: { name: "Test" },
  });
  
  assertResponseStatus(response, 200);
  
  const data = await parseJsonResponse(response);
  assertEquals(data.message, "Success");
});
```

## Test Fixtures

### mock-data.ts

Provides mock data for testing:

- **`mockUsers`** - Sample user data
- **`mockProfiles`** - Sample profile data
- **`mockPosts`** - Sample post data
- **`mockTokens`** - JWT tokens for testing
- **`mockApiResponses`** - Common API response formats
- **`mockRequestBodies`** - Sample request bodies
- **`mockEnv`** - Mock environment variables

### Usage Example

```typescript
import { mockUsers, mockTokens } from "../_shared/test-fixtures/mock-data.ts";

Deno.test("Function handles authenticated user", async () => {
  const response = await testRequest("my-function", {
    token: mockTokens.validUser1,
    body: { data: "test" },
  });
  
  assertResponseStatus(response, 200);
});
```

## Best Practices

### 1. Use Shared Utilities

Always use shared utilities instead of duplicating code:

```typescript
// ✅ Good
import { testRequest } from "../_shared/test-utils/test-helpers.ts";

// ❌ Bad - duplicating code
const response = await fetch("http://localhost:54321/...", {...});
```

### 2. Use Mock Data

Use mock data from fixtures for consistency:

```typescript
// ✅ Good
import { mockUsers } from "../_shared/test-fixtures/mock-data.ts";
const user = mockUsers[0];

// ❌ Bad - hardcoded values
const user = { id: "123", email: "test@test.com" };
```

### 3. Test Configuration

Use environment variables for configuration:

```typescript
import { getTestConfig } from "../_shared/test-utils/test-helpers.ts";

const config = getTestConfig();
const url = `${config.functionUrl}/my-function`;
```

### 4. Assertions

Use helper assertions for common checks:

```typescript
import {
  assertResponseStatus,
  assertCorsHeaders,
  assertResponseTime,
} from "../_shared/test-utils/test-helpers.ts";

const start = performance.now();
const response = await testRequest("my-function");

assertResponseStatus(response, 200);
assertCorsHeaders(response);
assertResponseTime(start, 1000);
```

### 5. Async Operations

Use retry and waitFor utilities for flaky operations:

```typescript
import { retry, waitFor } from "../_shared/test-utils/test-helpers.ts";

// Retry with exponential backoff
const data = await retry(
  () => fetchData(),
  { maxAttempts: 3, delayMs: 1000 }
);

// Wait for condition
await waitFor(
  () => isServiceReady(),
  { timeout: 5000, interval: 100 }
);
```

## Running Tests

```bash
# Run all tests
cd supabase/functions
deno test --allow-all

# Run with coverage
deno test --allow-all --coverage=coverage

# Generate coverage report
deno coverage coverage --lcov --output=coverage.lcov

# Run specific function tests
deno test --allow-all hello-world/test.ts

# Run tests in watch mode
deno test --allow-all --watch
```

## Environment Variables

Set these environment variables for tests:

```bash
# Function URL (defaults to localhost)
export FUNCTION_URL="http://localhost:54321/functions/v1"

# Supabase URL (defaults to localhost)
export SUPABASE_URL="http://localhost:54321"

# Supabase anon key (defaults to demo key)
export SUPABASE_ANON_KEY="your-anon-key"

# Test timeout in milliseconds
export TEST_TIMEOUT="5000"
```

## Adding New Utilities

When adding new utilities:

1. Add them to the appropriate file in `test-utils/`
2. Export them clearly with JSDoc comments
3. Add usage examples to this README
4. Update tests to use the new utilities

## Adding New Fixtures

When adding new fixtures:

1. Add them to `test-fixtures/mock-data.ts`
2. Use consistent data formats
3. Include helper functions to access the data
4. Document the fixture structure
