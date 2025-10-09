## Objective
Create unit tests to verify that storage buckets are properly configured with correct size limits, file type restrictions, and RLS policies.

## Related Issue
- Implements testing for #142 (Add storage buckets to tracked migrations)

## Test Coverage Required

### 1. Bucket Configuration
- [ ] `avatars` bucket exists with 5MB limit
- [ ] `avatars` bucket only allows image file types
- [ ] `public-assets` bucket exists with 10MB limit
- [ ] `public-assets` bucket allows images and PDFs
- [ ] `user-files` bucket exists with 50MB limit
- [ ] `user-files` bucket is private by default

### 2. Storage RLS Policies
- [ ] Authenticated users can upload to their own folder in `avatars`
- [ ] Authenticated users can read from their own folder in `avatars`
- [ ] Anyone can read from `public-assets`
- [ ] Only authenticated users can upload to `public-assets`
- [ ] Users can only access their own files in `user-files`
- [ ] Service role has full access to all buckets

### 3. File Type Validation
- [ ] `avatars` rejects non-image files
- [ ] `public-assets` rejects files other than images/PDFs
- [ ] File size limits are enforced correctly

## Implementation
Enhance `tests/storage_test_suite.sql` or create `tests/storage_buckets_test.sql`

## Success Criteria
- All bucket configuration tests pass
- All RLS policy tests pass
- File type and size restrictions work correctly

## Test Command
```bash
npm run test:storage
# or
supabase db execute --file tests/storage_buckets_test.sql
```
