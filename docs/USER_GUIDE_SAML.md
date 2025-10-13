# SAML SSO User Guide

User guide for authenticating with ZITADEL SAML Single Sign-On in self-hosted Supabase applications.

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Login with SAML SSO](#login-with-saml-sso)
- [Managing Your Account](#managing-your-account)
- [Troubleshooting](#troubleshooting)
- [Security Tips](#security-tips)
- [FAQs](#faqs)

---

## Overview

### What is SAML SSO?

SAML (Security Assertion Markup Language) Single Sign-On allows you to log in to applications using your organization's identity provider (ZITADEL) instead of creating separate passwords for each application.

### Benefits

- ✅ **Single Login**: One set of credentials for all applications
- ✅ **Enhanced Security**: Multi-factor authentication support
- ✅ **Centralized Management**: IT manages your access
- ✅ **No Password Sharing**: Never share application passwords

---

## Getting Started

### Prerequisites

- Valid ZITADEL account provided by your organization
- Email address registered in ZITADEL
- Access to the application URL

### First-Time Setup

1. **Receive Invitation**: Your administrator will provide:
   - ZITADEL login credentials
   - Application URL
   - Instructions specific to your organization

2. **Verify Email**: Check your email for ZITADEL welcome message
   - Click verification link
   - Set up your password
   - Configure MFA (if required)

3. **Test Access**: Try logging in to verify everything works

---

## Login with SAML SSO

### Method 1: Direct SSO Link

Use this if your administrator provided a direct SSO login link.

**Steps:**

1. **Open SSO URL**
   ```
   https://your-app.com/auth/v1/sso?domain=yourcompany.com
   ```

2. **Automatic Redirect**: You'll be redirected to ZITADEL

3. **Enter Credentials**: 
   - Username or email
   - Password
   - MFA code (if enabled)

4. **Grant Consent** (first time only):
   - Review permissions
   - Click "Allow" or "Grant Access"

5. **Redirected to Application**: Automatically logged in

### Method 2: Email-Based Login

Use this if the application has a login form.

**Steps:**

1. **Open Application**: Navigate to application login page

2. **Enter Email**: Type your organization email
   ```
   user@yourcompany.com
   ```

3. **Click "Continue with SSO"**: Button may say:
   - "Sign in with SSO"
   - "Enterprise Login"
   - "Continue with ZITADEL"

4. **Complete Login**: Follow steps 2-5 from Method 1

### Method 3: Provider Selection

Some applications offer multiple login methods.

**Steps:**

1. **Choose SSO Provider**: Look for:
   - "Sign in with ZITADEL"
   - Company logo/name
   - "Corporate Account"

2. **Complete Login**: Follow authentication flow

---

## Managing Your Account

### Viewing Profile Information

Your profile is managed in ZITADEL, not in individual applications.

**To View/Edit Profile:**

1. Log in to ZITADEL Console: `https://your-instance.zitadel.cloud`
2. Navigate to **Account Settings**
3. Update:
   - Personal information
   - Contact details
   - Profile photo

### Changing Password

**Steps:**

1. Go to ZITADEL Console
2. Navigate to **Security** → **Password**
3. Enter current password
4. Enter new password (follow password policy)
5. Confirm new password
6. Click **Save**

**Password Requirements** (typical):
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

### Setting Up Multi-Factor Authentication (MFA)

**Supported MFA Methods:**
- Authenticator App (Google Authenticator, Authy, Microsoft Authenticator)
- SMS (if enabled)
- Hardware tokens (if enabled)

**Setup Steps:**

1. Log in to ZITADEL Console
2. Navigate to **Security** → **Multi-Factor Authentication**
3. Click **Add Method**
4. Choose method:

   **For Authenticator App:**
   - Scan QR code with authenticator app
   - Enter 6-digit code
   - Save backup codes in safe place

   **For SMS:**
   - Enter phone number
   - Verify with code sent via SMS
   - Confirm setup

5. Test MFA on next login

### Recovering Access

#### Forgot Password

1. Go to ZITADEL login page
2. Click **Forgot Password**
3. Enter your email
4. Check email for reset link
5. Click link and set new password

#### Lost MFA Device

Contact your IT administrator immediately:
- Provide: Name, email, employee ID
- They will temporarily disable MFA
- Set up new MFA device after regaining access

#### Account Locked

After multiple failed login attempts, your account may be locked.

**Resolution:**
- Wait 30 minutes for automatic unlock
- OR contact IT administrator for immediate unlock

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Email not found" or "Access Denied"

**Symptoms:**
- Cannot log in with email
- Error: "User not authorized"

**Solutions:**
1. Verify email address spelling
2. Contact administrator to:
   - Confirm account is created
   - Verify application access granted
   - Check email domain is configured

#### Issue 2: Redirect Loop

**Symptoms:**
- Continuously redirected between application and ZITADEL
- Never successfully logged in

**Solutions:**
1. Clear browser cookies and cache:
   - Chrome: Settings → Privacy → Clear browsing data
   - Firefox: Settings → Privacy → Clear Data
   - Safari: Safari → Clear History
2. Try different browser
3. Try incognito/private browsing mode
4. Contact IT if issue persists

#### Issue 3: MFA Code Not Working

**Symptoms:**
- MFA code rejected
- "Invalid authentication code"

**Solutions:**
1. Verify time is synchronized:
   - Phone/computer time must match ZITADEL server time
   - Enable automatic time sync in device settings
2. Try next code (codes refresh every 30 seconds)
3. Use backup code if available
4. Contact administrator to reset MFA

#### Issue 4: "Session Expired" Error

**Symptoms:**
- Logged out unexpectedly
- "Your session has expired, please log in again"

**Solutions:**
1. Log in again (sessions expire after inactivity)
2. Enable "Remember me" if available
3. Check session timeout settings with administrator

#### Issue 5: Stuck on Consent Screen

**Symptoms:**
- Consent screen appears every login
- Cannot proceed past consent

**Solutions:**
1. Grant all requested permissions
2. Clear browser data
3. Check if application requires re-consent
4. Contact administrator about consent configuration

### Getting Help

#### Self-Service Resources

- **ZITADEL Console**: Check account status and settings
- **Application Support**: Contact application helpdesk
- **IT Help Center**: Check internal knowledge base

#### Contacting Support

When contacting IT support, provide:
- **Your Details**: Name, email, employee ID
- **Issue Description**: What happened, what you expected
- **Error Messages**: Exact text of any error messages
- **Screenshots**: If possible, capture the error
- **Steps to Reproduce**: What you did before the error
- **Browser Info**: Browser name and version
- **Timestamp**: When the issue occurred

**Example Support Request:**
```
Subject: Cannot login to [Application Name] with SAML SSO

Hi IT Team,

I'm unable to login to [Application Name] using my company email.

Details:
- Name: John Doe
- Email: john.doe@company.com
- Application: https://app.company.com
- Error Message: "Email not found in system"
- Browser: Chrome 120
- Time: 2024-01-01 14:30 UTC
- Steps: Entered email, clicked "Continue with SSO", got error

Screenshot attached.

Please help!

Thanks,
John
```

---

## Security Tips

### Protecting Your Account

1. **Strong Password**
   - Use unique password (not reused)
   - Use password manager
   - Change if compromised

2. **Enable MFA**
   - Always enable multi-factor authentication
   - Use authenticator app (most secure)
   - Keep backup codes safe

3. **Recognize Phishing**
   - Verify URL before entering credentials
   - Official ZITADEL URL: `https://your-instance.zitadel.cloud`
   - Never enter password on suspicious sites

4. **Secure Sessions**
   - Always log out on shared computers
   - Don't share session links
   - Use private browsing for public computers

5. **Report Suspicious Activity**
   - Unexpected password reset emails
   - Login attempts from unknown locations
   - Unusual account activity

### Safe Browsing Practices

✅ **Do:**
- Use official application URLs
- Verify HTTPS (padlock icon)
- Keep browser updated
- Use company-approved browsers
- Log out after use

❌ **Don't:**
- Click suspicious email links
- Use public WiFi without VPN
- Share credentials
- Save passwords in browser (use password manager)
- Ignore security warnings

### Data Privacy

**What's Shared:**
When you log in via SAML, the application receives:
- Email address
- Full name
- User ID (internal identifier)
- Organization/department (if configured)

**What's NOT Shared:**
- Your password (stays in ZITADEL)
- Other personal information
- Access to other applications

---

## FAQs

### General Questions

**Q: Do I need a separate password for each application?**  
A: No. SAML SSO means one password for all integrated applications.

**Q: Can I use SAML SSO on mobile devices?**  
A: Yes, if the application supports mobile browser or native app SSO.

**Q: What happens if I change my ZITADEL password?**  
A: You'll use the new password next time you log in. Active sessions may continue until they expire.

**Q: How long do sessions last?**  
A: Typically 8 hours, but varies by application. Inactive sessions may expire sooner.

**Q: Can I stay logged in permanently?**  
A: No, for security. You'll need to re-authenticate periodically.

### Technical Questions

**Q: What is the consent screen for?**  
A: Applications request permission to access your profile information. Grant access to proceed.

**Q: Why does login require MFA every time?**  
A: MFA frequency depends on:
- Application security requirements
- Your device trust settings
- Time since last MFA verification
- Network location changes

**Q: Can I use the same login across different applications?**  
A: Yes, if all applications use ZITADEL SAML SSO. Log in once, access all apps.

**Q: What if my email changes?**  
A: Contact IT administrator to update email in ZITADEL. May require re-verification.

**Q: Can I access applications offline?**  
A: Initial login requires internet. Some apps may work offline after authentication, but features may be limited.

### Troubleshooting Questions

**Q: Why can't I log in with my email?**  
A: Possible reasons:
- Email not registered in ZITADEL
- Account not granted application access
- Email domain not configured for SSO
- Contact administrator

**Q: Login works at home but not at office?**  
A: May be network/firewall issue. Contact IT to check:
- ZITADEL URLs not blocked
- Proxy configuration
- Corporate firewall rules

**Q: Application says "unauthorized" after successful login?**  
A: ZITADEL authenticated you, but application denied access. Administrator needs to:
- Grant application permissions
- Check role assignments
- Verify user provisioning

**Q: Can I use personal email instead of company email?**  
A: No, SAML SSO requires company-registered email. Personal emails cannot be used.

---

## Quick Reference

### Login URLs

| Purpose | URL |
|---------|-----|
| ZITADEL Console | `https://your-instance.zitadel.cloud` |
| Application Login | Provided by administrator |
| SSO Direct Link | `https://app.com/auth/v1/sso?domain=company.com` |

### Support Contacts

| Issue Type | Contact |
|------------|---------|
| Password Reset | ZITADEL self-service |
| Account Access | IT Administrator |
| Application Issues | Application Support |
| Technical Problems | IT Helpdesk |

### Emergency Procedures

**Compromised Account:**
1. Change password immediately in ZITADEL
2. Revoke all active sessions
3. Enable MFA if not already enabled
4. Report to IT security team

**Lost Device (with MFA):**
1. Contact IT administrator immediately
2. Request MFA reset
3. Log out all sessions
4. Set up new MFA device

---

## Glossary

| Term | Definition |
|------|------------|
| **SAML** | Security Assertion Markup Language - authentication standard |
| **SSO** | Single Sign-On - one login for multiple applications |
| **IdP** | Identity Provider - ZITADEL (manages your identity) |
| **SP** | Service Provider - the application you're accessing |
| **MFA** | Multi-Factor Authentication - extra security layer |
| **Session** | Your logged-in state (expires after inactivity) |
| **Consent** | Permission to share your info with application |

---

## Additional Resources

- **ZITADEL Documentation**: https://zitadel.com/docs
- **Company IT Portal**: Check internal resources
- **Video Tutorials**: Ask administrator for training materials
- **Security Guidelines**: Review company security policies

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-01-01  
**Audience**: End Users  
**Support**: Contact your IT administrator
