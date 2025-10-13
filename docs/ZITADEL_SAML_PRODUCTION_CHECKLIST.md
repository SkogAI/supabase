# ZITADEL SAML Production Deployment Checklist

Quick reference checklist for deploying ZITADEL SAML SSO to production.

> **Complete Guide**: See [ZITADEL_SAML_PRODUCTION_DEPLOYMENT.md](ZITADEL_SAML_PRODUCTION_DEPLOYMENT.md) for detailed instructions.

## Prerequisites

### Completed Phases

- [ ] **Phase 1**: ZITADEL IdP setup completed
- [ ] **Phase 2**: Supabase SAML configuration completed
- [ ] **Phase 3**: Testing & validation completed
- [ ] Security review completed
- [ ] Compliance requirements verified
- [ ] Rollback plan documented

### Infrastructure

- [ ] Production server provisioned (4+ CPU, 8+ GB RAM, 50+ GB disk)
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose 2.x+ installed
- [ ] Static IP or domain name configured
- [ ] DNS records configured and propagated
- [ ] Backup solution configured

### Access

- [ ] Root/sudo access to production server
- [ ] DNS management access
- [ ] Production ZITADEL admin access
- [ ] Certificate authority access (if commercial certs)

---

## 1. Production Environment Setup

### Server Configuration

- [ ] System packages updated (`apt update && apt upgrade`)
- [ ] Docker and Docker Compose installed
- [ ] User added to docker group
- [ ] System limits configured (`/etc/security/limits.conf`)
- [ ] Sysctl settings configured (`/etc/sysctl.conf`)

### Directory Structure

- [ ] Created `/opt/supabase/production`
- [ ] Created `/opt/supabase/config`
- [ ] Created `/opt/supabase/volumes/{db,storage,logs}`
- [ ] Created `/opt/supabase/backups`
- [ ] Created `/opt/supabase/certs`
- [ ] Set appropriate permissions (750 for config/certs)

### Firewall

- [ ] UFW installed
- [ ] SSH allowed (port 22)
- [ ] HTTP allowed (port 80)
- [ ] HTTPS allowed (port 443)
- [ ] PostgreSQL blocked from external access (port 54322)
- [ ] Firewall enabled and tested

---

## 2. SSL/TLS Configuration

### Certificate Acquisition

**Let's Encrypt:**
- [ ] Certbot installed
- [ ] Certificates obtained for domain
- [ ] Certificates copied to `/opt/supabase/certs/`
- [ ] Auto-renewal configured (`certbot.timer`)

**Commercial Certificate:**
- [ ] Certificate files obtained
- [ ] Certificate, key, and CA bundle copied to `/opt/supabase/certs/`
- [ ] File permissions set correctly (644 for cert, 600 for key)

### Nginx Configuration

- [ ] Nginx installed
- [ ] Configuration file created (`/etc/nginx/sites-available/supabase`)
- [ ] Symbolic link created (`/etc/nginx/sites-enabled/supabase`)
- [ ] Default configuration removed
- [ ] Configuration tested (`nginx -t`)
- [ ] Nginx enabled and started

### SSL Verification

- [ ] HTTPS accessible in browser
- [ ] No certificate warnings
- [ ] HTTP redirects to HTTPS
- [ ] Security headers present
- [ ] SSL Labs test passed (A+ rating)

---

## 3. Production ZITADEL Configuration

### SAML Application

- [ ] Logged into production ZITADEL instance
- [ ] Created new SAML application ("Supabase Production SSO")
- [ ] Configured Entity ID: `https://your-domain.com/auth/v1/sso/saml/metadata`
- [ ] Configured ACS URL: `https://your-domain.com/auth/v1/sso/saml/acs`
- [ ] Application saved successfully

### Attribute Mapping

- [ ] Email → Email (required)
- [ ] FirstName → FirstName
- [ ] LastName → SurName
- [ ] DisplayName → FullName
- [ ] Username → UserName
- [ ] UserID → UserID
- [ ] Attribute mapping saved

### Metadata Export

- [ ] Metadata XML downloaded
- [ ] Saved to `/opt/supabase/config/zitadel-prod-metadata.xml`
- [ ] Permissions set to 600
- [ ] Metadata URL noted for API configuration

### User Management

- [ ] Production users assigned to SAML application
- [ ] Test users removed or disabled
- [ ] User groups/roles configured (if needed)
- [ ] MFA policies configured (recommended)

---

## 4. Production Supabase Configuration

### SAML Keys

