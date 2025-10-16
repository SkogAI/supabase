---
title: Supabase Project Overview
type: note
permalink: project/supabase-project-overview
tags:
- project
- overview
- supabase
- backend
- postgresql
---

# Supabase Project Overview

## Description

Production-ready Supabase backend with PostgreSQL database, Row Level Security (RLS), Edge Functions (Deno), Storage buckets, Realtime subscriptions, and comprehensive CI/CD pipeline.

## Key Features

- [feature] PostgreSQL v17 with 6 working migrations #database
- [feature] 4 Edge Functions using Deno v2 runtime #serverless
- [feature] Row Level Security policies tested and working #security
- [feature] TypeScript type generation pipeline #types
- [feature] Seed data with 3 test users for development #testing
- [feature] Comprehensive CI/CD workflows via GitHub Actions #devops
- [feature] OpenAI and OpenRouter integration examples #ai
- [feature] SAML SSO with ZITADEL support #authentication
- [feature] Storage buckets with RLS policies #storage
- [feature] Realtime subscriptions enabled #realtime

## Technology Stack

- [stack] PostgreSQL 17 as primary database #database
- [stack] Supabase platform for backend services #platform
- [stack] Deno 2.x for Edge Functions runtime #serverless
- [stack] TypeScript 5.3+ for type safety #language
- [stack] Docker for local development #containers
- [stack] GitHub Actions for CI/CD #automation

## Project Structure

- [structure] `supabase/migrations/` - Timestamped SQL migrations
- [structure] `supabase/functions/` - Deno edge functions
- [structure] `supabase/seed.sql` - Test data with fixed user UUIDs
- [structure] `types/database.ts` - Auto-generated TypeScript types
- [structure] `tests/` - RLS and storage test suites
- [structure] `scripts/` - Development automation scripts
- [structure] `.github/workflows/` - CI/CD pipeline definitions

## Development Workflow

- [workflow] Create migrations with timestamped SQL files
- [workflow] Test locally with Docker-based Supabase stack
- [workflow] Generate TypeScript types from schema
- [workflow] Deploy via git push to main branch
- [workflow] Automated testing in CI pipeline

## Relations

- implements [[Row Level Security]]
- implements [[Edge Functions Architecture]]
- implements [[Storage Architecture]]
- implements [[Authentication System]]
- implements [[Realtime Subscriptions]]
- implements [[CI/CD Pipeline]]
- uses [[PostgreSQL Database]]
- uses [[Docker Containers]]
- integrates_with [[OpenAI]]
- integrates_with [[ZITADEL SAML]]
- documented_in [[Project Architecture]]
- documented_in [[Development Workflows]]
- documented_in [[Contributing Guide]]
