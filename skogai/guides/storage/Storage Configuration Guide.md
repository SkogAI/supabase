---
<<<<<<< HEAD
title: Storage Configuration Complete Guide
=======
title: Storage Configuration Guide
>>>>>>> heutonasueno
type: note
permalink: guides/storage/storage-configuration-guide
tags:
- storage
- files
- buckets
- uploads
- security
<<<<<<< HEAD
- rls
- testing
- consolidated
---

# Storage Configuration Complete Guide

Comprehensive guide for Supabase Storage buckets with access control, file organization, security best practices, and complete implementation details.

## Implementation Summary

[summary] Three storage buckets configured for different use cases with RLS policies #storage #overview
[implementation] Migration 20251006095457_configure_storage_buckets.sql created storage configuration #migration #database
[testing] Comprehensive test suite at tests/storage_test_suite.sql validates all functionality #testing #validation
[documentation] Complete implementation with 12 RLS policies across three buckets #security #comprehensive
=======
---

# Storage Configuration Guide

Complete guide for Supabase Storage buckets with access control, file organization, and best practices.
>>>>>>> heutonasueno

## Bucket Overview

[bucket] avatars bucket for profile pictures - public, 5MB limit, images only #storage #public
[bucket] public-assets bucket for general public files - public, 10MB limit, images/PDFs #storage #public
[bucket] user-files bucket for private documents - private, 50MB limit, multiple formats #storage #private

## Avatars Bucket Configuration

[purpose] Profile pictures accessible by anyone #usecase #images
[visibility] Public - anyone can view without authentication #access #public
[limit] 5MB maximum file size enforced at bucket level #constraint #size
[mimetype] image/jpeg and image/jpg allowed #filetype #images
[mimetype] image/png allowed #filetype #images
[mimetype] image/gif allowed #filetype #images
[mimetype] image/webp allowed #filetype #images
[access] Anyone can view avatars publicly #permission #read
[access] Authenticated users can upload their own avatar #permission #write
[access] Users can update/delete their own avatar only #permission #modify
[restriction] Users cannot access other users' avatars for upload/update/delete #security #isolation

## Public Assets Bucket Configuration

[purpose] General public files like logos, images, public documents #usecase #assets
[visibility] Public - anyone can view without authentication #access #public
[limit] 10MB maximum file size enforced at bucket level #constraint #size
[mimetype] Images: image/jpeg, image/png, image/gif, image/webp, image/svg+xml #filetype #images
[mimetype] Documents: application/pdf, text/plain, text/csv #filetype #documents
[access] Anyone can view public assets #permission #read
[access] Authenticated users can upload files #permission #write
[access] Users can update/delete their own files #permission #modify
[restriction] Users cannot modify other users' files #security #isolation

## User Files Bucket Configuration

[purpose] Private user documents and uploads #usecase #documents
[visibility] Private - only file owner can access #access #private
[limit] 50MB maximum file size enforced at bucket level #constraint #size
[mimetype] Images: image/jpeg, image/png, image/gif, image/webp #filetype #images
[mimetype] Word: application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document #filetype #documents
[mimetype] Excel: application/vnd.ms-excel, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet #filetype #spreadsheets
[mimetype] Other: application/pdf, text/plain, text/csv, application/zip #filetype #various
[access] Users can view their own files only #permission #read
[access] Users can upload files to their own folder #permission #write
[access] Users can update/delete their own files #permission #modify
[restriction] Users cannot access other users' files #security #isolation

## Access Policy Architecture

[security] All buckets use Row Level Security for access control #rls #enforcement
[criterion] Policies check bucket ID to identify which bucket #policy #identification
[criterion] Policies check user ID from auth.uid() for ownership #policy #authentication
[criterion] Policies check folder structure with user ID: `{bucket}/{user_id}/{filename}` #policy #organization
[function] `storage.foldername(name)[1]` extracts user ID from file path #helper #parsing
[comparison] Extracted user ID compared with `auth.uid()` for verification #security #validation

## File Organization Best Practices

[structure] Avatars: `{user_id}/avatar.{ext}` for current avatar #pattern #naming
[structure] Avatars: `{user_id}/avatar_thumbnail.{ext}` for optional thumbnail #pattern #naming
[structure] Public assets: `{user_id}/logo.png` for organized files #pattern #naming
[structure] User files: `{user_id}/{timestamp}_document.pdf` for uniqueness #pattern #naming
[structure] User files: `{user_id}/projects/{project_id}/{filename}` for organization #pattern #hierarchy
[convention] Use descriptive names like `avatar.jpg`, not `IMG_1234.jpg` #naming #clarity
[convention] Use timestamps like `1698765432_report.pdf` for uniqueness #naming #timestamp
[convention] Use versions like `project_spec_v2.pdf` for clarity #naming #versioning
[antipattern] Avoid spaces in filenames like `my document.pdf` #naming #compatibility
[antipattern] Avoid generic names like `file.pdf` or `document.pdf` #naming #clarity

