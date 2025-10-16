# Supabase Realtime Examples

This directory contains examples for using Supabase Realtime to listen to database changes in real-time.

## Prerequisites

```bash
npm install @supabase/supabase-js
```

Or using a CDN in browser:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

## Quick Start

1. Initialize the Supabase client
2. Subscribe to a channel
3. Listen to specific events (INSERT, UPDATE, DELETE)
4. Clean up subscriptions when done

## Examples

- **basic-subscription.js** - Simple channel subscription
- **table-changes.js** - Listen to specific table changes
- **filtered-subscription.js** - Subscribe with filters
- **presence.js** - Track online users (Presence feature)
- **broadcast.js** - Send messages between clients
- **rate-limiting.html** - Example with rate limiting

## Common Patterns

### Pattern 1: Listen to All Changes on a Table

```javascript
const channel = supabase
  .channel('posts-changes')
  .on('postgres_changes', 
    { event: '*', schema: 'public', table: 'posts' },
    (payload) => console.log('Change received!', payload)
  )
  .subscribe();
```

### Pattern 2: Listen to Specific Events

```javascript
const channel = supabase
  .channel('new-posts')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'posts' },
    (payload) => console.log('New post:', payload.new)
  )
  .subscribe();
```

### Pattern 3: Filter by Column Value

```javascript
const channel = supabase
  .channel('user-posts')
  .on('postgres_changes',
    { 
      event: '*', 
      schema: 'public', 
      table: 'posts',
      filter: 'user_id=eq.YOUR_USER_ID'
    },
    (payload) => console.log('Your post changed:', payload)
  )
  .subscribe();
```

## Best Practices

1. **Always unsubscribe when done** - Prevent memory leaks
   ```javascript
   await supabase.removeChannel(channel);
   ```

2. **Use specific channels** - Give each subscription a unique name
   ```javascript
   supabase.channel('unique-channel-name')
   ```

3. **Handle errors** - Listen for error events
   ```javascript
   channel.on('error', (error) => console.error('Channel error:', error));
   ```

4. **Respect rate limits** - Don't create too many subscriptions
   - Default: 100 concurrent connections per client
   - Default: 100 channels per connection

5. **Clean up on component unmount** (React example)
   ```javascript
   useEffect(() => {
     const channel = supabase.channel('my-channel')
       .on('postgres_changes', { ... }, handler)
       .subscribe();
     
     return () => {
       supabase.removeChannel(channel);
     };
   }, []);
   ```

6. **Use filters to reduce payload** - Filter server-side when possible

7. **Batch updates** - Debounce rapid changes on the client side

## Realtime Features

### 1. Postgres Changes
Listen to INSERT, UPDATE, DELETE events on your database tables.

### 2. Presence
Track which users are online and share state between them.

### 3. Broadcast
Send ephemeral messages between clients (chat, notifications, etc.).

## Troubleshooting

### Channel not receiving updates
- Check RLS policies allow SELECT on the table
- Verify realtime is enabled: `ALTER PUBLICATION supabase_realtime ADD TABLE your_table`
- Check replica identity: `ALTER TABLE your_table REPLICA IDENTITY FULL`

### Connection issues
- Check network connectivity
- Verify API keys are correct
- Check browser console for errors

### Performance issues
- Reduce number of active subscriptions
- Use filters to limit data
- Consider using broadcast for high-frequency updates

## Resources

- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [JavaScript Client Reference](https://supabase.com/docs/reference/javascript/subscribe)
- [Realtime Security](https://supabase.com/docs/guides/realtime/security)
