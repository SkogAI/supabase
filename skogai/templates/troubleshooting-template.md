---
title: [Troubleshooting Topic]
type: runbook
permalink: runbooks/[topic-name]
tags:
  - "troubleshooting"
  - "runbook"
  - "debugging"
  - "[specific-component]"
  - "[add-specific-tags]"
project: supabase
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Troubleshooting: [Topic Name]

**Component:** [Database | Edge Functions | Storage | Auth | Realtime | SAML | etc.]
**Severity:** 🔴 Critical | 🟡 Warning | 🟢 Info
**Last Validated:** YYYY-MM-DD

## Overview

Brief description of the problem area, common symptoms, and what this runbook covers.

## Quick Diagnosis

### Symptoms Checklist

Check if you're experiencing any of these:

- [ ] Symptom 1: Specific error message or behavior
- [ ] Symptom 2: Performance degradation
- [ ] Symptom 3: Failed requests or timeouts
- [ ] Symptom 4: Data inconsistencies

### Fast Checks (30 seconds)

```bash
# Quick health checks
docker ps | grep supabase
supabase status
curl -I http://localhost:54321/health
```

Expected: All services running, health check returns 200

## Common Issues

### Issue 1: [Specific Error or Problem]

**Severity:** 🔴 Critical | 🟡 Warning | 🟢 Info

**Symptoms:**

- Specific error messages you'll see
- Observable behavior (slow queries, failed connections, etc.)
- Where in logs to look

**Error Messages:**

```
Error: connection refused
could not connect to server
```

**Root Causes:**

1. **Cause 1:** Service not running
   - Why: Docker container stopped or crashed
   - How to verify: `docker ps | grep [service]`

2. **Cause 2:** Configuration issue
   - Why: Environment variables not set correctly
   - How to verify: `cat .env | grep [VARIABLE]`

3. **Cause 3:** Network/firewall issue
   - Why: Port blocked or networking problem
   - How to verify: `lsof -i :[PORT]` or `netstat -an | grep [PORT]`

**Solution:**

**Step 1: Verify the Service**
```bash
# Check if service is running
docker ps | grep [service-name]

# Check service logs
docker logs supabase-[service] --tail 50
```

**Step 2: Restart if Needed**
```bash
# Restart specific service
docker restart supabase-[service]

# Or restart all Supabase services
supabase stop
supabase start
```

**Step 3: Verify Fix**
```bash
# Test the connection/functionality
curl http://localhost:[PORT]/[endpoint]
```

**Expected Outcome:** Service responds correctly with no errors

**If Still Failing:** Move to Issue 2 or Advanced Diagnostics section

---

### Issue 2: [Another Common Problem]

**Severity:** 🟡 Warning

**Symptoms:**
- Description of what you'll observe

**Root Causes:**
1. Most common cause
2. Second most common cause

**Solution:**

```bash
# Commands to resolve
command1
command2
```

**Verification:**
```bash
# How to confirm it's fixed
verification command
```

---

### Issue 3: [Third Common Problem]

[Follow same structure as above]

## Advanced Diagnostics

### Detailed Logging

Enable debug logging to get more information:

```bash
# Enable debug mode
export DEBUG=true
supabase start --debug

# Or for specific component
LOG_LEVEL=debug docker logs -f supabase-[component]
```

### Check System Resources

```bash
# Check Docker resources
docker stats

# Check disk space
df -h

# Check memory
free -h

# Check CPU
top -b -n 1 | head -20
```

### Database Diagnostics

```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Check long-running queries
SELECT pid, query_start, state, query 
FROM pg_stat_activity 
WHERE state != 'idle' 
ORDER BY query_start;

-- Check table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

### Network Diagnostics

```bash
# Check port availability
lsof -i :8000    # Studio
lsof -i :54321   # API
lsof -i :54322   # Database
lsof -i :54323   # Inbucket

# Test connectivity
curl -v http://localhost:54321/health
telnet localhost 54322

# Check DNS resolution
nslookup your-project.supabase.co
```

## Environment-Specific Issues

### Local Development

**Issue:** Services won't start
**Solution:**
```bash
# Ensure Docker is running
docker info

# Clean up old containers
supabase stop
docker system prune -a

# Fresh start
supabase start
```

### Production/Remote

**Issue:** Cannot connect to remote database
**Solution:**
```bash
# Check credentials
supabase link --project-ref [your-ref]

# Test connection
psql "postgresql://postgres:[password]@[host]:5432/postgres"
```

## Monitoring & Prevention

### Health Check Script

Save this as `scripts/health-check.sh`:

```bash
#!/bin/bash
# Quick health check for Supabase services

echo "Checking Supabase services..."

# Check Docker containers
if docker ps | grep -q "supabase-db"; then
  echo "✅ Database running"
else
  echo "❌ Database not running"
fi

# Check API
if curl -s -o /dev/null -w "%{http_code}" http://localhost:54321/health | grep -q "200"; then
  echo "✅ API responding"
else
  echo "❌ API not responding"
fi

# Add more checks as needed
```

### Automated Monitoring

```bash
# Add to crontab for periodic checks
*/5 * * * * /path/to/health-check.sh >> /var/log/supabase-health.log 2>&1
```

### Alert Thresholds

Monitor these metrics:

- Database connections > 80% of max
- Response time > 500ms
- Error rate > 1% of requests
- Disk usage > 80%
- Memory usage > 85%

## Recovery Procedures

### Database Recovery

```bash
# Backup current state
supabase db dump -f backup-$(date +%Y%m%d-%H%M%S).sql

# Reset to clean state
npm run db:reset

# Or restore from specific backup
psql "postgresql://postgres:postgres@localhost:54322/postgres" < backup.sql
```

### Service Recovery

```bash
# Nuclear option: complete reset
supabase stop
docker system prune -a
supabase start
npm run db:reset
```

## When to Escalate

Escalate to senior team members if:

- [ ] Issue persists after following all steps
- [ ] Data loss or corruption suspected
- [ ] Production service down for > 15 minutes
- [ ] Security incident suspected
- [ ] Issue affects multiple components

**Escalation Contact:** [Name/Email/Slack channel]

## Related Documentation

- Related concept: `[[Component Architecture]]`
- Related guide: `[[Deployment Guide]]`
- Related runbook: `[[Related Troubleshooting]]`
- Health checks: `scripts/check-db-health.sh`
- Monitoring: `skogai/guides/mcp/monitoring.md`

## Common Command Reference

```bash
# Service Management
supabase start              # Start all services
supabase stop               # Stop all services
supabase status            # Check service status
supabase restart [service]  # Restart specific service

# Logs
docker logs -f supabase-[service]  # Follow logs
supabase functions logs [name]     # Function logs

# Database
npm run db:reset           # Reset database
npm run test:rls          # Test RLS policies
psql "connection-string"  # Connect to database

# Health Checks
./scripts/check-db-health.sh       # Database health
./scripts/test-connection.sh       # Connection test
curl http://localhost:54321/health # API health
```

## Change Log

- **YYYY-MM-DD:** Initial runbook created
- **YYYY-MM-DD:** Added Issue 3 based on production incident
- **YYYY-MM-DD:** Updated network diagnostics section

## Validation

This runbook was last validated on **YYYY-MM-DD** and confirmed to work with:

- Supabase CLI: v2.34.3
- Docker: 20.10.x
- PostgreSQL: 17.x
- OS: [Ubuntu 22.04 | macOS 13+ | Windows 11 with WSL2]

---

**Template Version:** 1.0
**Template Type:** Troubleshooting Runbook
**Last Updated:** 2025-10-26