## JavaScript Client Usage - Upload Avatar

[library] Import createClient from @supabase/supabase-js #client #import
[pattern] Extract file extension from file.name.split('.').pop() #javascript #parsing
[pattern] Build file path as `${userId}/avatar.${fileExt}` #javascript #path
[method] Use storage.from('avatars').upload(path, file, options) #api #upload
[option] Set cacheControl to '3600' for browser caching #performance #caching
[option] Set upsert to true to replace existing avatar #behavior #replace
[errorhandling] Check error object and return null on failure #javascript #validation
[method] Use storage.from('avatars').getPublicUrl(path) to get URL #api #url
[return] Return publicUrl string for display in UI #javascript #output

## JavaScript Client Usage - Upload Private Document

[pattern] Build unique file path with timestamp and original name #javascript #naming
[pattern] Use `${userId}/${timestamp}_${file.name}` for uniqueness #javascript #path
[method] Use storage.from('user-files').upload(filePath, file) #api #upload
[errorhandling] Check error and log message on failure #javascript #debugging
[return] Return filePath string for database storage #javascript #reference

## JavaScript Client Usage - Download Private File

[method] Use storage.from('user-files').download(filePath) #api #download
[errorhandling] Check error and return null on failure #javascript #validation
[pattern] Create blob URL with URL.createObjectURL(data) #javascript #blob
[return] Return blob URL for viewing or downloading #javascript #output

## JavaScript Client Usage - List User Files

[method] Use storage.from('user-files').list(userId, options) #api #list
[option] Set limit for pagination (default 100) #pagination #limit
[option] Set offset for pagination #pagination #offset
[option] Set sortBy with column and order for sorting #sorting #options
[errorhandling] Check error and return empty array on failure #javascript #fallback
[return] Return array of file metadata objects #javascript #output

## JavaScript Client Usage - Delete File

[method] Use storage.from(bucket).remove([filePath]) #api #delete
[parameter] Pass array of file paths even for single file #api #format
[errorhandling] Check error and return false on failure #javascript #validation
[return] Return boolean indicating success #javascript #status

## JavaScript Client Usage - Upload Public Asset

[pattern] Build file path as `${userId}/${file.name}` #javascript #path
[method] Use storage.from('public-assets').upload(filePath, file) #api #upload
[method] Use storage.from('public-assets').getPublicUrl(filePath) #api #url
[note] Public URL requires no authentication to access #access #public
[return] Return publicUrl string for sharing #javascript #output

## Security Best Practices - User-Scoped Paths

[bestpractice] Always use user ID in path: `${userId}/document.pdf` #security #required
[bestpractice] Never omit user ID from path #security #isolation
[antipattern] Don't use paths without user ID like `document.pdf` #security #violation
[antipattern] Don't use hardcoded or different user IDs in path #security #violation

## Security Best Practices - Client-Side Validation

[validation] Define allowed file types array for checking #security #whitelist
[validation] Check file.type against allowed types array #security #validation
[validation] Check file.size against maximum size limit #security #constraint
[error] Throw descriptive error for invalid file type #errorhandling #usability
[error] Throw descriptive error for file too large #errorhandling #usability
[example] Image validation: max 5MB, types: jpeg, png, gif, webp #validation #images

## Security Best Practices - Error Handling

[pattern] Use try-catch blocks for upload operations #errorhandling #reliability
[pattern] Handle specific error types (size, mime) differently #errorhandling #specificity
[pattern] Show user-friendly error messages to users #ux #communication
[pattern] Log detailed errors for debugging #debugging #logging
[example] Size error: "File size exceeds limit" #error #message
[example] MIME error: "File type not allowed" #error #message
[example] Generic error: "Failed to upload file. Please try again." #error #message

## Security Best Practices - File Cleanup

[maintenance] Clean up old files periodically to save storage #optimization #cleanup
[pattern] Calculate cutoff date based on days old threshold #logic #calculation
[method] Use storage.list() to get all user files #api #query
[filter] Filter files by created_at date before cutoff #logic #filtering
[method] Use storage.remove() with array of old file paths #api #deletion
[return] Return count of deleted files for reporting #tracking #metrics

## Security Best Practices - Signed URLs

