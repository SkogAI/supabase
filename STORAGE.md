# Supabase Storage Guide

Complete guide for file uploads, storage buckets, and access policies in this project.

## Overview

This project uses Supabase Storage for file management with two main buckets:

1. **public-assets** - For publicly accessible files (avatars, thumbnails)
2. **user-files** - For private user documents and files

Both buckets are protected with Row Level Security (RLS) policies to ensure users can only access and manage their own files.

## Buckets Configuration

### Public Assets Bucket

- **Name**: public-assets
- **Access**: Public (files accessible via URL)
- **Size Limit**: 5MB per file
- **Allowed MIME Types**: image/jpeg, image/png, image/gif, image/webp, image/svg+xml

**Use Cases**: User avatars, profile images, public thumbnails, logo images

### User Files Bucket

- **Name**: user-files
- **Access**: Private (requires authentication)
- **Size Limit**: 50MB per file
- **Allowed MIME Types**: Images (jpeg, png, gif, webp), Documents (pdf, doc, docx, xls, xlsx), Text (txt, csv)

**Use Cases**: Private documents, user uploads, invoices, receipts, personal media files

## Security & RLS Policies

All files must be organized with the user's UUID as the first folder level:
```
{user_id}/filename.ext
{user_id}/subfolder/file.pdf
```

This pattern is enforced by RLS policies using `storage.foldername()`.

### Public Assets Policies

- **SELECT**: Anyone can view
- **INSERT**: Authenticated users can upload to their folder
- **UPDATE/DELETE**: Users can manage their own files

### User Files Policies

- **All operations**: Owner only (users can only access files in their own folder)

## Usage Example

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Upload to public assets
async function uploadAvatar(userId: string, file: File) {
  const fileName = `${userId}/avatar.jpg`

  const { data, error } = await supabase.storage
    .from('public-assets')
    .upload(fileName, file, { upsert: true })

  if (error) return null

  const { data: { publicUrl } } = supabase.storage
    .from('public-assets')
    .getPublicUrl(fileName)

  return publicUrl
}

// Upload to private files
async function uploadDocument(userId: string, file: File) {
  const fileName = `${userId}/documents/${Date.now()}_${file.name}`

  const { data, error } = await supabase.storage
    .from('user-files')
    .upload(fileName, file)

  return error ? null : data
}

// List user files
async function listUserFiles(userId: string) {
  const { data, error } = await supabase.storage
    .from('user-files')
    .list(`${userId}`, {
      limit: 100,
      sortBy: { column: 'created_at', order: 'desc' }
    })

  return error ? [] : data
}

// Delete file
async function deleteFile(userId: string, fileName: string) {
  const { error } = await supabase.storage
    .from('user-files')
    .remove([`${userId}/${fileName}`])

  return !error
}

// Get file metadata (using helper function)
async function getUserFileMetadata(userId: string) {
  const { data, error } = await supabase
    .rpc('get_user_files', { user_uuid: userId })

  return error ? [] : data
}
```

## Testing Storage

### Manual Testing

1. Navigate to http://localhost:8000 (local) or your project dashboard
2. Go to Storage section
3. Select a bucket (`public-assets` or `user-files`)
4. Upload test files
5. Verify RLS policies work as expected

### Automated Tests

See `tests/storage-test-example.ts` for integration tests.

Run tests:
```bash
deno test --allow-all tests/storage-test-example.ts
```

## Common Issues

### "Policy violation" Error

**Cause**: RLS policy doesn't allow the operation

**Solution**:
- Ensure user is authenticated
- Check file path starts with user's UUID
- Verify the correct bucket is being used

```typescript
// ❌ Wrong - not in user folder
await supabase.storage.from('user-files').upload('file.pdf', file)

// ✅ Correct - in user folder
await supabase.storage.from('user-files').upload(`${userId}/file.pdf`, file)
```

### "File size exceeds limit"

Check bucket limits:
- public-assets: 5MB
- user-files: 50MB

### "Invalid MIME type"

Check allowed MIME types in migration file: `supabase/migrations/20251005052959_setup_storage_buckets.sql`

### Private bucket public URL issue

Use signed URLs for private files:

```typescript
const { data } = await supabase.storage
  .from('user-files')
  .createSignedUrl(`${userId}/file.pdf`, 3600) // Expires in 1 hour
```

## Migration Information

Storage buckets are created via migration file:
- **File**: `supabase/migrations/20251005052959_setup_storage_buckets.sql`
- **Applied**: Automatically on `supabase db reset` or `supabase db push`

To modify bucket configuration:
1. Edit the migration file
2. Run `supabase db reset` locally
3. Test thoroughly
4. Deploy changes with `supabase db push` (production)

## Resources

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Storage RLS Policies](https://supabase.com/docs/guides/storage/security/access-control)
- [Storage Client Library](https://supabase.com/docs/reference/javascript/storage-from-upload)
