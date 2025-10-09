## Objective
Create end-to-end integration tests that verify multiple features work together correctly.

## Related Issues
- Tests integration of #142, #143, #144, #145

## Test Coverage Required

### 1. User Profile Lifecycle
- [ ] New user signup creates profile automatically (via trigger)
- [ ] Profile data is populated from user metadata
- [ ] Profile can be updated via edge function
- [ ] Profile updates trigger realtime events
- [ ] Profile deletion cascades correctly

### 2. Avatar Upload Flow
- [ ] User can upload avatar to storage
- [ ] Avatar URL is saved to profile
- [ ] Avatar is publicly accessible
- [ ] Old avatar is cleaned up on update

### 3. Cross-Feature Integration
- [ ] Profile changes are visible in realtime subscriptions
- [ ] Storage policies respect profile ownership
- [ ] Edge functions can query profiles with correct RLS context
- [ ] Service role can perform admin operations

## Implementation
Create `tests/integration_test_suite.sql` and `tests/integration_test_suite.ts`

Use a combination of:
- SQL for database-level integration tests
- TypeScript/JavaScript for client-side integration tests
- Edge function calls to test full stack

## Success Criteria
- All integration tests pass
- Tests verify features work together, not in isolation
- Realistic user workflows are tested

## Test Command
```bash
npm run test:integration
# or
npm test
```
