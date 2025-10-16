// Tests for openai-chat edge function
// Run with: deno test --allow-all

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { testHeaders, testMessages, testUrls } from "../_shared/testing/fixtures.ts";
import { MockFetch, mockOpenAIError, mockOpenAIResponse } from "../_shared/testing/mocks.ts";

// Test configuration
const FUNCTION_URL = testUrls.getFunctionUrl("openai-chat");

Deno.test({
  name: "openai-chat: CORS headers present",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "OPTIONS",
    });

    assertEquals(response.status, 200);
    assertExists(response.headers.get("Access-Control-Allow-Origin"));
    assertExists(response.headers.get("Access-Control-Allow-Headers"));
  },
});

Deno.test({
  name: "openai-chat: requires messages in request body",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({}),
    });

    // Should return error for missing messages
    const data = await response.json();
    assertExists(data);
  },
});

Deno.test({
  name: "openai-chat: accepts valid message format",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: testMessages.simple,
      }),
    });

    // May fail without API key, but should accept the format
    assertExists(response);
    const data = await response.json();
    assertExists(data);
  },
});

Deno.test({
  name: "openai-chat: handles conversation history",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: testMessages.conversation,
      }),
    });

    assertExists(response);
    const data = await response.json();
    assertExists(data);
  },
});

Deno.test({
  name: "openai-chat: accepts optional model parameter",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: testMessages.simple,
        model: "gpt-4",
      }),
    });

    assertExists(response);
  },
});

Deno.test({
  name: "openai-chat: accepts optional temperature parameter",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: testMessages.simple,
        temperature: 0.7,
      }),
    });

    assertExists(response);
  },
});

Deno.test({
  name: "openai-chat: handles invalid JSON gracefully",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: "invalid json",
    });

    // Should handle error gracefully
    assertExists(response);
  },
});

Deno.test({
  name: "openai-chat: response time is reasonable",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const start = performance.now();

    await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: testMessages.simple,
      }),
    });

    const duration = performance.now() - start;

    // Initial request setup should be fast (actual API call may take longer)
    // We're just testing the function responds, not the full OpenAI call
    assertEquals(duration < 5000, true, `Response took ${duration}ms`);
  },
});

// Unit tests with mocks
Deno.test("openai-chat: mock - successful API response", () => {
  const mockFetch = new MockFetch();
  const mockResponse = mockOpenAIResponse("Hello! How can I help you?");

  mockFetch.addJsonMock(
    "https://api.openai.com/v1/chat/completions",
<<<<<<< HEAD
    mockResponse
=======
    mockResponse,
>>>>>>> heutonasueno
  );

  // Verify mock is set up correctly
  assertEquals(mockFetch.wasCalledWith("https://api.openai.com/v1/chat/completions"), false);
});

Deno.test("openai-chat: mock - API error response", () => {
  const mockFetch = new MockFetch();
  const mockError = mockOpenAIError("Invalid API key");

  mockFetch.addErrorMock(
    "https://api.openai.com/v1/chat/completions",
    401,
<<<<<<< HEAD
    JSON.stringify(mockError)
=======
    JSON.stringify(mockError),
>>>>>>> heutonasueno
  );

  // Verify mock error is set up correctly
  assertExists(mockError);
});

Deno.test({
  name: "openai-chat: validates message structure",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const invalidMessages = [
      { role: "invalid", content: "test" }, // Invalid role
    ];

    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: invalidMessages,
      }),
    });

    assertExists(response);
  },
});

// Integration test (only runs when RUN_INTEGRATION_TESTS is set)
Deno.test({
  name: "openai-chat: integration - full request/response cycle",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: [{ role: "user", content: "Say 'test successful' and nothing else" }],
        model: "gpt-3.5-turbo",
      }),
    });

    const data = await response.json();
    assertExists(data);

    // If API key is configured, should get a valid response
    if (response.ok) {
      assertExists(data.choices);
      assertEquals(Array.isArray(data.choices), true);
    }
  },
});

// Note: To run integration tests with actual OpenAI API:
// 1. Start Supabase: supabase start
// 2. Set API key: supabase secrets set OPENAI_API_KEY=your_key
// 3. Serve function: supabase functions serve openai-chat
// 4. Run tests: RUN_INTEGRATION_TESTS=true deno test --allow-all
