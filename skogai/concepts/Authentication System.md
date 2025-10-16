---
title: Authentication System
type: note
permalink: concepts/authentication-system
tags:
- authentication
- auth
- jwt
- security
---

# Authentication System

## Overview

Multi-method authentication system with JWT token-based authorization integrated with Row Level Security.

## Supported Methods

- [method] Email/Password - Traditional authentication
- [method] Magic Links - Passwordless email login
- [method] OAuth Providers - Social login (Google, GitHub, etc.)
- [method] Phone/SMS - SMS-based authentication with OTP
- [method] SAML 2.0 SSO - Enterprise Single Sign-On (self-hosted)

## JWT Token Flow

- [flow] User authenticates via chosen method
- [flow] Supabase Auth issues JWT token
- [flow] Client includes token in API requests
- [flow] PostgREST validates token
- [flow] PostgreSQL RLS uses token claims via auth.uid()
- [flow] Data filtered per authenticated user

## Token Structure

- [token] Contains user ID (sub claim)
- [token] Contains role (authenticated/anon)
- [token] Contains email and metadata
- [token] Signed with secret key
- [token] Expiry configurable (default 3600s)

## Configuration

- [config] Settings in `supabase/config.toml` [auth] section
- [config] Site URL for redirects
- [config] Enable/disable signup
- [config] Email confirmation settings
- [config] JWT expiry duration
- [config] External provider credentials

## User Management

- [feature] Automatic profile creation on signup
- [feature] Email confirmation flow
- [feature] Password reset via email
- [feature] User metadata storage
- [feature] Session management
- [feature] Multi-factor authentication (MFA)

## Security Features

- [security] Secure password hashing (bcrypt)
- [security] JWT signature verification
- [security] Rate limiting on auth endpoints
- [security] Session management
- [security] Automatic token refresh
- [security] PKCE for OAuth flows

## RLS Integration

- [integration] `auth.uid()` returns current user ID
- [integration] Policies use JWT claims for filtering
- [integration] Anonymous users get `anon` role
- [integration] Authenticated users get `authenticated` role
- [integration] Service role bypasses all RLS

## SAML SSO

- [saml] Enterprise Single Sign-On support
- [saml] ZITADEL as Identity Provider
- [saml] Just-In-Time (JIT) user provisioning
- [saml] Centralized user management
- [saml] Support for MFA and advanced policies

## Development Users

- [testing] Alice: `alice@example.com` (UUID: 00000000-0000-0000-0000-000000000001)
- [testing] Bob: `bob@example.com` (UUID: 00000000-0000-0000-0000-000000000002)
- [testing] Charlie: `charlie@example.com` (UUID: 00000000-0000-0000-0000-000000000003)
- [testing] Password: `password123` for all test users

## Best Practices

- [best-practice] Never expose service_role key to clients
- [best-practice] Use anon key for client applications
- [best-practice] Implement proper session handling
- [best-practice] Enable email confirmation in production
- [best-practice] Set strong password requirements
- [best-practice] Monitor auth logs for suspicious activity

## Relations

- part_of [[Project Architecture]]
- part_of [[Supabase Project Overview]]
- integrates_with [[Row Level Security]]
- integrates_with [[ZITADEL SAML]]
- uses [[JWT Tokens]]
- documented_in [[USER_GUIDE_SAML.md]]
- documented_in [[AUTH_ZITADEL_SAML_SELF_HOSTED.md]]
