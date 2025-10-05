/**
 * Basic Realtime Subscription Example
 * 
 * This example demonstrates the simplest way to subscribe to realtime changes
 * on a database table.
 */

import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:8000';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Subscribe to all changes on the posts table
const channel = supabase
  .channel('all-posts-changes')
  .on(
    'postgres_changes',
    {
      event: '*', // Listen to all events (INSERT, UPDATE, DELETE)
      schema: 'public',
      table: 'posts'
    },
    (payload) => {
      console.log('Change received:', payload);
      console.log('Event type:', payload.eventType);
      console.log('New data:', payload.new);
      console.log('Old data:', payload.old);
    }
  )
  .subscribe((status) => {
    console.log('Subscription status:', status);
    
    if (status === 'SUBSCRIBED') {
      console.log('✅ Successfully subscribed to posts changes');
    }
  });

// Handle channel errors
channel.on('error', (error) => {
  console.error('Channel error:', error);
});

// Cleanup function - call this when you're done
async function cleanup() {
  await supabase.removeChannel(channel);
  console.log('Unsubscribed from channel');
}

// Example: Clean up after 60 seconds (remove in production)
setTimeout(() => {
  cleanup();
  process.exit(0);
}, 60000);

// Handle process termination
process.on('SIGINT', async () => {
  await cleanup();
  process.exit(0);
});

console.log('Listening for changes on posts table...');
console.log('Press Ctrl+C to exit');
