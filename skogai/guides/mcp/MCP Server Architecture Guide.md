---
title: MCP Server Architecture Guide
type: note
permalink: guides/mcp/mcp-server-architecture-guide
tags:
- mcp
- architecture
- guide
- ai-agents
- connections
---

# MCP Server Architecture Guide

## Purpose

Complete architectural documentation for Model Context Protocol (MCP) server implementation enabling AI agents to securely connect to Supabase databases.

## Core Architecture Layers

- [layer] **MCP Server Layer** - Intermediary between AI agents and database
- [layer] **Connection Layer** - Multiple connection methods per agent type
- [layer] **Authentication Layer** - Service role, credentials, JWT, API keys
- [layer] **Security Layer** - RLS, network policies, SSL/TLS, rate limiting

## Connection Methods

- [connection-type] **Direct IPv6** - Port 5432, persistent agents, lowest latency
- [connection-type] **Supavisor Session** - Port 5432, IPv4 persistent, connection persistence
- [connection-type] **Supavisor Transaction** - Port 6543, serverless/edge, auto cleanup
- [connection-type] **Dedicated Pooler** - Port 6543, high-performance, isolated resources

## Agent Classifications

- [agent-class] **Persistent Agents** - Long-running, stable environment, dedicated resources
- [agent-class] **Serverless Agents** - Short-lived, cold starts, shared infrastructure  
- [agent-class] **Edge Agents** - Global distribution, minimal latency, resource constraints
- [agent-class] **High-Performance Agents** - Intensive workloads, SLA requirements, many concurrent ops

## Connection String Patterns

- [pattern] Direct IPv6: `postgresql://[user]:[pass]@[ipv6]:5432/[db]`
- [pattern] Supavisor Session: `postgresql://[user].[ref]:[pass]@[pooler]:5432/postgres`
- [pattern] Supavisor Transaction: `postgresql://[user].[ref]:[pass]@[pooler]:6543/postgres`
- [pattern] Dedicated Pooler: `postgresql://[user].[ref]:[pass]@db.[ref].supabase.co:6543/postgres`

## Security Best Practices

- [security] Use environment variables for credentials
- [security] Rotate passwords regularly
- [security] Service role only in trusted environments
- [security] Implement least-privilege access
- [security] Enable SSL/TLS for all connections
- [security] Leverage RLS policies for agent queries
- [security] Implement rate limiting per agent
- [security] Enable audit logging

## Performance Optimization

- [optimization] Connection pooling sized per agent type
- [optimization] Query timeouts prevent resource exhaustion
- [optimization] Prepared statements for repeated queries
- [optimization] Geographic proximity for edge agents
- [optimization] Work memory limits per role

## Monitoring Metrics

- [metric] Active connections and pool saturation
- [metric] Connection wait time and errors
- [metric] Query execution time and failures
- [metric] CPU, memory, network, disk I/O
- [metric] Slow query tracking (>1s)

## Deployment Options

- [deployment] Supabase Edge Functions - serverless MCP endpoints
- [deployment] Containerized service - Docker/Kubernetes
- [deployment] Serverless functions - Lambda, Cloud Functions
- [deployment] Development - docker-compose local stack

## Configuration Management

- [config] Environment-based settings (dev, staging, prod)
- [config] Pool sizes vary by environment and agent type
- [config] SSL requirements differ per environment
- [config] Rate limits more restrictive in production

## Relations

- implements [[MCP AI Agents]]
- part_of [[Project Architecture]]
- documented_in [[MCP_SERVER_ARCHITECTURE.md]]
- relates_to [[MCP Connection Pooling]]
- relates_to [[MCP Authentication]]
- relates_to [[MCP Configuration]]
- uses [[PostgreSQL Database]]
- uses [[Authentication System]]
- uses [[Row Level Security]]
