---
title: Edge Functions Architecture
type: note
permalink: concepts/edge-functions-architecture
tags:
- edge-functions
- deno
- serverless
- typescript
---

# Edge Functions Architecture

## Overview

Serverless compute platform using Deno runtime for custom business logic deployed globally at the edge.

## Core Technology

- [technology] Deno 2.x runtime with TypeScript/JavaScript support
- [technology] Secure by default with explicit permissions
- [technology] Web standard APIs (fetch, Request, Response)
- [technology] Built-in tooling (test, lint, format)
- [technology] Import from URLs and npm packages

## Function Structure

- [structure] Entry point in `index.ts` exports default handler
- [structure] Tests in `test.ts` using Deno.test()
- [structure] Shared utilities in `_shared/` directory
- [structure] Environment variables via `Deno.env.get()`
- [structure] CORS configuration in function code

## Current Functions

- [function] **hello-world** - Example function demonstrating basics
- [function] **openai-chat** - Direct OpenAI API integration
- [function] **openrouter-chat** - Multi-model AI access via OpenRouter

## Request Lifecycle

- [flow] HTTP request arrives at edge function endpoint
- [flow] JWT token validated if authentication required
- [flow] Handler function processes request
- [flow] Response returned with appropriate status code
- [flow] Auto-scaling based on demand

## Development Workflow

- [workflow] Create: `npm run functions:new <name>`
- [workflow] Develop: Edit `supabase/functions/<name>/index.ts`
- [workflow] Test locally: `npm run functions:serve`
- [workflow] Write tests: Create `test.ts` with Deno.test()
- [workflow] Deploy: `supabase functions deploy <name>`

## Environment Configuration

- [config] Secrets set in Supabase Dashboard → Edge Functions
- [config] Access via `Deno.env.get('VARIABLE_NAME')`
- [config] Never commit secrets to git
- [config] Different secrets per environment (local vs production)

## Performance Characteristics

- [performance] Fast cold starts compared to other runtimes
- [performance] Global distribution at edge locations
- [performance] Auto-scaling with zero configuration
- [performance] Efficient memory usage

## Security Features

- [security] Sandboxed execution environment
- [security] Explicit permission model
- [security] No file system access by default
- [security] Network requests require permission
- [security] JWT validation built-in

## Integration Points

- [integration] Access Supabase client with service role
- [integration] Query database directly
- [integration] Upload to storage buckets
- [integration] Send notifications
- [integration] Call external APIs (OpenAI, etc.)

## Best Practices

- [best-practice] Keep functions focused and single-purpose
- [best-practice] Use shared utilities for common logic
- [best-practice] Implement proper error handling
- [best-practice] Add CORS headers for browser access
- [best-practice] Test functions thoroughly before deploy
- [best-practice] Monitor function logs and metrics

## Relations

- part_of [[Project Architecture]]
- part_of [[Supabase Project Overview]]
- uses [[Deno Runtime]]
- integrates_with [[OpenAI]]
- integrates_with [[OpenRouter]]
- integrates_with [[PostgreSQL Database]]
- documented_in [[Edge Functions README]]
- tested_in [[CI/CD Pipeline]]
