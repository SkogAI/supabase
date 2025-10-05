/**
 * Mock data and fixtures for testing edge functions
 */

/**
 * Mock user data
 */
export const mockUsers = [
  {
    id: "00000000-0000-0000-0000-000000000001",
    email: "test1@example.com",
    username: "testuser1",
    created_at: "2024-01-01T00:00:00Z",
  },
  {
    id: "00000000-0000-0000-0000-000000000002",
    email: "test2@example.com",
    username: "testuser2",
    created_at: "2024-01-02T00:00:00Z",
  },
  {
    id: "00000000-0000-0000-0000-000000000003",
    email: "admin@example.com",
    username: "admin",
    created_at: "2024-01-01T00:00:00Z",
  },
];

/**
 * Mock profile data
 */
export const mockProfiles = [
  {
    id: "00000000-0000-0000-0000-000000000001",
    user_id: "00000000-0000-0000-0000-000000000001",
    full_name: "Test User One",
    avatar_url: "https://example.com/avatar1.jpg",
    bio: "Test user bio",
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  },
  {
    id: "00000000-0000-0000-0000-000000000002",
    user_id: "00000000-0000-0000-0000-000000000002",
    full_name: "Test User Two",
    avatar_url: "https://example.com/avatar2.jpg",
    bio: "Another test user",
    created_at: "2024-01-02T00:00:00Z",
    updated_at: "2024-01-02T00:00:00Z",
  },
];

/**
 * Mock posts data
 */
export const mockPosts = [
  {
    id: "00000000-0000-0000-0000-000000000101",
    user_id: "00000000-0000-0000-0000-000000000001",
    title: "Test Post 1",
    content: "This is test post content",
    published: true,
    created_at: "2024-01-01T10:00:00Z",
    updated_at: "2024-01-01T10:00:00Z",
  },
  {
    id: "00000000-0000-0000-0000-000000000102",
    user_id: "00000000-0000-0000-0000-000000000001",
    title: "Draft Post",
    content: "This is a draft",
    published: false,
    created_at: "2024-01-01T11:00:00Z",
    updated_at: "2024-01-01T11:00:00Z",
  },
  {
    id: "00000000-0000-0000-0000-000000000103",
    user_id: "00000000-0000-0000-0000-000000000002",
    title: "Test Post 2",
    content: "Another test post",
    published: true,
    created_at: "2024-01-02T10:00:00Z",
    updated_at: "2024-01-02T10:00:00Z",
  },
];

/**
 * Mock JWT tokens for testing
 */
export const mockTokens = {
  validAnon: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0",
  validUser1: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJleHAiOjE5ODM4MTI5OTZ9.test",
  validUser2: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDIiLCJleHAiOjE5ODM4MTI5OTZ9.test",
  expired: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE2MDk0NTkyMDB9.test",
};

/**
 * Mock API responses
 */
export const mockApiResponses = {
  success: {
    success: true,
    data: { id: 1, name: "Test" },
  },
  error: {
    success: false,
    error: "Something went wrong",
  },
  validationError: {
    success: false,
    error: "Validation failed",
    details: {
      name: ["Name is required"],
      email: ["Email is invalid"],
    },
  },
};

/**
 * Mock request bodies
 */
export const mockRequestBodies = {
  valid: {
    name: "Test User",
    email: "test@example.com",
  },
  invalid: {
    name: "",
    email: "invalid-email",
  },
  withMissingFields: {
    name: "Test User",
  },
};

/**
 * Mock environment variables
 */
export const mockEnv = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0",
  SUPABASE_SERVICE_ROLE_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.test",
};

/**
 * Get a mock user by ID
 */
export function getMockUser(id: string) {
  return mockUsers.find((user) => user.id === id);
}

/**
 * Get a mock profile by user ID
 */
export function getMockProfile(userId: string) {
  return mockProfiles.find((profile) => profile.user_id === userId);
}

/**
 * Get mock posts by user ID
 */
export function getMockPostsByUser(userId: string) {
  return mockPosts.filter((post) => post.user_id === userId);
}
