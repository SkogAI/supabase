# Bugfix Testing Checklist

Complete this checklist before submitting your bugfix PR.

## Bug Reproduction

- [ ] Bug reproduced in local environment
- [ ] Steps to reproduce documented
- [ ] Expected behavior clearly defined
- [ ] Actual behavior documented

## Root Cause Analysis

- [ ] Root cause identified
- [ ] Related code areas checked
- [ ] Similar bugs searched in codebase
- [ ] Impact assessment completed

## Fix Implementation

- [ ] Fix implemented with minimal changes
- [ ] Code follows existing patterns
- [ ] No unrelated changes included
- [ ] Comments added for complex logic

## Testing

### Automated Tests

- [ ] Test added that fails before fix
- [ ] Test passes after fix
- [ ] Edge cases covered
- [ ] Regression tests run successfully

### Manual Testing

- [ ] Bug no longer reproducible
- [ ] Fix tested in development environment
- [ ] Related functionality still works
- [ ] No new bugs introduced

### Type-Specific Tests

**Database Bug:**
- [ ] Migration tested: `npm run db:reset`
- [ ] RLS policies tested: `npm run test:rls`
- [ ] Types regenerated: `npm run types:generate`

**Edge Function Bug:**
- [ ] Function tests pass: `npm run test:functions`
- [ ] Function served locally: `npm run functions:serve`
- [ ] Manual API testing completed

**Storage Bug:**
- [ ] Storage tests pass
- [ ] Upload/download tested
- [ ] Permissions verified

## Documentation

- [ ] Code comments updated
- [ ] README updated if needed
- [ ] CHANGELOG entry added (if applicable)
- [ ] Related documentation reviewed

## Pre-Commit

- [ ] Code linted (if applicable)
- [ ] No console.log statements left
- [ ] No commented-out code
- [ ] Clean git diff reviewed

## Commit Message

- [ ] Clear description of bug
- [ ] Explanation of fix
- [ ] References issue number
- [ ] Follows commit conventions

Example:
```
Fix authentication redirect loop

The redirect was occurring because session validation
happened before cookie parsing completed.

- Move session check after cookie middleware
- Add timeout to prevent infinite loops
- Update tests for new flow

Fixes SkogAI/supabase#<issue-number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Pull Request

- [ ] PR title clearly describes fix
- [ ] PR description includes:
  - Bug description
  - Root cause
  - Fix explanation
  - Testing performed
- [ ] Issue linked in PR
- [ ] Screenshots/logs attached (if applicable)

## Code Review Ready

- [ ] All checklist items completed
- [ ] CI checks passing
- [ ] Ready for review

---

**Note**: Don't skip steps! Thorough testing prevents regressions.
