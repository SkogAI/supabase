---
title: ZITADEL SAML Integration Guide
type: note
permalink: guides/saml/zitadel-saml-integration-guide
tags:
- saml
- zitadel
- sso
- authentication
- self-hosted
---

# ZITADEL SAML Integration Guide

## Purpose

Complete end-to-end guide for implementing SAML 2.0 Single Sign-On using ZITADEL with self-hosted Supabase instances.

## Architecture Components

- [component] **User Browser** - Initiates authentication flow
- [component] **Supabase (Service Provider)** - Kong, GoTrue, PostgreSQL
- [component] **ZITADEL (Identity Provider)** - User directory, SAML endpoints
- [component] **Kong API Gateway** - Routes SAML endpoints to GoTrue
- [component] **GoTrue Auth Server** - SAML provider management
- [component] **PostgreSQL** - Stores SAML providers and users

## Implementation Phases

- [phase] **Phase 1: ZITADEL Configuration** - Setup IdP application
- [phase] **Phase 2: Supabase Configuration** - Generate certs, configure GoTrue
- [phase] **Phase 3: Integration Testing** - Validate end-to-end flow
- [phase] **Phase 4: Production Deployment** - SSL/TLS, monitoring, security

## SAML Authentication Flow

- [flow] User accesses application → Supabase
- [flow] Supabase generates SAML Request (AuthnRequest XML)
- [flow] Browser redirects to ZITADEL with SAML Request
- [flow] User authenticates with ZITADEL (username/password/MFA)
- [flow] ZITADEL generates SAML Response with assertions
- [flow] Browser POST to Supabase ACS endpoint
- [flow] Supabase validates signature and assertions
- [flow] Supabase creates/updates user from attributes
- [flow] Supabase generates JWT token and establishes session
- [flow] User redirected to application, authenticated

## Certificate Management

- [cert] Generate private key: RSA 2048-bit
- [cert] Generate self-signed certificate: 10 year validity
- [cert] Store securely with restricted permissions (chmod 600)
- [cert] Base64 encode for environment variables
- [cert] Rotate certificates annually recommended
- [security] Never commit certificates to version control

## Environment Configuration

- [config] GOTRUE_SAML_ENABLED: Enable SAML support
- [config] GOTRUE_SAML_PRIVATE_KEY: Base64 encoded private key
- [config] GOTRUE_SITE_URL: Supabase instance URL
- [config] GOTRUE_ADMIN_JWT_SECRET: JWT secret for admin API
- [restart] Restart services after configuration changes

## SAML Provider Registration

- [api] Use GoTrue Admin API to register ZITADEL
- [api] POST /auth/v1/admin/sso/providers with metadata
- [config] Include domains, metadata_url, metadata_xml
- [config] Configure attribute mapping (email, name, etc.)
- [verify] Check database: auth.saml_providers table

## Kong Routing

- [route] /auth/v1/sso/saml/metadata → GoTrue (GET)
- [route] /auth/v1/sso/saml/acs → GoTrue (POST)
- [route] /auth/v1/admin/sso/providers → GoTrue Admin API
- [auto] Routes automatically configured by Kong

## Testing Strategy

- [test] Verify metadata endpoint accessible
- [test] Test complete SAML authentication flow
- [test] Validate user creation in database
- [test] Verify attribute mapping correct
- [test] Check JWT token generation
- [test] Test session management

## Production Deployment

- [production] Configure SSL/TLS certificates
- [production] Update all URLs to HTTPS
- [production] Use secret management for credentials
- [production] Enable monitoring and alerting
- [production] Configure certificate expiry monitoring
- [production] Setup backup procedures
- [production] Document incident response

## Security Measures

- [security] Private key protection with encryption
- [security] Annual certificate rotation
- [security] Comprehensive audit logging
- [security] Network isolation with Docker networks
- [security] IP allowlisting where possible
- [security] Rate limiting on SAML endpoints

## Troubleshooting

- [issue] 404 on SAML endpoints: Check Kong routing
- [issue] Invalid signature: Verify certificate sync
- [issue] User not created: Check attribute mapping
- [issue] 500 on ACS: Verify private key loaded
- [diagnostic] Check GoTrue logs for SAML events
- [diagnostic] Verify provider in database

## Maintenance Tasks

- [maintenance] Monthly certificate expiry checks
- [maintenance] Weekly security updates
- [maintenance] Regular backup verification
- [maintenance] Audit log reviews
- [maintenance] Performance monitoring
- [maintenance] Configuration updates via Admin API

## Relations

- implements [[ZITADEL SAML]]
- implements [[Authentication System]]
- part_of [[Project Architecture]]
- documented_in [[AUTH_ZITADEL_SAML_SELF_HOSTED.md]]
- requires [[ZITADEL IdP Setup]]
- requires [[Certificate Management]]
- uses [[Kong API Gateway]]
- uses [[GoTrue Auth Server]]
- relates_to [[SAML Admin API]]
- relates_to [[SAML Troubleshooting]]