[feature] Create temporary download links with expiration #security #temporary
[method] Use storage.createSignedUrl(path, expiresIn) #api #signature
[parameter] expiresIn in seconds (default 3600 = 1 hour) #configuration #timeout
[errorhandling] Check error and return null on failure #javascript #validation
[return] Return signedUrl string with embedded token #security #access

## Testing Storage

[command] Run storage tests with `supabase db execute --file tests/storage_test_suite.sql` #testing #automation
[alternative] Copy SQL to Supabase Studio SQL Editor for manual testing #testing #manual
[checklist] Upload file to each bucket #testing #basic
[checklist] Verify file size limits are enforced #testing #constraint
[checklist] Verify MIME type restrictions work #testing #validation
[checklist] Test access control - can't access other users' files #testing #security
[checklist] Test public bucket access without authentication #testing #public
[checklist] Test private bucket access requires authentication #testing #private
[checklist] Test file deletion works correctly #testing #functionality
[checklist] Test file updates work correctly #testing #functionality
[checklist] Verify folder organization structure #testing #organization

## Troubleshooting - RLS Policy Violation

[error] "new row violates row-level security policy" #troubleshooting #rls
[cause] File path doesn't match user ID format #diagnosis #path
[solution] Ensure file path starts with user ID: `${auth.uid()}/file.ext` #fix #pattern
[example] Wrong: `files/document.pdf` #antipattern #path
[example] Correct: `${auth.uid()}/document.pdf` #pattern #path

## Troubleshooting - File Size Exceeded

[error] "File size exceeds limit" #troubleshooting #constraint
[cause] File larger than bucket's maximum size limit #diagnosis #size
[solution] Compress file or use different bucket #fix #alternative
[validation] Check file.size before upload against limit #prevention #validation
[example] Avatars: max 5MB, Public: max 10MB, User files: max 50MB #limits #reference

## Troubleshooting - Invalid MIME Type

[error] "Invalid mime type" #troubleshooting #validation
[cause] File type not in bucket's allowed list #diagnosis #mimetype
[solution] Convert file or use appropriate bucket #fix #alternative
[validation] Check file.type against allowed types before upload #prevention #validation
[example] Avatars: only image types allowed #constraint #images

## Troubleshooting - Can't Access Public Files

[error] Cannot access files in public bucket #troubleshooting #access
[cause] Using wrong method or incorrect path #diagnosis #api
[solution] Use getPublicUrl() for public buckets #fix #method
[method] storage.from('avatars').getPublicUrl(filePath) returns URL #api #public
[usage] Use publicUrl directly in HTML or fetch #application #integration

## Troubleshooting - Can't Download Private Files

[error] Cannot download files from private bucket #troubleshooting #access
[cause] Missing authentication or using wrong method #diagnosis #security
[solution] Use download() with authenticated client #fix #method
[requirement] Must be authenticated with valid session #security #authentication
[method] storage.from('user-files').download(filePath) returns blob #api #private

## Debugging Storage

[query] View bucket settings: `SELECT id, name, public, file_size_limit, allowed_mime_types FROM storage.buckets` #sql #inspection
<<<<<<< HEAD
[query] View storage policies: `SELECT schemaname, tablename, policyname, cmd, qual FROM pg_policies WHERE schemaname = 'storage'` #sql #inspection
[query] View all storage objects: `SELECT * FROM storage.objects WHERE bucket_id = 'user-files'` #sql #data
[test] Test policy as specific user: `SET request.jwt.claims.sub = 'user-uuid-here'` #sql #simulation
[verification] Check helper function exists: `SELECT proname FROM pg_proc WHERE proname = 'foldername'` #sql #functions

## Testing Storage - User Isolation Testing

[test] Upload file as User A to user-files bucket #testing #setup
[test] Attempt to access User A's file as User B (should fail with RLS error) #testing #security
[verification] Verify error is returned indicating policy violation #testing #validation
[pattern] Use different authenticated sessions for multi-user testing #testing #methodology

## Testing Storage - Studio Verification

[procedure] Open Supabase Studio at http://localhost:8000 #testing #ui
[procedure] Navigate to Storage section #testing #navigation
[verify] Check avatars bucket exists and is public #testing #configuration
[verify] Check public-assets bucket exists and is public #testing #configuration
[verify] Check user-files bucket exists and is private #testing #configuration
[manual] Try uploading different file types and sizes via Studio UI #testing #interactive

## Implementation Details

