// Mock utilities for testing edge functions

/**
 * Mock fetch responses for testing external API calls
 */
export class MockFetch {
  private responses: Map<string, Response> = new Map();
  private calls: Array<{ url: string; init?: RequestInit }> = [];

  /**
   * Add a mock response for a specific URL
   */
  addMock(url: string, response: Response): void {
    this.responses.set(url, response);
  }

  /**
   * Add a mock JSON response
   */
  addJsonMock(url: string, data: unknown, status = 200): void {
    const response = new Response(JSON.stringify(data), {
      status,
      headers: { "Content-Type": "application/json" },
    });
    this.addMock(url, response);
  }

  /**
   * Add a mock error response
   */
  addErrorMock(url: string, statusCode: number, message: string): void {
    const response = new Response(JSON.stringify({ error: message }), {
      status: statusCode,
      headers: { "Content-Type": "application/json" },
    });
    this.addMock(url, response);
  }

  /**
   * Mock fetch function
   */
  fetch(url: string | URL | Request, init?: RequestInit): Promise<Response> {
    const urlString = typeof url === "string" ? url : url.toString();

    // Record the call
    this.calls.push({ url: urlString, init });

    // Return mocked response
    const response = this.responses.get(urlString);
    if (!response) {
      return Promise.reject(
<<<<<<< HEAD
        new Error(`No mock response configured for: ${urlString}`)
=======
        new Error(`No mock response configured for: ${urlString}`),
>>>>>>> heutonasueno
      );
    }

    // Clone the response so it can be used multiple times
    return Promise.resolve(response.clone());
  }

  /**
   * Get all fetch calls made
   */
  getCalls(): Array<{ url: string; init?: RequestInit }> {
    return [...this.calls];
  }

  /**
   * Clear all mocks and call history
   */
  clear(): void {
    this.responses.clear();
    this.calls = [];
  }

  /**
   * Verify a specific URL was called
   */
  wasCalledWith(url: string): boolean {
    return this.calls.some((call) => call.url === url);
  }

  /**
   * Get number of times a URL was called
   */
  getCallCount(url: string): number {
    return this.calls.filter((call) => call.url === url).length;
  }
}

/**
 * Create a mock OpenAI chat completion response
 */
export function mockOpenAIResponse(
  content: string,
  model = "gpt-3.5-turbo",
): unknown {
  return {
    id: `chatcmpl-${Date.now()}`,
    object: "chat.completion",
    created: Math.floor(Date.now() / 1000),
    model,
    choices: [
      {
        index: 0,
        message: {
          role: "assistant",
          content,
        },
        finish_reason: "stop",
      },
    ],
    usage: {
      prompt_tokens: 10,
      completion_tokens: content.split(" ").length,
      total_tokens: 10 + content.split(" ").length,
    },
  };
}

/**
 * Create a mock OpenAI error response
 */
export function mockOpenAIError(
  message: string,
  type = "invalid_request_error",
  code = "invalid_api_key",
): unknown {
  return {
    error: {
      message,
      type,
      code,
    },
  };
}

/**
 * Create a mock OpenRouter response
 */
export function mockOpenRouterResponse(
  content: string,
  model = "openai/gpt-3.5-turbo",
): unknown {
  return {
    id: `gen-${Date.now()}`,
    model,
    choices: [
      {
        index: 0,
        message: {
          role: "assistant",
          content,
        },
        finish_reason: "stop",
      },
    ],
    usage: {
      prompt_tokens: 15,
      completion_tokens: content.split(" ").length,
      total_tokens: 15 + content.split(" ").length,
    },
  };
}

/**
 * Mock Supabase client for testing
 */
export class MockSupabaseClient {
  private mockData: Map<string, unknown[]> = new Map();
  private queries: Array<{ table: string; operation: string; params: unknown }> = [];

  /**
   * Set mock data for a table
   */
  setTableData(table: string, data: unknown[]): void {
    this.mockData.set(table, data);
  }

  /**
   * Mock from() method
   */
  from(table: string): MockQueryBuilder {
    return new MockQueryBuilder(table, this.mockData, this.queries);
  }

  /**
   * Get all queries that were made
   */
  getQueries(): Array<{ table: string; operation: string; params: unknown }> {
    return [...this.queries];
  }

  /**
   * Clear all mock data and queries
   */
  clear(): void {
    this.mockData.clear();
    this.queries = [];
  }
}

/**
 * Mock query builder for Supabase
 */
class MockQueryBuilder {
  private filters: Map<string, unknown> = new Map();

  constructor(
    private table: string,
    private mockData: Map<string, unknown[]>,
    private queries: Array<{ table: string; operation: string; params: unknown }>,
  ) {}

  select(columns = "*"): this {
    this.queries.push({
      table: this.table,
      operation: "select",
      params: { columns },
    });
    return this;
  }

  insert(data: unknown): this {
    this.queries.push({
      table: this.table,
      operation: "insert",
      params: { data },
    });
    return this;
  }

  update(data: unknown): this {
    this.queries.push({
      table: this.table,
      operation: "update",
      params: { data },
    });
    return this;
  }

  delete(): this {
    this.queries.push({
      table: this.table,
      operation: "delete",
      params: {},
    });
    return this;
  }

  eq(column: string, value: unknown): this {
    this.filters.set(column, value);
    return this;
  }

  single(): Promise<{ data: unknown; error: null }> {
    const tableData = this.mockData.get(this.table) || [];
    const filtered = tableData.find((row: unknown) => {
      for (const [key, value] of this.filters) {
        if ((row as Record<string, unknown>)[key] !== value) return false;
      }
      return true;
    });

    return Promise.resolve({
      data: filtered || null,
      error: null,
    });
  }

  then(
    onfulfilled?: ((value: { data: unknown[]; error: null }) => unknown) | null,
  ): Promise<unknown> {
    const tableData = this.mockData.get(this.table) || [];
    let filtered = tableData;

    // Apply filters
    if (this.filters.size > 0) {
      filtered = tableData.filter((row: unknown) => {
        for (const [key, value] of this.filters) {
          if ((row as Record<string, unknown>)[key] !== value) return false;
        }
        return true;
      });
    }

    const result = { data: filtered, error: null };
    return onfulfilled ? Promise.resolve(onfulfilled(result)) : Promise.resolve(result);
  }
}

/**
 * Create a mock Response object
 */
export function createMockResponse(
  body: unknown,
  status = 200,
  headers: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
  });
}

/**
 * Create a mock Request object
 */
export function createMockRequest(
  url: string,
  options: {
    method?: string;
    body?: unknown;
    headers?: Record<string, string>;
  } = {},
): Request {
  return new Request(url, {
    method: options.method || "POST",
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
}

/**
 * Simulate network delay
 */
export async function simulateDelay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Simulate a fetch with delay and potential failure
 */
export async function simulateUnreliableFetch(
  url: string,
  options: RequestInit = {},
  failureRate = 0.1,
  delayMs = 100,
  errorMessage = "Simulated network error",
): Promise<Response> {
  await simulateDelay(delayMs);

  if (Math.random() < failureRate) {
    throw new Error(errorMessage);
  }

  return fetch(url, options);
}
