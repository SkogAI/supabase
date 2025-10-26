---
title: [Function Name]
type: note
permalink: functions/[function-name]
tags:
  - "function"
  - "edge-function"
  - "deno"
  - "serverless"
  - "[add-specific-tags]"
project: supabase
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# [Function Name]

**Function Path:** `supabase/functions/[function-name]/`
**Runtime:** Deno 2.x
**Deployed:** YYYY-MM-DD
**Status:** ✅ Active | 🔄 In Development | ⚠️ Deprecated

## Purpose

One-sentence description of what this edge function does.

Detailed explanation of the function's role, when to use it, and what problem it solves.

## Endpoint

```
POST https://[project-ref].supabase.co/functions/v1/[function-name]
```

Local development:
```
POST http://localhost:54321/functions/v1/[function-name]
```

## Request Format

### Headers

```
Authorization: Bearer [ANON_KEY or SERVICE_ROLE_KEY]
Content-Type: application/json
```

### Body

```json
{
  "param1": "value1",
  "param2": "value2"
}
```

### Parameters

- `param1` (required) - Description of parameter
- `param2` (optional) - Description, defaults to X

## Response Format

### Success Response (200)

```json
{
  "success": true,
  "data": {
    "result": "value"
  }
}
```

### Error Response (4xx/5xx)

```json
{
  "error": "Error message",
  "details": "Additional context"
}
```

## Implementation Details

### Core Logic

Brief explanation of the main algorithm or flow:

1. Validate input parameters
2. Authenticate user (if needed)
3. Process request
4. Return response

### Key Functions

```typescript
// Important code snippets
async function processRequest(data: RequestData): Promise<Response> {
  // Core logic here
}
```

### Dependencies

- [dependency] `supabase-js` - Client library
- [dependency] `@supabase/supabase-js` - Database access
- [dependency] External API: Service Name
- [dependency] Shared utilities: `_shared/[util-name].ts`

### Environment Variables

- `SUPABASE_URL` - Automatically provided
- `SUPABASE_ANON_KEY` - Automatically provided
- `SUPABASE_SERVICE_ROLE_KEY` - For admin operations
- `CUSTOM_API_KEY` - Description (set in Supabase Dashboard)

## Authentication

- [auth] **Public:** No authentication required
- [auth] **Authenticated:** Requires valid JWT token
- [auth] **Service Role:** Requires service role key for admin operations

```typescript
// Extract user from JWT
const authHeader = req.headers.get('Authorization')
const token = authHeader?.replace('Bearer ', '')
const { data: { user } } = await supabaseClient.auth.getUser(token)
```

## Database Access

### Tables Accessed

- `table_name` - Description of how it's used (read/write)
- `another_table` - Description

### RLS Considerations

- Function respects RLS policies when using anon/authenticated keys
- Uses service role key to bypass RLS when needed
- Explain any special permission handling

## Testing

### Local Testing

```bash
# Start function locally
npm run functions:serve

# Test with curl
curl -i --location --request POST 'http://localhost:54321/functions/v1/[function-name]' \
  --header 'Authorization: Bearer [ANON_KEY]' \
  --header 'Content-Type: application/json' \
  --data '{"param1":"value1"}'
```

### Unit Tests

```bash
# Run function tests
cd supabase/functions/[function-name]
deno test --allow-all test.ts
```

### Test Cases

- [test] Valid input returns success
- [test] Invalid input returns error with helpful message
- [test] Unauthenticated request handled correctly
- [test] Edge cases: empty data, malformed JSON, etc.

## Use Cases

### Use Case 1: [Name]

**When:** Describe when to use this
**Example:**

```bash
curl -i --location --request POST 'https://[project-ref].supabase.co/functions/v1/[function-name]' \
  --header 'Authorization: Bearer [ANON_KEY]' \
  --header 'Content-Type: application/json' \
  --data '{"specific":"example"}'
```

**Result:** What the function returns

### Use Case 2: [Name]

**When:** Another scenario
**Example:** Code example

## Performance

- **Cold Start:** ~500ms typical
- **Warm Execution:** ~50-100ms typical
- **Rate Limits:** 100 requests/second per function
- **Timeout:** 150 seconds max
- **Memory:** 512 MB default

### Optimization Tips

- Cache expensive operations
- Use connection pooling for database
- Minimize cold starts with keep-alive strategies

## Common Issues

### Issue: [Error Message or Problem]

**Symptoms:**
- What developers see when this happens
- Error messages or behavior

**Cause:** Why this happens

**Solution:**

```typescript
// How to fix in code
```

### Issue: CORS Errors

**Symptoms:** `Access-Control-Allow-Origin` errors in browser

**Solution:**

```typescript
// Ensure CORS headers are set
return new Response(JSON.stringify(data), {
  headers: { 
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  }
})
```

## Deployment

### Deploy Function

```bash
# Deploy single function
supabase functions deploy [function-name]

# Deploy all functions
npm run functions:deploy
```

### Set Environment Variables

```bash
# In Supabase Dashboard
Settings → Edge Functions → [function-name] → Add variable
```

### Verify Deployment

```bash
# Check function logs
supabase functions logs [function-name]

# Test deployed function
curl https://[project-ref].supabase.co/functions/v1/[function-name]
```

## Monitoring

### View Logs

```bash
# Real-time logs during development
supabase functions serve --debug

# Production logs
supabase functions logs [function-name] --tail
```

### Common Log Patterns

```
[INFO] Function invoked: {param1: "value"}
[ERROR] Validation failed: Missing required field
[DEBUG] Processing step 1 of 3
```

## Integration

### Client-Side Integration

```typescript
// From frontend application
const { data, error } = await supabase.functions.invoke('[function-name]', {
  body: { param1: 'value1' }
})
```

### Server-Side Integration

```typescript
// From another edge function or backend
const response = await fetch(`${SUPABASE_URL}/functions/v1/[function-name]`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ param1: 'value1' })
})
```

## Related Files

- Shared utilities: `supabase/functions/_shared/[utility].ts`
- Tests: `supabase/functions/[function-name]/test.ts`
- Related functions: `supabase/functions/[related-function]/`
- Documentation: `supabase/functions/README.md`

## Security Considerations

- [security] Input validation: All inputs are validated
- [security] SQL injection: Uses parameterized queries
- [security] Rate limiting: Consider implementing rate limits
- [security] Secrets: Never expose service role key to clients
- [security] CORS: Configured appropriately for use case

## Future Improvements

- [ ] Potential enhancement 1
- [ ] Potential enhancement 2
- [ ] Performance optimization ideas

## References

- Related concept: `[[Edge Functions Architecture]]`
- Related guide: `[[Working with Edge Functions]]`
- Related function: `[[Related Function Name]]`
- Deno docs: [Deno Manual](https://deno.land/manual)
- Official docs: [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

**Template Version:** 1.0
**Template Type:** Edge Function
**Last Updated:** 2025-10-26
