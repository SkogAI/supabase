---
title: PostgreSQL Database
type: note
permalink: concepts/postgre-sql-database
tags:
- database
- postgresql
- schema
- migrations
---

# PostgreSQL Database

## Overview

PostgreSQL 17 database serving as the primary data store with advanced features, migrations, and Row Level Security.

## Core Features

- [feature] Full SQL support with ACID transactions
- [feature] Advanced data types (JSON, Arrays, UUID, etc.)
- [feature] Full-text search capabilities
- [feature] Custom functions and triggers
- [feature] Extensions (pgvector for embeddings)
- [feature] Automatic timestamp management

## Schema Organization

- [schema] **public** - Main application data (profiles, posts)
- [schema] **auth** - User authentication (managed by Supabase)
- [schema] **storage** - File metadata (managed by Supabase)
- [schema] **graphql_public** - GraphQL API exposure
- [schema] Custom schemas can be added via config.toml

## Current Tables

- [table] **profiles** - User profiles with RLS policies
- [table] **posts** - User-generated content with publish/draft states
- [table] Additional tables defined in migrations

## Migration System

- [migration] File format: `YYYYMMDDHHMMSS_description.sql`
- [migration] Version-controlled schema changes
- [migration] Applied sequentially in timestamp order
- [migration] Rollback support via down migrations
- [migration] Tested locally before production deploy

## Migration Workflow

- [workflow] Create: `npm run migration:new <name>`
- [workflow] Edit generated SQL file
- [workflow] Test locally: `npm run db:reset`
- [workflow] Commit to git
- [workflow] Deploy: Auto-applied on merge to main

## Indexing Strategy

- [index] Foreign keys automatically indexed
- [index] Frequently queried columns indexed
- [index] Columns in WHERE clauses indexed
- [index] Partial indexes for filtered queries
- [index] Compound indexes for multi-column queries

## Trigger Patterns

- [trigger] Auto-update `updated_at` timestamp
- [trigger] Auto-create profile on user signup
- [trigger] Validate data before insert/update
- [trigger] Maintain computed columns
- [trigger] Audit trail logging

## Performance Optimization

- [optimization] Connection pooling via Supavisor
- [optimization] Query optimization with EXPLAIN ANALYZE
- [optimization] Strategic index placement
- [optimization] Materialized views for complex queries
- [optimization] Partitioning for large tables (when needed)

## Backup Strategy

- [backup] Automated daily backups via CI/CD
- [backup] Point-in-time recovery available
- [backup] Migration history in git
- [backup] Seed data for development environments

## Development Tools

- [tool] Supabase Studio for visual management
- [tool] psql for command-line access
- [tool] pg_dump for backups
- [tool] sqlfluff for SQL linting
- [tool] TypeScript type generation

## Connection Information

- [connection] Local: `postgresql://postgres:postgres@localhost:54322/postgres`
- [connection] Production: via Supabase Dashboard connection string
- [connection] Pooler: Available for serverless/edge connections

## Best Practices

- [best-practice] Always use migrations for schema changes
- [best-practice] Test migrations locally before deploy
- [best-practice] Enable RLS on all public tables
- [best-practice] Index foreign keys and query columns
- [best-practice] Use transactions for multi-step operations
- [best-practice] Keep database normalized (3NF)

## Relations

- part_of [[Project Architecture]]
- part_of [[Supabase Project Overview]]
- implements [[Row Level Security]]
- uses [[Migration System]]
- accessed_by [[Edge Functions Architecture]]
- accessed_by [[MCP AI Agents]]
- documented_in [[Database Schema Organization]]
- tested_by [[Migration Test Suite]]
