/**
 * Table Changes Example
 * 
 * This example shows how to listen to specific events (INSERT, UPDATE, DELETE)
 * on different tables with separate handlers.
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:8000';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Create a channel for posts
const postsChannel = supabase
  .channel('posts-channel')
  // Listen to new posts
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('🆕 New post created:', payload.new);
      // Example: Update UI, show notification, etc.
    }
  )
  // Listen to post updates
  .on(
    'postgres_changes',
    { event: 'UPDATE', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('✏️  Post updated:', {
        before: payload.old,
        after: payload.new
      });
      // Example: Update the post in your UI
    }
  )
  // Listen to post deletions
  .on(
    'postgres_changes',
    { event: 'DELETE', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('🗑️  Post deleted:', payload.old);
      // Example: Remove the post from your UI
    }
  )
  .subscribe((status) => {
    if (status === 'SUBSCRIBED') {
      console.log('✅ Subscribed to posts changes');
    }
  });

// Create a separate channel for profiles
const profilesChannel = supabase
  .channel('profiles-channel')
  .on(
    'postgres_changes',
    { event: 'UPDATE', schema: 'public', table: 'profiles' },
    (payload) => {
      console.log('👤 Profile updated:', payload.new);
      // Example: Update user info in UI
    }
  )
  .subscribe((status) => {
    if (status === 'SUBSCRIBED') {
      console.log('✅ Subscribed to profile changes');
    }
  });

// Cleanup function
async function cleanup() {
  await supabase.removeChannel(postsChannel);
  await supabase.removeChannel(profilesChannel);
  console.log('Unsubscribed from all channels');
}

// Handle process termination
process.on('SIGINT', async () => {
  await cleanup();
  process.exit(0);
});

console.log('Listening for table changes...');
console.log('Press Ctrl+C to exit');
