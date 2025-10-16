---
title: Supavisor Session Mode Setup
type: note
permalink: guides/mcp/supavisor-session-mode-setup
tags:
- mcp
- supavisor
- session-mode
- ipv4
- setup
---

# Supavisor Session Mode Setup

## Purpose

Step-by-step guide for configuring Supavisor session mode connections for persistent AI agents requiring IPv4 support and connection persistence.

## What is Session Mode

- [feature] Connection pooling maintaining persistent connections
- [feature] IPv4 compatibility for IPv4-only networks
- [feature] Full support for prepared statements
- [feature] Preserves session-level PostgreSQL settings
- [feature] All PostgreSQL features work as expected
- [port] Uses port 5432 (same as direct connections)

## Connection String Format

- [pattern] `postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres`
- [component] postgres: database username
- [component] project-ref: Supabase project reference ID
- [component] password: database password
- [component] region: AWS region (us-east-1, eu-west-1, etc.)

## Pool Configuration

- [sizing] Small agent (1-5 ops): min=2, max=5
- [sizing] Medium agent (5-15 ops): min=5, max=15
- [sizing] Large agent (15-30 ops): min=10, max=30
- [formula] Pool size = (Concurrent Operations + 20% Buffer)

## Timeout Configuration

- [timeout] Connection establishment: 10 seconds
- [timeout] Idle connection: 5 minutes (300s)
- [timeout] Statement execution: 30 seconds
- [timeout] Idle in transaction: 60 seconds
- [timeout] Connection max lifetime: 30 minutes

## Environment Setup

- [config] SUPABASE_SESSION_POOLER: full connection string
- [config] DB_CONNECTION_TYPE: supavisor_session
- [config] DB_POOL_MIN: minimum pool connections
- [config] DB_POOL_MAX: maximum pool connections
- [config] DB_POOL_IDLE_TIMEOUT: idle connection timeout
- [security] Never commit .env files to git

## Monitoring Utilities

- [utility] Health check: Test connection every 30 seconds
- [utility] Pool monitoring: Track total, idle, waiting connections
- [utility] Graceful shutdown: Close pool cleanly on termination
- [metric] Active connections: Currently executing queries
- [metric] Idle connections: Waiting for queries
- [metric] Wait time: Client wait for available connection

## PostgreSQL Monitoring

- [query] Active connections by state
- [query] Pool utilization metrics
- [query] Oldest connection age
- [dashboard] Supabase Dashboard: connection count, CPU, memory

## IPv4 Verification

- [test] DNS resolution: nslookup pooler hostname
- [test] Port connectivity: telnet to port 5432
- [test] Connection test: psql command line
- [code] Programmatic verification with net.connect()

## Implementation Examples

- [example] Python with asyncpg: SessionPoolManager class
- [example] Node.js with pg: SessionPoolManager class
- [feature] Connection lifecycle management
- [feature] Health checks and monitoring
- [feature] Graceful shutdown handling

## Troubleshooting

- [issue] Too many connections: Reduce pool max, upgrade tier, check leaks
- [issue] Connection timeouts: Increase timeout, check network, verify firewall
- [issue] Idle connection drops: Reduce idle timeout, add keep-alive, retry logic
- [issue] Slow queries: Add indexes, optimize structure, check CPU/memory
- [issue] Pool saturation: Increase max, reduce query time, implement queuing

## Best Practices

- [best-practice] Always release connections after use
- [best-practice] Implement graceful shutdown handling
- [best-practice] Use prepared statements for repeated queries
- [best-practice] Set appropriate statement timeouts
- [best-practice] Monitor pool health regularly
- [best-practice] Handle connection errors gracefully
- [best-practice] Use environment variables for credentials

## Relations

- implements [[MCP AI Agents]]
- part_of [[MCP Server Architecture Guide]]
- uses [[Supavisor Pooler]]
- documented_in [[MCP_SESSION_MODE_SETUP.md]]
- compares_with [[Supavisor Transaction Mode]]
- relates_to [[Connection Pooling]]
- relates_to [[IPv4 Support]]
