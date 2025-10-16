# Realtime Quick Start Guide

Get up and running with Supabase Realtime in 5 minutes.

## Prerequisites

```bash
npm install @supabase/supabase-js
```

## 1. Basic Setup

```javascript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SUPABASE_ANON_KEY'
);
```

## 2. Listen to Database Changes

```javascript
// Subscribe to all changes on posts table
const channel = supabase
  .channel('posts-changes')
  .on('postgres_changes', 
    { event: '*', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('Change:', payload);
    }
  )
  .subscribe();
```

## 3. Filter Updates

```javascript
// Only listen to published posts
const channel = supabase
  .channel('published-posts')
  .on('postgres_changes',
    { 
      event: 'INSERT', 
      schema: 'public', 
      table: 'posts',
      filter: 'published=eq.true'
    },
    (payload) => {
      console.log('New published post:', payload.new);
    }
  )
  .subscribe();
```

## 4. Track Online Users (Presence)

```javascript
const channel = supabase.channel('online-users');

await channel
  .on('presence', { event: 'sync' }, () => {
    const users = channel.presenceState();
    console.log('Online:', users);
  })
  .subscribe();

// Track your presence
await channel.track({
  user_id: 'user-123',
  username: 'John',
  status: 'online'
});
```

## 5. Send Messages (Broadcast)

```javascript
const channel = supabase.channel('chat');

// Listen for messages
await channel
  .on('broadcast', { event: 'message' }, ({ payload }) => {
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

## 6. Clean Up

```javascript
// Always unsubscribe when done
await supabase.removeChannel(channel);
```

## Running Examples

```bash
cd examples/realtime
npm install

# Try different examples
npm run basic           # Basic subscription
npm run table-changes   # Event-specific handlers
npm run filtered        # Filtered subscriptions
npm run presence        # Online user tracking
npm run broadcast       # Messaging
npm run test           # Test suite
```

## Browser Example

Open `rate-limiting.html` in your browser to see a visual demonstration with rate limiting.

## Enabled Tables

Realtime is currently enabled for:
- ✅ `profiles` - User profile changes
- ✅ `posts` - Content changes

## Common Events

- `INSERT` - New row created
- `UPDATE` - Row modified
- `DELETE` - Row removed
- `*` - All events

## Need Help?

- See `README.md` for detailed examples
- See `../docs/REALTIME.md` for complete guide
- See `../../README.md` for project overview
- Visit [Supabase Docs](https://supabase.com/docs/guides/realtime)

## Troubleshooting

**Not receiving updates?**
1. Check table is in `supabase_realtime` publication
2. Verify RLS policies allow SELECT
3. Confirm replica identity is FULL
4. Check API keys are correct

**Connection issues?**
1. Verify network connectivity
2. Check browser console for errors
3. Ensure WebSocket support is available
