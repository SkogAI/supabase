## Objective
Create comprehensive unit tests to verify that all RLS policies on the `profiles` table work correctly.

## Related Issue
- Implements testing for #144 (Add service role policy to profiles)

## Test Coverage Required

### 1. Service Role Access
- [ ] Service role can SELECT all profiles
- [ ] Service role can INSERT profiles for any user
- [ ] Service role can UPDATE any profile
- [ ] Service role can DELETE any profile

### 2. Authenticated User Access
- [ ] Authenticated users can view all profiles (public read)
- [ ] Authenticated users can insert their own profile
- [ ] Authenticated users can update their own profile
- [ ] Authenticated users CANNOT update other users' profiles
- [ ] Authenticated users can delete their own profile (if policy exists)
- [ ] Authenticated users CANNOT delete other users' profiles

### 3. Anonymous User Access
- [ ] Anonymous users can view all profiles (public read)
- [ ] Anonymous users CANNOT insert profiles
- [ ] Anonymous users CANNOT update profiles
- [ ] Anonymous users CANNOT delete profiles

## Implementation
Add tests to `tests/rls_test_suite.sql` or create `tests/profile_rls_test.sql`

## Success Criteria
- All tests pass with PASS status
- Test covers all CRUD operations for all roles (service_role, authenticated, anon)
- Clear error messages when policies are violated

## Test Command
```bash
npm run test:rls
```
