/**
 * Public Assets Upload Example
 * 
 * Demonstrates uploading public files to the 'public-assets' bucket.
 * - Public bucket (anyone can view)
 * - 10MB size limit
 * - Images, PDFs, text files supported
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
 * Upload a public asset
 */
async function uploadPublicAsset(userId, filePath) {
  console.log('🌐 Uploading public asset...');
  console.log(`  User: ${userId}`);
  console.log(`  File: ${filePath}`);

  try {
    // Read file
    const file = readFileSync(filePath);
    const fileName = filePath.split('/').pop();
    const storagePath = `${userId}/${fileName}`;

    // Upload file
    const { data, error } = await supabase.storage
      .from('public-assets')
      .upload(storagePath, file, {
        cacheControl: '3600'
      });

    if (error) {
      console.error('❌ Upload failed:', error.message);
      return null;
    }

    console.log('✅ Asset uploaded successfully!');
    console.log(`  Path: ${data.path}`);

    // Get public URL (no authentication required)
    const { data: { publicUrl } } = supabase.storage
      .from('public-assets')
      .getPublicUrl(storagePath);

    console.log(`  Public URL: ${publicUrl}`);
    console.log('  ℹ️  Anyone can access this URL without authentication');

    return publicUrl;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return null;
  }
}

/**
 * List public assets for a user
 */
async function listPublicAssets(userId) {
  console.log('\n📋 Listing public assets...');
  
  try {
    const { data, error } = await supabase.storage
      .from('public-assets')
      .list(userId, {
        limit: 100,
        sortBy: { column: 'created_at', order: 'desc' }
      });

    if (error) {
      console.error('❌ List failed:', error.message);
      return;
    }

    if (!data || data.length === 0) {
      console.log('  No assets found');
      return;
    }

    console.log(`  Found ${data.length} asset(s):`);
    data.forEach((file, index) => {
      const size = file.metadata?.size ? formatBytes(file.metadata.size) : 'Unknown';
      const date = new Date(file.created_at).toLocaleString();
      console.log(`    ${index + 1}. ${file.name}`);
      console.log(`       Size: ${size}, Created: ${date}`);
      
      // Show public URL
      const { data: { publicUrl } } = supabase.storage
        .from('public-assets')
        .getPublicUrl(`${userId}/${file.name}`);
      console.log(`       URL: ${publicUrl}`);
    });
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

/**
 * Delete a public asset
 */
async function deletePublicAsset(userId, fileName) {
  console.log('\n🗑️  Deleting public asset...');
  console.log(`  File: ${fileName}`);
  
  try {
    const filePath = `${userId}/${fileName}`;
    
    const { error } = await supabase.storage
      .from('public-assets')
      .remove([filePath]);

    if (error) {
      console.error('❌ Delete failed:', error.message);
      return false;
    }

    console.log('✅ Asset deleted successfully!');
    return true;
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

/**
 * Update/replace a public asset
 */
async function updatePublicAsset(userId, fileName, newFilePath) {
  console.log('\n🔄 Updating public asset...');
  console.log(`  Original: ${fileName}`);
  console.log(`  New file: ${newFilePath}`);

  try {
    const file = readFileSync(newFilePath);
    const storagePath = `${userId}/${fileName}`;

    // Upload with upsert to replace existing file
    const { data, error } = await supabase.storage
      .from('public-assets')
      .upload(storagePath, file, {
        cacheControl: '3600',
        upsert: true
      });

    if (error) {
      console.error('❌ Update failed:', error.message);
      return null;
    }

    console.log('✅ Asset updated successfully!');

    const { data: { publicUrl } } = supabase.storage
      .from('public-assets')
      .getPublicUrl(storagePath);

    console.log(`  Public URL: ${publicUrl}`);
    return publicUrl;
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
  console.log('PUBLIC ASSETS UPLOAD EXAMPLE');
  console.log('='.repeat(60));
  
  // Example: Upload a public asset (replace with actual file path)
  // const assetUrl = await uploadPublicAsset(userId, './path/to/image.png');
  
  // List existing assets
  await listPublicAssets(userId);
  
  // Example: Update an asset
  // await updatePublicAsset(userId, 'logo.png', './path/to/new-logo.png');
  
  // Example: Delete an asset
  // await deletePublicAsset(userId, 'logo.png');
  
  console.log('\n' + '='.repeat(60));
  console.log('ℹ️  To upload a public asset, uncomment the upload line and provide a valid file path');
  console.log('='.repeat(60));
}

main().catch(console.error);
