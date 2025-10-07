// Test fixtures and sample data for edge function testing

/**
 * Test users matching seed data in supabase/seed.sql
 * These users are pre-created in local development database
 */
export const testUsers = {
  alice: {
    id: "00000000-0000-0000-0000-000000000001",
    email: "alice@example.com",
    password: "password123",
  },
  bob: {
    id: "00000000-0000-0000-0000-000000000002",
    email: "bob@example.com",
    password: "password123",
  },
  charlie: {
    id: "00000000-0000-0000-0000-000000000003",
    email: "charlie@example.com",
    password: "password123",
  },
};

/**
 * Sample chat messages for testing AI functions
 */
export const testMessages = {
  simple: [
    { role: "user", content: "Hello" },
  ],
  conversation: [
    { role: "user", content: "What is the weather like?" },
    { role: "assistant", content: "I don't have access to real-time weather data." },
    { role: "user", content: "Can you tell me a joke?" },
  ],
  withSystem: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "Hello" },
  ],
};

/**
 * Sample API responses for mocking
 */
export const mockApiResponses = {
  openai: {
    success: {
      id: "chatcmpl-123",
      object: "chat.completion",
      created: 1677652288,
      model: "gpt-3.5-turbo",
      choices: [
        {
          index: 0,
          message: {
            role: "assistant",
            content: "Hello! How can I help you today?",
          },
          finish_reason: "stop",
        },
      ],
      usage: {
        prompt_tokens: 10,
        completion_tokens: 10,
        total_tokens: 20,
      },
    },
    error: {
      error: {
        message: "Invalid API key",
        type: "invalid_request_error",
        code: "invalid_api_key",
      },
    },
  },
  openrouter: {
    success: {
      id: "gen-123",
      model: "openai/gpt-3.5-turbo",
      choices: [
        {
          message: {
            role: "assistant",
            content: "This is a response from OpenRouter",
          },
          finish_reason: "stop",
        },
      ],
      usage: {
        prompt_tokens: 15,
        completion_tokens: 12,
        total_tokens: 27,
      },
    },
  },
};

/**
 * Sample database records
 */
export const testRecords = {
  profile: {
    id: testUsers.alice.id,
    email: testUsers.alice.email,
    full_name: "Alice Smith",
    avatar_url: "https://example.com/avatar.jpg",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  post: {
    id: "10000000-0000-0000-0000-000000000001",
    user_id: testUsers.alice.id,
    title: "Test Post",
    content: "This is a test post",
    status: "published",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
};

/**
 * Generate a simple test JWT token (for local testing only)
 * In production, use proper JWT signing
 */
export function generateTestJWT(userId: string): string {
  // This is a simplified version for testing
  // In real tests with Supabase, use the actual auth service
  const header = btoa(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payload = btoa(
    JSON.stringify({
      sub: userId,
      aud: "authenticated",
      role: "authenticated",
      exp: Math.floor(Date.now() / 1000) + 3600,
    }),
  );
  return `${header}.${payload}.test_signature`;
}

/**
 * Sample request bodies for different test scenarios
 */
export const testRequestBodies = {
  valid: {
    name: "Test User",
    email: "test@example.com",
  },
  empty: {},
  invalidEmail: {
    name: "Test User",
    email: "not-an-email",
  },
  missingRequired: {
    name: "Test User",
    // email is missing
  },
  withSpecialChars: {
    name: "Test <script>alert('xss')</script>",
    email: "test@example.com",
  },
  largePayload: {
    data: "x".repeat(10000),
  },
};

/**
 * Common HTTP headers for testing
 */
export const testHeaders = {
  json: {
    "Content-Type": "application/json",
  },
  jsonWithAuth: (token: string) => ({
    "Content-Type": "application/json",
    "Authorization": `Bearer ${token}`,
  }),
  cors: {
    "Origin": "http://localhost:3000",
    "Access-Control-Request-Method": "POST",
    "Access-Control-Request-Headers": "content-type",
  },
};

/**
 * Test environment URLs
 */
export const testUrls = {
  local: {
    supabase: "http://localhost:54321",
    functions: "http://localhost:54321/functions/v1",
  },
  getFunctionUrl: (functionName: string): string => {
    return Deno.env.get("FUNCTION_URL") ||
      `http://localhost:54321/functions/v1/${functionName}`;
  },
};

/**
 * Wait helper for async operations
 */
export function waitFor(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Retry helper for flaky operations
 */
export async function retry<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  delayMs = 1000,
): Promise<T> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await waitFor(delayMs);
    }
  }
  throw new Error("Retry failed");
}
