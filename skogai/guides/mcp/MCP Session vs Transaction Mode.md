---
title: MCP Session vs Transaction Mode
type: note
permalink: guides/mcp/mcp-session-vs-transaction-mode
tags:
- mcp
- connection-modes
- comparison
- pooling
---

# MCP Session vs Transaction Mode

## Purpose

Decision guide comparing Supavisor session mode and transaction mode to choose the appropriate connection pooling strategy for AI agents.

## Session Mode

- [characteristic] Persistent connection for entire client session
- [characteristic] Port 5432 (same as direct connections)
- [characteristic] Full PostgreSQL feature support
- [characteristic] Prepared statements preserved
- [characteristic] Session variables maintained
- [use-case] Persistent AI agents running for hours/days
- [use-case] Agents needing prepared statement caching
- [use-case] Complex transactions with session state

## Transaction Mode

- [characteristic] Connection returned after each transaction
- [characteristic] Port 6543 (different from session mode)
- [characteristic] Automatic connection cleanup
- [characteristic] Prepared statements not preserved
- [characteristic] No session state persistence
- [use-case] Serverless AI agents (Lambda, Cloud Functions)
- [use-case] Edge agents with limited execution time
- [use-case] Short-lived operations without state

## Performance Comparison

- [performance] Session mode: Lower latency for repeated queries
- [performance] Transaction mode: Better resource utilization
- [performance] Session mode: Connection overhead once per session
- [performance] Transaction mode: Connection overhead per transaction

## Resource Usage

- [resource] Session mode: Higher memory per agent (persistent)
- [resource] Transaction mode: Lower memory (automatic cleanup)
- [resource] Session mode: Predictable connection count
- [resource] Transaction mode: Variable connection count

## Feature Support

- [feature] Session mode: All PostgreSQL features
- [feature] Transaction mode: Basic features only
- [limitation] Transaction mode: No prepared statements
- [limitation] Transaction mode: No session-level settings
- [limitation] Transaction mode: No LISTEN/NOTIFY

## Decision Criteria

- [criteria] Execution duration: Long → Session, Short → Transaction
- [criteria] State requirements: Stateful → Session, Stateless → Transaction
- [criteria] Resource constraints: Limited → Transaction, Ample → Session
- [criteria] Feature needs: Advanced → Session, Basic → Transaction

## Configuration Comparison

- [config] Session: min=5, max=20, idle=300s
- [config] Transaction: min=0, max=10, idle=5s
- [config] Session: connection timeout=10s
- [config] Transaction: connection timeout=5s

## Best Practices

- [best-practice] Use session mode for persistent agents
- [best-practice] Use transaction mode for serverless/edge
- [best-practice] Don't mix modes for same agent
- [best-practice] Match pool configuration to mode
- [best-practice] Monitor mode-specific metrics

## Relations

- compares [[Supavisor Session Mode Setup]]
- compares [[Supavisor Transaction Mode]]
- part_of [[MCP Connection Pooling]]
- documented_in [[MCP_SESSION_VS_TRANSACTION.md]]
- helps_choose [[Connection Strategy]]
