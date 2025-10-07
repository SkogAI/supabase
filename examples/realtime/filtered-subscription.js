/**
 * Filtered Subscription Example
 * 
 * This example demonstrates how to filter realtime events based on column values.
 * This is useful for listening to changes relevant to specific users or criteria.
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:8000';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// User ID to filter by. Set TEST_USER_ID in your environment, or use a valid example user ID.
const userId = process.env.TEST_USER_ID || '00000000-0000-0000-0000-000000000000';

// Listen only to posts created by a specific user
const userPostsChannel = supabase
  .channel('user-posts')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'posts',
      filter: `user_id=eq.${userId}` // Filter by user_id column
    },
    (payload) => {
      console.log('Your post changed:', payload);
    }
  )
  .subscribe();

// Listen only to published posts
const publishedPostsChannel = supabase
  .channel('published-posts')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'posts',
      filter: 'published=eq.true' // Filter by published column
    },
    (payload) => {
      console.log('New published post:', payload.new);
    }
  )
  .subscribe();

// Listen to updates on published posts
const publishedUpdatesChannel = supabase
  .channel('published-updates')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'posts',
      filter: 'published=eq.true'
    },
    (payload) => {
      console.log('Published post updated:', {
        before: payload.old,
        after: payload.new
      });
    }
  )
  .subscribe();

// Advanced: Listen to multiple conditions
// Note: Complex filters should be done client-side after receiving events
const channel = supabase
  .channel('complex-filter')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'posts'
    },
    (payload) => {
      // Client-side filtering for complex conditions
      const post = payload.new || payload.old;
      
      // Example: Only process posts with titles longer than 10 characters
      if (post && post.title && post.title.length > 10) {
        console.log('Post with long title:', post);
      }
    }
  )
  .subscribe();

// Cleanup function
async function cleanup() {
  await supabase.removeChannel(userPostsChannel);
  await supabase.removeChannel(publishedPostsChannel);
  await supabase.removeChannel(publishedUpdatesChannel);
  await supabase.removeChannel(channel);
  console.log('Unsubscribed from all channels');
}

// Handle process termination
process.on('SIGINT', async () => {
  await cleanup();
  process.exit(0);
});

console.log('Listening with filters...');
console.log('Available filter operators:');
console.log('  - eq: Equal to (=)');
console.log('  - neq: Not equal to (!=)');
console.log('  - gt: Greater than (>)');
console.log('  - gte: Greater than or equal (>=)');
console.log('  - lt: Less than (<)');
console.log('  - lte: Less than or equal (<=)');
console.log('  - in: In a list');
console.log('\nPress Ctrl+C to exit');
