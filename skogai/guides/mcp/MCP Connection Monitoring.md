---
title: MCP Connection Monitoring
type: note
permalink: guides/mcp/mcp-connection-monitoring
tags:
- mcp
- monitoring
- metrics
- observability
---

# MCP Connection Monitoring

## Purpose

Comprehensive monitoring and observability strategies for MCP servers and AI agent database connections.

## Key Metrics

- [metric] **Active Connections** - Currently executing queries
- [metric] **Idle Connections** - Waiting in pool for queries
- [metric] **Waiting Clients** - Queued waiting for connection
- [metric] **Connection Wait Time** - Time to acquire connection
- [metric] **Query Execution Time** - P50, P95, P99 latencies
- [metric] **Connection Errors** - Failed connection attempts
- [metric] **Query Errors** - Failed query executions
- [metric] **Pool Utilization** - Percentage of pool capacity used
- [metric] **Slow Queries** - Queries exceeding threshold (>1s)

## Monitoring Tools

- [tool] **Prometheus** - Metrics collection and alerting
- [tool] **Grafana** - Metrics visualization dashboards
- [tool] **PostgreSQL pg_stat_activity** - Real-time connection view
- [tool] **Supabase Dashboard** - Built-in metrics and logs
- [tool] **Application Logs** - Structured logging with Winston/Pino
- [tool] **Custom Health Checks** - Automated connection testing

## Prometheus Metrics

- [prometheus] db_pool_connections{state="total|idle|active|waiting"}
- [prometheus] db_query_duration_seconds (histogram)
- [prometheus] db_connection_errors_total (counter)
- [prometheus] db_pool_utilization (gauge)
- [prometheus] db_slow_queries_total (counter)

## Alert Thresholds

- [alert] **Pool Saturation** - idle <2 for >5min (warning)
- [alert] **High Wait Time** - waiting >10 for >2min (critical)
- [alert] **Connection Errors** - >0.1/sec for >2min (warning)
- [alert] **Slow Queries** - P95 >5s for >5min (warning)
- [alert] **Database CPU** - >80% sustained (warning)
- [alert] **Memory Usage** - >85% (warning)

## Health Check Implementation

- [pattern] Periodic health checks every 30 seconds
- [pattern] Test actual query execution, not just connection
- [pattern] Track health check failures
- [pattern] Automatic recovery attempts
- [pattern] Escalate after N consecutive failures

## PostgreSQL Monitoring Queries

- [query] Active connections by application and state
- [query] Long-running queries (>30s)
- [query] Blocked queries and lock conflicts
- [query] Connection pool statistics
- [query] Database size and growth rate
- [query] Index usage statistics

## Dashboard Panels

- [panel] Connection pool status over time
- [panel] Query performance (P50, P95, P99)
- [panel] Pool utilization percentage
- [panel] Error rate per minute
- [panel] Top slow queries
- [panel] Connection lifecycle events

## Logging Best Practices

- [logging] Structured JSON logs for parsing
- [logging] Include agent ID, operation, timestamps
- [logging] Log connection lifecycle events
- [logging] Track query execution times
- [logging] Capture error details with stack traces
- [logging] Use appropriate log levels (debug, info, warn, error)

## Performance Monitoring

- [performance] Track query execution time distribution
- [performance] Monitor connection establishment time
- [performance] Measure pool wait time
- [performance] Track database CPU and memory
- [performance] Monitor network latency
- [performance] Analyze query patterns and hotspots

## Anomaly Detection

- [detection] Sudden spike in connection errors
- [detection] Gradual increase in query latency
- [detection] Pool utilization approaching 100%
- [detection] Unusual query patterns
- [detection] Connection leak patterns
- [detection] Memory usage trends

## Alerting Strategy

- [strategy] Different severity levels (info, warning, critical)
- [strategy] Aggregation windows to reduce noise
- [strategy] Escalation paths for critical alerts
- [strategy] Automatic remediation for known issues
- [strategy] Alert fatigue prevention with thresholds

## Best Practices

- [best-practice] Monitor proactively, not reactively
- [best-practice] Set realistic alert thresholds
- [best-practice] Review metrics regularly
- [best-practice] Correlate metrics with events
- [best-practice] Document baseline performance
- [best-practice] Automate health checks
- [best-practice] Keep historical data for trend analysis

## Relations

- monitors [[MCP AI Agents]]
- monitors [[MCP Connection Pooling]]
- part_of [[Observability Strategy]]
- documented_in [[MCP_CONNECTION_MONITORING.md]]
- uses [[Prometheus]]
- uses [[Grafana]]
- integrates_with [[Supabase Dashboard]]
