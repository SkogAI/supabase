// Example test demonstrating all testing utilities
// This file serves as documentation and can be used as a template
// Run with: deno test --allow-all

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";

// Import fixtures
import {
  generateTestJWT,
  retry,
  testHeaders,
  testMessages,
  testUrls,
  testUsers,
  waitFor,
} from "./fixtures.ts";

// Import mocks
import {
  createMockResponse,
  MockFetch,
  mockOpenAIResponse,
  mockOpenRouterResponse,
  MockSupabaseClient,
} from "./mocks.ts";

// Import helpers
import {
  assertJsonStructure,
  assertResponse,
  generateTestData,
  measureResponseTime,
  testConcurrent,
  testCORS,
  testFetch,
  testPatterns,
  waitForCondition,
} from "./helpers.ts";

// Example 1: Basic test with fixtures
Deno.test("example: using test fixtures", () => {
  // Use pre-defined test users
  assertEquals(testUsers.alice.email, "alice@example.com");
  assertEquals(testUsers.bob.id, "00000000-0000-0000-0000-000000000002");

  // Use test messages
  assertEquals(testMessages.simple.length, 1);
  assertEquals(testMessages.conversation.length, 3);
});

// Example 2: Mock fetch responses
Deno.test("example: mock fetch response", async () => {
  const mockFetch = new MockFetch();

  // Add a mock JSON response
  mockFetch.addJsonMock(
    "https://api.example.com/data",
    { message: "success", data: [1, 2, 3] },
    200,
  );

  // Use the mock
  const response = await mockFetch.fetch("https://api.example.com/data");
  const data = await response.json();

  assertEquals(data.message, "success");
  assertEquals(mockFetch.getCallCount("https://api.example.com/data"), 1);
});

// Example 3: Mock OpenAI response
Deno.test("example: mock OpenAI API", () => {
  const response = mockOpenAIResponse("Hello, world!") as {
    choices: Array<{ message: { content: string } }>;
  };

  assertExists(response.choices);
  assertEquals(response.choices[0].message.content, "Hello, world!");
});

// Example 4: Mock Supabase client
Deno.test("example: mock Supabase client", async () => {
  const mockClient = new MockSupabaseClient();

  // Set mock data
  mockClient.setTableData("profiles", [
    { id: "1", name: "Alice" },
    { id: "2", name: "Bob" },
  ]);

  // Query the mock
  const { data, error } = await mockClient
    .from("profiles")
    .select("*")
    .eq("id", "1")
    .single();

  assertEquals(error, null);
  assertEquals((data as { name: string }).name, "Alice");
});

// Example 5: Generate test JWT
Deno.test("example: generate test JWT", () => {
  const token = generateTestJWT(testUsers.alice.id);

  assertExists(token);
  assertStringIncludes(token, ".");
});

// Example 6: Using test helpers - CORS check
Deno.test({
  name: "example: test CORS headers",
  ignore: true, // Skip in this example file
  async fn() {
    const cors = await testCORS("hello-world");

    assertEquals(cors.hasOrigin, true);
    assertEquals(cors.status, 200);
  },
});

// Example 7: Performance testing
Deno.test({
  name: "example: measure response time",
  ignore: true, // Skip in this example file
  async fn() {
    const { duration, response } = await measureResponseTime("hello-world", {
      name: "test",
    });

    assertEquals(response.status, 200);
    assertEquals(duration < 1000, true);
  },
});

// Example 8: Concurrent requests
Deno.test({
  name: "example: test concurrent requests",
  ignore: true, // Skip in this example file
  async fn() {
    const { responses, avgTime } = await testConcurrent("hello-world", 5, {
      name: "test",
    });

    responses.forEach((response) => {
      assertEquals(response.status, 200);
    });

    console.log(`Average response time: ${avgTime}ms`);
  },
});

// Example 9: Assert JSON structure
Deno.test("example: validate JSON structure", () => {
  const data = {
    message: "Hello",
    timestamp: "2024-01-01T00:00:00Z",
    user: { id: "123", name: "Test" },
  };

  const { valid, missingKeys } = assertJsonStructure(data, [
    "message",
    "timestamp",
    "user",
  ]);

  assertEquals(valid, true);
  assertEquals(missingKeys.length, 0);
});

// Example 10: Generate random test data
Deno.test("example: generate test data", () => {
  const randomString = generateTestData.string(10);
  const randomEmail = generateTestData.email();
  const randomUuid = generateTestData.uuid();
  const randomNumber = generateTestData.number(1, 100);

  assertEquals(randomString.length, 10);
  assertStringIncludes(randomEmail, "@example.com");
  assertEquals(randomUuid.length, 36);
  assertEquals(randomNumber >= 1 && randomNumber <= 100, true);
});

// Example 11: Assert response structure
Deno.test({
  name: "example: assert response structure",
  ignore: true, // Skip in this example file
  async fn() {
    const response = await testFetch("hello-world", {
      body: { name: "test" },
    });

    const { valid, errors } = await assertResponse(response, {
      status: 200,
      headers: { "Content-Type": "application/json" },
      bodyKeys: ["message", "timestamp"],
    });

    assertEquals(valid, true);
    assertEquals(errors.length, 0);
  },
});

