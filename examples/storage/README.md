# Storage Examples

Examples demonstrating Supabase Storage usage with the configured buckets.

## Available Examples

1. **avatar-upload.js** - Upload and manage user avatars
2. **file-upload.js** - Upload private documents to user-files bucket
3. **public-assets.js** - Upload and manage public assets
4. **list-files.js** - List and organize user files
5. **file-operations.html** - Browser-based file upload demo

## Setup

```bash
# Install dependencies
npm install

# Set environment variables
cp .env.example .env
# Edit .env with your Supabase credentials
```

## Running Examples

### Node.js Examples

```bash
# Upload avatar
node avatar-upload.js

# Upload private file
node file-upload.js

# Upload public asset
node public-assets.js

# List user files
node list-files.js
```

### Browser Example

```bash
# Open in browser
open file-operations.html
```

## Environment Variables

Create a `.env` file in this directory:

```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key-here
```

For local development:
- URL: `http://localhost:54321`
- Anon key: Get from `supabase status` or Studio

## Bucket Configuration

The examples use these buckets:

- **avatars** - Public, 5MB limit, images only
- **public-assets** - Public, 10MB limit, multiple file types
- **user-files** - Private, 50MB limit, documents and archives

See `../../docs/STORAGE.md` for complete documentation.

## Common Patterns

### Upload Avatar

```javascript
const filePath = `${userId}/avatar.jpg`;
await supabase.storage.from('avatars').upload(filePath, file, { upsert: true });
```

### Upload Private Document

```javascript
const filePath = `${userId}/${Date.now()}_${file.name}`;
await supabase.storage.from('user-files').upload(filePath, file);
```

### List User Files

```javascript
const { data } = await supabase.storage.from('user-files').list(userId);
```

### Delete File

```javascript
await supabase.storage.from('user-files').remove([filePath]);
```

## Testing

Test file uploads with different:
- File sizes (within and exceeding limits)
- MIME types (allowed and disallowed)
- User contexts (owner vs. other users)
- Public vs. private access

## Troubleshooting

See `../../docs/STORAGE.md` for common issues and solutions.
