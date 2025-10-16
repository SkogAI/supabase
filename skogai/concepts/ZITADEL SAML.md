---
title: ZITADEL SAML
type: note
permalink: concepts/zitadel-saml
tags:
- saml
- sso
- zitadel
- authentication
- enterprise
---

# ZITADEL SAML SSO

## Overview

SAML 2.0 Single Sign-On integration with ZITADEL as Identity Provider for enterprise authentication in self-hosted Supabase instances.

## Architecture Flow

- [flow] User accesses application
- [flow] Application redirects to Supabase Auth
- [flow] Supabase redirects to ZITADEL IdP
- [flow] User authenticates with ZITADEL
- [flow] ZITADEL sends SAML assertion to Supabase
- [flow] Supabase validates assertion and creates session
- [flow] User redirected back to application with auth token

## Key Components

- [component] **ZITADEL** - SAML Identity Provider (IdP)
- [component] **Supabase GoTrue** - SAML Service Provider (SP)
- [component] **Kong Gateway** - API routing for SAML endpoints
- [component] **SAML Metadata** - Configuration exchange format
- [component] **X.509 Certificates** - Signing and encryption

## Configuration Phases

- [phase] **Phase 1**: ZITADEL IdP Setup - Configure SAML application
- [phase] **Phase 2**: Supabase SP Configuration - Generate certs, configure GoTrue
- [phase] **Phase 3**: Testing & Validation - End-to-end flow testing
- [phase] **Phase 4**: Production Deployment - SSL/TLS, monitoring, hardening

## Certificate Management

- [certificate] Private key for Supabase (service provider)
- [certificate] X.509 certificate for SAML assertions
- [certificate] 3650-day validity (10 years)
- [certificate] Generated via OpenSSL
- [certificate] Stored securely in environment variables

## Attribute Mapping

- [attribute] Email address from SAML assertion
- [attribute] Display name/full name
- [attribute] User ID/username
- [attribute] Group memberships (optional)
- [attribute] Custom attributes per organization

## Just-In-Time Provisioning

- [jit] Automatic user creation on first login
- [jit] Profile populated from SAML attributes
- [jit] No manual user management needed
- [jit] Seamless user onboarding

## Security Features

- [security] SAML assertion signature verification
- [security] SSL/TLS encryption in transit
- [security] Certificate-based trust
- [security] Assertion expiration validation
- [security] Replay attack prevention
- [security] Domain-based access control

## Admin API

- [api] Create SAML provider via POST /auth/v1/admin/sso/providers
- [api] List providers via GET /auth/v1/admin/sso/providers
- [api] Update provider configuration
- [api] Delete provider
- [api] Requires service_role authentication

## Testing Strategy

- [testing] Metadata endpoint validation
- [testing] SSO flow end-to-end testing
- [testing] Attribute mapping verification
- [testing] Error handling scenarios
- [testing] Certificate expiration checks

## Troubleshooting

- [troubleshooting] Check GoTrue logs for SAML errors
- [troubleshooting] Validate metadata exchange
- [troubleshooting] Verify certificate configuration
- [troubleshooting] Test attribute mapping
- [troubleshooting] Check Kong routing configuration

## Automation

- [automation] `scripts/saml-setup.sh` for automated configuration
- [automation] Certificate generation automation
- [automation] Provider registration via API
- [automation] Health check endpoints

## Use Cases

- [use-case] Enterprise SSO for employee access
- [use-case] Multi-tenant SaaS applications
- [use-case] Centralized user management
- [use-case] Compliance requirements (SOC2, etc.)
- [use-case] Integration with corporate identity systems

## Best Practices

- [best-practice] Use long-lived certificates (10 years)
- [best-practice] Store certificates securely in secrets
- [best-practice] Test thoroughly in staging first
- [best-practice] Monitor auth logs for failures
- [best-practice] Document attribute mapping decisions
- [best-practice] Plan certificate rotation strategy

## Documentation Structure

- [doc-area] Complete integration guide
- [doc-area] ZITADEL IdP setup instructions
- [doc-area] Supabase SP configuration
- [doc-area] Admin API reference
- [doc-area] User guide for end users
- [doc-area] Production deployment procedures
- [doc-area] Troubleshooting runbooks

## Relations

- part_of [[Authentication System]]
- part_of [[Supabase Project Overview]]
- integrates_with [[ZITADEL]]
- uses [[X.509 Certificates]]
- uses [[SAML Protocol]]
- documented_in [[AUTH_ZITADEL_SAML_SELF_HOSTED.md]]
- documented_in [[ZITADEL_SAML_IDP_SETUP.md]]
- documented_in [[SAML_ADMIN_API.md]]
- documented_in [[USER_GUIDE_SAML.md]]
- documented_in [[saml-troubleshooting-self-hosted.md]]