// Example 12: Retry flaky operations
Deno.test("example: retry mechanism", async () => {
  let attempts = 0;

  const result = await retry(
    async () => {
      attempts++;
      if (attempts < 2) {
        throw new Error("Simulated failure");
      }
      return "success";
    },
    3,
    10,
  );

  assertEquals(result, "success");
  assertEquals(attempts, 2);
});

// Example 13: Wait for condition
Deno.test("example: wait for condition", async () => {
  let counter = 0;

  // Simulate async state change
  setTimeout(() => {
    counter = 5;
  }, 50);

  // Import from fixtures.ts (waitFor is a simple delay helper)
  await waitFor(100);

  assertEquals(counter, 5);
});

// Example 14: Test pattern - basic flow
Deno.test({
  name: "example: test pattern - basic flow",
  ignore: true, // Skip in this example file
  async fn() {
    const response = await testPatterns.basicFlow("hello-world", {
      name: "test",
    });

    assertEquals(response.status, 200);
  },
});

// Example 15: Using headers from fixtures
Deno.test("example: using test headers", () => {
  // JSON headers
  assertEquals(testHeaders.json["Content-Type"], "application/json");

  // JSON with auth
  const authHeaders = testHeaders.jsonWithAuth("test_token");
  assertExists(authHeaders.Authorization);
  assertStringIncludes(authHeaders.Authorization, "Bearer");
});

// Example 16: Using test URLs
Deno.test("example: using test URLs", () => {
  const functionUrl = testUrls.getFunctionUrl("my-function");

  assertStringIncludes(functionUrl, "functions/v1/my-function");
});

// Example 17: Integration test example
Deno.test({
  name: "example: integration test",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"), // Only runs when flag is set
  async fn() {
    // This test would only run when RUN_INTEGRATION_TESTS=true
    const response = await testFetch("hello-world", {
      body: { name: "integration test" },
    });

    assertEquals(response.status, 200);

    // Could also verify database state, etc.
  },
});

// Example 18: Error handling test
Deno.test({
  name: "example: error handling",
  ignore: true, // Skip in this example file
  async fn() {
    const { hasError, errorMessage } = await testPatterns.errorHandling(
      "hello-world",
      { invalid: "data" },
    );

    // Verify error is handled gracefully
    assertExists(hasError);
  },
});

// Example 19: Mock multiple API calls
Deno.test("example: mock multiple endpoints", async () => {
  const mockFetch = new MockFetch();

  // Mock multiple endpoints
  mockFetch.addJsonMock("https://api1.example.com/data", { data: "api1" });
  mockFetch.addJsonMock("https://api2.example.com/data", { data: "api2" });

  // Fetch from both
  const response1 = await mockFetch.fetch("https://api1.example.com/data");
  const response2 = await mockFetch.fetch("https://api2.example.com/data");

  const data1 = await response1.json();
  const data2 = await response2.json();

  assertEquals(data1.data, "api1");
  assertEquals(data2.data, "api2");

  // Verify both were called
  assertEquals(mockFetch.wasCalledWith("https://api1.example.com/data"), true);
  assertEquals(mockFetch.wasCalledWith("https://api2.example.com/data"), true);
});

// Example 20: Create custom mock response
Deno.test("example: create custom mock response", () => {
  const mockResponse = createMockResponse(
    { custom: "data" },
    201,
    { "X-Custom-Header": "value" },
  );

  assertEquals(mockResponse.status, 201);
  assertEquals(mockResponse.headers.get("X-Custom-Header"), "value");
});

/*
 * Summary of Testing Utilities:
 *
 * FIXTURES (fixtures.ts):
 * - testUsers: Pre-defined test users (alice, bob, charlie)
 * - testMessages: Sample chat messages for AI functions
 * - testHeaders: Common HTTP headers
 * - testUrls: Function URLs for testing
 * - generateTestJWT(): Create test JWT tokens
 * - retry(): Retry flaky operations
 * - waitFor(): Wait for async conditions
 *
 * MOCKS (mocks.ts):
 * - MockFetch: Mock HTTP fetch calls
 * - MockSupabaseClient: Mock Supabase database client
 * - mockOpenAIResponse(): Create OpenAI API mock responses
 * - mockOpenRouterResponse(): Create OpenRouter API mock responses
 * - createMockResponse(): Create custom Response objects
 *
 * HELPERS (helpers.ts):
 * - testFetch(): Make test requests to functions
 * - testCORS(): Test CORS headers
 * - measureResponseTime(): Performance testing
 * - testConcurrent(): Test concurrent requests
 * - assertJsonStructure(): Validate JSON structure
 * - assertResponse(): Comprehensive response assertions
 * - generateTestData: Random test data generators
 * - testPatterns: Common test pattern implementations
 *
 * Best Practices:
 * 1. Use fixtures for consistent test data
 * 2. Mock external APIs to avoid real API calls
 * 3. Use helpers to reduce boilerplate
 * 4. Test edge cases and error handling
 * 5. Clean up test data after integration tests
 * 6. Make tests independent and repeatable
 * 7. Use descriptive test names
 * 8. Group related tests
 * 9. Skip integration tests by default (use RUN_INTEGRATION_TESTS flag)
 * 10. Measure and verify performance
 */
