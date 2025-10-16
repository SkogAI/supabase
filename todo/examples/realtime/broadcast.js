/**
 * Broadcast Example
 * 
 * This example demonstrates how to use Supabase Broadcast to send
 * ephemeral messages between clients in real-time.
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:8000';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Simulate user
const userId = `user-${Math.random().toString(36).substr(2, 9)}`;
const username = `User ${userId.split('-')[1]}`;

// Create a broadcast channel
const channel = supabase.channel('chat-room');

// Listen for broadcast messages
channel
  .on('broadcast', { event: 'message' }, (payload) => {
    console.log('💬 Message received:', payload);
  })
  .on('broadcast', { event: 'typing' }, (payload) => {
    console.log('✍️  Typing indicator:', payload);
  })
  .on('broadcast', { event: 'notification' }, (payload) => {
    console.log('🔔 Notification:', payload);
  })
  .subscribe(async (status) => {
    if (status === 'SUBSCRIBED') {
      console.log('✅ Connected to broadcast channel');
      
      // Send a join message
      await channel.send({
        type: 'broadcast',
        event: 'message',
        payload: {
          user: username,
          text: 'joined the chat',
          timestamp: new Date().toISOString(),
        },
      });
    }
  });

// Function to send a chat message
async function sendMessage(text) {
  const status = await channel.send({
    type: 'broadcast',
    event: 'message',
    payload: {
      user: username,
      text: text,
      timestamp: new Date().toISOString(),
    },
  });
  
  if (status === 'ok') {
    console.log('Message sent successfully');
  } else {
    console.error('Failed to send message:', status);
  }
}

// Function to send typing indicator
async function sendTypingIndicator(isTyping) {
  await channel.send({
    type: 'broadcast',
    event: 'typing',
    payload: {
      user: username,
      isTyping: isTyping,
      timestamp: new Date().toISOString(),
    },
  });
}

// Function to send a notification
async function sendNotification(message, type = 'info') {
  await channel.send({
    type: 'broadcast',
    event: 'notification',
    payload: {
      message: message,
      type: type, // info, success, warning, error
      timestamp: new Date().toISOString(),
    },
  });
}

// Example: Send messages at intervals
let messageCount = 0;
const messageInterval = setInterval(async () => {
  messageCount++;
  
  if (messageCount === 1) {
    await sendTypingIndicator(true);
  } else if (messageCount === 2) {
    await sendTypingIndicator(false);
    await sendMessage(`Hello from ${username}!`);
  } else if (messageCount === 3) {
    await sendNotification('This is a broadcast notification', 'info');
  } else {
    clearInterval(messageInterval);
  }
}, 3000);

// Cleanup function
async function cleanup() {
  // Send leave message
  await channel.send({
    type: 'broadcast',
    event: 'message',
    payload: {
      user: username,
      text: 'left the chat',
      timestamp: new Date().toISOString(),
    },
  });
  
  clearInterval(messageInterval);
  await supabase.removeChannel(channel);
  console.log('Unsubscribed from broadcast channel');
}

// Handle process termination
process.on('SIGINT', async () => {
  await cleanup();
  process.exit(0);
});

console.log(`\n💬 ${username} joined the broadcast channel`);
console.log('Broadcasting messages...');
console.log('Press Ctrl+C to exit\n');

/**
 * Broadcast Use Cases:
 * 
 * 1. Real-time chat messages
 * 2. Typing indicators
 * 3. Live cursors in collaborative editing
 * 4. Game state updates
 * 5. Live notifications
 * 6. Mouse positions
 * 7. Ephemeral events that don't need persistence
 * 
 * Note: Broadcast messages are NOT persisted in the database.
 * They only exist in memory and are sent to currently connected clients.
 */
