// Tests for hello-world edge function
// Run with: deno test --allow-all

import { assertEquals, assertExists } from "https://deno.land/std@0.224.0/testing/asserts.ts";
import {
  testRequest,
  assertResponseStatus,
  assertCorsHeaders,
  parseJsonResponse,
  assertResponseTime,
} from "../_shared/test-utils/test-helpers.ts";
import { mockTokens } from "../_shared/test-fixtures/mock-data.ts";

// Test configuration
const FUNCTION_URL = Deno.env.get("FUNCTION_URL") || "http://localhost:54321/functions/v1/hello-world";

Deno.test("hello-world: Basic request returns 200", async () => {
  const response = await testRequest("hello-world", {
    body: { name: "Test" },
  });

  assertResponseStatus(response, 200);
});

Deno.test("hello-world: Returns correct message structure", async () => {
  const response = await testRequest("hello-world", {
    body: { name: "Deno" },
  });

  const data = await parseJsonResponse(response);

  assertExists(data.message);
  assertExists(data.timestamp);
  assertEquals(data.message, "Hello, Deno!");
});

Deno.test("hello-world: Default name is 'World'", async () => {
  const response = await testRequest("hello-world", {
    body: {},
  });

  const data = await parseJsonResponse(response);
  assertEquals(data.message, "Hello, World!");
});

Deno.test("hello-world: CORS headers present", async () => {
  const response = await testRequest("hello-world", {
    method: "OPTIONS",
  });

  assertResponseStatus(response, 200);
  assertCorsHeaders(response);
});

Deno.test("hello-world: Handles invalid JSON gracefully", async () => {
  // Note: This test uses fetch directly since testRequest auto-stringifies body
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: "invalid json",
  });

  // Should still return 200 with default values
  assertResponseStatus(response, 200);
  const data = await parseJsonResponse(response);
  assertEquals(data.message, "Hello, World!");
});

Deno.test("hello-world: Database check works when enabled", async () => {
  const response = await testRequest("hello-world", {
    body: { name: "Test", includeDatabase: true },
  });

  assertResponseStatus(response, 200);
  const data = await parseJsonResponse(response);

  assertExists(data.databaseCheck);
  assertEquals(typeof data.databaseCheck.connected, "boolean");
});

// Performance test
Deno.test("hello-world: Response time is reasonable", async () => {
  const start = performance.now();

  await testRequest("hello-world", {
    body: { name: "Performance" },
  });

  // Should respond within 1 second (adjust as needed)
  assertResponseTime(start, 1000, "hello-world");
});
