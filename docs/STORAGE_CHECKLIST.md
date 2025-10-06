# Storage Setup Checklist

Quick checklist to verify your storage buckets are correctly configured and working.

## 🚀 Initial Setup

### 1. Apply Migration

```bash
# Reset database to apply all migrations including storage
npm run db:reset

# Or apply manually
supabase db reset
```

Expected output:
```
✓ Applying migration 20251006095457_configure_storage_buckets.sql
✓ Storage buckets configured successfully
```

### 2. Run Tests

```bash
# Run storage test suite
supabase db execute --file tests/storage_test_suite.sql
```

Expected output:
```
TEST 1: Verifying storage buckets are created...
PASS: All storage buckets created with correct visibility

TEST 2: Verifying file size limits...
PASS: File size limits configured correctly

TEST 3: Verifying MIME type restrictions...
PASS: MIME type restrictions configured correctly

TEST 4: Verifying storage RLS policies...
PASS: Storage RLS policies configured correctly

All tests passed!
```

## ✅ Verification Checklist

### Database Configuration

- [ ] Migration file exists: `supabase/migrations/20251006095457_configure_storage_buckets.sql`
- [ ] Migration has been applied (check with `supabase db status`)
- [ ] Test suite passes: `tests/storage_test_suite.sql`

### Buckets Created

- [ ] `avatars` bucket exists (public, 5MB limit)
- [ ] `public-assets` bucket exists (public, 10MB limit)
- [ ] `user-files` bucket exists (private, 50MB limit)

### RLS Policies

- [ ] 4 policies on avatars bucket (SELECT, INSERT, UPDATE, DELETE)
- [ ] 4 policies on public-assets bucket (SELECT, INSERT, UPDATE, DELETE)
- [ ] 4 policies on user-files bucket (SELECT, INSERT, UPDATE, DELETE)
- [ ] Total: 12 storage policies configured

### File Restrictions

- [ ] avatars: 5MB limit, images only
- [ ] public-assets: 10MB limit, multiple types
- [ ] user-files: 50MB limit, documents/images/archives

### Documentation

- [ ] `docs/STORAGE.md` - Complete usage guide
- [ ] `docs/STORAGE_IMPLEMENTATION_SUMMARY.md` - Implementation summary
- [ ] `examples/storage/` - Working code examples
- [ ] README.md updated with storage section

## 🧪 Manual Testing

### Test 1: Upload Avatar (Public Bucket)

```bash
cd examples/storage
npm install
node avatar-upload.js
```

Expected: Can list avatars (if any exist)

### Test 2: Upload Private File

```bash
node file-upload.js
```

Expected: Can list user files (if any exist)

### Test 3: Upload Public Asset

```bash
node public-assets.js
```

Expected: Can list public assets and get public URLs

### Test 4: Verify in Studio

1. Open Supabase Studio: http://localhost:8000
2. Navigate to Storage
3. Verify buckets:
   - ✓ avatars (public)
   - ✓ public-assets (public)
   - ✓ user-files (private)

### Test 5: Upload via Studio

1. Select `avatars` bucket
2. Try to upload an image (should work)
3. Try to upload a PDF (should fail - wrong MIME type)
4. Try to upload a 10MB image (should fail - size limit)

## 🔒 Security Testing

### Test User Isolation

```javascript
// Test that users can't access other users' files
const userA = 'user-id-a';
const userB = 'user-id-b';

// User A uploads file
await supabase.storage.from('user-files').upload(`${userA}/doc.pdf`, file);

// User B tries to access (should fail)
const { error } = await supabase.storage
  .from('user-files')
  .download(`${userA}/doc.pdf`); // Error: RLS policy violation
```

### Test MIME Type Restrictions

```javascript
// Try uploading PDF to avatars bucket (should fail)
await supabase.storage.from('avatars').upload('user/doc.pdf', pdfFile);
// Error: File type not allowed
```

### Test Size Limits

```javascript
// Try uploading 6MB image to avatars (should fail)
await supabase.storage.from('avatars').upload('user/big.jpg', largeFile);
// Error: File size exceeds limit
```

## 📊 Verification Commands

### Check Buckets

```sql
SELECT id, name, public, file_size_limit 
FROM storage.buckets 
ORDER BY name;
```

Expected output:
```
id             | name          | public | file_size_limit
---------------+---------------+--------+-----------------
avatars        | avatars       | true   | 5242880
public-assets  | public-assets | true   | 10485760
user-files     | user-files    | false  | 52428800
```

### Check Policies

```sql
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN definition LIKE '%avatars%' THEN 'avatars'
        WHEN definition LIKE '%public-assets%' THEN 'public-assets'
        WHEN definition LIKE '%user-files%' THEN 'user-files'
    END as bucket
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
ORDER BY bucket, cmd;
```

Expected: 12 rows (4 per bucket)

### Check MIME Types

```sql
SELECT id, allowed_mime_types 
FROM storage.buckets 
ORDER BY id;
```

Expected: Each bucket has appropriate MIME types array

## 🐛 Troubleshooting

### Migration Fails

```bash
# Check migration status
supabase db status

# View error details
supabase db reset --debug
```

### Tests Fail

```bash
# Reset and rerun
supabase db reset
supabase db execute --file tests/storage_test_suite.sql
```

### Can't Upload Files

1. Check authentication (user must be signed in)
2. Verify file path format: `{user_id}/{filename}`
3. Check MIME type is allowed
4. Verify file size within limit
5. Check RLS policies in Studio

### Policy Errors

```bash
# View storage policies
supabase db execute --sql "SELECT * FROM pg_policies WHERE tablename = 'objects'"

# Check if storage.foldername exists
supabase db execute --sql "SELECT proname FROM pg_proc WHERE proname = 'foldername'"
```

## 📚 Next Steps

Once all checks pass:

1. ✅ Review [docs/STORAGE.md](./STORAGE.md) for usage patterns
2. ✅ Integrate storage in your application
3. ✅ Test with real user authentication
4. ✅ Monitor storage usage in production
5. ✅ Set up backup policies if needed

## 🎯 Production Readiness

Before deploying to production:

- [ ] All tests pass
- [ ] Manual testing completed
- [ ] Security testing verified
- [ ] File organization strategy defined
- [ ] Backup strategy in place
- [ ] Monitoring configured
- [ ] Team trained on storage patterns
- [ ] Documentation reviewed

---

**Last Updated:** 2025-10-06  
**Version:** 1.0.0

For issues or questions, see:
- [STORAGE.md](./STORAGE.md) - Complete guide
- [GitHub Issues](https://github.com/SkogAI/supabase/issues)