- [ ] RSA private key generated (`openssl genpkey`)
- [ ] Key converted to base64
- [ ] Saved to `/opt/supabase/config/prod_saml_key.base64`
- [ ] File permissions set to 600

### Service Keys

- [ ] JWT secret generated (32+ characters)
- [ ] Anon key generated
- [ ] Service role key generated
- [ ] Keys stored securely in `/opt/supabase/config/prod_secrets.txt`
- [ ] File permissions set to 600

### Environment Variables

- [ ] Created `/opt/supabase/.env.production`
- [ ] Set `SUPABASE_URL=https://your-domain.com`
- [ ] Set `ANON_KEY` (production key)
- [ ] Set `SERVICE_ROLE_KEY` (production key)
- [ ] Set `POSTGRES_PASSWORD` (strong random password)
- [ ] Set `JWT_SECRET` (production secret)
- [ ] Set `GOTRUE_SAML_ENABLED=true`
- [ ] Set `GOTRUE_SAML_PRIVATE_KEY` (base64 key)
- [ ] Set `GOTRUE_SITE_URL=https://your-domain.com`
- [ ] Set `GOTRUE_URI_ALLOW_LIST` (HTTPS URLs only)
- [ ] Set session timeouts (`GOTRUE_JWT_EXP=3600`)
- [ ] Set refresh token rotation enabled
- [ ] File permissions set to 600

### Docker Compose

- [ ] Created `docker-compose.production.yml`
- [ ] Resource limits configured for all services
- [ ] Health checks configured
- [ ] Restart policies set to `unless-stopped`
- [ ] Volume mounts configured
- [ ] Logging configured (json-file with rotation)

---

## 5. Security Hardening

### Passwords & Secrets

- [ ] All default passwords changed
- [ ] Strong passwords used (32+ characters)
- [ ] Service role keys rotated (if previously exposed)
- [ ] Secrets not committed to git
- [ ] Secrets stored in secure location

### Rate Limiting

- [ ] Kong rate limiting configured
- [ ] Limits appropriate for expected traffic
- [ ] Rate limiting tested

### Session Security

- [ ] JWT expiration set (`GOTRUE_JWT_EXP=3600`)
- [ ] Refresh token rotation enabled
- [ ] Cookie domain configured
- [ ] Cookie key set (32 characters)

### Audit Logging

- [ ] ZITADEL audit logging enabled
- [ ] Log retention configured (90+ days)
- [ ] Log export configured (if SIEM required)
- [ ] Docker logging configured with rotation

### Database Security

- [ ] SSL enabled for database connections (if external)
- [ ] Database user permissions reviewed
- [ ] RLS policies verified on all tables
- [ ] Password policy configured

### Network Security

- [ ] Database port blocked from external access
- [ ] Only necessary ports exposed
- [ ] IP whitelisting configured (if required)
- [ ] VPN access configured (if required)

---

## 6. Monitoring & Alerting

### Infrastructure Monitoring

- [ ] Prometheus/Node Exporter installed
- [ ] cAdvisor running for Docker monitoring
- [ ] CPU/Memory/Disk monitoring configured
- [ ] Container health checks configured

### Application Monitoring

- [ ] SAML authentication logging enabled
- [ ] Success/failure rates tracked
- [ ] Response time monitoring configured
- [ ] Error rate alerts configured

### Health Checks

- [ ] Health check script created (`/opt/supabase/scripts/health-check.sh`)
- [ ] Script executable and tested
- [ ] Cron job configured (every 5 minutes)
- [ ] Health check logs reviewed

### Log Aggregation

- [ ] Log rotation configured (`/etc/logrotate.d/supabase`)
- [ ] Centralized logging configured (optional)
- [ ] Log retention policy set (30+ days)

### Alerting

- [ ] Alert script created
- [ ] Email/Slack/Discord webhook configured
- [ ] Alert thresholds configured
- [ ] Alerts tested

---

## 7. Deployment

### Pre-Deployment

- [ ] Current production data backed up
- [ ] Maintenance window scheduled
- [ ] Users notified of upcoming changes
- [ ] Team members available for support
- [ ] Rollback plan reviewed

### Deployment Steps

- [ ] Repository cloned to `/opt/supabase/production`
- [ ] Environment file copied to `.env`
- [ ] Configuration verified (no sensitive data exposed)
- [ ] Database started and initialized
- [ ] Migrations run successfully
- [ ] All services started
- [ ] All containers running and healthy
- [ ] No errors in logs

### SAML Provider Configuration

