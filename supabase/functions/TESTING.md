# Edge Functions Testing Guide

Comprehensive guide for testing Supabase Edge Functions with Deno test framework.

## Overview

This guide covers unit testing, integration testing, test fixtures, mocking strategies, and CI/CD integration for edge functions.

## Table of Contents

- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Test Fixtures and Mocks](#test-fixtures-and-mocks)
- [Coverage Reporting](#coverage-reporting)
- [Integration Tests](#integration-tests)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)

## Test Structure

Each edge function should have a corresponding `test.ts` file in its directory:

```
functions/
├── my-function/
│   ├── index.ts      # Function implementation
│   └── test.ts       # Unit tests
└── _shared/
    └── testing/
        ├── fixtures.ts   # Test data and fixtures
        ├── mocks.ts      # Mock utilities
        └── helpers.ts    # Test helper functions
```

## Running Tests

### Run All Tests

```bash
# From repository root
npm run test:functions

# Or directly with Deno
cd supabase/functions
deno test --allow-all
```

### Run Specific Function Tests

```bash
cd supabase/functions/<function-name>
deno test --allow-all test.ts
```

### Run with Coverage

```bash
cd supabase/functions
deno test --allow-all --coverage=coverage
deno coverage coverage --lcov > coverage.lcov
```

### Watch Mode

```bash
cd supabase/functions/<function-name>
deno test --allow-all --watch test.ts
```

### Parallel Execution

```bash
# Deno runs tests in parallel by default
# To run sequentially:
deno test --allow-all --jobs=1
```

## Writing Tests

### Basic Test Structure

```typescript
import { assertEquals, assertExists } from "std/testing/asserts.ts";

// Test configuration
const FUNCTION_URL = Deno.env.get("FUNCTION_URL") || 
  "http://localhost:54321/functions/v1/my-function";

Deno.test("my-function: description of what it tests", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ key: "value" }),
  });

  assertEquals(response.status, 200);
  const data = await response.json();
  assertExists(data);
});
```

### Available Assertions

```typescript
import {
  assertEquals,      // Strict equality (===)
  assertNotEquals,   // Strict inequality (!==)
  assertExists,      // Not null or undefined
  assertStrictEquals, // Same object reference
  assertMatch,       // Regex matching
  assertArrayIncludes, // Array contains items
  assertStringIncludes, // String contains substring
  assertThrows,      // Function throws error
  assertRejects,     // Async function rejects
} from "std/testing/asserts.ts";
```

### Test Categories

#### 1. Request/Response Tests

```typescript
Deno.test("returns correct status code", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: "test" }),
  });
  assertEquals(response.status, 200);
});

Deno.test("returns correct response structure", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: "test" }),
  });
  
  const data = await response.json();
  assertExists(data.message);
  assertExists(data.timestamp);
});
```

#### 2. CORS Tests

```typescript
Deno.test("handles CORS preflight", async () => {
  const response = await fetch(FUNCTION_URL, { method: "OPTIONS" });
  assertEquals(response.status, 200);
  assertExists(response.headers.get("Access-Control-Allow-Origin"));
  assertExists(response.headers.get("Access-Control-Allow-Headers"));
});
```

#### 3. Authentication Tests

```typescript
Deno.test("requires authentication", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: "test" }),
  });
  // Depending on your implementation
  assertEquals(response.status, 401);
});

Deno.test("accepts valid JWT token", async () => {
  const token = "valid_jwt_token"; // Use test fixture
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ name: "test" }),
  });
  assertEquals(response.status, 200);
});
```

#### 4. Error Handling Tests

```typescript
Deno.test("handles invalid JSON gracefully", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "invalid json",
  });
  assertEquals(response.status, 400);
});

Deno.test("returns error for missing required fields", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  const data = await response.json();
  assertExists(data.error);
});
```

#### 5. Performance Tests

```typescript
Deno.test("responds within acceptable time", async () => {
  const start = performance.now();
  await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: "test" }),
  });
  const duration = performance.now() - start;
  assertEquals(duration < 1000, true, `Took ${duration}ms`);
});
```

## Test Fixtures and Mocks

### Creating Fixtures

Create `_shared/testing/fixtures.ts`:

```typescript
export const testUsers = {
  alice: {
    id: "00000000-0000-0000-0000-000000000001",
    email: "alice@example.com",
  },
  bob: {
    id: "00000000-0000-0000-0000-000000000002",
    email: "bob@example.com",
  },
};

export const testMessages = [
  { role: "user", content: "Hello" },
  { role: "assistant", content: "Hi there!" },
];

export function generateTestJWT(userId: string): string {
  // Generate test JWT token
  return `test_jwt_${userId}`;
}
```

### Using Fixtures

```typescript
import { testUsers, generateTestJWT } from "../_shared/testing/fixtures.ts";

Deno.test("authenticated request with test user", async () => {
  const token = generateTestJWT(testUsers.alice.id);
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ name: "test" }),
  });
  assertEquals(response.status, 200);
});
```

### Mocking External APIs

Create `_shared/testing/mocks.ts`:

```typescript
export class MockFetch {
  private responses: Map<string, Response> = new Map();

  addMock(url: string, response: Response) {
    this.responses.set(url, response);
  }

  fetch(url: string): Promise<Response> {
    const response = this.responses.get(url);
    if (!response) {
      throw new Error(`No mock for ${url}`);
    }
    return Promise.resolve(response);
  }
}

export function mockOpenAIResponse(content: string) {
  return {
    choices: [
      {
        message: {
          role: "assistant",
          content: content,
        },
      },
    ],
  };
}
```

## Coverage Reporting

### Generate Coverage

```bash
# Run tests with coverage
cd supabase/functions
deno test --allow-all --coverage=coverage

# Generate coverage report
deno coverage coverage

# Generate LCOV format (for CI tools)
deno coverage coverage --lcov > coverage.lcov

# Generate HTML report
deno coverage coverage --html
```

### Coverage Thresholds

Aim for these minimum coverage targets:
- **Line Coverage**: 80%
- **Branch Coverage**: 75%
- **Function Coverage**: 85%

### Checking Coverage

```bash
# View coverage summary
deno coverage coverage

# View detailed coverage for specific file
deno coverage coverage --include="hello-world/index.ts"
```

## Integration Tests

Integration tests verify the function works with real Supabase services.

### Setup for Integration Tests

```typescript
import { createClient } from "@supabase/supabase-js";

// Integration test - requires Supabase running
Deno.test({
  name: "integration: function creates database record",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    // Setup
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Test
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "integration test" }),
    });

    assertEquals(response.status, 200);

    // Verify in database
    const { data } = await supabase
      .from("table_name")
      .select("*")
      .eq("name", "integration test")
      .single();

    assertExists(data);

    // Cleanup
    await supabase.from("table_name").delete().eq("id", data.id);
  },
});
```

### Running Integration Tests

```bash
# Start Supabase first
supabase start

# Run integration tests
RUN_INTEGRATION_TESTS=true deno test --allow-all
```

## CI/CD Integration

Tests run automatically in CI pipeline via `.github/workflows/edge-functions-test.yml`:

### CI Test Workflow

1. **Lint**: Check code style with `deno lint`
2. **Format Check**: Verify formatting with `deno fmt --check`
3. **Type Check**: Validate TypeScript with `deno check`
4. **Unit Tests**: Run all unit tests
5. **Integration Tests**: Test with Supabase running
6. **Coverage**: Generate and upload coverage reports

### Local CI Simulation

```bash
# Run the same checks as CI
cd supabase/functions

# 1. Lint
deno lint

# 2. Format check
deno fmt --check

# 3. Type check all functions
deno check */index.ts

# 4. Run tests
deno test --allow-all

# 5. Generate coverage
deno test --allow-all --coverage=coverage
deno coverage coverage
```

## Best Practices

### 1. Test Organization

- Keep tests close to the code they test
- Use descriptive test names: `"function-name: what it tests"`
- Group related tests using nested `Deno.test` blocks
- One assertion per test when possible

### 2. Test Independence

```typescript
// ❌ Bad: Tests depend on each other
let sharedState: any;

Deno.test("test 1", () => {
  sharedState = { value: 1 };
});

Deno.test("test 2", () => {
  assertEquals(sharedState.value, 1); // Depends on test 1
});

// ✅ Good: Each test is independent
Deno.test("test 1", () => {
  const state = { value: 1 };
  assertEquals(state.value, 1);
});

Deno.test("test 2", () => {
  const state = { value: 1 };
  assertEquals(state.value, 1);
});
```

### 3. Use Setup and Teardown

```typescript
Deno.test({
  name: "test with setup and teardown",
  async fn() {
    // Setup
    const resource = await createResource();

    try {
      // Test
      const result = await testFunction(resource);
      assertEquals(result, expectedValue);
    } finally {
      // Cleanup
      await cleanupResource(resource);
    }
  },
});
```

### 4. Test Edge Cases

```typescript
Deno.test("handles empty input", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  });
  assertEquals(response.status, 200);
});

Deno.test("handles very large input", async () => {
  const largeData = "x".repeat(10000);
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ data: largeData }),
  });
  assertExists(response);
});

Deno.test("handles special characters", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: "Test <script>alert('xss')</script>" }),
  });
  assertEquals(response.status, 200);
});
```

### 5. Mock External Dependencies

```typescript
// Use dependency injection for testability
Deno.test("mocked external API", async () => {
  const mockFetch = (url: string) => {
    return Promise.resolve(
      new Response(JSON.stringify({ data: "mocked" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      })
    );
  };

  // Test with mock
  const result = await functionWithFetch(mockFetch);
  assertEquals(result.data, "mocked");
});
```

### 6. Test Error Scenarios

```typescript
Deno.test("handles network timeout", async () => {
  const controller = new AbortController();
  setTimeout(() => controller.abort(), 100);

  try {
    await fetch(FUNCTION_URL, {
      method: "POST",
      signal: controller.signal,
    });
  } catch (error) {
    assertEquals(error.name, "AbortError");
  }
});
```

### 7. Performance Testing

```typescript
Deno.test("handles concurrent requests", async () => {
  const requests = Array(10).fill(null).map(() =>
    fetch(FUNCTION_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "concurrent" }),
    })
  );

  const responses = await Promise.all(requests);
  responses.forEach(response => {
    assertEquals(response.status, 200);
  });
});
```

## Debugging Tests

### Enable Verbose Output

```bash
deno test --allow-all --log-level=debug
```

### Debug Single Test

```bash
# Run only tests matching pattern
deno test --allow-all --filter "my specific test"
```

### Use Deno Inspector

```bash
# Start with debugger
deno test --allow-all --inspect-brk test.ts

# Connect Chrome DevTools to chrome://inspect
```

## Common Issues

### Issue: Function not accessible during tests

**Solution**: Ensure Supabase is running and function is served:
```bash
supabase start
supabase functions serve
```

### Issue: Tests fail with permission errors

**Solution**: Run with `--allow-all` flag:
```bash
deno test --allow-all
```

### Issue: Environment variables not set

**Solution**: Set required variables:
```bash
export FUNCTION_URL=http://localhost:54321/functions/v1/my-function
deno test --allow-all
```

### Issue: Flaky integration tests

**Solution**: Add proper waits and retries:
```typescript
async function retryFetch(url: string, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fetch(url);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
}
```

## Resources

- [Deno Testing Documentation](https://deno.land/manual/testing)
- [Deno Standard Testing Library](https://deno.land/std/testing)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Supabase Local Development](https://supabase.com/docs/guides/cli/local-development)

## Examples

See the following functions for testing examples:
- `hello-world/test.ts` - Comprehensive unit tests
- `openai-chat/test.ts` - Mocking external APIs
- `openrouter-chat/test.ts` - Multiple integration scenarios
