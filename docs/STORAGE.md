# Storage Configuration Guide

Complete guide for using Supabase Storage buckets with proper access control and best practices.

## 📋 Table of Contents

- [Overview](#overview)
- [Bucket Configuration](#bucket-configuration)
- [Access Policies](#access-policies)
- [Usage Examples](#usage-examples)
- [File Organization](#file-organization)
- [Security Best Practices](#security-best-practices)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project uses Supabase Storage for file uploads with three configured buckets:

| Bucket | Visibility | Purpose | Size Limit | Allowed Types |
|--------|-----------|---------|------------|---------------|
| `avatars` | Public | Profile pictures | 5MB | Images only (JPEG, PNG, GIF, WebP) |
| `public-assets` | Public | General public files | 10MB | Images, PDFs, text files |
| `user-files` | Private | User documents | 50MB | Documents, images, archives |

### Key Features

✅ **Row Level Security (RLS)** - All buckets protected with RLS policies  
✅ **File Size Limits** - Enforced at bucket level  
✅ **MIME Type Restrictions** - Only allowed file types accepted  
✅ **User-based Access Control** - Users can only access their own files  
✅ **Public/Private Buckets** - Appropriate visibility for each use case

---

## Bucket Configuration

### Avatars Bucket

**Purpose:** User profile pictures  
**Visibility:** Public (anyone can view)  
**Size Limit:** 5MB  
**Allowed MIME Types:**
- `image/jpeg`, `image/jpg`
- `image/png`
- `image/gif`
- `image/webp`

**Access Rules:**
- ✅ Anyone can view avatars
- ✅ Authenticated users can upload their own avatar
- ✅ Users can update/delete their own avatar
- ❌ Users cannot access other users' avatars (for upload/update/delete)

### Public Assets Bucket

**Purpose:** General public files (logos, images, public documents)  
**Visibility:** Public (anyone can view)  
**Size Limit:** 10MB  
**Allowed MIME Types:**
- Images: `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml`
- Documents: `application/pdf`, `text/plain`, `text/csv`

**Access Rules:**
- ✅ Anyone can view public assets
- ✅ Authenticated users can upload files
- ✅ Users can update/delete their own files
- ❌ Users cannot modify other users' files

### User Files Bucket

**Purpose:** Private user documents and uploads  
**Visibility:** Private (only file owner can access)  
**Size Limit:** 50MB  
**Allowed MIME Types:**
- Images: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
- Documents: `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
- Spreadsheets: `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- Other: `text/plain`, `text/csv`, `application/zip`

**Access Rules:**
- ✅ Users can view their own files only
- ✅ Users can upload files to their own folder
- ✅ Users can update/delete their own files
- ❌ Users cannot access other users' files

---

## Access Policies

All buckets use Row Level Security (RLS) to enforce access control. Policies are based on:

1. **Bucket ID** - Which bucket the file belongs to
2. **User ID** - The authenticated user's ID
3. **Folder Structure** - Files organized by user ID: `{bucket}/{user_id}/{filename}`

### Policy Pattern

For user-owned files, the folder structure must be:
```
bucket_name/{user_id}/filename.ext
```

The RLS policies use `storage.foldername(name)[1]` to extract the user ID from the path and compare it with `auth.uid()`.

### Example Policy

```sql
-- Users can only upload files to their own folder
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'user-files' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## Usage Examples

### JavaScript/TypeScript Client

#### 1. Upload Avatar

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

async function uploadAvatar(userId: string, file: File) {
  const fileExt = file.name.split('.').pop()
  const filePath = `${userId}/avatar.${fileExt}`

  const { data, error } = await supabase.storage
    .from('avatars')
    .upload(filePath, file, {
      cacheControl: '3600',
      upsert: true // Replace existing avatar
    })

  if (error) {
    console.error('Error uploading avatar:', error)
    return null
  }

  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('avatars')
    .getPublicUrl(filePath)

  return publicUrl
}
```

#### 2. Upload Private Document

```typescript
async function uploadUserDocument(userId: string, file: File) {
  const timestamp = Date.now()
  const filePath = `${userId}/${timestamp}_${file.name}`

  const { data, error } = await supabase.storage
    .from('user-files')
    .upload(filePath, file)

  if (error) {
    console.error('Error uploading document:', error)
    return null
  }

  return filePath
}
```

#### 3. Download Private File

```typescript
async function downloadUserFile(filePath: string) {
  const { data, error } = await supabase.storage
    .from('user-files')
    .download(filePath)

  if (error) {
    console.error('Error downloading file:', error)
    return null
  }

  // Create blob URL for viewing/downloading
  const url = URL.createObjectURL(data)
  return url
}
```

#### 4. List User's Files

```typescript
async function listUserFiles(userId: string) {
  const { data, error } = await supabase.storage
    .from('user-files')
    .list(userId, {
      limit: 100,
      offset: 0,
      sortBy: { column: 'created_at', order: 'desc' }
    })

  if (error) {
    console.error('Error listing files:', error)
    return []
  }

  return data
}
```

#### 5. Delete File

```typescript
async function deleteFile(bucket: string, filePath: string) {
  const { error } = await supabase.storage
    .from(bucket)
    .remove([filePath])

  if (error) {
    console.error('Error deleting file:', error)
    return false
  }

  return true
}
```

#### 6. Upload Public Asset

```typescript
async function uploadPublicAsset(userId: string, file: File) {
  const filePath = `${userId}/${file.name}`

  const { data, error } = await supabase.storage
    .from('public-assets')
    .upload(filePath, file)

  if (error) {
    console.error('Error uploading asset:', error)
    return null
  }

  // Get public URL (no authentication required to access)
  const { data: { publicUrl } } = supabase.storage
    .from('public-assets')
    .getPublicUrl(filePath)

  return publicUrl
}
```

---

## File Organization

### Folder Structure Best Practices

#### Recommended Structure

```
avatars/
  {user_id}/
    avatar.jpg              # Current avatar
    avatar_thumbnail.jpg    # Optional thumbnail

public-assets/
  {user_id}/
    logo.png
    banner.jpg
    document.pdf

user-files/
  {user_id}/
    {timestamp}_document.pdf
    {timestamp}_report.xlsx
    projects/
      project1/
        spec.pdf
        design.png
```

#### Naming Conventions

✅ **Good File Names:**
- `avatar.jpg` - Clear purpose
- `1698765432_report.pdf` - Timestamped
- `project_spec_v2.pdf` - Descriptive with version

❌ **Bad File Names:**
- `IMG_1234.jpg` - Not descriptive
- `file.pdf` - Too generic
- `my document.pdf` - Contains spaces

### File Path Examples

```typescript
// Avatar - single file per user (upsert)
`{user_id}/avatar.{ext}`

// Documents - timestamped for uniqueness
`{user_id}/{timestamp}_{original_name}`

// Organized by category
`{user_id}/{category}/{filename}`

// Project files
`{user_id}/projects/{project_id}/{filename}`
```

---

## Security Best Practices

### 1. Always Use User-Scoped Paths

```typescript
// ✅ Good - user ID in path
const filePath = `${userId}/document.pdf`

// ❌ Bad - no user ID
const filePath = `document.pdf`

// ❌ Bad - hardcoded or different user
const filePath = `other-user-id/document.pdf`
```

### 2. Validate File Types on Client

```typescript
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']

function validateImageFile(file: File): boolean {
  if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
    throw new Error(`Invalid file type: ${file.type}`)
  }
  
  const maxSize = 5 * 1024 * 1024 // 5MB
  if (file.size > maxSize) {
    throw new Error('File too large (max 5MB)')
  }
  
  return true
}
```

### 3. Handle Upload Errors Gracefully

```typescript
async function safeUpload(bucket: string, path: string, file: File) {
  try {
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(path, file)

    if (error) {
      // Handle specific error types
      if (error.message.includes('size')) {
        throw new Error('File size exceeds limit')
      }
      if (error.message.includes('mime')) {
        throw new Error('File type not allowed')
      }
      throw error
    }

    return data
  } catch (error) {
    console.error('Upload failed:', error)
    // Show user-friendly error message
    throw new Error('Failed to upload file. Please try again.')
  }
}
```

### 4. Clean Up Old Files

```typescript
async function cleanupOldFiles(userId: string, daysOld: number = 90) {
  const cutoffDate = new Date()
  cutoffDate.setDate(cutoffDate.getDate() - daysOld)

  const { data: files } = await supabase.storage
    .from('user-files')
    .list(userId)

  const oldFiles = files?.filter(file => 
    new Date(file.created_at) < cutoffDate
  ) || []

  if (oldFiles.length > 0) {
    const filePaths = oldFiles.map(f => `${userId}/${f.name}`)
    await supabase.storage
      .from('user-files')
      .remove(filePaths)
  }

  return oldFiles.length
}
```

### 5. Use Signed URLs for Temporary Access

```typescript
async function createTemporaryDownloadLink(bucket: string, path: string, expiresIn: number = 3600) {
  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrl(path, expiresIn) // seconds

  if (error) {
    console.error('Error creating signed URL:', error)
    return null
  }

  return data.signedUrl
}
```

---

## Testing

### Running Tests

Test the storage configuration with the provided test suite:

```bash
# Run storage tests
supabase db execute --file tests/storage_test_suite.sql

# Or using the Supabase Studio SQL Editor
# Copy and paste the contents of tests/storage_test_suite.sql
```

### Manual Testing Checklist

- [ ] Upload file to each bucket
- [ ] Verify file size limits are enforced
- [ ] Verify MIME type restrictions work
- [ ] Test access control (can't access other users' files)
- [ ] Test public bucket access (no authentication required)
- [ ] Test private bucket access (authentication required)
- [ ] Test file deletion
- [ ] Test file updates
- [ ] Verify folder organization works correctly

### Testing with Different Users

```typescript
// Test as User A
const userA = supabase.auth.user()
await uploadUserDocument(userA.id, fileA)

// Test as User B - should not access User A's files
const userB = supabase.auth.user()
const { error } = await supabase.storage
  .from('user-files')
  .download(`${userA.id}/document.pdf`) // Should fail

// Verify error is returned
expect(error).toBeTruthy()
```

---

## Troubleshooting

### Common Issues

#### 1. "new row violates row-level security policy"

**Cause:** File path doesn't match user ID  
**Solution:** Ensure file path starts with user ID

```typescript
// ❌ Wrong
const path = `files/document.pdf`

// ✅ Correct
const path = `${auth.uid()}/document.pdf`
```

#### 2. "File size exceeds limit"

**Cause:** File larger than bucket limit  
**Solution:** Compress file or use different bucket

```typescript
// Check file size before upload
if (file.size > 5 * 1024 * 1024) {
  throw new Error('File too large for avatars bucket')
}
```

#### 3. "Invalid mime type"

**Cause:** File type not in allowed list  
**Solution:** Convert file or use appropriate bucket

```typescript
// Check MIME type before upload
const ALLOWED_TYPES = ['image/jpeg', 'image/png']
if (!ALLOWED_TYPES.includes(file.type)) {
  throw new Error('Only JPEG and PNG images allowed')
}
```

#### 4. Can't access public bucket files

**Cause:** Using wrong method or incorrect path  
**Solution:** Use `getPublicUrl()` for public buckets

```typescript
// For public buckets
const { data } = supabase.storage
  .from('avatars')
  .getPublicUrl(filePath)

console.log(data.publicUrl) // Use this URL directly
```

#### 5. Can't download private files

**Cause:** Need authentication or using wrong method  
**Solution:** Use `download()` with authenticated client

```typescript
// For private buckets, must be authenticated
const { data, error } = await supabase.storage
  .from('user-files')
  .download(filePath)

if (error) {
  console.error('Download failed:', error)
}
```

### Debugging Tips

#### Check Bucket Configuration

```sql
-- View bucket settings
SELECT id, name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets;
```

#### Check Storage Policies

```sql
-- View all storage policies
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'storage';
```

#### Test Policy Directly

```sql
-- Test as specific user
SET request.jwt.claims.sub = 'user-uuid-here';

-- Try to select files
SELECT * FROM storage.objects WHERE bucket_id = 'user-files';
```

---

## Related Documentation

- [RLS Policies Guide](./RLS_POLICIES.md) - General RLS patterns
- [RLS Testing Guide](./RLS_TESTING.md) - Testing strategies
- [Database Migrations](../supabase/migrations/README.md) - Migration guidelines
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage) - Official documentation

---

## Migration History

| Migration | Date | Description |
|-----------|------|-------------|
| `20251006095457_configure_storage_buckets.sql` | 2025-10-06 | Initial storage bucket configuration with RLS policies |

---

**Last Updated:** 2025-10-06  
**Version:** 1.0.0  
**Status:** ✅ Complete