- [ ] SAML provider added via API
- [ ] Metadata URL configured
- [ ] Domain(s) configured
- [ ] Attribute mapping configured
- [ ] Provider verified via API

---

## 8. Post-Deployment Validation

### Smoke Tests

- [ ] SAML metadata endpoint accessible
- [ ] Metadata XML valid and well-formed
- [ ] API endpoint responding (`/rest/v1/`)
- [ ] Auth endpoint responding (`/auth/v1/health`)

### Authentication Testing

- [ ] Navigated to application login
- [ ] SSO login initiated
- [ ] Redirected to ZITADEL successfully
- [ ] Logged in with production user
- [ ] Redirected back to application successfully
- [ ] User profile populated correctly

### User Provisioning

- [ ] New user created in database
- [ ] User email correct
- [ ] User metadata correct (name, etc.)
- [ ] User permissions correct

### Existing Authentication

- [ ] Email/password login still works
- [ ] Magic link login still works (if enabled)
- [ ] OAuth providers still work (if configured)

### Monitoring

- [ ] Health check script running successfully
- [ ] No errors in application logs
- [ ] Container health checks passing
- [ ] Monitoring dashboard accessible

### Performance

- [ ] Response times acceptable (<2s for auth)
- [ ] No memory leaks observed
- [ ] CPU usage normal
- [ ] Database connections stable

---

## 9. 24-48 Hour Monitoring

### First 24 Hours

- [ ] Continuous monitoring active
- [ ] Error rates tracked (should be <1%)
- [ ] Authentication success rate high (>95%)
- [ ] No service disruptions
- [ ] User feedback collected
- [ ] Issues documented

### 48 Hour Review

- [ ] All metrics within acceptable ranges
- [ ] No critical issues reported
- [ ] User adoption tracking
- [ ] Performance baseline established
- [ ] Documentation updated with lessons learned

---

## 10. Ongoing Maintenance

### Weekly Tasks

- [ ] Review authentication logs
- [ ] Check error rates
- [ ] Monitor resource usage
- [ ] Review user feedback

### Monthly Tasks

- [ ] SSL certificate expiration check
- [ ] Security updates applied
- [ ] Backup restoration tested
- [ ] Audit logs reviewed

### Quarterly Tasks

- [ ] Secrets rotated (JWT, SAML keys)
- [ ] Security review conducted
- [ ] Performance optimization review
- [ ] Disaster recovery plan tested

---

## Rollback Plan

**If critical issues arise, execute rollback:**

### Immediate Actions

- [ ] Stop current deployment
- [ ] Restore previous version
- [ ] Restart services
- [ ] Verify services running

### SAML Specific Rollback

- [ ] Remove SAML provider via API
- [ ] Remove SAML environment variables
- [ ] Restart auth service
- [ ] Verify traditional auth works

### Database Rollback

- [ ] Stop all services
- [ ] Restore database from backup
- [ ] Restart services
- [ ] Verify data integrity

### Communication

- [ ] Notify users of rollback
- [ ] Document issues encountered
- [ ] Schedule post-mortem meeting
- [ ] Plan remediation for issues

---

## Acceptance Criteria

All items must be checked before considering deployment complete:

- [ ] Production environment fully configured
- [ ] SSL/HTTPS enabled and working (A+ rating)
- [ ] ZITADEL production integration complete
- [ ] Users can authenticate via SAML
- [ ] User provisioning working correctly
- [ ] Monitoring and alerting operational
- [ ] Documentation complete and accessible
- [ ] Post-deployment validation successful
- [ ] 24-48 hour monitoring period complete
- [ ] No critical issues reported
- [ ] Rollback plan tested and documented
- [ ] Team trained on operations and troubleshooting

---

## Support & Resources

### Documentation

- [Production Deployment Guide](ZITADEL_SAML_PRODUCTION_DEPLOYMENT.md)
- [ZITADEL IdP Setup](ZITADEL_SAML_IDP_SETUP.md)
- [DevOps Guide](../DEVOPS.md)

### External Resources

- [Supabase Self-Hosting Docs](https://supabase.com/docs/guides/self-hosting)
- [ZITADEL Documentation](https://zitadel.com/docs)
- [Docker Production Best Practices](https://docs.docker.com/config/containers/resource_constraints/)

### Getting Help

- Review troubleshooting section in main guide
- Check Supabase Discord community
- Open issue in repository with logs
- Contact ZITADEL support if needed

---

**Checklist Version**: 1.0.0  
**Last Updated**: 2024-01-09  
**Status**: ✅ Complete
