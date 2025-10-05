# Supabase Storage Guide

Complete guide for file uploads, storage buckets, and access policies in this project.

## Table of Contents

- [Overview](#overview)
- [Buckets Configuration](#buckets-configuration)
- [Security & RLS Policies](#security--rls-policies)
- [Usage Examples](#usage-examples)
- [File Organization](#file-organization)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Testing Storage](#testing-storage)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project uses Supabase Storage for file management with two main buckets:

1. **public-assets** - For publicly accessible files (avatars, thumbnails)
2. **user-files** - For private user documents and files

Both buckets are protected with Row Level Security (RLS) policies to ensure users can only access and manage their own files.

---

## Buckets Configuration

### Public Assets Bucket

```
Name: public-assets
Access: Public (files accessible via URL)
Size Limit: 5MB per file
Allowed MIME Types:
  - image/jpeg
  - image/png
  - image/gif
  - image/webp
  - image/svg+xml
```

**Use Cases:**
- User avatars
- Profile images
- Public thumbnails
- Logo images
- Public media assets

### User Files Bucket

```
Name: user-files
Access: Private (requires authentication)
Size Limit: 50MB per file
Allowed MIME Types:
  - Images: jpeg, png, gif, webp
  - Documents: pdf, doc, docx, xls, xlsx
  - Text: txt, csv
```

**Use Cases:**
- Private documents
- User uploads
- Invoices and receipts
- Personal media files
- Data exports

---

## Security & RLS Policies

### Public Assets Policies

| Action | Policy | Description |
|--------|--------|-------------|
| SELECT | Anyone | All users can view public assets |
| INSERT | Authenticated | Users can upload to their folder (`{user_id}/...`) |
| UPDATE | Authenticated | Users can update their own files |
| DELETE | Authenticated | Users can delete their own files |

### User Files Policies

| Action | Policy | Description |
|--------|--------|-------------|
| SELECT | Owner only | Users can only view files in their folder |
| INSERT | Owner only | Users can only upload to their folder |
| UPDATE | Owner only | Users can only update their own files |
| DELETE | Owner only | Users can only delete their own files |

**File Organization Pattern:**
All files must be organized with the user's UUID as the first folder level:
```
{user_id}/filename.ext
{user_id}/subfolder/file.pdf
```

This pattern is enforced by RLS policies using `storage.foldername()`.

---

## Usage Examples

### JavaScript/TypeScript (Browser)

#### 1. Initialize Supabase Client

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
)
```

#### 2. Upload to Public Assets

```typescript
// Upload user avatar
async function uploadAvatar(userId: string, file: File) {
  const fileExt = file.name.split('.').pop()
  const fileName = `${userId}/avatar.${fileExt}`
  
  const { data, error } = await supabase.storage
    .from('public-assets')
    .upload(fileName, file, {
      cacheControl: '3600',
      upsert: true // Replace if exists
    })
  
  if (error) {
    console.error('Upload error:', error)
    return null
  }
  
  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('public-assets')
    .getPublicUrl(fileName)
  
  return publicUrl
}
```

#### 3. Upload to Private User Files

```typescript
// Upload private document
async function uploadDocument(userId: string, file: File) {
  const timestamp = Date.now()
  const fileName = `${userId}/documents/${timestamp}_${file.name}`
  
  const { data, error } = await supabase.storage
    .from('user-files')
    .upload(fileName, file)
  
  if (error) {
    console.error('Upload error:', error)
    return null
  }
  
  return data
}
```

#### 4. Download Private File

```typescript
// Download user's private file
async function downloadFile(userId: string, fileName: string) {
  const { data, error } = await supabase.storage
    .from('user-files')
    .download(`${userId}/${fileName}`)
  
  if (error) {
    console.error('Download error:', error)
    return null
  }
  
  // Create download link
  const url = URL.createObjectURL(data)
  const a = document.createElement('a')
  a.href = url
  a.download = fileName
  a.click()
  URL.revokeObjectURL(url)
}
```

#### 5. List User Files

```typescript
// List all files in user's folder
async function listUserFiles(userId: string) {
  const { data, error } = await supabase.storage
    .from('user-files')
    .list(`${userId}`, {
      limit: 100,
      offset: 0,
      sortBy: { column: 'created_at', order: 'desc' }
    })
  
  if (error) {
    console.error('List error:', error)
    return []
  }
  
  return data
}
```

#### 6. Delete File

```typescript
// Delete user's file
async function deleteFile(userId: string, fileName: string) {
  const { error } = await supabase.storage
    .from('user-files')
    .remove([`${userId}/${fileName}`])
  
  if (error) {
    console.error('Delete error:', error)
    return false
  }
  
  return true
}
```

#### 7. Get File Metadata (Using Helper Function)

```typescript
// Use the database helper function
async function getUserFileMetadata(userId: string) {
  const { data, error } = await supabase
    .rpc('get_user_files', { user_uuid: userId })
  
  if (error) {
    console.error('Metadata error:', error)
    return []
  }
  
  return data
}
```

### React Example with File Upload Component

```tsx
import { useState } from 'react'
import { supabase } from './supabaseClient'

export function FileUpload({ userId }: { userId: string }) {
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setUploading(true)
      setError(null)

      if (!event.target.files || event.target.files.length === 0) {
        throw new Error('You must select a file to upload.')
      }

      const file = event.target.files[0]
      
      // Validate file size (50MB for user-files)
      if (file.size > 50 * 1024 * 1024) {
        throw new Error('File size must be less than 50MB')
      }

      const fileExt = file.name.split('.').pop()
      const fileName = `${userId}/documents/${Date.now()}.${fileExt}`

      const { error: uploadError } = await supabase.storage
        .from('user-files')
        .upload(fileName, file)

      if (uploadError) {
        throw uploadError
      }

      alert('File uploaded successfully!')
    } catch (error: any) {
      setError(error.message)
    } finally {
      setUploading(false)
    }
  }

  return (
    <div>
      <input
        type="file"
        onChange={handleUpload}
        disabled={uploading}
      />
      {uploading && <p>Uploading...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  )
}
```

---

## File Organization

### Recommended Folder Structure

```
public-assets/
├── {user_id}/
│   ├── avatar.jpg
│   ├── cover.jpg
│   └── thumbnails/
│       └── thumb_*.jpg

user-files/
├── {user_id}/
│   ├── documents/
│   │   ├── invoice_*.pdf
│   │   └── report_*.docx
│   ├── images/
│   │   └── private_*.jpg
│   └── exports/
│       └── data_*.csv
```

### Naming Conventions

1. **Use descriptive names**: `invoice_2024_01.pdf` instead of `file1.pdf`
2. **Add timestamps**: `${Date.now()}_${originalName}` for uniqueness
3. **Organize in subfolders**: Group related files (`documents/`, `images/`)
4. **Lowercase with hyphens**: `user-profile-pic.jpg` instead of `User Profile Pic.jpg`

---

## API Reference

### Storage Client Methods

```typescript
// Upload
.upload(path: string, file: File | Blob, options?: {
  cacheControl?: string
  contentType?: string
  upsert?: boolean
})

// Download
.download(path: string)

// List
.list(path: string, options?: {
  limit?: number
  offset?: number
  sortBy?: { column: string, order: 'asc' | 'desc' }
})

// Remove
.remove(paths: string[])

// Get Public URL
.getPublicUrl(path: string)

// Create Signed URL (for private files)
.createSignedUrl(path: string, expiresIn: number)

// Move
.move(fromPath: string, toPath: string)

// Copy
.copy(fromPath: string, toPath: string)
```

### Database Helper Functions

```sql
-- Get all user files with metadata
SELECT * FROM get_user_files('{user_id}');
```

---

## Best Practices

### Security

1. **Never trust client-side validation**: Always validate file types and sizes
2. **Use signed URLs for temporary access**: For sharing private files
3. **Implement rate limiting**: Prevent abuse of upload endpoints
4. **Scan files for malware**: Use external services for uploaded files
5. **Validate file content**: Check MIME type matches file extension

### Performance

1. **Compress images before upload**: Reduce bandwidth and storage costs
2. **Use lazy loading**: For image galleries
3. **Implement pagination**: When listing many files
4. **Cache public URLs**: Avoid repeated API calls
5. **Use CDN**: For public assets (Supabase provides this)

### User Experience

1. **Show upload progress**: Use progress events
2. **Validate before upload**: Check size and type client-side first
3. **Handle errors gracefully**: Display user-friendly error messages
4. **Provide file previews**: For images and documents
5. **Allow batch operations**: Upload/delete multiple files at once

### Storage Management

1. **Set file retention policies**: Auto-delete old temporary files
2. **Monitor storage usage**: Track per-user quotas
3. **Implement cleanup jobs**: Remove orphaned files
4. **Use appropriate file sizes**: Don't store unnecessarily large files
5. **Document file purposes**: Add metadata for tracking

---

## Testing Storage

### Manual Testing via Supabase Studio

1. Navigate to http://localhost:8000 (local) or your project dashboard
2. Go to Storage section
3. Select a bucket (`public-assets` or `user-files`)
4. Upload test files
5. Verify RLS policies work as expected

### Testing with curl

```bash
# Get your JWT token (from browser dev tools or auth flow)
TOKEN="your-jwt-token"

# Upload file
curl -X POST \
  'http://localhost:8000/storage/v1/object/public-assets/{user_id}/test.jpg' \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: image/jpeg" \
  --data-binary @test.jpg

# Download file
curl -X GET \
  'http://localhost:8000/storage/v1/object/user-files/{user_id}/test.pdf' \
  -H "Authorization: Bearer $TOKEN" \
  -o downloaded.pdf

# List files
curl -X GET \
  'http://localhost:8000/storage/v1/object/list/user-files/{user_id}' \
  -H "Authorization: Bearer $TOKEN"

# Delete file
curl -X DELETE \
  'http://localhost:8000/storage/v1/object/user-files/{user_id}/test.pdf' \
  -H "Authorization: Bearer $TOKEN"
```

### Automated Tests

Create test files in `supabase/functions/` or use a testing framework:

```typescript
// Example test for storage operations
describe('Storage Operations', () => {
  it('should upload file to user folder', async () => {
    const file = new File(['test'], 'test.txt', { type: 'text/plain' })
    const { error } = await supabase.storage
      .from('user-files')
      .upload(`${userId}/test.txt`, file)
    
    expect(error).toBeNull()
  })
  
  it('should prevent upload to another user folder', async () => {
    const file = new File(['test'], 'test.txt', { type: 'text/plain' })
    const { error } = await supabase.storage
      .from('user-files')
      .upload(`${otherUserId}/test.txt`, file)
    
    expect(error).not.toBeNull()
    expect(error?.message).toContain('policy')
  })
})
```

---

## Troubleshooting

### Common Issues

#### 1. "Policy violation" Error

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

#### 2. "File size exceeds limit"

**Cause**: File is larger than bucket limit
**Solution**: 
- Check bucket limits (5MB for public-assets, 50MB for user-files)
- Compress files before upload
- Consider chunked uploads for large files

#### 3. "Invalid MIME type"

**Cause**: File type not allowed in bucket
**Solution**:
- Check allowed MIME types in migration file
- Convert file to supported format
- Request additional MIME types be added to bucket config

#### 4. "Unable to get public URL for private bucket"

**Cause**: Trying to get public URL from private bucket
**Solution**: Use signed URLs for private files

```typescript
// For private files, use signed URLs
const { data, error } = await supabase.storage
  .from('user-files')
  .createSignedUrl(`${userId}/file.pdf`, 3600) // Expires in 1 hour

if (data) {
  console.log('Signed URL:', data.signedUrl)
}
```

#### 5. Files Not Appearing in List

**Cause**: Incorrect folder path or RLS policy issue
**Solution**:
- Ensure path doesn't start with `/`
- Check folder name matches exactly
- Verify user is authenticated

```typescript
// ❌ Wrong
await supabase.storage.from('user-files').list('/user-id/documents')

// ✅ Correct
await supabase.storage.from('user-files').list('user-id/documents')
```

### Debug Checklist

- [ ] User is authenticated (check `supabase.auth.getUser()`)
- [ ] File path format is correct (`{user_id}/...`)
- [ ] File size is within bucket limits
- [ ] MIME type is allowed for the bucket
- [ ] RLS policies are enabled on `storage.objects`
- [ ] Bucket exists and is properly configured

### Getting Help

1. Check Supabase Storage logs in Dashboard
2. Review RLS policies in Database → Policies → storage.objects
3. Test with a simple file first (small text file)
4. Verify bucket configuration in Storage settings
5. Check browser console for detailed error messages

---

## Resources

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Storage RLS Policies](https://supabase.com/docs/guides/storage/security/access-control)
- [Storage Client Library](https://supabase.com/docs/reference/javascript/storage-from-upload)
- [File Upload Best Practices](https://supabase.com/docs/guides/storage/uploads/file-limits)

---

## Migration Information

Storage buckets are created via migration file:
- **File**: `supabase/migrations/20251005052959_setup_storage_buckets.sql`
- **Applied**: Automatically on `supabase db reset` or `supabase db push`

To modify bucket configuration:
1. Edit the migration file
2. Run `supabase db reset` locally
3. Test thoroughly
4. Deploy changes with `supabase db push` (production)
