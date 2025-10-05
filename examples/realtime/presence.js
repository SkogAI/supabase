/**
 * Presence Example
 * 
 * This example demonstrates how to use Supabase Presence to track online users
 * and share state between clients in real-time.
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:8000';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Simulate user data (replace with actual auth user)
const userId = `user-${Math.random().toString(36).substr(2, 9)}`;
const username = `User ${userId.split('-')[1]}`;

// Create a presence channel
const channel = supabase.channel('online-users', {
  config: {
    presence: {
      key: userId, // Unique identifier for this client
    },
  },
});

// Track this user's state
const userStatus = {
  user_id: userId,
  username: username,
  online_at: new Date().toISOString(),
  status: 'active',
};

// Subscribe to presence events
channel
  .on('presence', { event: 'sync' }, () => {
    // Get the current state of all tracked users
    const state = channel.presenceState();
    console.log('👥 Online users:', state);
    
    // List all online users
    const onlineUsers = Object.keys(state).map(key => state[key][0]);
    console.log(`Total online: ${onlineUsers.length}`);
    onlineUsers.forEach(user => {
      console.log(`  - ${user.username} (${user.status})`);
    });
  })
  .on('presence', { event: 'join' }, ({ key, newPresences }) => {
    console.log('✅ User joined:', newPresences);
  })
  .on('presence', { event: 'leave' }, ({ key, leftPresences }) => {
    console.log('❌ User left:', leftPresences);
  })
  .subscribe(async (status) => {
    if (status === 'SUBSCRIBED') {
      console.log('✅ Connected to presence channel');
      
      // Track this client's presence
      const presenceTrackStatus = await channel.track(userStatus);
      console.log('Presence track status:', presenceTrackStatus);
    }
  });

// Update presence state (e.g., when user status changes)
async function updateStatus(newStatus) {
  const updated = await channel.track({
    ...userStatus,
    status: newStatus,
    updated_at: new Date().toISOString(),
  });
  console.log(`Status updated to: ${newStatus}`);
  return updated;
}

// Example: Change status after 5 seconds
setTimeout(() => {
  updateStatus('away');
}, 5000);

// Example: Change status to active after 10 seconds
setTimeout(() => {
  updateStatus('active');
}, 10000);

// Cleanup function
async function cleanup() {
  // Untrack presence before leaving
  await channel.untrack();
  await supabase.removeChannel(channel);
  console.log('Presence untracked and channel removed');
}

// Handle process termination
process.on('SIGINT', async () => {
  await cleanup();
  process.exit(0);
});

console.log(`\n🟢 ${username} is now online`);
console.log('Tracking presence...');
console.log('Press Ctrl+C to exit\n');

/**
 * Presence Use Cases:
 * 
 * 1. Show who's online in a chat app
 * 2. Display active users viewing a document
 * 3. Show typing indicators
 * 4. Track user status (active, away, busy)
 * 5. Display cursors in collaborative editing
 * 6. Show viewers in a live stream
 */
