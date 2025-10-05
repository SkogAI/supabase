/**
 * Shared test utilities for edge functions
 * Provides common helpers for testing edge functions with Supabase
 */

import { assertEquals, assertExists } from "https://deno.land/std@0.224.0/testing/asserts.ts";

/**
 * Configuration for test environment
 */
export interface TestConfig {
  functionUrl?: string;
  supabaseUrl?: string;
  supabaseAnonKey?: string;
  timeout?: number;
}

/**
 * Get test configuration from environment or defaults
 */
export function getTestConfig(): TestConfig {
  return {
    functionUrl: Deno.env.get("FUNCTION_URL") || "http://localhost:54321/functions/v1",
    supabaseUrl: Deno.env.get("SUPABASE_URL") || "http://localhost:54321",
    supabaseAnonKey: Deno.env.get("SUPABASE_ANON_KEY") ||
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0",
    timeout: parseInt(Deno.env.get("TEST_TIMEOUT") || "5000", 10),
  };
}

/**
 * Create a test request with common defaults
 */
export async function testRequest(
  functionName: string,
  options: {
    method?: string;
    body?: unknown;
    headers?: Record<string, string>;
    token?: string;
  } = {},
): Promise<Response> {
  const config = getTestConfig();
  const url = `${config.functionUrl}/${functionName}`;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  if (options.token) {
    headers["Authorization"] = `Bearer ${options.token}`;
  }

  return await fetch(url, {
    method: options.method || "POST",
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
}

/**
 * Assert that a response has the expected status code
 */
export function assertResponseStatus(response: Response, expectedStatus: number) {
  assertEquals(
    response.status,
    expectedStatus,
    `Expected status ${expectedStatus}, got ${response.status}`,
  );
}

/**
 * Assert that a response contains CORS headers
 */
export function assertCorsHeaders(response: Response) {
  assertExists(
    response.headers.get("Access-Control-Allow-Origin"),
    "CORS header 'Access-Control-Allow-Origin' should be present",
  );
}

/**
 * Parse JSON response with error handling
 */
export async function parseJsonResponse<T = unknown>(response: Response): Promise<T> {
  try {
    return await response.json() as T;
  } catch (error) {
    throw new Error(`Failed to parse JSON response: ${error instanceof Error ? error.message : "Unknown error"}`);
  }
}

/**
 * Assert that response time is within acceptable range
 */
export function assertResponseTime(startTime: number, maxMs: number, label = "Request") {
  const duration = performance.now() - startTime;
  assertEquals(
    duration < maxMs,
    true,
    `${label} took ${duration.toFixed(2)}ms, expected less than ${maxMs}ms`,
  );
}

/**
 * Wait for a condition to be true with timeout
 */
export async function waitFor(
  condition: () => boolean | Promise<boolean>,
  options: { timeout?: number; interval?: number } = {},
): Promise<void> {
  const timeout = options.timeout || 5000;
  const interval = options.interval || 100;
  const startTime = Date.now();

  while (Date.now() - startTime < timeout) {
    if (await condition()) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, interval));
  }

  throw new Error(`Condition not met within ${timeout}ms`);
}

/**
 * Retry a function with exponential backoff
 */
export async function retry<T>(
  fn: () => Promise<T>,
  options: { maxAttempts?: number; delayMs?: number; backoff?: number } = {},
): Promise<T> {
  const maxAttempts = options.maxAttempts || 3;
  const delayMs = options.delayMs || 1000;
  const backoff = options.backoff || 2;

  let lastError: Error | undefined;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      if (attempt < maxAttempts) {
        const delay = delayMs * Math.pow(backoff, attempt - 1);
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError || new Error("Retry failed");
}

/**
 * Create a mock Supabase client for testing
 */
export function createMockSupabaseClient() {
  return {
    from: (table: string) => ({
      select: () => ({
        eq: () => ({
          single: () => Promise.resolve({ data: {}, error: null }),
        }),
      }),
      insert: () => Promise.resolve({ data: {}, error: null }),
      update: () => Promise.resolve({ data: {}, error: null }),
      delete: () => Promise.resolve({ data: {}, error: null }),
    }),
    auth: {
      getUser: () => Promise.resolve({
        data: { user: { id: "test-user-id", email: "test@example.com" } },
        error: null,
      }),
    },
  };
}

/**
 * Generate a random string for testing
 */
export function randomString(length = 10): string {
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  return Array.from({ length }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
}

/**
 * Generate a test JWT token (for testing only, not secure)
 */
export function generateTestToken(payload: Record<string, unknown> = {}): string {
  // This is a simple test token, not a real JWT
  // In real tests, you should use the Supabase anon key
  const header = btoa(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = btoa(JSON.stringify({ ...payload, exp: Date.now() + 3600000 }));
  return `${header}.${body}.test-signature`;
}
