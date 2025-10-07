// Tests for hello-world edge function
// Run with: deno test --allow-all

import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";

// Test configuration
const FUNCTION_URL = Deno.env.get("FUNCTION_URL") ||
  "http://localhost:54321/functions/v1/hello-world";

Deno.test({
  name: "hello-world: Basic request returns 200",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name: "Test" }),
    });

    assertEquals(response.status, 200);
  },
});

Deno.test({
  name: "hello-world: Returns correct message structure",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name: "Deno" }),
    });

    const data = await response.json();

    assertExists(data.message);
    assertExists(data.timestamp);
    assertEquals(data.message, "Hello, Deno!");
  },
});

Deno.test({
  name: "hello-world: Default name is 'World'",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    });

    const data = await response.json();
    assertEquals(data.message, "Hello, World!");
  },
});

Deno.test({
  name: "hello-world: CORS headers present",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "OPTIONS",
    });

    assertEquals(response.status, 200);
    assertExists(response.headers.get("Access-Control-Allow-Origin"));
  },
});

Deno.test({
  name: "hello-world: Handles invalid JSON gracefully",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: "invalid json",
    });

    // Should still return 200 with default values
    assertEquals(response.status, 200);
    const data = await response.json();
    assertEquals(data.message, "Hello, World!");
  },
});

Deno.test({
  name: "hello-world: Database check works when enabled",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name: "Test", includeDatabase: true }),
    });

    assertEquals(response.status, 200);
    const data = await response.json();

    assertExists(data.databaseCheck);
    assertEquals(typeof data.databaseCheck.connected, "boolean");
  },
});

// Performance test
Deno.test({
  name: "hello-world: Response time is reasonable",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const start = performance.now();

    await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name: "Performance" }),
    });

    const duration = performance.now() - start;

    // Should respond within 1 second (adjust as needed)
    assertEquals(duration < 1000, true, `Response took ${duration}ms`);
  },
});
