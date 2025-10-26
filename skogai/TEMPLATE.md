---
title: Template Command Documentation
type: command
permalink: supabase/template
tags:
  - "template"
  - "documentation"
  - "example"
  - "lifecycle"
  - "management"
  - "supabase"
project: supabase
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

> **Note:** This template is specifically for CLI command documentation. For other types of documentation, see `templates/README.md`:
> - **Migrations:** `templates/migration-template.md`
> - **Edge Functions:** `templates/function-template.md`
> - **How-To Guides:** `templates/guide-template.md`
> - **Concepts:** `templates/concept-template.md`
> - **Troubleshooting:** `templates/troubleshooting-template.md`

# supabase [command] [subcommand]

**CLI Version:** v2.34.3
**Last Updated:** YYYY-MM-DD
**Category:** [Local Development | Management API | Lifecycle]

## Purpose

One sentence describing what this command does.

Detailed explanation of the command's role in your workflow.

## Syntax

```bash
supabase command subcommand [flags]
```

## Flags

- `--flag-name`: Description of what this flag does
- `-f, --short`: Short and long form
- `--example="value"`: Flag that takes a value

## Your Project Context

How this command behaves specifically in YOUR setup:

- What it does to your specific tables/schemas
- How long it typically takes
- What data it affects
- Any project-specific configuration that influences behavior

Example:

> In this project, `db reset` drops all tables in the `public` schema, runs 6 migrations from `supabase/migrations/`, and creates 3 test users (alice, bob, charlie) with 8 sample posts. Takes ~5 seconds.

## Common Use Cases

### 1. Use Case Name

**When:** Describe when you'd use this
**Steps:**

```bash
# Commands with actual output examples
supabase command subcommand
```

**Result:** What happens after running this

### 2. Another Use Case

**When:** Another scenario
**Steps:**

```bash
supabase command subcommand --flag
```

## Expected Output

```
Show actual output from running the command
Include success messages
Include progress indicators
```

## Common Issues

### Issue: Error message or problem description

**Symptoms:**

- What you see when this happens
- Error messages

**Cause:** Why this happens

**Solution:**

```bash
# Steps to fix
command to fix
```

### Issue: Another common problem

**Symptoms:** What you observe

**Solution:** How to fix it

## Integration with Your Workflow

Describe how this command fits into your daily workflow:

- What you typically run before this command
- What you typically run after
- What other commands this pairs with

Example:

> After pulling new migrations from git, run `supabase db reset` to apply them locally, then `npm run types:generate` to update TypeScript types, and finally `npm run test:rls` to verify RLS policies.

## Related Commands

- `[other-command]` - Description of relationship
- `[another-command]` - How they work together
- See `concepts/topic.md` for deeper dive on related concept
- See `workflows/workflow-name.md` for multi-command procedure

## Additional Notes

Any other important information:

- Performance considerations
- Security implications
- Version-specific behavior
- Tips and tricks
- Links to official docs

## Official Documentation

[Supabase CLI - Command Name](https://supabase.com/docs/guides/cli/...)

---

**Template Version:** 1.0
**Last Template Update:** 2025-10-10
