// Tests for health-check edge function
// Run with: deno test --allow-all
// Or with integration tests: RUN_INTEGRATION_TESTS=1 deno test --allow-all

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";

// Test configuration
const FUNCTION_URL = Deno.env.get("FUNCTION_URL") ||
  "http://localhost:54321/functions/v1/health-check";

Deno.test({
  name: "health-check: Basic request returns 200",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    });

    assertEquals(response.status, 200);
  },
});

Deno.test({
  name: "health-check: Returns correct structure for simple mode",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(`${FUNCTION_URL}?mode=simple`, {
      method: "GET",
    });

    const data = await response.json();

    assertExists(data.status);
    assertExists(data.timestamp);
    assertEquals(data.status, "healthy");
  },
});

Deno.test({
  name: "health-check: Full mode returns comprehensive metrics",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(`${FUNCTION_URL}?mode=full`, {
      method: "GET",
    });

    const data = await response.json();

    assertExists(data.status);
    assertExists(data.timestamp);
    assertExists(data.database);
    assertExists(data.connectionPool);

    // Check database metrics
    assertExists(data.database.connected);
    assertEquals(typeof data.database.connected, "boolean");

    // Check connection pool metrics
    assertExists(data.connectionPool.active);
    assertExists(data.connectionPool.idle);
    assertExists(data.connectionPool.waiting);
    assertExists(data.connectionPool.total);
  },
});

Deno.test({
  name: "health-check: Agents mode returns agent-specific data",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(`${FUNCTION_URL}?mode=agents`, {
      method: "GET",
    });

    const data = await response.json();

    assertExists(data.status);
    assertExists(data.timestamp);
    assertExists(data.aiAgents);

    // Check AI agent metrics
    if (data.aiAgents) {
      assertExists(data.aiAgents.totalConnections);
      assertExists(data.aiAgents.activeConnections);
      assertEquals(typeof data.aiAgents.totalConnections, "number");
      assertEquals(typeof data.aiAgents.activeConnections, "number");
    }
  },
});

Deno.test({
  name: "health-check: Metrics mode returns detailed statistics",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(`${FUNCTION_URL}?mode=metrics`, {
      method: "GET",
    });

    const data = await response.json();

    assertExists(data.status);
    assertExists(data.timestamp);
    assertExists(data.metrics);

    // Check metrics structure
    if (data.metrics) {
      assertExists(data.metrics.queries);
      assertExists(data.metrics.transactions);
      assertEquals(typeof data.metrics.queries, "object");
      assertEquals(typeof data.metrics.transactions, "object");
    }
  },
});

Deno.test({
  name: "health-check: Returns appropriate alert levels",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(`${FUNCTION_URL}?mode=full`, {
      method: "GET",
    });

    const data = await response.json();

    assertExists(data.alertLevel);

    // Alert level should be one of: OK, WARNING, CRITICAL
    assert(
      data.alertLevel === "OK" ||
        data.alertLevel === "WARNING" ||
        data.alertLevel === "CRITICAL",
      `Invalid alert level: ${data.alertLevel}`,
    );
  },
});

Deno.test({
  name: "health-check: CORS headers present",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "OPTIONS",
    });

    assertEquals(response.status, 200);
    assertExists(response.headers.get("Access-Control-Allow-Origin"));
    assertExists(response.headers.get("Access-Control-Allow-Methods"));
  },
});

Deno.test({
  name: "health-check: Invalid mode parameter handled gracefully",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(`${FUNCTION_URL}?mode=invalid`, {
      method: "GET",
    });

    // Should still return 200 with default behavior
    assertEquals(response.status, 200);
    const data = await response.json();
    assertExists(data.status);
  },
});

Deno.test({
  name: "health-check: Response time is reasonable",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const start = performance.now();

    await fetch(FUNCTION_URL, {
      method: "GET",
    });

    const duration = performance.now() - start;

    // Health check should respond quickly (within 2 seconds)
    assert(
      duration < 2000,
      `Health check took ${duration}ms (should be < 2000ms)`,
    );
  },
});

Deno.test({
  name: "health-check: Connection pool stats are valid numbers",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(`${FUNCTION_URL}?mode=full`, {
      method: "GET",
    });

    const data = await response.json();

    if (data.connectionPool) {
      // All values should be non-negative integers
      assert(data.connectionPool.active >= 0, "Active connections must be >= 0");
      assert(data.connectionPool.idle >= 0, "Idle connections must be >= 0");
      assert(data.connectionPool.waiting >= 0, "Waiting connections must be >= 0");
      assert(
        data.connectionPool.total >= 0,
        "Total connections must be >= 0",
      );

      // Total should equal active + idle
      assertEquals(
        data.connectionPool.total,
        data.connectionPool.active + data.connectionPool.idle,
        "Total should equal active + idle",
      );
    }
  },
});

// Unit test (no integration required)
Deno.test({
  name: "health-check: URL construction works correctly",
  fn() {
    const baseUrl = "http://localhost:54321/functions/v1/health-check";

    // Test with simple mode
    const simpleUrl = new URL(baseUrl);
    simpleUrl.searchParams.set("mode", "simple");
    assertEquals(
      simpleUrl.toString(),
      "http://localhost:54321/functions/v1/health-check?mode=simple",
    );

    // Test with full mode
    const fullUrl = new URL(baseUrl);
    fullUrl.searchParams.set("mode", "full");
    assertEquals(
      fullUrl.toString(),
      "http://localhost:54321/functions/v1/health-check?mode=full",
    );
  },
});

// Unit test for expected response structure
Deno.test({
  name: "health-check: Response structure validation",
  fn() {
    // Mock expected response
    const mockResponse = {
      status: "healthy",
      timestamp: new Date().toISOString(),
      database: {
        connected: true,
        responseTime: 10,
      },
      connectionPool: {
        active: 2,
        idle: 3,
        waiting: 0,
        total: 5,
      },
      alertLevel: "OK",
    };

    // Validate structure
    assertExists(mockResponse.status);
    assertExists(mockResponse.timestamp);
    assertExists(mockResponse.database);
    assertExists(mockResponse.connectionPool);
    assertExists(mockResponse.alertLevel);

    assertEquals(typeof mockResponse.status, "string");
    assertEquals(typeof mockResponse.timestamp, "string");
    assertEquals(typeof mockResponse.database.connected, "boolean");
    assertEquals(typeof mockResponse.connectionPool.active, "number");
  },
});
