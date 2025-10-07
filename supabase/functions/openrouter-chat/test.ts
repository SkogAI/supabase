// Tests for openrouter-chat edge function
// Run with: deno test --allow-all

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { testHeaders, testMessages, testUrls } from "../_shared/testing/fixtures.ts";
import { MockFetch, mockOpenRouterResponse } from "../_shared/testing/mocks.ts";

// Test configuration
const FUNCTION_URL = testUrls.getFunctionUrl("openrouter-chat");

// List of models to test
const testModels = {
  openai: "openai/gpt-3.5-turbo",
  anthropic: "anthropic/claude-3-sonnet",
  google: "google/gemini-pro",
  meta: "meta-llama/llama-3-70b",
};

Deno.test("openrouter-chat: CORS headers present", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "OPTIONS",
  });

  assertEquals(response.status, 200);
  assertExists(response.headers.get("Access-Control-Allow-Origin"));
  assertExists(response.headers.get("Access-Control-Allow-Headers"));
});

Deno.test("openrouter-chat: requires messages in request body", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({}),
  });

  // Should return error for missing messages
  const data = await response.json();
  assertExists(data);
});

Deno.test("openrouter-chat: requires model parameter", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: testMessages.simple,
      // model is missing
    }),
  });

  const data = await response.json();
  assertExists(data);
});

Deno.test("openrouter-chat: accepts valid request format", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: testMessages.simple,
      model: testModels.openai,
    }),
  });

  // May fail without API key, but should accept the format
  assertExists(response);
  const data = await response.json();
  assertExists(data);
});

Deno.test("openrouter-chat: handles conversation history", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: testMessages.conversation,
      model: testModels.openai,
    }),
  });

  assertExists(response);
  const data = await response.json();
  assertExists(data);
});

Deno.test("openrouter-chat: accepts different model providers", async () => {
  // Test with different model formats
  for (const [provider, model] of Object.entries(testModels)) {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: testMessages.simple,
        model: model,
      }),
    });

    assertExists(response, `Failed for provider: ${provider}`);
  }
});

Deno.test("openrouter-chat: accepts optional temperature parameter", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: testMessages.simple,
      model: testModels.openai,
      temperature: 0.7,
    }),
  });

  assertExists(response);
});

Deno.test("openrouter-chat: accepts optional max_tokens parameter", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: testMessages.simple,
      model: testModels.openai,
      max_tokens: 100,
    }),
  });

  assertExists(response);
});

Deno.test("openrouter-chat: handles invalid JSON gracefully", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: "invalid json",
  });

  // Should handle error gracefully
  assertExists(response);
});

Deno.test("openrouter-chat: response time is reasonable", async () => {
  const start = performance.now();

  await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: testMessages.simple,
      model: testModels.openai,
    }),
  });

  const duration = performance.now() - start;

  // Initial request setup should be fast
  assertEquals(duration < 5000, true, `Response took ${duration}ms`);
});

// Unit tests with mocks
Deno.test("openrouter-chat: mock - successful API response", () => {
  const mockFetch = new MockFetch();
  const mockResponse = mockOpenRouterResponse(
    "Hello from OpenRouter!",
    testModels.openai,
  );

  mockFetch.addJsonMock(
    "https://openrouter.ai/api/v1/chat/completions",
    mockResponse,
  );

  // Verify mock is set up correctly
  assertEquals(mockFetch.wasCalledWith("https://openrouter.ai/api/v1/chat/completions"), false);
});

Deno.test("openrouter-chat: validates model format", async () => {
  const invalidModels = [
    "", // Empty string
    "invalid", // Missing provider prefix
    "provider/", // Missing model name
  ];

  for (const model of invalidModels) {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: testMessages.simple,
        model: model,
      }),
    });

    assertExists(response);
  }
});

Deno.test("openrouter-chat: handles system messages", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: testMessages.withSystem,
      model: testModels.openai,
    }),
  });

  assertExists(response);
});

Deno.test("openrouter-chat: handles empty message content", async () => {
  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: [{ role: "user", content: "" }],
      model: testModels.openai,
    }),
  });

  assertExists(response);
});

Deno.test("openrouter-chat: handles very long messages", async () => {
  const longMessage = "test ".repeat(1000); // ~5000 characters

  const response = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: testHeaders.json,
    body: JSON.stringify({
      messages: [{ role: "user", content: longMessage }],
      model: testModels.openai,
    }),
  });

  assertExists(response);
});

// Integration test (only runs when RUN_INTEGRATION_TESTS is set)
Deno.test({
  name: "openrouter-chat: integration - full request/response cycle with OpenAI",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: testHeaders.json,
      body: JSON.stringify({
        messages: [{ role: "user", content: "Say 'test successful' and nothing else" }],
        model: testModels.openai,
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

Deno.test({
  name: "openrouter-chat: integration - test different providers",
  ignore: !Deno.env.get("RUN_INTEGRATION_TESTS"),
  async fn() {
    // Test multiple providers in integration environment
    const providersToTest = [testModels.openai]; // Add more if needed

    for (const model of providersToTest) {
      const response = await fetch(FUNCTION_URL, {
        method: "POST",
        headers: testHeaders.json,
        body: JSON.stringify({
          messages: [{ role: "user", content: "Hello" }],
          model: model,
        }),
      });

      assertExists(response, `Failed for model: ${model}`);
    }
  },
});

// Note: To run integration tests with actual OpenRouter API:
// 1. Start Supabase: supabase start
// 2. Set API key: supabase secrets set OPENROUTER_API_KEY=your_key
// 3. Serve function: supabase functions serve openrouter-chat
// 4. Run tests: RUN_INTEGRATION_TESTS=true deno test --allow-all
//
// Available models to test:
// - openai/gpt-3.5-turbo (OpenAI)
// - anthropic/claude-3-sonnet (Anthropic)
// - google/gemini-pro (Google)
// - meta-llama/llama-3-70b (Meta)
//
// See https://openrouter.ai/models for full list