[migration] 20251006095457_configure_storage_buckets.sql created initial storage configuration #history #database
[migration] Migration is 230+ lines with full comments and idempotent design #implementation #quality
[migration] Uses ON CONFLICT for idempotency to allow re-running safely #pattern #reliability
[policies] 12 RLS policies total: 4 per bucket covering SELECT, INSERT, UPDATE, DELETE #security #comprehensive
[policies] Each bucket has policies for: Avatars (4), Public Assets (4), User Files (4) #security #organization
[testing] Test suite is 280+ lines with 6 comprehensive test categories #testing #coverage
[documentation] Implementation includes migration, tests, and complete usage guide #documentation #thorough

## RLS Policy Details

[policy-avatars] "Avatars are publicly accessible" - SELECT policy for public viewing #rls #read
[policy-avatars] "Users can upload their own avatar" - INSERT with user check #rls #write
[policy-avatars] "Users can update their own avatar" - UPDATE with user check #rls #modify
[policy-avatars] "Users can delete their own avatar" - DELETE with user check #rls #delete
[policy-public] "Public assets are viewable by everyone" - SELECT policy for public viewing #rls #read
[policy-public] "Authenticated users can upload public assets" - INSERT for authenticated users #rls #write
[policy-public] "Users can update their own public assets" - UPDATE with user check #rls #modify
[policy-public] "Users can delete their own public assets" - DELETE with user check #rls #delete
[policy-private] "Users can view their own files" - SELECT with user check #rls #read
[policy-private] "Users can upload their own files" - INSERT with user check #rls #write
[policy-private] "Users can update their own files" - UPDATE with user check #rls #modify
[policy-private] "Users can delete their own files" - DELETE with user check #rls #delete

## Production Readiness Checklist

[checklist] All tests pass successfully #production #validation
[checklist] Manual testing completed with real uploads #production #verification
[checklist] Security testing verified with multi-user scenarios #production #security
[checklist] File organization strategy defined and documented #production #planning
[checklist] Backup strategy in place for production data #production #backup
[checklist] Monitoring configured for storage usage metrics #production #observability
[checklist] Team trained on storage patterns and best practices #production #training
[checklist] Documentation reviewed and up-to-date #production #documentation

## Optional Enhancements

[enhancement] Add image transformation policies for automatic resizing #future #optimization
[enhancement] Implement automatic file cleanup for old files #future #maintenance
[enhancement] Add virus scanning for uploaded files #future #security
[enhancement] Create helper functions for common operations #future #usability
[enhancement] Add storage usage tracking per user #future #metrics
[enhancement] Implement file versioning for user documents #future #feature
[enhancement] Add metadata extraction for uploaded files #future #feature
[enhancement] Consider CDN integration for public buckets #future #performance

## Key Takeaways

[summary] Three buckets provide public, semi-public, and private storage patterns #architecture #organization
[summary] Size limits appropriate for each use case: 5MB, 10MB, 50MB #configuration #practical
[summary] MIME type restrictions enforce appropriate file types per bucket #security #validation
[summary] 12 RLS policies provide secure, user-scoped access control #security #comprehensive
[summary] Comprehensive test suite validates all functionality #testing #quality
[summary] Complete documentation with examples and best practices #documentation #thorough
[summary] Production-ready with idempotent migration and secure policies #deployment #ready

## Source Files Consolidated

[source] STORAGE.md - 595 lines with complete usage guide and examples #consolidation #origin
[source] STORAGE_IMPLEMENTATION_SUMMARY.md - 280 lines with implementation details #consolidation #origin
[source] STORAGE_CHECKLIST.md - 272 lines with testing procedures #consolidation #origin
[consolidated] All three source files merged into this comprehensive guide #consolidation #complete
[date] Consolidation completed as part of Issue #182 documentation organization #consolidation #tracking
=======
[query] View storage policies: `SELECT * FROM pg_policies WHERE schemaname = 'storage'` #sql #inspection
[test] Test policy as specific user: `SET request.jwt.claims.sub = 'user-uuid'` #sql #simulation
[test] Query files: `SELECT * FROM storage.objects WHERE bucket_id = 'user-files'` #sql #data

## Migration History

[migration] 20251006095457_configure_storage_buckets.sql created initial storage configuration #history #database
[migration] Initial migration included three buckets with complete RLS policies #history #feature
>>>>>>> heutonasueno

## Related Documentation

- [[Storage Architecture]] - Core storage concepts
- [[RLS Policy Guide]] - Row Level Security patterns
- [[Contributing Guide]] - Development guidelines
- [[Development Workflows]] - Workflow procedures
- [[Authentication System]] - User authentication
<<<<<<< HEAD
- [[Migration 20251006095457]] - Storage configuration migration
- [[Storage Test Suite]] - Automated testing
=======
>>>>>>> heutonasueno
