/**
 * File Upload Example
 * 
 * Demonstrates uploading private files to the 'user-files' bucket.
 * - Private bucket (only owner can access)
 * - 50MB size limit
 * - Multiple file types supported
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
 * Upload a private file for a user
 */
async function uploadFile(userId, filePath) {
  console.log('📄 Uploading file...');
  console.log(`  User: ${userId}`);
  console.log(`  File: ${filePath}`);

  try {
    // Read file
    const file = readFileSync(filePath);
    const fileName = filePath.split('/').pop();
    const timestamp = Date.now();
    const storagePath = `${userId}/${timestamp}_${fileName}`;

    // Upload file
    const { data, error } = await supabase.storage
      .from('user-files')
      .upload(storagePath, file);

    if (error) {
      console.error('❌ Upload failed:', error.message);
      return null;
    }

    console.log('✅ File uploaded successfully!');
    console.log(`  Path: ${data.path}`);
    console.log(`  Full path: user-files/${data.path}`);

    return data.path;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return null;
  }
}

/**
 * Download a private file
 */
async function downloadFile(filePath) {
  console.log('\n⬇️  Downloading file...');
  console.log(`  Path: ${filePath}`);

  try {
    const { data, error } = await supabase.storage
      .from('user-files')
      .download(filePath);

    if (error) {
      console.error('❌ Download failed:', error.message);
      return null;
    }

    console.log('✅ File downloaded successfully!');
    console.log(`  Size: ${formatBytes(data.size)}`);
    console.log(`  Type: ${data.type}`);

    return data;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return null;
  }
}

/**
 * List user's files
 */
async function listFiles(userId) {
  console.log('\n📋 Listing files...');
  
  try {
    const { data, error } = await supabase.storage
      .from('user-files')
      .list(userId, {
        limit: 100,
        sortBy: { column: 'created_at', order: 'desc' }
      });

    if (error) {
      console.error('❌ List failed:', error.message);
      return;
    }

    if (!data || data.length === 0) {
      console.log('  No files found');
      return;
    }

    console.log(`  Found ${data.length} file(s):`);
    data.forEach((file, index) => {
      const size = file.metadata?.size ? formatBytes(file.metadata.size) : 'Unknown';
      const date = new Date(file.created_at).toLocaleString();
      console.log(`    ${index + 1}. ${file.name}`);
      console.log(`       Size: ${size}, Created: ${date}`);
    });
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

/**
 * Delete a file
 */
async function deleteFile(userId, fileName) {
  console.log('\n🗑️  Deleting file...');
  console.log(`  File: ${fileName}`);
  
  try {
    const filePath = `${userId}/${fileName}`;
    
    const { error } = await supabase.storage
      .from('user-files')
      .remove([filePath]);

    if (error) {
      console.error('❌ Delete failed:', error.message);
      return false;
    }

    console.log('✅ File deleted successfully!');
    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

/**
 * Create a signed URL for temporary access
 */
async function createSignedUrl(filePath, expiresIn = 3600) {
  console.log('\n🔗 Creating signed URL...');
  console.log(`  Path: ${filePath}`);
  console.log(`  Expires in: ${expiresIn} seconds`);

  try {
    const { data, error } = await supabase.storage
      .from('user-files')
      .createSignedUrl(filePath, expiresIn);

    if (error) {
      console.error('❌ Failed to create signed URL:', error.message);
      return null;
    }

    console.log('✅ Signed URL created!');
    console.log(`  URL: ${data.signedUrl}`);
    
    return data.signedUrl;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return null;
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
  console.log('FILE UPLOAD EXAMPLE (Private Bucket)');
  console.log('='.repeat(60));
  
  // Example: Upload a file (replace with actual file path)
  // const filePath = await uploadFile(userId, './path/to/document.pdf');
  
  // List existing files
  await listFiles(userId);
  
  // Example: Download a file
  // await downloadFile(`${userId}/filename.pdf`);
  
  // Example: Create signed URL
  // await createSignedUrl(`${userId}/filename.pdf`, 3600);
  
  // Example: Delete a file
  // await deleteFile(userId, 'filename.pdf');
  
  console.log('\n' + '='.repeat(60));
  console.log('ℹ️  To upload a file, uncomment the upload line and provide a valid file path');
  console.log('='.repeat(60));
}

main().catch(console.error);
