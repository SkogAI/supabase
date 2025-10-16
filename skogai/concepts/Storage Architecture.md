---
title: Storage Architecture
type: note
permalink: concepts/storage-architecture
tags:
- storage
- files
- buckets
- security
---

# Storage Architecture

## Overview

Supabase Storage provides secure file upload and management with Row Level Security policies and user-scoped organization.

## Bucket Configuration

- [bucket] **avatars** - Public profile pictures, 5MB limit, images only
- [bucket] **public-assets** - General public files, 10MB limit, images/PDFs
- [bucket] **user-files** - Private user documents, 50MB limit, authenticated only

## Path Organization

- [structure] Convention: `{bucket}/{user_id}/filename.ext`
- [structure] User-scoped folders prevent unauthorized access
- [structure] Predictable paths for easy retrieval
- [structure] Supports nested directories within user folder

## Security Model

- [security] Row Level Security policies on storage.objects table
- [security] Public buckets: Anyone can read, authenticated can write own files
- [security] Private buckets: Authenticated users only, own files only
- [security] MIME type validation on upload
- [security] File size limits enforced per bucket

## Access Patterns

- [pattern] Upload: `supabase.storage.from('bucket').upload(path, file)`
- [pattern] Download: `supabase.storage.from('bucket').download(path)`
- [pattern] Public URL: `supabase.storage.from('bucket').getPublicUrl(path)`
- [pattern] Delete: `supabase.storage.from('bucket').remove([path])`
- [pattern] List: `supabase.storage.from('bucket').list(folder)`

## Policy Examples

- [policy] Public read: `FOR SELECT USING (bucket_id = 'avatars')`
- [policy] User upload own: `FOR INSERT WITH CHECK (auth.uid()::text = (storage.foldername(name))[1])`
- [policy] User delete own: `FOR DELETE USING (auth.uid()::text = (storage.foldername(name))[1])`

## File Type Restrictions

- [restriction] avatars bucket: image/jpeg, image/png, image/gif
- [restriction] public-assets: images + application/pdf
- [restriction] user-files: broader range of document types
- [restriction] Validated via MIME type check

## Performance Features

- [performance] CDN integration for fast delivery
- [performance] Automatic image optimization
- [performance] Resumable uploads for large files
- [performance] Parallel uploads supported

## Best Practices

- [best-practice] Always use user ID in path structure
- [best-practice] Validate file types on client before upload
- [best-practice] Handle upload errors gracefully
- [best-practice] Use public URLs for cacheable content
- [best-practice] Clean up unused files periodically
- [best-practice] Test policies with different user roles

## Common Use Cases

- [use-case] User profile pictures in avatars bucket
- [use-case] PDF documents in public-assets
- [use-case] Private user documents in user-files
- [use-case] Application assets served via CDN

## Relations

- part_of [[Project Architecture]]
- part_of [[Supabase Project Overview]]
- uses [[Row Level Security]]
- documented_in [[STORAGE.md]]
- tested_by [[Storage Test Suite]]
- integrates_with [[CDN]]
