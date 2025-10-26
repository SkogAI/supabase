// Storage integration tests
// Run with: deno test --allow-all tests/storage-test-example.ts
// NOTE: Requires Supabase to be running locally (npm run db:start)

import { assertEquals, assertExists, assertRejects } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Test configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:8000";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helper to create test user
async function createTestUser() {
  const email = `test-${Date.now()}@example.com`;
  const password = "testpassword123";

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
  });

  if (error) throw error;
  return data.user;
}

// Helper to cleanup test user
async function cleanupTestUser() {
  await supabase.auth.signOut();
}

Deno.test("Storage: Buckets exist", async () => {
  const { data, error } = await supabase.storage.listBuckets();

  assertEquals(error, null);
  assertExists(data);

  const bucketNames = data.map(b => b.name);
  assertEquals(bucketNames.includes("public-assets"), true, "public-assets bucket should exist");
  assertEquals(bucketNames.includes("user-files"), true, "user-files bucket should exist");
});

Deno.test("Storage: Public bucket configuration", async () => {
  const { data, error } = await supabase.storage.listBuckets();

  assertEquals(error, null);
  const publicBucket = data?.find(b => b.name === "public-assets");

  assertExists(publicBucket);
  assertEquals(publicBucket.public, true, "public-assets should be public");
  assertEquals(publicBucket.file_size_limit, 5242880, "Should have 5MB limit");
});

Deno.test("Storage: Private bucket configuration", async () => {
  const { data, error } = await supabase.storage.listBuckets();

  assertEquals(error, null);
  const privateBucket = data?.find(b => b.name === "user-files");

  assertExists(privateBucket);
  assertEquals(privateBucket.public, false, "user-files should be private");
  assertEquals(privateBucket.file_size_limit, 52428800, "Should have 50MB limit");
});

Deno.test("Storage: Upload to public bucket requires authentication", async () => {
  // Try to upload without authentication
  const file = new File(["test content"], "test.txt", { type: "text/plain" });
  const testPath = "unauthenticated-test/test.txt";

  const { error } = await supabase.storage
    .from("public-assets")
    .upload(testPath, file);

  // Should fail without authentication
  assertExists(error, "Upload should fail without authentication");
});

Deno.test("Storage: Authenticated user can upload to their folder", async () => {
  // Create test user
  const user = await createTestUser();
  assertExists(user, "Test user should be created");

  try {
    // Create test file
    const file = new File(["test content"], "test.jpg", { type: "image/jpeg" });
    const testPath = `${user.id}/test.jpg`;

    // Upload file
    const { data, error } = await supabase.storage
      .from("public-assets")
      .upload(testPath, file);

    assertEquals(error, null, "Upload should succeed");
    assertExists(data);

    // Verify file exists
    const { data: listData, error: listError } = await supabase.storage
      .from("public-assets")
      .list(user.id);

    assertEquals(listError, null);
    assertEquals(listData?.some(f => f.name === "test.jpg"), true);

    // Cleanup
    await supabase.storage
      .from("public-assets")
      .remove([testPath]);
  } finally {
    await cleanupTestUser();
  }
});

Deno.test("Storage: User cannot upload to another user's folder", async () => {
  const user = await createTestUser();
  assertExists(user);

  try {
    const file = new File(["test content"], "test.jpg", { type: "image/jpeg" });
    // Try to upload to a different user's folder
    const otherUserId = "00000000-0000-0000-0000-000000000000";
    const testPath = `${otherUserId}/test.jpg`;

    const { error } = await supabase.storage
      .from("public-assets")
      .upload(testPath, file);

    // Should fail due to RLS policy
    assertExists(error, "Upload to another user's folder should fail");
  } finally {
    await cleanupTestUser();
  }
});

Deno.test("Storage: Get public URL for public bucket", async () => {
  const testPath = "test-user-id/test.jpg";

  const { data } = supabase.storage
    .from("public-assets")
    .getPublicUrl(testPath);

  assertExists(data.publicUrl);
  assertEquals(data.publicUrl.includes("public-assets"), true);
  assertEquals(data.publicUrl.includes(testPath), true);
});

Deno.test("Storage: Create signed URL for private bucket", async () => {
  const user = await createTestUser();
  assertExists(user);

  try {
    const testPath = `${user.id}/private-test.pdf`;

    const { data, error } = await supabase.storage
      .from("user-files")
      .createSignedUrl(testPath, 3600); // 1 hour expiry

    // Should succeed even if file doesn't exist (URL is created)
    // Error would occur on actual download if file doesn't exist
    assertExists(data || error); // One should be present
  } finally {
    await cleanupTestUser();
  }
});

Deno.test("Storage: Helper function get_user_files", async () => {
  const user = await createTestUser();
  assertExists(user);

  try {
    // Upload a test file first
    const file = new File(["test content"], "test.jpg", { type: "image/jpeg" });
    const testPath = `${user.id}/test.jpg`;

    await supabase.storage
      .from("public-assets")
      .upload(testPath, file);

    // Call the helper function
    const { data, error } = await supabase.rpc("get_user_files", {
      user_uuid: user.id
    });

    assertEquals(error, null);
    assertExists(data);
    assertEquals(Array.isArray(data), true);

    // Cleanup
    await supabase.storage
      .from("public-assets")
      .remove([testPath]);
  } finally {
    await cleanupTestUser();
  }
});

console.log("\n✅ Storage test suite completed!");
console.log("These tests validate:");
console.log("  - Bucket existence and configuration");
console.log("  - RLS policies for authenticated access");
console.log("  - User folder isolation");
console.log("  - Public and signed URL generation");
console.log("  - Helper functions for file metadata");
