---
title: MCP Connection Pooling
type: note
permalink: guides/mcp/mcp-connection-pooling
tags:
- mcp
- connection-pooling
- optimization
- performance
---

# MCP Connection Pooling Optimization

## Purpose

Comprehensive guide for configuring and optimizing connection pools specifically for AI agent workloads with unique connection patterns.

## AI Agent Connection Patterns

- [pattern] Burst traffic during model inference
- [pattern] Variable query complexity (simple lookups to analytical)
- [pattern] Mixed read-heavy and write operations
- [pattern] Long-running analytical queries
- [pattern] Auto-scaling requirements

## Pool Size Calculation

- [formula] Basic: `(Concurrent Agents × Queries/Agent) + 20% buffer`
- [formula] Performance-based: `((CPU Cores × 2) + Disk Spindles) × Agent Multiplier`
- [formula] Multiplier: 2-4 based on query complexity

## Pool Size by Workload

- [sizing] Low concurrency (1-10 agents): min=5, max=25
- [sizing] Medium concurrency (10-50 agents): min=20, max=200
- [sizing] High concurrency (50-200 agents): min=50, max=1000

## Persistent Agent Configuration

- [config] Pool: min=5, max=20
- [config] Idle timeout: 10 minutes
- [config] Connection timeout: 10 seconds
- [config] Max lifetime: 30 minutes
- [config] Mode: session (preserves prepared statements)

## Serverless Agent Configuration

- [config] Pool: min=0, max=10
- [config] Idle timeout: 5 seconds
- [config] Connection timeout: 5 seconds
- [config] Aggressive cleanup: 1 second intervals
- [config] Mode: transaction (automatic release)

## Edge Agent Configuration

- [config] Pool: min=0, max=3 (memory constraints)
- [config] Idle timeout: 1 second
- [config] Connection timeout: 3 seconds
- [config] Query timeout: 10 seconds
- [config] Geographic optimization for latency

## High-Performance Configuration

- [config] Pool: min=20, max=100
- [config] Idle timeout: 10 minutes
- [config] Queue limit: 1000 requests
- [config] Prepared statement caching: 100
- [config] Binary protocol enabled

## Timeout Strategies

- [timeout] Connection establishment: 3-10s depending on agent type
- [timeout] Simple queries: 5 seconds
- [timeout] Moderate queries: 30 seconds
- [timeout] Complex queries: 60 seconds
- [timeout] Analytical queries: 5 minutes
- [timeout] Idle in transaction: 60 seconds

## Supabase Tier Limits

- [limit] Free tier: 60 max (50 available for pooling)
- [limit] Small tier: 90 max (80 available)
- [limit] Medium tier: 150 max (135 available)
- [limit] Large tier: 200 max (180 available)
- [limit] XL tier: 300 max (270 available)
- [limit] 2XL tier: 500 max (450 available)

## Queue Management

- [queue] Priority-based queueing (high, medium, low)
- [queue] Max queue size: 1000 requests
- [queue] Queue timeout: 30 seconds
- [queue] FIFO or priority-based processing

## Auto-Scaling Guidelines

- [scaling] Scale up: queue depth >50 for >2min, utilization >80%
- [scaling] Scale down: queue depth =0 for >10min, utilization <30%
- [scaling] Dynamic pool sizing based on utilization metrics
- [scaling] Vertical scaling triggers on sustained CPU >80%

## Monitoring Metrics

- [metric] Total, idle, active, waiting connections
- [metric] Average connection and query times
- [metric] Connection and query error counts
- [metric] Pool utilization percentage
- [metric] Queue depth and wait times

## Alert Thresholds

- [alert] Pool saturation: idle <2 for >5min (warning)
- [alert] High wait time: waiting >10 for >2min (critical)
- [alert] Connection errors: >0.1/sec for >2min (warning)
- [alert] Slow queries: P95 >5s for >5min (warning)

## Best Practices

- [best-practice] Match pool size to workload patterns
- [best-practice] Use session mode for persistent, transaction for serverless
- [best-practice] Implement aggressive timeouts for serverless
- [best-practice] Monitor pool metrics continuously
- [best-practice] Implement connection retry with exponential backoff
- [best-practice] Use prepared statements for repeated queries
- [best-practice] Always release connections in finally blocks

## Troubleshooting

- [issue] Pool exhausted: increase max, reduce idle timeout, check for leaks
- [issue] Slow queries: set query timeouts, use caching, prioritize queries
- [issue] Memory leaks: enforce max lifetime, monitor connection age, recycle periodically

## Relations

- implements [[MCP AI Agents]]
- part_of [[MCP Server Architecture Guide]]
- documented_in [[MCP_CONNECTION_POOLING.md]]
- optimizes [[PostgreSQL Database]]
- relates_to [[Performance Optimization]]
- relates_to [[MCP Monitoring]]
