## Objective
Create unit tests to verify that realtime subscriptions work correctly on the `profiles` table.

## Related Issue
- Implements testing for #143 (Enable realtime on profiles table)

## Test Coverage Required

### 1. Realtime Configuration
- [ ] `profiles` table is added to `supabase_realtime` publication
- [ ] `profiles` table has `REPLICA IDENTITY FULL` set
- [ ] Realtime is enabled in `config.toml` for profiles

### 2. Subscription Events
- [ ] INSERT events are broadcast when new profile is created
- [ ] UPDATE events are broadcast when profile is updated
- [ ] DELETE events are broadcast when profile is deleted
- [ ] Events contain correct payload data

### 3. Authorization
- [ ] Authenticated users can subscribe to profile changes
- [ ] Anonymous users can subscribe to public profile changes
- [ ] Users receive updates for all profiles (public read)

## Implementation
Create `tests/realtime_profiles_test.sql` and/or `tests/realtime_profiles_test.ts`

For JavaScript/TypeScript tests:
- Use `@supabase/supabase-js` client
- Subscribe to `profiles` table changes
- Verify events are received for INSERT/UPDATE/DELETE

For SQL tests:
- Verify publication includes profiles table
- Verify replica identity is set

## Success Criteria
- Publication configuration is correct
- Real-time events are received for all CRUD operations
- Event payloads contain expected data

## Test Command
```bash
npm run test:realtime
```
