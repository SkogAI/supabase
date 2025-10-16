---
title: ZITADEL IdP Setup Guide
type: note
permalink: guides/saml/zitadel-id-p-setup-guide
tags:
- saml
- zitadel
- idp
- configuration
---

# ZITADEL IdP Setup Guide

## Purpose

Step-by-step guide for configuring ZITADEL as a SAML 2.0 Identity Provider for self-hosted Supabase authentication.

## Prerequisites

- [prereq] ZITADEL instance (cloud or self-hosted)
- [prereq] Admin access to ZITADEL console
- [prereq] Organization created in ZITADEL
- [prereq] Project created within organization
- [prereq] Supabase instance URL/domain known

## SAML Application Setup

- [step] Navigate to Project → Applications
- [step] Create new SAML 2.0 application
- [step] Name: "Supabase SSO"
- [config] Entity ID (SP): `https://domain.com/auth/v1/sso/saml/metadata`
- [config] ACS URL: `https://domain.com/auth/v1/sso/saml/acs`
- [environment] Local dev uses http://localhost:8000
- [environment] Production uses https:// with SSL

## Attribute Mapping

- [attribute] **Email** → `Email` (Required) - Primary identifier
- [attribute] **First Name** → `FirstName` (Recommended)
- [attribute] **Last Name** → `SurName` (Recommended)
- [attribute] **Full Name** → `FullName` (Recommended)
- [attribute] **Username** → `UserName` (Optional)
- [attribute] **User ID** → `UserID` (Recommended) - Unique identifier
- [format] Use Basic format for attributes
- [case-sensitive] Attribute names must match exactly

## Metadata Export

- [metadata] Location: SAML application settings → Metadata
- [metadata] URL format: `https://instance-id.zitadel.cloud/saml/v2/metadata`
- [download] Download XML via console or curl
- [extract] Note Entity ID (Issuer)
- [extract] Note SSO endpoint URL
- [extract] Extract X.509 certificate
- [storage] Store metadata XML securely (chmod 600)

## Test User Creation

- [users] Create minimum 2 test users
- [users] Populate all required attributes (email, name)
- [authorization] Assign users to SAML application
- [authorization] Grant appropriate roles/permissions
- [security] Store credentials in password manager
- [verify] Test user can access ZITADEL console
- [verify] User sees "Supabase SSO" in app list

## Configuration Reference

- [url] Entity ID: ZITADEL SAML metadata URL
- [url] SSO endpoint: `/saml/v2/SSO`
- [url] Metadata endpoint: `/saml/v2/metadata`
- [port] Standard HTTPS port 443
- [protocol] SAML 2.0 specification

## URLs by Environment

- [local] Entity ID: `http://localhost:8000/auth/v1/sso/saml/metadata`
- [local] ACS: `http://localhost:8000/auth/v1/sso/saml/acs`
- [staging] Entity ID: `https://staging.domain.com/auth/v1/sso/saml/metadata`
- [staging] ACS: `https://staging.domain.com/auth/v1/sso/saml/acs`
- [production] Entity ID: `https://domain.com/auth/v1/sso/saml/metadata`
- [production] ACS: `https://domain.com/auth/v1/sso/saml/acs`

## Troubleshooting

- [issue] Cannot access console: Verify instance running, check connectivity
- [issue] Application not appearing: Check organization/project, refresh page
- [issue] Attribute mapping not working: Verify exact names (case-sensitive)
- [issue] Metadata export issues: Verify application saved, check URL format
- [issue] Users cannot access app: Verify authorization grants
- [tool] Use SAML-tracer browser extension for debugging
- [tool] Use xmllint for metadata validation

## Security Best Practices

- [security] Always use HTTPS in production
- [security] ZITADEL auto-rotates certificates
- [security] Monitor certificate expiration dates
- [security] Store metadata in secure location
- [security] Enable JIT user provisioning
- [security] Implement user deprovisioning workflows
- [security] Enable audit logging for all SAML events
- [security] Use MFA for admin accounts
- [security] Test in staging before production

## Next Steps

- [next] Configure Supabase with exported metadata
- [next] Test SSO flow end-to-end
- [next] Validate attribute mapping
- [next] Production readiness checklist
- [next] Update project documentation

## Example SAML Response Structure

- [xml] EntityDescriptor with entity ID
- [xml] AttributeStatement with user attributes
- [xml] Signature with X.509 certificate
- [xml] Conditions with time validity
- [xml] Audience restriction for security

## Implementation Checklist

- [checklist] ZITADEL instance available
- [checklist] Admin access verified
- [checklist] SAML application created
- [checklist] Entity ID and ACS URL configured
- [checklist] Attribute mapping configured
- [checklist] Metadata exported and stored
- [checklist] Test users created and assigned
- [checklist] Ready for Supabase configuration

## Relations

- configures [[ZITADEL SAML]]
- part_of [[ZITADEL SAML Integration Guide]]
- documented_in [[ZITADEL_SAML_IDP_SETUP.md]]
- prerequisite_for [[Supabase SAML Configuration]]
- produces [[SAML Metadata]]
- creates [[Test Users]]
- relates_to [[Attribute Mapping]]
