# Edge Functions Testing Guide

Comprehensive guide for testing Supabase Edge Functions using Deno's built-in test framework.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Test Types](#test-types)
- [Writing Tests](#writing-tests)
- [Test Utilities](#test-utilities)
- [Running Tests](#running-tests)
- [Coverage](#coverage)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Our testing framework provides:

- ✅ **Unit Tests** - Test individual functions and logic
- ✅ **Integration Tests** - Test with live Supabase instance
- ✅ **Performance Tests** - Monitor response times and resource usage
- ✅ **Security Tests** - Verify authentication and authorization
- ✅ **Coverage Reporting** - Track test coverage metrics
- ✅ **CI/CD Integration** - Automated testing on every PR

## Quick Start

### 1. Run Existing Tests

```bash
cd supabase/functions
deno test --allow-all
```

### 2. Run Tests for Specific Function

```bash
cd supabase/functions
deno test --allow-all hello-world/test.ts
```

### 3. Run Tests with Coverage

```bash
cd supabase/functions
deno test --allow-all --coverage=coverage
deno coverage coverage --lcov --output=coverage.lcov
```

## Test Types

### Unit Tests

Test individual functions without external dependencies:

```typescript
import { assertEquals } from "https://deno.land/std@0.224.0/testing/asserts.ts";

Deno.test("Function: validates input", () => {
  const result = validateInput({ name: "Test" });
  assertEquals(result.valid, true);
});
```

### Integration Tests

Test with a running Supabase instance:

```typescript
import { testRequest, assertResponseStatus } from "../_shared/test-utils/test-helpers.ts";

Deno.test("Function: creates user profile", async () => {
  const response = await testRequest("create-profile", {
    body: { name: "John Doe", email: "john@example.com" },
  });
  
  assertResponseStatus(response, 201);
});
```

### Performance Tests

Monitor response times:

```typescript
import { assertResponseTime } from "../_shared/test-utils/test-helpers.ts";

Deno.test("Function: responds within 500ms", async () => {
  const start = performance.now();
  
  await testRequest("fast-function", {
    body: { data: "test" },
  });
  
  assertResponseTime(start, 500, "Fast function");
});
```

### Security Tests

Verify authentication and authorization:

```typescript
import { mockTokens } from "../_shared/test-fixtures/mock-data.ts";

Deno.test("Function: requires authentication", async () => {
  const response = await testRequest("protected-function", {
    body: { data: "test" },
  });
  
  assertEquals(response.status, 401);
});

Deno.test("Function: accepts valid token", async () => {
  const response = await testRequest("protected-function", {
    token: mockTokens.validUser1,
    body: { data: "test" },
  });
  
  assertEquals(response.status, 200);
});
```

## Writing Tests

### Test Structure

Follow this structure for consistency:

```typescript
// Import assertions
import { assertEquals, assertExists } from "https://deno.land/std@0.224.0/testing/asserts.ts";

// Import test utilities
import { testRequest, assertResponseStatus } from "../_shared/test-utils/test-helpers.ts";

// Import mock data
import { mockUsers } from "../_shared/test-fixtures/mock-data.ts";

// Configuration
const FUNCTION_URL = Deno.env.get("FUNCTION_URL") || "http://localhost:54321/functions/v1";

// Test group 1: Basic functionality
Deno.test("function-name: Basic test", async () => {
  // Arrange
  const input = { name: "Test" };
  
  // Act
  const response = await testRequest("function-name", { body: input });
  
  // Assert
  assertResponseStatus(response, 200);
});

// Test group 2: Edge cases
Deno.test("function-name: Handles invalid input", async () => {
  // Test implementation
});

// Test group 3: Error handling
Deno.test("function-name: Returns error on failure", async () => {
  // Test implementation
});
```

### Naming Conventions

Use descriptive test names:

```typescript
// ✅ Good - descriptive and clear
Deno.test("user-profile: Creates profile with valid data", async () => {});
Deno.test("user-profile: Returns 400 for missing email", async () => {});
Deno.test("user-profile: Requires authentication", async () => {});

// ❌ Bad - vague and unclear
Deno.test("test1", async () => {});
Deno.test("profile test", async () => {});
```

### Arrange-Act-Assert Pattern

Structure tests clearly:

```typescript
Deno.test("function-name: Descriptive name", async () => {
  // Arrange - Set up test data and conditions
  const testData = { name: "Test", email: "test@example.com" };
  const expectedResponse = { success: true };
  
  // Act - Execute the function being tested
  const response = await testRequest("function-name", { body: testData });
  const data = await response.json();
  
  // Assert - Verify the results
  assertEquals(response.status, 200);
  assertEquals(data.success, expectedResponse.success);
});
```

## Test Utilities

### Available Helpers

See [_shared/README.md](./_shared/README.md) for complete documentation of test utilities.

Quick reference:

```typescript
import {
  testRequest,           // Make test requests
  assertResponseStatus,  // Assert status codes
  assertCorsHeaders,     // Check CORS headers
  parseJsonResponse,     // Parse JSON safely
  assertResponseTime,    // Check performance
  waitFor,              // Wait for conditions
  retry,                // Retry with backoff
  randomString,         // Generate test data
} from "../_shared/test-utils/test-helpers.ts";

import {
  mockUsers,            // Sample users
  mockProfiles,         // Sample profiles
  mockTokens,           // JWT tokens
  mockApiResponses,     // API responses
} from "../_shared/test-fixtures/mock-data.ts";
```

## Running Tests

### Local Development

```bash
# Run all tests
cd supabase/functions
deno test --allow-all

# Run with watch mode (auto-rerun on changes)
deno test --allow-all --watch

# Run specific test file
deno test --allow-all hello-world/test.ts

# Run tests matching pattern
deno test --allow-all --filter "hello-world"

# Run with verbose output
deno test --allow-all --parallel --jobs=4
```

### With Supabase Running

For integration tests that need a database:

```bash
# Terminal 1: Start Supabase
supabase start

# Terminal 2: Run tests
cd supabase/functions
deno test --allow-all

# Or use the npm script
npm run test:functions
```

### Using Deno Tasks

Tasks are defined in `deno.json`:

```bash
# Run tests
deno task test

# Run tests with watch mode
deno task test:watch

# Generate coverage report
deno task test:coverage

# Check types
deno task check

# Lint code
deno task lint

# Format code
deno task fmt
```

## Coverage

### Generate Coverage Reports

```bash
# Run tests with coverage
cd supabase/functions
deno test --allow-all --coverage=coverage

# Generate LCOV report
deno coverage coverage --lcov --output=coverage.lcov

# View coverage in browser (requires lcov-report tool)
genhtml coverage.lcov -o coverage-html
open coverage-html/index.html
```

### Coverage Goals

- **Minimum Coverage**: 80% overall
- **Critical Functions**: 90%+ coverage
- **New Functions**: 100% coverage required

### Viewing Coverage in CI

Coverage reports are automatically generated in CI and available in:
- GitHub Actions workflow summary
- PR comments (if configured)
- Coverage tracking services (e.g., Codecov, Coveralls)

## CI/CD Integration

Tests run automatically via GitHub Actions on:
- Every pull request
- Every push to `main` branch
- Manual workflow trigger

### Workflow: edge-functions-test.yml

The CI pipeline includes:

1. **Formatting Check** - Ensures code is properly formatted
2. **Linting** - Checks for code quality issues
3. **Type Checking** - Verifies TypeScript types
4. **Unit Tests** - Runs all test files
5. **Integration Tests** - Tests with live Supabase instance
6. **Coverage Report** - Generates and reports coverage

### Local CI Simulation

Test what will run in CI locally:

```bash
cd supabase/functions

# 1. Format check
deno fmt --check

# 2. Lint
deno lint

# 3. Type check
deno check **/*.ts

# 4. Run tests
deno test --allow-all --coverage=coverage

# 5. Generate coverage
deno coverage coverage --lcov --output=coverage.lcov
```

## Best Practices

### 1. Test Independence

Each test should be independent:

```typescript
// ✅ Good - independent test
Deno.test("function: creates user", async () => {
  const userId = randomString();
  const response = await createUser({ id: userId });
  assertEquals(response.status, 201);
});

// ❌ Bad - depends on previous test
let globalUserId: string;
Deno.test("function: creates user", async () => {
  const response = await createUser();
  globalUserId = response.data.id; // Don't do this
});
```

### 2. Use Test Fixtures

Reuse mock data from fixtures:

```typescript
// ✅ Good
import { mockUsers } from "../_shared/test-fixtures/mock-data.ts";
const user = mockUsers[0];

// ❌ Bad - hardcoded data scattered everywhere
const user = { id: "123", email: "test@test.com" };
```

### 3. Test Error Cases

Always test error scenarios:

```typescript
// Test happy path
Deno.test("function: succeeds with valid input", async () => {
  // ...
});

// Test error cases
Deno.test("function: handles missing field", async () => {
  // ...
});

Deno.test("function: handles invalid format", async () => {
  // ...
});

Deno.test("function: handles unauthorized access", async () => {
  // ...
});
```

### 4. Test Edge Cases

Consider boundary conditions:

```typescript
Deno.test("function: handles empty string", async () => {});
Deno.test("function: handles very long string", async () => {});
Deno.test("function: handles null values", async () => {});
Deno.test("function: handles special characters", async () => {});
```

### 5. Clean Assertions

Use clear, specific assertions:

```typescript
// ✅ Good - specific assertion
assertEquals(response.status, 200, "Should return success status");
assertExists(data.id, "Response should include ID");

// ❌ Bad - vague assertion
assertEquals(response.ok, true);
```

### 6. Performance Considerations

Set reasonable timeouts:

```typescript
Deno.test("function: responds quickly", async () => {
  const start = performance.now();
  await testRequest("function-name");
  const duration = performance.now() - start;
  
  // Adjust threshold based on function complexity
  assertEquals(duration < 1000, true, `Took ${duration}ms`);
});
```

### 7. Cleanup

Clean up after tests when necessary:

```typescript
Deno.test("function: with cleanup", async () => {
  // Setup
  const testData = await createTestData();
  
  try {
    // Test
    const response = await testRequest("function-name", {
      body: testData,
    });
    assertEquals(response.status, 200);
  } finally {
    // Cleanup
    await deleteTestData(testData.id);
  }
});
```

## Troubleshooting

### Common Issues

#### Tests Fail Locally But Pass in CI

```bash
# Ensure you're using the same Deno version
deno --version

# Check if Supabase is running
supabase status

# Clear any cached data
rm -rf coverage/
```

#### Timeout Errors

```typescript
// Increase timeout for slow operations
Deno.test({
  name: "slow operation",
  fn: async () => {
    // Test implementation
  },
  sanitizeOps: false,
  sanitizeResources: false,
});
```

#### Permission Errors

```bash
# Ensure --allow-all flag is used
deno test --allow-all

# Or specify specific permissions
deno test --allow-net --allow-env --allow-read
```

#### Import Errors

```bash
# Clear Deno cache
deno cache --reload test.ts

# Check import URLs are correct
deno check test.ts
```

### Debug Mode

Enable debug output:

```typescript
Deno.test("debug test", async () => {
  console.log("Debug: Starting test");
  const response = await testRequest("function-name");
  console.log("Debug: Response status:", response.status);
  console.log("Debug: Response body:", await response.text());
});
```

### Test Isolation

If tests interfere with each other:

```bash
# Run tests sequentially
deno test --allow-all --jobs=1

# Run specific test
deno test --allow-all --filter "specific-test-name"
```

## Resources

- [Deno Testing Documentation](https://deno.land/manual/testing)
- [Deno Standard Library Assertions](https://deno.land/std/testing)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Test Utilities README](./_shared/README.md)
- [Edge Functions README](./README.md)

## Contributing

When adding new functions:

1. ✅ Create a `test.ts` file in the function directory
2. ✅ Include unit tests for all logic paths
3. ✅ Add integration tests for API endpoints
4. ✅ Test error handling and edge cases
5. ✅ Aim for 90%+ code coverage
6. ✅ Use shared test utilities
7. ✅ Document any special test requirements

## Questions?

- Check existing tests for examples: `hello-world/test.ts`
- Review shared utilities: `_shared/README.md`
- See main Edge Functions docs: `README.md`
- Check DEVOPS guide: `../../DEVOPS.md`
