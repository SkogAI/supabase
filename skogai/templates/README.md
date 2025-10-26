# Knowledge Base Templates

This directory contains templates for documenting different aspects of the Supabase project in the knowledge base.

## Available Templates

### 1. Migration Template (`migration-template.md`)

**Use for:** Documenting database migrations (schema changes, RLS policies, functions)

**When to use:**
- After creating a new migration in `supabase/migrations/`
- When adding or modifying database tables
- When setting up Row Level Security policies
- When adding database functions or triggers

**Key sections:**
- Purpose and changes made
- SQL overview and snippets
- Testing procedures (RLS tests)
- Deployment checklist
- Rollback plan

---

### 2. Edge Function Template (`function-template.md`)

**Use for:** Documenting Deno edge functions

**When to use:**
- After creating a new function in `supabase/functions/`
- When modifying existing edge function behavior
- When adding new API endpoints

**Key sections:**
- Request/response formats
- Authentication requirements
- Implementation details
- Testing procedures
- Deployment instructions
- Security considerations

---

### 3. Troubleshooting Template (`troubleshooting-template.md`)

**Use for:** Creating runbooks for debugging common issues

**When to use:**
- After resolving a tricky production issue
- When documenting operational procedures
- Creating diagnostic guides for specific components

**Key sections:**
- Quick diagnosis checklist
- Common issues and solutions
- Advanced diagnostics
- Recovery procedures
- Escalation guidelines

---

### 4. Concept Template (`concept-template.md`)

**Use for:** Explaining architectural concepts and patterns

**When to use:**
- Documenting system architecture
- Explaining design patterns used in the project
- Creating educational content about technologies
- Clarifying complex technical concepts

**Key sections:**
- Core concepts breakdown
- How it works (architecture)
- Implementation patterns
- Best practices and anti-patterns
- Security and performance considerations

---

### 5. Guide Template (`guide-template.md`)

**Use for:** Step-by-step how-to guides

**When to use:**
- Creating tutorials for common tasks
- Documenting workflows and procedures
- Teaching how to implement features
- Onboarding new developers

**Key sections:**
- Prerequisites and setup
- Step-by-step instructions
- Complete working examples
- Testing and verification
- Troubleshooting and best practices

---

## How to Use Templates

### 1. Copy the Template

```bash
# Copy the relevant template to your target location
cp skogai/templates/migration-template.md skogai/migrations/my-new-migration.md
```

### 2. Fill in the Frontmatter

```yaml
---
title: Add User Preferences Table
type: note
permalink: migrations/add-user-preferences-table
tags:
  - "migration"
  - "database"
  - "schema"
  - "user-preferences"
project: supabase
created: 2025-10-26
updated: 2025-10-26
---
```

**Important frontmatter fields:**
- `title`: Clear, descriptive title
- `type`: note | guide | concept | runbook | command
- `permalink`: Unique identifier for references
- `tags`: Searchable tags (keep consistent with existing tags)
- `created`/`updated`: ISO date format (YYYY-MM-DD)

### 3. Replace Placeholders

- `[Name]` → Actual name
- `YYYY-MM-DD` → Actual dates
- `[description]` → Your description
- Delete sections that aren't relevant
- Keep all sections that apply

### 4. Add Rich Content

- **Code blocks:** Use syntax highlighting
- **Commands:** Show actual commands with real output
- **Links:** Use WikiLinks `[[Page Name]]` for internal refs
- **Examples:** Provide working, tested examples
- **Tags:** Use inline tags like `#database`, `#security`

### 5. Review and Save

- Check frontmatter is complete
- Verify all placeholders are replaced
- Test any code examples
- Ensure links to related docs exist
- Save in appropriate directory

## Template Selection Guide

| What are you documenting? | Use this template |
|---------------------------|-------------------|
| Database schema change | `migration-template.md` |
| New API endpoint | `function-template.md` |
| How to do X | `guide-template.md` |
| Why we use X | `concept-template.md` |
| X is broken, how to fix | `troubleshooting-template.md` |
| CLI command reference | `../TEMPLATE.md` |

## Template Structure Philosophy

All templates follow these principles:

1. **Frontmatter First:** Metadata for searchability and organization
2. **Quick Reference:** TL;DR or overview at the top
3. **Progressive Detail:** Start simple, get detailed
4. **Practical Examples:** Always show real, working code
5. **Testing Included:** How to verify it works
6. **Troubleshooting:** Common issues and fixes
7. **Related Docs:** Links to concepts, guides, other docs

## Directory Structure

Place your completed documentation in the appropriate directory:

```
skogai/
├── templates/           # 👈 You are here - templates only
├── concepts/           # Architecture and technical concepts
├── guides/            # How-to guides and tutorials
│   ├── saml/
│   ├── storage/
│   ├── mcp/
│   └── ...
├── project/           # Project-level documentation
└── summaries/         # Session summaries and reports
```

For migrations and functions, document them inline in:
```
supabase/
├── migrations/        # Add migration docs here
└── functions/         # Add function docs here
```

## Best Practices

### ✅ Do

- **Use templates:** They ensure consistency
- **Fill everything:** Don't leave `[placeholders]`
- **Add examples:** Working code is invaluable
- **Link liberally:** Use `[[WikiLinks]]` to related docs
- **Test code:** Verify examples actually work
- **Update dates:** Keep `updated` field current
- **Tag consistently:** Use existing tag conventions

### ❌ Don't

- **Don't skip frontmatter:** It's essential for search/organization
- **Don't copy-paste without adapting:** Customize to your specific use case
- **Don't leave TODOs:** Complete the documentation
- **Don't include untested code:** Only working examples
- **Don't duplicate:** Link to existing docs instead

## Tags Conventions

Use consistent tags for better searchability:

**General:**
- `migration`, `function`, `guide`, `concept`, `runbook`
- `database`, `edge-function`, `storage`, `auth`, `realtime`

**Specific:**
- `rls`, `policies`, `security`
- `testing`, `ci-cd`, `deployment`
- `troubleshooting`, `debugging`, `monitoring`
- `saml`, `mcp`, `openai`, `zitadel`

**Technology:**
- `postgresql`, `deno`, `typescript`
- `docker`, `github-actions`

## Examples of Good Documentation

Check these for inspiration:

- Migration: `skogai/guides/saml/SAML Implementation Summary.md`
- Concept: `skogai/concepts/Row Level Security.md`
- Guide: `skogai/guides/saml/ZITADEL SAML Integration Guide.md`

## Questions?

- See `skogai/BASIC_CLI_REFERENCE.md` for the documentation philosophy
- Check existing docs for patterns and examples
- Ask in team chat for guidance

## Template Maintenance

- **Version:** All templates are version 1.0
- **Last Updated:** 2025-10-26
- **Feedback:** Submit improvements via PR or issue

---

**Quick Links:**
- `[[Knowledge Base Coverage]]` - Track documentation progress
- `[[Supabase Project Overview]]` - Project documentation entry point
- `../TEMPLATE.md` - CLI command template (different use case)
