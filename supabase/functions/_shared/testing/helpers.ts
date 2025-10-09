// Helper utilities for edge function testing

import { testHeaders, testUrls } from "./fixtures.ts";

/**
 * Make a test request to a function
 */
export function testFetch(
export async function testFetch(
  functionName: string,
  options: {
    method?: string;
    body?: unknown;
    headers?: Record<string, string>;
    token?: string;
  } = {},
): Promise<Response> {
  const url = testUrls.getFunctionUrl(functionName);

  const headers: Record<string, string> = {
    ...testHeaders.json,
    ...options.headers,
  };

  if (options.token) {
    headers["Authorization"] = `Bearer ${options.token}`;
  }

  return fetch(url, {
    method: options.method || "POST",
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
}

/**
 * Test CORS headers on a function
 */
export async function testCORS(functionName: string): Promise<{
  hasOrigin: boolean;
  hasHeaders: boolean;
  hasMethods: boolean;
  status: number;
}> {
  const url = testUrls.getFunctionUrl(functionName);
  const response = await fetch(url, {
    method: "OPTIONS",
    headers: testHeaders.cors,
  });

  return {
    hasOrigin: response.headers.has("Access-Control-Allow-Origin"),
    hasHeaders: response.headers.has("Access-Control-Allow-Headers"),
    hasMethods: response.headers.has("Access-Control-Allow-Methods"),
    status: response.status,
  };
}

/**
 * Test function response time
 */
export async function measureResponseTime(
  functionName: string,
  body?: unknown,
): Promise<{
  duration: number;
  response: Response;
}> {
  const start = performance.now();
  const response = await testFetch(functionName, { body });
  const duration = performance.now() - start;

  return { duration, response };
}

/**
 * Test concurrent requests
 */
export async function testConcurrent(
  functionName: string,
  requestCount: number,
  body?: unknown,
): Promise<{
  responses: Response[];
  totalTime: number;
  avgTime: number;
}> {
  const start = performance.now();

  const requests = Array(requestCount)
    .fill(null)
    .map(() => testFetch(functionName, { body }));

  const responses = await Promise.all(requests);
  const totalTime = performance.now() - start;
  const avgTime = totalTime / requestCount;

  return { responses, totalTime, avgTime };
}

/**
 * Verify JSON response structure
 */
export function assertJsonStructure(
  data: unknown,
  expectedKeys: string[],
): { valid: boolean; missingKeys: string[] } {
  if (typeof data !== "object" || data === null) {
    return { valid: false, missingKeys: expectedKeys };
  }

  const missingKeys = expectedKeys.filter(
    (key) => !(key in (data as Record<string, unknown>)),
  );

  return {
    valid: missingKeys.length === 0,
    missingKeys,
  };
}

/**
 * Wait for condition to be true
 */
export async function waitForCondition(
  condition: () => boolean | Promise<boolean>,
  timeoutMs = 5000,
  checkIntervalMs = 100,
): Promise<boolean> {
  const startTime = Date.now();

  while (Date.now() - startTime < timeoutMs) {
    if (await condition()) {
      return true;
    }
    await new Promise((resolve) => setTimeout(resolve, checkIntervalMs));
  }

  return false;
}

/**
 * Generate random test data
 */
export const generateTestData = {
  string: (length = 10): string => {
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    return Array(length)
      .fill(null)
      .map(() => chars[Math.floor(Math.random() * chars.length)])
      .join("");
  },

  email: (): string => {
    return `test-${Date.now()}@example.com`;
  },

  uuid: (): string => {
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  },

  timestamp: (): string => {
    return new Date().toISOString();
  },

  number: (min = 0, max = 100): number => {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  },
};

/**
 * Assert response has expected structure
 */
export interface ExpectedResponse {
  status?: number;
  headers?: Record<string, string>;
  bodyKeys?: string[];
  bodyValues?: Record<string, unknown>;
}

export async function assertResponse(
  response: Response,
  expected: ExpectedResponse,
): Promise<{
  valid: boolean;
  errors: string[];
}> {
  const errors: string[] = [];

  // Check status
  if (expected.status !== undefined && response.status !== expected.status) {
    errors.push(
      `Expected status ${expected.status}, got ${response.status}`,
    );
  }

  // Check headers
  if (expected.headers) {
    for (const [key, value] of Object.entries(expected.headers)) {
      const actualValue = response.headers.get(key);
      if (actualValue !== value) {
        errors.push(
          `Expected header ${key}='${value}', got '${actualValue}'`,
        );
      }
    }
  }

  // Check body
  if (expected.bodyKeys || expected.bodyValues) {
    try {
      const body = await response.json();

      if (expected.bodyKeys) {
        const { valid, missingKeys } = assertJsonStructure(
          body,
          expected.bodyKeys,
        );
        if (!valid) {
          errors.push(`Missing keys in response: ${missingKeys.join(", ")}`);
        }
      }

      if (expected.bodyValues) {
        for (const [key, value] of Object.entries(expected.bodyValues)) {
          const bodyRecord = body as Record<string, unknown>;
          if (bodyRecord[key] !== value) {
            errors.push(
              `Expected ${key}='${value}', got '${bodyRecord[key]}'`,
            );
          }
        }
      }
    } catch (error) {
      errors.push(
        `Failed to parse JSON response: ${error instanceof Error ? error.message : String(error)}`,
        `Failed to parse JSON response: ${
          error instanceof Error ? error.message : String(error)
        }`
      );
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Retry a test function with exponential backoff
 */
export async function retryTest<T>(
  testFn: () => Promise<T>,
  maxRetries = 3,
  baseDelayMs = 1000,
): Promise<T> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await testFn();
    } catch (error) {
      if (i === maxRetries - 1) {
        throw error;
      }
      const delay = baseDelayMs * Math.pow(2, i);
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
  throw new Error("Retry failed");
}

/**
 * Create a test timeout
 */
export function withTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number,
  errorMessage = "Operation timed out",
): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) => setTimeout(() => reject(new Error(errorMessage)), timeoutMs)),
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error(errorMessage)), timeoutMs)
    ),
  ]);
}

