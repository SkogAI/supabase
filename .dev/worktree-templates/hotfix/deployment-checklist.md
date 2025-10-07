# Hotfix Deployment Checklist

⚠️ **CRITICAL**: This is a production hotfix. Follow every step carefully.

## Pre-Development

- [ ] Critical issue confirmed in production
- [ ] Impact assessment completed
- [ ] Stakeholders notified
- [ ] Incident ticket created
- [ ] Rollback plan prepared

## Development

### Minimal Changes Only

- [ ] Fix targets root cause only
- [ ] No feature additions
- [ ] No refactoring
- [ ] No unrelated changes
- [ ] Changes are as small as possible

### Code Quality

- [ ] Code reviewed by senior developer
- [ ] Follows existing patterns exactly
- [ ] No experimental approaches
- [ ] Comments explain critical logic

## Testing (DO NOT SKIP)

### Automated Tests

- [ ] All existing tests pass
- [ ] New test added for bug
- [ ] RLS policies tested: `npm run test:rls`
- [ ] Edge functions tested: `npm run test:functions`
- [ ] Storage tests pass (if applicable)

### Manual Testing

- [ ] Critical issue reproduced locally
- [ ] Fix verified locally
- [ ] Related functionality tested
- [ ] Edge cases tested
- [ ] No regression in core features

### Production-Like Testing

- [ ] Tested with production-like data
- [ ] Tested under load (if applicable)
- [ ] Tested with production configuration
- [ ] Tested on production-like environment

## Database Changes (if applicable)

- [ ] Migration tested multiple times
- [ ] Rollback migration prepared
- [ ] Data migration tested
- [ ] Backup plan documented
- [ ] Zero-downtime approach verified

## Documentation

- [ ] Incident documented
- [ ] Fix documented in code
- [ ] Deployment notes prepared
- [ ] Rollback procedure documented

## Pre-Deployment

- [ ] Code review approved
- [ ] All tests passing
- [ ] CI/CD checks green
- [ ] Deployment window scheduled
- [ ] Team notified
- [ ] Monitoring prepared

## Deployment Steps

1. **Pre-Deployment**
   - [ ] Verify current production state
   - [ ] Take production backup
   - [ ] Verify rollback procedure
   - [ ] Alert monitoring team

2. **Deployment**
   - [ ] Merge to master branch
   - [ ] Tag release with hotfix version
   - [ ] Deploy to production
   - [ ] Monitor logs during deployment

3. **Post-Deployment Verification**
   - [ ] Verify fix in production
   - [ ] Check error rates
   - [ ] Monitor performance metrics
   - [ ] Verify no new errors
   - [ ] Test critical user paths

4. **Monitoring (First Hour)**
   - [ ] Watch error logs
   - [ ] Monitor performance
   - [ ] Check user feedback
   - [ ] Verify metrics normal
   - [ ] Document any issues

## Rollback Plan

**If issues detected:**

1. Immediate rollback steps:
   ```bash
   # Document exact rollback commands here
   git revert <commit-hash>
   # OR
   git reset --hard <previous-commit>
   # Deploy previous version
   ```

2. Rollback verification:
   - [ ] Previous version deployed
   - [ ] Services operational
   - [ ] Error rates normal
   - [ ] Notify stakeholders

## Post-Deployment

- [ ] Incident ticket updated
- [ ] Stakeholders notified
- [ ] Hotfix backported to develop
- [ ] Post-mortem scheduled
- [ ] Documentation updated
- [ ] Lessons learned documented

## Commit Message Format

```
HOTFIX: Brief description of critical issue

Critical production issue where [describe problem].

Root cause: [explain]

Fix: [explain minimal change]

Testing:
- All automated tests pass
- Manual testing completed
- Production verification ready

Rollback: [brief rollback procedure]

Fixes SkogAI/supabase#<issue-number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Pull Request Requirements

- [ ] Title prefixed with "HOTFIX:"
- [ ] Severity level indicated
- [ ] Impact assessment included
- [ ] Testing evidence attached
- [ ] Rollback plan documented
- [ ] Deployment steps outlined
- [ ] Expedited review requested

## Sign-Off Required

- [ ] Developer sign-off
- [ ] Code reviewer sign-off
- [ ] Team lead sign-off
- [ ] Deployment approved

---

**⚠️ REMINDER**: Hotfixes bypass normal process for critical issues only.
All other changes should go through regular feature/bugfix workflow.
