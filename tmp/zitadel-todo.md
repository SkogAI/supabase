# ZITADEL Configuration Todo List

**Issue**: #69 - Setup ZITADEL as SAML Identity Provider
**ZITADEL Instance**: https://auth.aldervall.se
**Date Started**: 2025-10-07

---

## Phase 1: SAML Application Setup

- [ ] Log into ZITADEL console at https://auth.aldervall.se
- [ ] Navigate to Project → Applications in ZITADEL
- [ ] Create new SAML application named 'Supabase SSO'
- [ ] Configure Entity ID: `http://localhost:8000/auth/v1/sso/saml/metadata`
  - _Note: Update to `https://` if you have SSL configured_
- [ ] Configure ACS URL: `http://localhost:8000/auth/v1/sso/saml/acs`
  - _Note: Update to `https://` if you have SSL configured_

## Phase 2: Attribute Mapping

Configure the following attribute mappings in ZITADEL SAML application:

- [ ] Email → `Email` (required)
- [ ] First Name → `FirstName`
- [ ] Last Name → `SurName`
- [ ] Full Name → `FullName`
- [ ] Username → `UserName`
- [ ] User ID → `UserID`

## Phase 3: Metadata & Certificates

- [ ] Verify metadata URL accessible: https://auth.aldervall.se/saml/v2/metadata
  ```bash
  curl https://auth.aldervall.se/saml/v2/metadata
  ```
- [ ] Download or save ZITADEL metadata XML
  ```bash
  curl https://auth.aldervall.se/saml/v2/metadata > zitadel-metadata.xml
  ```
- [ ] Verify SSO endpoint: https://auth.aldervall.se/saml/v2/SSO
- [ ] Download X.509 certificate
  ```bash
  curl https://auth.aldervall.se/saml/v2/certificate > zitadel-cert.pem
  ```

## Phase 4: Test Users

- [ ] Create at least 2 test users in ZITADEL
  - Test User 1: ___________________
  - Test User 2: ___________________
- [ ] Assign test users to 'Supabase SSO' SAML application
- [ ] Document test user credentials securely (password manager)

## Phase 5: Documentation

- [ ] Document ZITADEL configuration details:
  - Entity ID (Issuer): `https://auth.aldervall.se/saml/v2/metadata`
  - SSO Endpoint: `https://auth.aldervall.se/saml/v2/SSO`
  - SLO Endpoint: `https://auth.aldervall.se/saml/v2/SLO` (not used yet)
  - Metadata URL: `https://auth.aldervall.se/saml/v2/metadata`
  - Certificate URL: `https://auth.aldervall.se/saml/v2/certificate`
- [ ] Save all configuration to project documentation

---

## ZITADEL Endpoints Reference

| Endpoint | URL |
|----------|-----|
| SAML Certificate | https://auth.aldervall.se/saml/v2/certificate |
| Single Sign On (SSO) | https://auth.aldervall.se/saml/v2/SSO |
| Single Logout (SLO) | https://auth.aldervall.se/saml/v2/SLO |
| Metadata | https://auth.aldervall.se/saml/v2/metadata |
| Discovery (OIDC) | https://auth.aldervall.se/.well-known/openid-configuration |

## Supabase Endpoints (to configure in ZITADEL)

| Endpoint | URL |
|----------|-----|
| Entity ID | http://localhost:8000/auth/v1/sso/saml/metadata |
| ACS URL | http://localhost:8000/auth/v1/sso/saml/acs |
| Metadata | http://localhost:8000/auth/v1/sso/saml/metadata?download=true |

_Note: Update to `https://your-domain.com` when deploying to production_

---

## Completion

- [ ] All tasks completed
- [ ] Ready to proceed to Issue #70 (Supabase Configuration)

**Completed Date**: ___________
