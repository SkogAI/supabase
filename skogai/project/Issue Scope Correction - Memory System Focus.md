---
title: Issue Scope Correction - Memory System Focus
type: note
permalink: project/issue-scope-correction-memory-system-focus
tags:
- issue
- scope
- planning
- lessons-learned
- memory-system
---

# Issue Scope Correction: Memory System Focus

## What Happened

[issue] Issue #181 was created with overly broad scope mixing multiple concerns
[decision] Closed #181 and split into focused, actionable issues

## Original Problem

[scope-issue] #181 combined 4 different work streams:
- [work-stream] Documentation consolidation (existing content)
- [work-stream] Memory system automation (tooling/workflows)
- [work-stream] CLI reference creation (new documentation)
- [work-stream] Feature guide creation (new documentation)

[problem] Mixed "organize what exists" with "create new content"
[problem] 40-50 hour estimate too large for single issue
[problem] Unclear deliverables and success criteria

## Corrected Scope

### Issue #182: Documentation Consolidation
[link] https://github.com/SkogAI/supabase/issues/182
[scope] ONLY consolidate existing docs from skogai/todo/
[scope] Merge duplicates, archive historical content
[scope] Extract observations from existing content
[estimate] 15-20 hours over 1-2 weeks

**Key Activities:**
- [activity] Consolidate duplicate storage docs
- [activity] Consolidate duplicate RLS docs
- [activity] Consolidate duplicate MCP/SAML docs
- [activity] Archive historical status files
- [activity] Extract useful content from workflow docs

**Out of Scope:**
- [not-in-scope] Writing new documentation
- [not-in-scope] Creating CLI references
- [not-in-scope] Expanding existing topics

### Issue #183: Memory System Automation
[link] https://github.com/SkogAI/supabase/issues/183
[scope] Build automation for memory system usage
[scope] Git hooks, GitHub Actions, helper scripts
[scope] Validation, coverage tracking, templates
[estimate] 25-30 hours over 3-4 weeks

**Key Deliverables:**
- [deliverable] Git post-commit hook for auto-sync
- [deliverable] GitHub Actions workflow for CI sync
- [deliverable] Quick-add helper scripts (concept, guide, observation)
- [deliverable] Coverage report generator
- [deliverable] Validation script for quality checks
- [deliverable] Observation templates and standards doc

**Out of Scope:**
- [not-in-scope] Writing documentation content
- [not-in-scope] Migrating existing docs
- [not-in-scope] Creating new guides

### Future Work: CLI Reference & Feature Guides
[future-work] Creating CLI command references (db/, migration/, functions/, gen/)
[future-work] Writing new feature implementation guides
[future-work] Expanding testing documentation
[future-work] Creating workflow tutorials

[decision] These are separate documentation efforts, not memory system work
[decision] Should be prioritized based on actual need, not "complete coverage"

## Lessons Learned

[lesson] Separate "organize existing" from "create new"
[lesson] Keep issues focused on single work stream
[lesson] 15-30 hour estimates more manageable than 40-50
[lesson] Memory system scope: consolidation + automation, not content creation
[lesson] Documentation creation should be demand-driven, not coverage-driven

## Issue Relationships

- [closed] #181 - Too broad, mixed concerns
- [created] #182 - Documentation consolidation (pure organization)
- [created] #183 - Memory system automation (pure tooling)
- [continues] #160 - Original knowledge base initiative
- [builds-on] PR #180 - Initial 32 notes migrated

## Memory System Definition

[definition] The "memory system" includes:
- [component] Basic Memory MCP integration
- [component] Semantic note structure (YAML + observations + WikiLinks)
- [component] Folder organization (concepts/, guides/, project/)
- [component] Automation tooling (hooks, scripts, workflows)
- [component] Quality standards and templates

[definition] The "memory system" does NOT include:
- [not-component] Writing new documentation content
- [not-component] Creating comprehensive CLI references
- [not-component] Building new feature guides
- [not-component] Tutorial creation

## Success Criteria

[success] Issues are focused and independently deliverable
[success] Scope boundaries are clear
[success] Estimates are realistic (15-30 hours)
[success] Dependencies are explicit
[success] Out-of-scope items documented for future work

## Relations

- supersedes [[Issue 181]]
- creates [[Issue 182]]
- creates [[Issue 183]]
- refines_scope_of [[Issue 160]]
- documents [[Lesson Learned]]