/**
 * Clean up test data from database
 */
export async function cleanupTestData(
  supabaseClient: {
    from: (table: string) => {
      delete: () => {
        match: (query: Record<string, unknown>) => Promise<{ error: unknown }>;
      };
    };
  },
  table: string,
  query: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabaseClient
    .from(table)
    .delete()
    .match(query);

  if (error) {
    console.warn(`Failed to cleanup test data from ${table}:`, error);
  }
}

/**
 * Check if Supabase is running locally
 */
export async function isSupabaseRunning(): Promise<boolean> {
  try {
    const response = await fetch(`${testUrls.local.supabase}/rest/v1/`, {
      method: "HEAD",
    });
    return response.ok || response.status === 401; // 401 means running but no auth
  } catch {
    return false;
  }
}

/**
 * Skip test if condition is not met
 */
export function skipUnless(
  condition: boolean,
  reason: string,
): { ignore: boolean; reason?: string } {
  return {
    ignore: !condition,
    reason: condition ? undefined : reason,
  };
}

/**
 * Common test patterns
 */
export const testPatterns = {
  /**
   * Test basic request/response flow
   */
  async basicFlow(
    functionName: string,
    body: unknown,
    expectedStatus = 200,
  ): Promise<Response> {
    const response = await testFetch(functionName, { body });
    if (response.status !== expectedStatus) {
      throw new Error(
        `Expected status ${expectedStatus}, got ${response.status}`,
      );
    }
    return response;
  },

  /**
   * Test authentication requirement
   */
  async requiresAuth(functionName: string): Promise<boolean> {
    const response = await testFetch(functionName, {
      body: { test: "data" },
    });
    return response.status === 401;
  },

  /**
   * Test error handling
   */
  async errorHandling(
    functionName: string,
    invalidBody: unknown,
  ): Promise<{ hasError: boolean; errorMessage?: string }> {
    const response = await testFetch(functionName, { body: invalidBody });
    if (response.ok) {
      return { hasError: false };
    }

    try {
      const data = await response.json();
      return {
        hasError: true,
        errorMessage: (data as { error?: string }).error,
      };
    } catch {
      return { hasError: true };
    }
  },
};
