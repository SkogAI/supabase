# Supabase Realtime Guide

Complete guide to implementing realtime features in your Supabase application.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Features](#features)
- [Configuration](#configuration)
- [Common Patterns](#common-patterns)
- [Security](#security)
- [Rate Limiting](#rate-limiting)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

---

## Overview

Supabase Realtime provides three main features:

1. **Postgres Changes** - Listen to INSERT, UPDATE, DELETE events on database tables
2. **Presence** - Track which users are online and share state between them
3. **Broadcast** - Send ephemeral messages between clients

All communication happens over WebSockets for low-latency, bidirectional updates.

---

## Quick Start

### Installation

```bash
npm install @supabase/supabase-js
```

### Basic Usage

```javascript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Subscribe to database changes
const channel = supabase
  .channel('my-channel')
  .on('postgres_changes', 
    { event: '*', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('Change received!', payload);
    }
  )
  .subscribe();

// Remember to clean up
await supabase.removeChannel(channel);
```

---

## Features

### 1. Postgres Changes

Listen to database events in real-time.

**Events Available:**
- `INSERT` - New rows added
- `UPDATE` - Rows modified
- `DELETE` - Rows removed
- `*` - All events

**Event Payload:**
```typescript
{
  schema: string;      // Database schema
  table: string;       // Table name
  commit_timestamp: string;
  eventType: 'INSERT' | 'UPDATE' | 'DELETE';
  new: Record;         // New row data (INSERT, UPDATE)
  old: Record;         // Old row data (UPDATE, DELETE)
  errors: string[];
}
```

### 2. Presence

Track online users and share state.

**Example:**
```javascript
const channel = supabase.channel('online-users');

// Track this user
await channel
  .on('presence', { event: 'sync' }, () => {
    const state = channel.presenceState();
    console.log('Online users:', state);
  })
  .on('presence', { event: 'join' }, ({ newPresences }) => {
    console.log('User joined:', newPresences);
  })
  .on('presence', { event: 'leave' }, ({ leftPresences }) => {
    console.log('User left:', leftPresences);
  })
  .subscribe();

await channel.track({
  user_id: 'user-1',
  username: 'John',
  status: 'online'
});
```

### 3. Broadcast

Send messages between clients without database persistence.

**Example:**
```javascript
const channel = supabase.channel('chat-room');

// Listen for messages
channel
  .on('broadcast', { event: 'message' }, (payload) => {
    console.log('Message:', payload);
  })
  .subscribe();

// Send a message
await channel.send({
  type: 'broadcast',
  event: 'message',
  payload: { text: 'Hello!' }
});
```

---

## Configuration

### Database Setup

Enable realtime on tables:

```sql
-- Add table to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;

-- Set replica identity to FULL (required for UPDATE/DELETE)
ALTER TABLE public.posts REPLICA IDENTITY FULL;
```

### Config.toml Settings

```toml
[realtime]
enabled = true
max_connections = 100              # Max concurrent connections per client
max_channels_per_client = 100      # Max channels per connection
max_joins_per_second = 500         # Max joins per second
max_messages_per_second = 1000     # Max messages per second
max_events_per_second = 100        # Max events per second per channel
```

### RLS Policies

Users must have SELECT permission to receive realtime updates:

```sql
-- Allow everyone to see published posts
CREATE POLICY "Published posts are viewable"
  ON posts FOR SELECT
  USING (published = true);

-- Allow users to see their own drafts
CREATE POLICY "Users see own drafts"
  ON posts FOR SELECT
  USING (auth.uid() = user_id);
```

---

## Common Patterns

### Pattern 1: Live Feed

Display new content as it's created.

```javascript
const channel = supabase
  .channel('posts-feed')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'posts', filter: 'published=eq.true' },
    (payload) => {
      // Add new post to top of feed
      addPostToFeed(payload.new);
    }
  )
  .subscribe();
```

### Pattern 2: Live Editing

Show when others are editing a document.

```javascript
// Track who's editing
const channel = supabase.channel(`document:${docId}`);

await channel
  .on('presence', { event: 'sync' }, () => {
    const editors = channel.presenceState();
    updateEditorsList(editors);
  })
  .subscribe();

// Track your presence
await channel.track({
  user_id: currentUser.id,
  username: currentUser.name,
  editing_at: new Date().toISOString()
});

// Send cursor position
await channel.send({
  type: 'broadcast',
  event: 'cursor',
  payload: { x: cursorX, y: cursorY }
});
```

### Pattern 3: User-Specific Updates

Listen only to changes relevant to the current user.

```javascript
const userId = supabase.auth.user()?.id;

const channel = supabase
  .channel('my-notifications')
  .on('postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'notifications',
      filter: `user_id=eq.${userId}`
    },
    (payload) => {
      showNotification(payload.new);
    }
  )
  .subscribe();
```

### Pattern 4: Chat Application

Implement real-time chat with presence and broadcast.

```javascript
const channel = supabase.channel(`chat:${roomId}`);

// Track online users
await channel
  .on('presence', { event: 'sync' }, () => {
    updateOnlineUsers(channel.presenceState());
  })
  // Listen for messages
  .on('broadcast', { event: 'message' }, ({ payload }) => {
    addMessage(payload);
  })
  // Listen for typing indicators
  .on('broadcast', { event: 'typing' }, ({ payload }) => {
    showTyping(payload);
  })
  .subscribe();

// Track your presence
await channel.track({
  user_id: currentUser.id,
  username: currentUser.name,
  avatar: currentUser.avatar
});

// Send message
async function sendMessage(text) {
  await channel.send({
    type: 'broadcast',
    event: 'message',
    payload: {
      user_id: currentUser.id,
      username: currentUser.name,
      text: text,
      timestamp: Date.now()
    }
  });
}

// Send typing indicator
async function setTyping(isTyping) {
  await channel.send({
    type: 'broadcast',
    event: 'typing',
    payload: { user_id: currentUser.id, isTyping }
  });
}
```

### Pattern 5: Live Dashboard

Display real-time metrics and updates.

```javascript
const channels = [
  supabase
    .channel('orders')
    .on('postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'orders' },
      (payload) => updateOrderCount(payload.new)
    ),
  
  supabase
    .channel('users')
    .on('postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'profiles' },
      (payload) => updateUserCount(payload.new)
    ),
  
  supabase
    .channel('revenue')
    .on('postgres_changes',
      { event: 'UPDATE', schema: 'public', table: 'stats' },
      (payload) => updateRevenue(payload.new)
    )
];

// Subscribe to all channels
channels.forEach(ch => ch.subscribe());
```

---

## Security

### RLS Integration

Realtime respects Row Level Security (RLS) policies. Users only receive updates for rows they can SELECT.

```sql
-- Users can only see their own data
CREATE POLICY "Users see own data"
  ON sensitive_table FOR SELECT
  USING (auth.uid() = user_id);
```

### Filter Server-Side

Use filters to reduce data exposure:

```javascript
// Good: Filter on server
.on('postgres_changes',
  { 
    event: '*', 
    schema: 'public', 
    table: 'posts',
    filter: 'published=eq.true'
  },
  handler
)

// Avoid: Receiving all data then filtering client-side
.on('postgres_changes',
  { event: '*', schema: 'public', table: 'posts' },
  (payload) => {
    if (payload.new.published) {
      handler(payload);
    }
  }
)
```

### Authentication

Use authenticated clients for sensitive data:

```javascript
// Set user's JWT token
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  global: {
    headers: {
      Authorization: `Bearer ${userJwt}`
    }
  }
});
```

---

## Rate Limiting

### Default Limits

- 100 concurrent connections per client IP
- 100 channels per connection
- 500 joins per second per client
- 1000 messages per second per client
- 100 events per second per channel

### Handling Rate Limits

1. **Share Channels**: Use one channel for multiple subscriptions
2. **Debounce Updates**: Limit how often you process events
3. **Connection Pooling**: Reuse connections across components
4. **Implement Backoff**: Exponential backoff on reconnection

**Example: Debouncing**
```javascript
function debounce(func, wait) {
  let timeout;
  return function(...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

const debouncedHandler = debounce((payload) => {
  updateUI(payload);
}, 500);

channel.on('postgres_changes', { ... }, debouncedHandler);
```

---

## Best Practices

### 1. Always Clean Up

```javascript
// React example
useEffect(() => {
  const channel = supabase.channel('my-channel')
    .on('postgres_changes', { ... }, handler)
    .subscribe();
  
  return () => {
    supabase.removeChannel(channel);
  };
}, []);
```

### 2. Use Unique Channel Names

```javascript
// Good
supabase.channel(`post:${postId}`)

// Avoid
supabase.channel('post')
```

### 3. Handle Reconnections

```javascript
channel
  .on('system', { event: 'connected' }, () => {
    console.log('Connected');
  })
  .on('system', { event: 'disconnected' }, () => {
    console.log('Disconnected');
  })
  .on('system', { event: 'reconnecting' }, () => {
    console.log('Reconnecting...');
  });
```

### 4. Batch Operations

```javascript
// Instead of multiple channels
const channel = supabase
  .channel('all-changes')
  .on('postgres_changes', { event: 'INSERT', ... }, insertHandler)
  .on('postgres_changes', { event: 'UPDATE', ... }, updateHandler)
  .on('postgres_changes', { event: 'DELETE', ... }, deleteHandler)
  .subscribe();
```

### 5. Test Thoroughly

- Test with multiple clients
- Test under load
- Test disconnection/reconnection
- Test with RLS policies
- Test rate limiting

### 6. Monitor Performance

- Track connection count
- Monitor message throughput
- Watch for dropped events
- Check client-side memory usage

---

## Troubleshooting

### Not Receiving Updates

**Check 1: Table in Publication**
```sql
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

**Check 2: RLS Policies**
```sql
SELECT * FROM pg_policies WHERE tablename = 'your_table';
```

**Check 3: Replica Identity**
```sql
SELECT relname, relreplident FROM pg_class WHERE relname = 'your_table';
-- Should be 'f' for FULL
```

**Check 4: Subscription Status**
```javascript
channel.subscribe((status, err) => {
  console.log('Status:', status, 'Error:', err);
});
```

### Connection Issues

- Verify API keys are correct
- Check network connectivity
- Review browser console for errors
- Check CORS settings
- Verify WebSocket support

### Performance Issues

- Reduce active subscriptions
- Use filters to limit data
- Implement client-side debouncing
- Check rate limit settings
- Monitor network bandwidth

---

## Examples

See the `examples/realtime/` directory for complete examples:

1. **basic-subscription.js** - Simple table subscription
2. **table-changes.js** - Listening to specific events
3. **filtered-subscription.js** - Using filters
4. **presence.js** - Tracking online users
5. **broadcast.js** - Sending messages
6. **test-realtime.js** - Testing realtime functionality
7. **rate-limiting.html** - Browser example with rate limiting

### Running Examples

```bash
cd examples/realtime
npm install
npm run basic           # Basic subscription
npm run table-changes   # Table-specific changes
npm run filtered        # Filtered subscriptions
npm run presence        # Presence tracking
npm run broadcast       # Broadcast messages
npm run test           # Test suite
```

---

## Additional Resources

- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [JavaScript Client Reference](https://supabase.com/docs/reference/javascript/subscribe)
- [Realtime Security](https://supabase.com/docs/guides/realtime/security)
- [Realtime Rate Limits](https://supabase.com/docs/guides/realtime/rate-limits)
- [Postgres Replication](https://www.postgresql.org/docs/current/logical-replication.html)

---

**Last Updated**: 2025-10-05
