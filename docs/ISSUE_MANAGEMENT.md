# Issue Management Guide

This document describes the issue management system for the SkogAI/supabase repository.

## Overview

The repository uses GitHub Issues with custom templates to track:
- Bug reports
- Feature requests
- DevOps tasks
- Database changes
- And more

## Issue Templates

We provide several issue templates to help structure and categorize issues:

### 🐛 Bug Report (`bug_report.yml`)
Use this template when reporting bugs or unexpected behavior.

**Includes:**
- Bug description
- Reproduction steps
- Expected vs actual behavior
- Logs and screenshots
- Component selection
- Additional context

### ✨ Feature Request (`feature_request.yml`)
Use this template to suggest new features or enhancements.

**Includes:**
- Problem statement
- Proposed solution
- Alternatives considered
- Component selection
- Priority level
- Additional context

### 🔧 DevOps Task (`devops_task.yml`)
Use this template for infrastructure, CI/CD, or deployment tasks.

**Includes:**
- Task description
- Category (CI/CD, Migration, Deployment, etc.)
- Acceptance criteria
- Implementation details
- Risk assessment
- Priority level
- Dependencies

### 🗄️ Database Task (`database_task.yml`)
Use this template for database schema changes, migrations, or RLS policies.

**Includes:**
- Task description
- Task type (Table, Schema, Migration, RLS, etc.)
- Schema/SQL code
- Acceptance criteria
- Pre-deployment checklist
- Impact assessment
- Priority level

## Creating Issues

### Via GitHub Web Interface

1. Go to https://github.com/SkogAI/supabase/issues/new/choose
2. Select the appropriate template
3. Fill out all required fields
4. Add relevant labels
5. Assign to team members (if known)
6. Submit the issue

### Via GitHub CLI

```bash
# Create a bug report
gh issue create --repo SkogAI/supabase --web

# Create with specific template
gh issue create \
  --repo SkogAI/supabase \
  --title "Your title" \
  --body "Your description" \
  --label "bug"

# List issues
gh issue list --repo SkogAI/supabase

# View specific issue
gh issue view 123 --repo SkogAI/supabase
```

### Using the Issue Creation Script

We provide a script to create all the initial project tracking issues:

```bash
# Run the script (requires gh CLI authentication)
./scripts/create-issues.sh
```

This will create 12 comprehensive issues covering:
1. Storage Buckets Configuration
2. Database Performance Monitoring
3. Realtime Subscriptions Configuration
4. Expand RLS Policies for Production
5. Edge Functions - Production Examples
6. GitHub Actions Secrets Configuration
7. Testing Framework Enhancement
8. Custom Database Schemas Enhancement
9. Documentation Review and Updates
10. Security Audit and Hardening
11. Backup and Recovery Procedures
12. Monitoring and Alerting Setup

## Issue Labels

### Priority Labels
- `high-priority` - Critical issues that block progress
- `medium-priority` - Important but not blocking
- `low-priority` - Nice to have improvements

### Type Labels
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Documentation improvements
- `security` - Security-related issues
- `devops` - Infrastructure and CI/CD
- `database` - Database-related tasks
- `edge-functions` - Edge function development
- `testing` - Testing improvements

### Status Labels
- `triage` - Needs review and prioritization
- `in-progress` - Currently being worked on
- `blocked` - Cannot proceed due to dependencies
- `needs-review` - Awaiting code review
- `duplicate` - Issue already exists elsewhere

### Component Labels
- `storage` - Supabase Storage
- `realtime` - Supabase Realtime
- `migration` - Database migrations
- `monitoring` - Monitoring and alerting

## Issue Workflow

### 1. Creation
- Use appropriate template
- Fill out all required fields
- Add relevant labels
- Link related issues/PRs

### 2. Triage
- Review new issues regularly
- Assign priority labels
- Assign to team members
- Set milestones if applicable

