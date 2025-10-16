---
title: SAML User Guide
type: note
permalink: guides/saml/saml-user-guide
tags:
- saml
- user-guide
- end-user
- documentation
---

# SAML User Guide

## Purpose

End-user guide for authenticating to Supabase applications using SAML Single Sign-On (SSO) with ZITADEL.

## What is SAML SSO

- [concept] Single Sign-On authentication method
- [concept] Centralized identity management via ZITADEL
- [benefit] Single login for multiple applications
- [benefit] Enhanced security with MFA support
- [benefit] IT-managed user access
- [benefit] No need to remember multiple passwords

## How to Login

- [step] Navigate to application login page
- [step] Enter company email address
- [step] Automatic redirect to ZITADEL login
- [step] Enter ZITADEL username and password
- [step] Complete MFA if enabled (OTP, SMS, etc.)
- [step] Automatic redirect back to application
- [step] Now logged in with active session

## First Time Login

- [first-time] May see consent screen
- [first-time] Accept permissions to proceed
- [first-time] Profile automatically created from ZITADEL
- [first-time] Subsequent logins skip consent
- [security] Consent can be revoked in ZITADEL settings

## Session Management

- [session] Sessions last 1-24 hours (configured by admin)
- [session] Automatic token refresh in background
- [session] Logout in application terminates session
- [session] Browser close may or may not logout (depends on config)
- [session] Can manage sessions in ZITADEL console

## Troubleshooting

- [issue] "Access Denied" error: Contact IT admin
- [issue] Login loop (keeps redirecting): Clear browser cache/cookies
- [issue] "Invalid email" message: Verify email domain matches company
- [issue] Account not found: Contact IT for account creation
- [issue] MFA problems: Check ZITADEL authenticator app

## Password Reset

- [password] Passwords managed in ZITADEL, not application
- [password] Use ZITADEL password reset flow
- [password] Navigate to ZITADEL login → "Forgot password"
- [password] Follow email instructions to reset
- [contact] Contact IT if unable to reset

## Multi-Factor Authentication

- [mfa] MFA may be required by your organization
- [mfa] Setup in ZITADEL console → Security → MFA
- [mfa] Supported methods: Authenticator app, SMS, email
- [mfa] Backup codes provided during setup
- [mfa] Contact IT if lost MFA device

## Account Settings

- [settings] Update profile in ZITADEL console
- [settings] Changes sync to all applications
- [settings] Update name, email, phone number
- [settings] Manage MFA devices
- [settings] View active sessions
- [settings] Application cannot modify ZITADEL profile

## Security Best Practices

- [security] Never share ZITADEL credentials
- [security] Use strong, unique password
- [security] Enable MFA for enhanced security
- [security] Log out on shared/public computers
- [security] Report suspicious activity to IT
- [security] Verify ZITADEL URL before entering credentials

## Support

- [support] Technical issues: Contact IT help desk
- [support] Account access: IT admin
- [support] Password problems: ZITADEL password reset
- [support] Application-specific issues: Application support team

## FAQ

- [faq] Q: Why am I redirected to ZITADEL?
- [answer] A: SAML SSO centralizes authentication for security
- [faq] Q: Can I use my personal email?
- [answer] A: No, must use company email domain
- [faq] Q: How long do sessions last?
- [answer] A: Configured by admin, typically 1-8 hours
- [faq] Q: Can I stay logged in permanently?
- [answer] A: No, for security reasons sessions expire

## Privacy

- [privacy] ZITADEL stores basic profile information
- [privacy] Application receives only mapped attributes
- [privacy] Audit logs track authentication events
- [privacy] Contact IT for data access/deletion requests
- [compliance] Follows GDPR, SOC 2 requirements

## Relations

- documents [[ZITADEL SAML]]
- part_of [[Authentication System]]
- documented_in [[USER_GUIDE_SAML.md]]
- uses [[ZITADEL IdP]]
- relates_to [[Session Management]]
- relates_to [[Multi-Factor Authentication]]
