/**
 * Avatar Upload Example
 * 
 * Demonstrates uploading user avatars to the 'avatars' bucket.
 * - Public bucket (anyone can view)
 * - 5MB size limit
 * - Images only (JPEG, PNG, GIF, WebP)
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { config } from 'dotenv';

// Load environment variables
config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Upload an avatar for a user
 */
async function uploadAvatar(userId, filePath) {
  console.log('📸 Uploading avatar...');
  console.log(`  User: ${userId}`);
  console.log(`  File: ${filePath}`);

  try {
    // Read file
    const file = readFileSync(filePath);
    const fileExt = filePath.split('.').pop();
    const fileName = `avatar.${fileExt}`;
    const storagePath = `${userId}/${fileName}`;

    // Upload file (upsert = true replaces existing avatar)
    const { data, error } = await supabase.storage
      .from('avatars')
      .upload(storagePath, file, {
        cacheControl: '3600',
        upsert: true,
        contentType: `image/${fileExt}`
      });

    if (error) {
      console.error('❌ Upload failed:', error.message);
      return null;
    }

    console.log('✅ Avatar uploaded successfully!');
    console.log(`  Path: ${data.path}`);

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('avatars')
      .getPublicUrl(storagePath);

    console.log(`  Public URL: ${publicUrl}`);

    return publicUrl;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return null;
  }
}

/**
 * Delete an avatar
 */
async function deleteAvatar(userId) {
  console.log('\n🗑️  Deleting avatar...');
  
  try {
    const { data: files } = await supabase.storage
      .from('avatars')
      .list(userId);

    if (!files || files.length === 0) {
      console.log('  No avatar found to delete');
      return;
    }

    const filePaths = files.map(f => `${userId}/${f.name}`);
    
    const { error } = await supabase.storage
      .from('avatars')
      .remove(filePaths);

    if (error) {
      console.error('❌ Delete failed:', error.message);
      return;
    }

    console.log('✅ Avatar deleted successfully!');
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

/**
 * List user's avatars
 */
async function listAvatars(userId) {
  console.log('\n📋 Listing avatars...');
  
  try {
    const { data, error } = await supabase.storage
      .from('avatars')
      .list(userId, {
        limit: 10,
        sortBy: { column: 'created_at', order: 'desc' }
      });

    if (error) {
      console.error('❌ List failed:', error.message);
      return;
    }

    if (!data || data.length === 0) {
      console.log('  No avatars found');
      return;
    }

    console.log(`  Found ${data.length} file(s):`);
    data.forEach(file => {
      console.log(`    - ${file.name} (${formatBytes(file.metadata?.size)})`);
    });
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

/**
 * Format bytes to human-readable size
 */
function formatBytes(bytes) {
  if (!bytes) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

// Example usage
async function main() {
  const userId = process.env.TEST_USER_ID || '00000000-0000-0000-0000-000000000001';
  
  console.log('='.repeat(60));
  console.log('AVATAR UPLOAD EXAMPLE');
  console.log('='.repeat(60));
  
  // Example: Upload an avatar (replace with actual file path)
  // const avatarUrl = await uploadAvatar(userId, './path/to/avatar.jpg');
  
  // List existing avatars
  await listAvatars(userId);
  
  // Example: Delete avatar
  // await deleteAvatar(userId);
  
  console.log('\n' + '='.repeat(60));
  console.log('ℹ️  To upload an avatar, uncomment the upload line and provide a valid image file path');
  console.log('='.repeat(60));
}

main().catch(console.error);
