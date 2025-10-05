/**
 * Integration test helpers for testing with live Supabase instance
 * These helpers are used when testing edge functions that interact with the database
 */

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface IntegrationTestContext {
  supabase: SupabaseClient;
  cleanup: () => Promise<void>;
}

/**
 * Create a Supabase client for integration testing
 */
export function createTestClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";
  const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ||
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0";

  return createClient(supabaseUrl, supabaseKey);
}

/**
 * Create a service role client for integration testing (bypasses RLS)
 */
export function createServiceRoleClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EHRLW7jLvZ8LyxIr8YRQvQz2hifgOsVCwRjJVhKkMj4";

  return createClient(supabaseUrl, serviceRoleKey);
}

/**
 * Setup integration test context with cleanup
 */
export async function setupIntegrationTest(): Promise<IntegrationTestContext> {
  const supabase = createServiceRoleClient();
  const cleanupFunctions: (() => Promise<void>)[] = [];

  return {
    supabase,
    cleanup: async () => {
      for (const fn of cleanupFunctions) {
        try {
          await fn();
        } catch (error) {
          console.error("Cleanup error:", error);
        }
      }
    },
  };
}

/**
 * Create a test user in the database
 */
export async function createTestUser(
  supabase: SupabaseClient,
  userData: { email: string; password: string },
) {
  const { data, error } = await supabase.auth.signUp({
    email: userData.email,
    password: userData.password,
  });

  if (error) throw error;
  return data;
}

/**
 * Delete a test user from the database
 */
export async function deleteTestUser(supabase: SupabaseClient, userId: string) {
  const { error } = await supabase.auth.admin.deleteUser(userId);
  if (error) throw error;
}

/**
 * Create test data in a table
 */
export async function createTestData<T>(
  supabase: SupabaseClient,
  table: string,
  data: Partial<T> | Partial<T>[],
): Promise<T[]> {
  const insertData = Array.isArray(data) ? data : [data];
  const { data: result, error } = await supabase
    .from(table)
    .insert(insertData)
    .select();

  if (error) throw error;
  return result as T[];
}

/**
 * Delete test data from a table
 */
export async function deleteTestData(
  supabase: SupabaseClient,
  table: string,
  conditions: Record<string, unknown>,
) {
  let query = supabase.from(table).delete();

  for (const [key, value] of Object.entries(conditions)) {
    query = query.eq(key, value);
  }

  const { error } = await query;
  if (error) throw error;
}

/**
 * Check if Supabase is running and accessible
 */
export async function isSupabaseRunning(): Promise<boolean> {
  try {
    const supabase = createTestClient();
    const { error } = await supabase.from("profiles").select("id").limit(1);
    return !error;
  } catch {
    return false;
  }
}

/**
 * Wait for Supabase to be ready
 */
export async function waitForSupabase(timeoutMs = 10000): Promise<void> {
  const startTime = Date.now();

  while (Date.now() - startTime < timeoutMs) {
    if (await isSupabaseRunning()) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  throw new Error("Supabase did not become ready within timeout");
}

/**
 * Run a test with automatic database cleanup
 */
export async function withDatabaseCleanup<T>(
  testFn: (supabase: SupabaseClient) => Promise<T>,
): Promise<T> {
  const supabase = createServiceRoleClient();
  try {
    return await testFn(supabase);
  } finally {
    // Cleanup is handled by the test function itself
    // This is a wrapper for consistency
  }
}

/**
 * Create a test profile
 */
export async function createTestProfile(
  supabase: SupabaseClient,
  profileData: {
    user_id: string;
    full_name?: string;
    avatar_url?: string;
    bio?: string;
  },
) {
  const { data, error } = await supabase
    .from("profiles")
    .insert(profileData)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Create a test post
 */
export async function createTestPost(
  supabase: SupabaseClient,
  postData: {
    user_id: string;
    title: string;
    content: string;
    published?: boolean;
  },
) {
  const { data, error } = await supabase
    .from("posts")
    .insert(postData)
    .select()
    .single();

  if (error) throw error;
  return data;
}
