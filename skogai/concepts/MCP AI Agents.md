---
title: MCP AI Agents
type: note
permalink: concepts/mcp-ai-agents
tags:
- mcp
- ai-agents
- model-context-protocol
- connections
---

# MCP AI Agents

## Overview

Model Context Protocol (MCP) infrastructure enabling AI agents to connect to and interact with the Supabase PostgreSQL database.

## Supported Agent Types

- [agent-type] **Persistent Agents** - Long-running AI assistants with direct connections
- [agent-type] **Serverless Agents** - AWS Lambda, Google Cloud Functions with transaction pooling
- [agent-type] **Edge Agents** - Cloudflare Workers, Vercel Edge with optimized latency
- [agent-type] **High-Performance Agents** - Dedicated poolers for intensive workloads

## Connection Methods

- [connection] **Direct IPv6** - Port 5432, persistent agents, full PostgreSQL features
- [connection] **Supavisor Session** - Port 5432, IPv4 persistent agents, connection persistence
- [connection] **Supavisor Transaction** - Port 6543, serverless/edge agents, auto cleanup
- [connection] **Dedicated Pooler** - Custom port, maximum throughput, isolated resources

## Architecture Principles

- [principle] Connection pooling for efficient resource usage
- [principle] Automatic connection cleanup for serverless
- [principle] Session persistence for stateful agents
- [principle] Security through RLS and authentication
- [principle] Monitoring and health checks

## Security Model

- [security] JWT token authentication
- [security] Service role for backend operations
- [security] RLS policies enforced on queries
- [security] SSL/TLS encryption required
- [security] Connection string security best practices

## Use Cases

- [use-case] AI assistants querying user data
- [use-case] Automated data analysis and reporting
- [use-case] Chatbots with database context
- [use-case] AI-powered content generation
- [use-case] Intelligent data processing pipelines

## Connection Pooling

- [pooling] Supavisor for connection management
- [pooling] Session mode for persistent connections
- [pooling] Transaction mode for short-lived queries
- [pooling] Pool size optimization per agent type
- [pooling] Connection lifecycle management

## Performance Considerations

- [performance] Direct IPv6 for lowest latency
- [performance] Transaction pooling for serverless efficiency
- [performance] Read replicas for high-traffic scenarios
- [performance] Query optimization for AI workloads
- [performance] Connection reuse patterns

## Monitoring

- [monitoring] Connection metrics and health checks
- [monitoring] Query performance tracking
- [monitoring] Error rate monitoring
- [monitoring] Pool saturation alerts
- [monitoring] Agent activity logging

## Code Examples

- [example] Node.js persistent agent with connection pool
- [example] Python async agent with asyncpg
- [example] Deno edge function integration
- [example] Serverless function with transaction mode

## Best Practices

- [best-practice] Use appropriate connection mode per agent type
- [best-practice] Implement proper error handling
- [best-practice] Close connections when done
- [best-practice] Monitor connection pool usage
- [best-practice] Use service role for backend agents
- [best-practice] Implement retry logic for transient failures

## Documentation Structure

- [doc-area] Architecture and design patterns
- [doc-area] Connection configuration templates
- [doc-area] Authentication strategies
- [doc-area] Pool optimization guides
- [doc-area] Monitoring and troubleshooting
- [doc-area] Code examples per language/platform

## Relations

- part_of [[Project Architecture]]
- part_of [[Supabase Project Overview]]
- uses [[PostgreSQL Database]]
- uses [[Authentication System]]
- implements [[Connection Pooling]]
- documented_in [[MCP_SERVER_ARCHITECTURE.md]]
- documented_in [[MCP_CONNECTION_POOLING.md]]
- documented_in [[MCP_AUTHENTICATION.md]]
- documented_in [[MCP_CONNECTION_EXAMPLES.md]]
- documented_in [[MCP_SESSION_MODE_SETUP.md]]
- documented_in [[MCP_TROUBLESHOOTING.md]]
