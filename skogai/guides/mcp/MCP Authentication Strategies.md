---
title: MCP Authentication Strategies
type: note
permalink: guides/mcp/mcp-authentication-strategies
tags:
- mcp
- authentication
- security
- credentials
---

# MCP Authentication Strategies

## Purpose

Comprehensive guide for secure authentication methods enabling AI agents to connect to Supabase databases with appropriate permissions and security controls.

## Authentication Methods Overview

- [method] **Service Role Key** - Full database access for trusted backend agents
- [method] **Database User Credentials** - Granular permissions for specific agent tasks
- [method] **JWT Token** - User-context aware with RLS enforcement
- [method] **API Key** - Rate-limited external agent access
- [method] **OAuth 2.0 / OIDC** - Delegated third-party agent access

## Service Role Authentication

- [use-case] Trusted server-side agents with full database access
- [feature] Bypasses Row Level Security completely
- [security] Must be stored in environment variables only
- [security] Never expose to client-side code
- [security] Rotate quarterly recommended
- [security] Enable audit logging for all operations
- [restriction] Backend/server environments only

## Database User Credentials

- [use-case] Dedicated agents with specific permission requirements
- [pattern] Read-only agent: SELECT permissions only
- [pattern] Read-write agent: SELECT, INSERT, UPDATE on specific tables
- [pattern] Analytics agent: SELECT all + CREATE for materialized views
- [config] Set resource limits: statement_timeout, work_mem, max_connections
- [security] Least-privilege access principle

## JWT Token Authentication

- [use-case] User-context aware agents with RLS enforcement
- [feature] Enables Row Level Security policies
- [feature] Agents act on behalf of specific users
- [config] Token expiry: 1-24 hours typical
- [pattern] Claims include user ID (sub), role, agent_type
- [security] RLS policies use auth.uid() and auth.jwt()
- [integration] Works seamlessly with Supabase auth

## API Key Authentication

- [use-case] External agents with rate limiting requirements
- [feature] Built-in rate limiting per key
- [feature] Usage tracking and analytics
- [feature] Configurable permissions per key
- [pattern] Store keys in database table with RLS
- [pattern] Validation function checks active status and expiry
- [security] Revocable individual keys without affecting others

## OAuth 2.0 / OIDC

- [use-case] Third-party agents with delegated user access
- [feature] Consent-based access control
- [feature] Standard OAuth flows (authorization code, etc.)
- [pattern] Scopes define permission levels
- [integration] Works with Google, GitHub, and custom providers

## Multi-Factor Authentication

- [security] Additional layer for critical AI agents
- [method] TOTP (Time-based One-Time Password)
- [config] MFA secret stored securely
- [pattern] Verification required for service account access

## Security Best Practices

- [best-practice] Store credentials in environment variables
- [best-practice] Rotate credentials regularly (quarterly for service roles)
- [best-practice] Enable audit logging for authentication attempts
- [best-practice] Implement rate limiting by auth method
- [best-practice] Use IP allowlisting for production agents
- [best-practice] Different rate limits per authentication method
- [best-practice] Never commit credentials to version control

## Authentication Decision Matrix

- [decision] Persistent server-side → Service Role (no RLS)
- [decision] Limited permissions → DB Credentials (role-based RLS)
- [decision] User-context aware → JWT (full RLS)
- [decision] External third-party → API Key (configurable RLS)
- [decision] User-facing delegated → OAuth + JWT (user RLS)

## Troubleshooting

- [issue] Invalid service role key: Verify in dashboard, test connection
- [issue] JWT expired: Increase expiry time, implement refresh
- [issue] Permission denied: Grant necessary permissions to DB user
- [issue] Rate limit exceeded: Implement exponential backoff retry

## Relations

- implements [[MCP AI Agents]]
- part_of [[MCP Server Architecture Guide]]
- documented_in [[MCP_AUTHENTICATION.md]]
- uses [[Row Level Security]]
- uses [[JWT Tokens]]
- relates_to [[Security Best Practices]]
- relates_to [[API Key Management]]
