---
title: MCP Troubleshooting Guide
type: note
permalink: guides/mcp/mcp-troubleshooting-guide
tags:
- mcp
- troubleshooting
- debugging
- errors
---

# MCP Troubleshooting Guide

## Purpose

Comprehensive troubleshooting reference for diagnosing and resolving common MCP server and AI agent connection issues.

## Connection Issues

- [issue] **Connection Refused** - Check firewall, verify host/port, confirm service running
- [issue] **Connection Timeout** - Increase timeout, test network, verify DNS resolution
- [issue] **Too Many Connections** - Reduce pool max, upgrade tier, find connection leaks
- [issue] **SSL/TLS Errors** - Verify certificates, check SSL mode, update CA bundle
- [solution] Test with psql command line first
- [solution] Use telnet to verify port accessibility
- [solution] Check Supabase Dashboard service status

## Authentication Issues

- [issue] **Invalid Credentials** - Verify username/password, check project reference
- [issue] **Service Role Key Invalid** - Get fresh key from dashboard, check environment vars
- [issue] **JWT Expired** - Increase expiry time, implement token refresh
- [issue] **Permission Denied** - Grant necessary permissions, check RLS policies
- [solution] Test credentials independently
- [solution] Review RLS policy logs
- [solution] Enable authentication audit logging

## Pool Saturation

- [issue] **Clients Waiting for Connections** - Pool exhausted
- [symptom] High wait times, frequent timeouts
- [solution] Increase pool max size (within tier limits)
- [solution] Reduce query execution time
- [solution] Implement connection queueing
- [solution] Check for connection leaks (unreleased connections)
- [monitoring] Track waiting clients metric

## Slow Query Performance

- [issue] **High Query Latency** - Queries taking longer than expected
- [symptom] P95/P99 times elevated, timeouts increasing
- [solution] Add database indexes for frequent queries
- [solution] Use EXPLAIN ANALYZE to identify bottlenecks
- [solution] Set appropriate statement timeouts
- [solution] Implement query result caching
- [solution] Check database CPU/memory in dashboard

## Memory Leaks

- [issue] **Gradual Memory Increase** - Connections not being recycled
- [symptom] Out of memory errors, slow connection establishment
- [solution] Enforce connection max lifetime (maxUses)
- [solution] Monitor connection age, recycle old connections
- [solution] Force periodic pool drain and clear
- [monitoring] Track memory usage over time

## Network Issues

- [issue] **Intermittent Connection Drops** - Network instability
- [symptom] Random connection terminations
- [solution] Reduce idle timeout for faster detection
- [solution] Implement connection keep-alive
- [solution] Add automatic retry with exponential backoff
- [solution] Use session mode for persistent agents

## Configuration Issues

- [issue] **Wrong Connection Mode** - Using session mode for serverless
- [symptom] Connections not cleaning up, pool exhaustion
- [solution] Use transaction mode (port 6543) for serverless
- [solution] Use session mode (port 5432) for persistent
- [solution] Match pool configuration to agent type

## Rate Limiting

- [issue] **Rate Limit Exceeded** - Too many requests from agent
- [symptom] 429 errors, rejected requests
- [solution] Implement exponential backoff retry
- [solution] Reduce request frequency
- [solution] Spread load across multiple agent instances
- [solution] Cache frequent queries

## Monitoring & Diagnostics

- [diagnostic] Check pg_stat_activity for active connections
- [diagnostic] Query pool statistics (total, idle, waiting)
- [diagnostic] Review Supabase Dashboard metrics
- [diagnostic] Check application logs for errors
- [diagnostic] Use connection pool health checks
- [diagnostic] Monitor query execution times

## Debug Queries

- [query] Active connections by state
- [query] Long-running queries
- [query] Blocked queries waiting for locks
- [query] Pool utilization metrics
- [query] Connection age and lifetime

## Common Error Messages

- [error] "remaining connection slots reserved" → Pool exhausted
- [error] "Connection terminated unexpectedly" → Network/timeout issue
- [error] "authentication failed" → Wrong credentials
- [error] "no pg_hba.conf entry" → IP not allowlisted
- [error] "statement timeout" → Query took too long

## Best Practices

- [best-practice] Enable comprehensive logging early
- [best-practice] Monitor pool metrics continuously
- [best-practice] Test in staging before production
- [best-practice] Document issue resolution steps
- [best-practice] Keep connection strings updated
- [best-practice] Regular health checks automated

## Relations

- troubleshoots [[MCP AI Agents]]
- troubleshoots [[MCP Server Architecture Guide]]
- troubleshoots [[MCP Connection Pooling]]
- documented_in [[MCP_TROUBLESHOOTING.md]]
- relates_to [[Monitoring and Observability]]
- relates_to [[Error Handling]]
