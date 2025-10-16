/**
 * Realtime Testing Example
 * 
 * This script demonstrates how to test realtime functionality
 * by creating, updating, and deleting records while listening for events.
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:8000';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Test results tracking
const testResults = {
  insert: { received: false, data: null },
  update: { received: false, data: null },
  delete: { received: false, data: null },
};

let testPostId = null;
let testTimeout = null;

// Create a channel to listen for changes
const channel = supabase
  .channel('test-channel')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('✅ INSERT event received:', payload.new);
      testResults.insert.received = true;
      testResults.insert.data = payload.new;
      testPostId = payload.new.id;
    }
  )
  .on(
    'postgres_changes',
    { event: 'UPDATE', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('✅ UPDATE event received:', {
        old: payload.old,
        new: payload.new
      });
      testResults.update.received = true;
      testResults.update.data = payload.new;
    }
  )
  .on(
    'postgres_changes',
    { event: 'DELETE', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('✅ DELETE event received:', payload.old);
      testResults.delete.received = true;
      testResults.delete.data = payload.old;
    }
  )
  .subscribe(async (status) => {
    if (status === 'SUBSCRIBED') {
      console.log('📡 Subscribed to realtime channel');
      console.log('\nStarting tests in 2 seconds...\n');
      
      // Wait a moment for subscription to be fully ready
      setTimeout(() => runTests(), 2000);
    }
  });

// Run the tests
async function runTests() {
  try {
    console.log('🧪 Test 1: Creating a new post (INSERT)...');
    const { data: insertData, error: insertError } = await supabase
      .from('posts')
      .insert({
        title: 'Test Post for Realtime',
        content: 'This post is created to test realtime functionality',
        published: false,
        // Note: user_id should be a valid UUID that exists in your profiles table
        // For testing, you may need to adjust this or use a test user
      })
      .select()
      .single();
    
    if (insertError) {
      console.error('❌ Insert failed:', insertError);
      return;
    }
    
    testPostId = insertData.id;
    console.log('   Post created with ID:', testPostId);
    
    // Wait for realtime event
    await wait(2000);
    
    if (!testResults.insert.received) {
      console.log('⚠️  Warning: INSERT event not received yet');
    }
    
    console.log('\n🧪 Test 2: Updating the post (UPDATE)...');
    const { data: updateData, error: updateError } = await supabase
      .from('posts')
      .update({
        title: 'Updated Test Post',
        content: 'This content has been updated to test realtime',
        published: true,
      })
      .eq('id', testPostId)
      .select()
      .single();
    
    if (updateError) {
      console.error('❌ Update failed:', updateError);
      return;
    }
    
    console.log('   Post updated');
    
    // Wait for realtime event
    await wait(2000);
    
    if (!testResults.update.received) {
      console.log('⚠️  Warning: UPDATE event not received yet');
    }
    
    console.log('\n🧪 Test 3: Deleting the post (DELETE)...');
    const { error: deleteError } = await supabase
      .from('posts')
      .delete()
      .eq('id', testPostId);
    
    if (deleteError) {
      console.error('❌ Delete failed:', deleteError);
      return;
    }
    
    console.log('   Post deleted');
    
    // Wait for realtime event
    await wait(2000);
    
    if (!testResults.delete.received) {
      console.log('⚠️  Warning: DELETE event not received yet');
    }
    
    // Print test results
    printResults();
    
  } catch (error) {
    console.error('❌ Test error:', error);
  } finally {
    await cleanup();
  }
}

// Helper function to wait
function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Print test results
function printResults() {
  console.log('\n' + '='.repeat(60));
  console.log('TEST RESULTS');
  console.log('='.repeat(60));
  
  const tests = [
    { name: 'INSERT Event', result: testResults.insert.received },
    { name: 'UPDATE Event', result: testResults.update.received },
    { name: 'DELETE Event', result: testResults.delete.received },
  ];
  
  tests.forEach(test => {
    const status = test.result ? '✅ PASS' : '❌ FAIL';
    console.log(`${status} - ${test.name}`);
  });
  
  const allPassed = tests.every(t => t.result);
  
  console.log('='.repeat(60));
  if (allPassed) {
    console.log('✅ All tests passed! Realtime is working correctly.');
  } else {
    console.log('❌ Some tests failed. Check your realtime configuration:');
    console.log('   1. Is realtime enabled in config.toml?');
    console.log('   2. Are tables added to supabase_realtime publication?');
    console.log('   3. Do RLS policies allow SELECT on these tables?');
    console.log('   4. Is REPLICA IDENTITY set to FULL?');
  }
  console.log('='.repeat(60) + '\n');
}

// Cleanup function
async function cleanup() {
  clearTimeout(testTimeout);
  
  // Clean up any test data that might still exist
  if (testPostId) {
    await supabase.from('posts').delete().eq('id', testPostId).catch(() => {});
  }
  
  await supabase.removeChannel(channel);
  console.log('Cleanup complete');
  process.exit(0);
}

// Handle process termination
process.on('SIGINT', async () => {
  console.log('\nTest interrupted');
  await cleanup();
});

// Set a timeout for the entire test suite
testTimeout = setTimeout(async () => {
  console.log('\n⏰ Test timeout - this is taking too long');
  await cleanup();
}, 30000); // 30 second timeout

console.log('🚀 Realtime Testing Suite');
console.log('Connecting to:', supabaseUrl);
console.log('Waiting for subscription...');
