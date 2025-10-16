# GitHub Labels Reference

This document defines the labels used in the SkogAI/supabase repository.

## Priority Labels

| Label | Color | Description |
|-------|-------|-------------|
| `high-priority` | #d73a4a | Critical issues that block progress or security concerns |
| `medium-priority` | #fbca04 | Important but not blocking |
| `low-priority` | #0e8a16 | Nice to have improvements |

## Type Labels

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | #d73a4a | Something isn't working |
| `enhancement` | #a2eeef | New feature or request |
| `documentation` | #0075ca | Documentation improvements |
| `security` | #d73a4a | Security-related issues |
| `devops` | #d876e3 | Infrastructure and CI/CD |
| `database` | #c5def5 | Database-related tasks |
| `edge-functions` | #bfdadc | Edge function development |
| `testing` | #bfd4f2 | Testing improvements |

## Status Labels

| Label | Color | Description |
|-------|-------|-------------|
| `triage` | #d876e3 | Needs review and prioritization |
| `in-progress` | #fbca04 | Currently being worked on |
| `blocked` | #d73a4a | Cannot proceed due to dependencies |
| `needs-review` | #0075ca | Awaiting code review |
| `duplicate` | #cfd3d7 | Issue already exists elsewhere |
| `wontfix` | #ffffff | Will not be implemented |
| `help-wanted` | #008672 | Extra attention is needed |
| `good-first-issue` | #7057ff | Good for newcomers |

## Component Labels

| Label | Color | Description |
|-------|-------|-------------|
| `storage` | #e99695 | Supabase Storage |
| `realtime` | #f9d0c4 | Supabase Realtime |
| `migration` | #c5def5 | Database migrations |
| `monitoring` | #5319e7 | Monitoring and alerting |
| `rls` | #c5def5 | Row Level Security |
| `ci-cd` | #d876e3 | CI/CD pipelines |

## Creating Labels

### Via GitHub CLI

```bash
# Priority labels
gh label create "high-priority" --color "d73a4a" --description "Critical issues that block progress" --repo SkogAI/supabase
gh label create "medium-priority" --color "fbca04" --description "Important but not blocking" --repo SkogAI/supabase
gh label create "low-priority" --color "0e8a16" --description "Nice to have improvements" --repo SkogAI/supabase

# Type labels
gh label create "bug" --color "d73a4a" --description "Something isn't working" --repo SkogAI/supabase
gh label create "enhancement" --color "a2eeef" --description "New feature or request" --repo SkogAI/supabase
gh label create "documentation" --color "0075ca" --description "Documentation improvements" --repo SkogAI/supabase
gh label create "security" --color "d73a4a" --description "Security-related issues" --repo SkogAI/supabase
gh label create "devops" --color "d876e3" --description "Infrastructure and CI/CD" --repo SkogAI/supabase
gh label create "database" --color "c5def5" --description "Database-related tasks" --repo SkogAI/supabase
gh label create "edge-functions" --color "bfdadc" --description "Edge function development" --repo SkogAI/supabase
gh label create "testing" --color "bfd4f2" --description "Testing improvements" --repo SkogAI/supabase

# Status labels
gh label create "triage" --color "d876e3" --description "Needs review and prioritization" --repo SkogAI/supabase
gh label create "in-progress" --color "fbca04" --description "Currently being worked on" --repo SkogAI/supabase
gh label create "blocked" --color "d73a4a" --description "Cannot proceed due to dependencies" --repo SkogAI/supabase
gh label create "needs-review" --color "0075ca" --description "Awaiting code review" --repo SkogAI/supabase
gh label create "help-wanted" --color "008672" --description "Extra attention is needed" --repo SkogAI/supabase
gh label create "good-first-issue" --color "7057ff" --description "Good for newcomers" --repo SkogAI/supabase

# Component labels
gh label create "storage" --color "e99695" --description "Supabase Storage" --repo SkogAI/supabase
gh label create "realtime" --color "f9d0c4" --description "Supabase Realtime" --repo SkogAI/supabase
gh label create "migration" --color "c5def5" --description "Database migrations" --repo SkogAI/supabase
gh label create "monitoring" --color "5319e7" --description "Monitoring and alerting" --repo SkogAI/supabase
gh label create "rls" --color "c5def5" --description "Row Level Security" --repo SkogAI/supabase
gh label create "ci-cd" --color "d876e3" --description "CI/CD pipelines" --repo SkogAI/supabase
```

### Via Script

Run all label creation commands at once:

```bash
# Make script executable
chmod +x scripts/setup/create-labels.sh

# Run script
./scripts/setup/create-labels.sh
```

## Label Usage Guidelines

### When Creating Issues

1. **Always add a priority label** - Helps with triage
2. **Add type label** - Categorizes the work
3. **Add component labels as needed** - For filtering
4. **Don't overuse labels** - 2-4 labels is usually sufficient

### When Working on Issues

1. **Add "in-progress"** when you start work
2. **Add "needs-review"** when ready for review
3. **Add "blocked"** if dependencies prevent progress
4. **Remove labels** when no longer applicable

### For Maintainers

1. **Triage new issues** - Add "triage" initially
2. **Set priorities** - Based on impact and urgency
3. **Update status** - Keep labels current
4. **Close stale** - Remove outdated labels

---

**Last Updated**: 2025-01-05
**See Also**: [ISSUE_MANAGEMENT.md](./ISSUE_MANAGEMENT.md)