### 3. Development
- Update issue with progress
- Reference issue in commits: `git commit -m "feat: add feature (#123)"`
- Link PRs to issues
- Keep issue description updated

### 4. Review
- Mark as `needs-review` when ready
- Request reviews from team
- Address review feedback

### 5. Closure
- Verify issue is resolved
- Update documentation if needed
- Close with comment explaining resolution
- Link to merged PR

## Issue Conventions

### Titles
Use descriptive titles with context:

✅ Good:
- "Add RLS policy for posts table"
- "Fix edge function authentication error"
- "Configure automated backups for production"

❌ Bad:
- "Fix bug"
- "Update database"
- "Help needed"

### Descriptions
- Be specific and detailed
- Include reproduction steps for bugs
- Provide acceptance criteria
- Link to relevant documentation
- Add screenshots/logs when helpful

### Comments
- Keep discussion focused on the issue
- Use task lists to track progress
- @ mention team members when needed
- Update status regularly

## Linking Issues and PRs

### In Commits
```bash
# References the issue
git commit -m "docs: update RLS guide (see #4)"

# Closes the issue when PR is merged
git commit -m "feat: add storage buckets (closes #5)"
git commit -m "fix: resolve authentication bug (fixes #10)"
```

### In Pull Requests
Add to PR description:
```markdown
Closes #123
Fixes #456
Related to #789
```

### In Issues
Reference other issues:
```markdown
Depends on #123
Blocks #456
Duplicate of #789
Related to #012
```

## Project Board Integration

Consider using GitHub Projects to visualize issue status:

1. Create a project board
2. Add columns: Backlog, To Do, In Progress, Review, Done
3. Add issues to the board
4. Move cards as work progresses
5. Filter by labels, assignees, milestones

## Issue Metrics

Track these metrics to improve workflow:
- Time to triage (creation → assignment)
- Time to first response
- Time to resolution
- Issue velocity (opened vs closed)
- Bug/feature ratio

## Best Practices

### For Reporters
1. **Search first** - Check if issue already exists
2. **Use templates** - Provide all required information
3. **Be specific** - Include details, steps, context
4. **One issue per problem** - Don't combine unrelated issues
5. **Follow up** - Respond to questions and updates

### For Assignees
1. **Update status** - Keep issue current with progress
2. **Ask questions** - Clarify requirements early
3. **Break down large issues** - Create sub-tasks if needed
4. **Document decisions** - Record why choices were made
5. **Test thoroughly** - Verify issue is resolved

### For Maintainers
1. **Triage regularly** - Review new issues daily/weekly
2. **Set priorities** - Help team focus on important work
3. **Provide context** - Share domain knowledge
4. **Close stale issues** - Archive inactive or obsolete issues
5. **Celebrate wins** - Acknowledge completed work

## Automation

The repository includes automated workflows:

### PR Checks (`.github/workflows/pr-checks.yml`)
- Validates PR has linked issue
- Checks for secrets in code
- Runs automated tests

### Issue Labeling
Consider adding GitHub Actions for:
- Auto-labeling based on title/content
- Stale issue detection
- Size estimation

### Issue Templates
- Custom templates in `.github/ISSUE_TEMPLATE/`
- Config file controls blank issues
- Forms provide structured input

## References

### Documentation
- [SETUP_COMPLETE.md](../SETUP_COMPLETE.md) - Project overview and initial issues
- [DEVOPS.md](../DEVOPS.md) - DevOps workflows and CI/CD
- [README.md](../README.md) - Development guide

### GitHub Resources
- [GitHub Issues Documentation](https://docs.github.com/en/issues)
- [Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)
- [GitHub CLI](https://cli.github.com/manual/gh_issue)

### Repository
- [Issues](https://github.com/SkogAI/supabase/issues)
- [Projects](https://github.com/SkogAI/supabase/projects)
- [Pull Requests](https://github.com/SkogAI/supabase/pulls)

---

**Last Updated**: 2025-01-05  
**Maintained by**: @Skogix, @Ic0n
