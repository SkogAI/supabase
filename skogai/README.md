# skogai Memory System

A semantic knowledge base using Basic Memory MCP integration for AI-powered search and retrieval.

## Overview

The skogai memory system is a structured collection of semantic notes that capture project knowledge in a machine-readable format. Each note contains:

- **YAML frontmatter** with metadata (title, tags, permalink)
- **Observations** tagged by type for semantic search
- **WikiLinks** connecting related concepts

**Current State:**
- 34 semantic notes (8 concepts, 21 guides, 5 project docs)
- 1,552 observations across 100+ tag types
- 109 WikiLinks connecting knowledge
- Organized in three categories: concepts/, guides/, project/

## Quick Start

### Adding a New Note

```bash
# Add a concept note
scripts/memory-add-concept.sh "My Concept"

# Add a guide (specify category)
scripts/memory-add-guide.sh mcp "Setup Guide"

# Add an observation interactively
scripts/memory-add-observation.sh
```

### Validating Notes

```bash
# Check all notes for proper formatting
scripts/validate-memory.sh

# Generate coverage report
scripts/generate-coverage-report.sh
```

### Git Hook Setup (Optional)

Install the post-commit hook to automatically sync changes:

```bash
# Create symlink to git hooks
ln -s ../../scripts/hooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit

# Test it
git commit -m "test commit"
# Should see: "✓ Memory sync complete"
```

## Directory Structure

```
skogai/
├── concepts/           # Core concepts and architecture
├── guides/             # Step-by-step how-to guides
│   ├── mcp/           # MCP integration guides
│   ├── saml/          # SAML authentication guides
│   ├── security/      # Security and RLS guides
│   └── ...            # Other guide categories
├── project/           # Project-specific documentation
├── archived/          # Deprecated or obsolete notes
├── TEMPLATE.md        # Template for new notes
└── OBSERVATION_TEMPLATES.md  # Guide to observation tags
```

## Note Structure

Each note follows this format:

```markdown
---
title: Note Title
type: note|guide|concept
permalink: category/note-slug
tags:
  - tag1
  - tag2
---

# Note Title

## Overview

Brief description.

## Section with Observations

- [observation-type] Your observation here
- [another-type] Another fact or pattern

## Relations

- part_of [[Parent Concept]]
- relates_to [[Related Note]]
- documented_in [[Guide Name]]
```

## Observation Types

Observations are tagged facts that make knowledge searchable. Use standardized tags from these categories:

**Technical Implementation** (380+ observations)
- `[best-practice]` - Recommended approaches (108 uses)
- `[security]` - Security requirements (96 uses)
- `[pattern]` - Code patterns (38 uses)
- `[testing]` - Test strategies (26 uses)
- `[optimization]` - Performance tips (25 uses)

**Features & Capabilities** (160+ observations)
- `[feature]` - Specific features (60 uses)
- `[config]` - Configuration options (54 uses)
- `[component]` - System components (35 uses)

**Problem Solving** (117+ observations)
- `[issue]` - Known problems (44 uses)
- `[solution]` - How to fix (29 uses)
- `[workflow]` - Multi-step processes (24 uses)

See **OBSERVATION_TEMPLATES.md** for complete reference with examples.

## WikiLinks

Connect related concepts using double brackets:

```markdown
- [concept] Uses [[PostgreSQL Database]] for storage
- [integration] Works with [[GitHub Actions]] for CI/CD
- part_of [[Project Architecture]]
```

WikiLinks enable:
- Semantic navigation between notes
- Automatic relationship mapping
- Graph visualization of knowledge

## Automation & CI/CD

### GitHub Actions

The workflow runs automatically on:
- Push to main/master/develop (validation + sync)
- Pull requests touching skogai/ (validation + coverage comment)

**Workflow file:** `.github/workflows/sync-knowledge-base.yml`

### Git Hooks

**Post-commit hook** (`scripts/hooks/post-commit`):
- Triggers on commits modifying skogai/
- Validates notes
- Syncs to memory system (if configured)

## Scripts Reference

### Content Creation

| Script | Purpose | Example |
|--------|---------|---------|
| `memory-add-concept.sh` | Create concept note | `./scripts/memory-add-concept.sh "Load Balancing"` |
| `memory-add-guide.sh` | Create guide | `./scripts/memory-add-guide.sh mcp "Connection Guide"` |
| `memory-add-observation.sh` | Add observation interactively | `./scripts/memory-add-observation.sh` |

### Quality Assurance

| Script | Purpose | Usage |
|--------|---------|-------|
| `validate-memory.sh` | Validate all notes | `./scripts/validate-memory.sh` |
| `generate-coverage-report.sh` | Generate statistics | `./scripts/generate-coverage-report.sh` |
| `sync-memory.sh` | Sync to MCP | `./scripts/sync-memory.sh` |

## Validation Rules

The validation script checks:

1. **YAML Frontmatter**
   - Must start and end with `---`
   - Must contain `title:`, `permalink:`, `tags:`
   - Recommended: `type:` field

2. **Observation Format**
   - Must follow: `- [tag-name] Content`
   - Tag must be lowercase, hyphenated
   - Must have content after tag

3. **File Organization**
   - Concepts in `concepts/`
   - Guides in `guides/<category>/`
   - Project docs in `project/`

## Best Practices

### Writing Good Observations

✅ **Do:**
```markdown
- [best-practice] Enable RLS on all public tables to prevent unauthorized access
- [config] Function timeout: 60 seconds (configurable in supabase/config.toml)
- [metric] Cold start latency: 200-500ms for edge functions
```

❌ **Don't:**
```markdown
- [info] Has good performance (too vague)
- [best-practice] Enable RLS and test and add indexes (multiple facts)
- Set to 60 seconds (no tag, no context)
```

### One Fact Per Line

Each observation should be atomic:

```markdown
- [security] RLS policies enforced at database layer
- [security] Cannot be bypassed by malicious clients  
- [security] Works with all access methods (REST, GraphQL, SQL)
```

Not:
```markdown
- [security] RLS policies are enforced at database layer and cannot be bypassed by malicious clients and work with all access methods
```

### Use Specific Tags

Choose the most precise tag:

- `[config]` not `[info]` for configuration details
- `[metric]` not `[feature]` for measurements
- `[security]` not `[best-practice]` for security requirements

### Link Related Concepts

Add relations at the end of each note:

```markdown
## Relations

- part_of [[System Architecture]]
- implements [[Design Pattern]]
- used_by [[Feature Name]]
- documented_in [[Guide Name]]
```

## Coverage Metrics

Run `scripts/generate-coverage-report.sh` to see:

- Total notes and observations
- Notes by type (concepts/guides/project)
- Top observation tags
- Repository coverage (scripts, tests, migrations documented)
- Tag category breakdown

**Example output:**
```
Total Notes: 34
Total Observations: 1552
Unique WikiLinks: 109
Scripts Documented: 4/20
Tests Documented: 4/8
```

## MCP Integration

### Basic Memory MCP

The memory system integrates with Basic Memory MCP for:
- Semantic search across all notes
- AI-powered retrieval
- Automatic indexing of observations
- Vector embeddings for similarity search

### Configuration

MCP settings in `.mcp.json`:
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

### Syncing

Sync happens automatically:
- After commits (if post-commit hook installed)
- On push to main/master/develop (via GitHub Actions)
- Manually: `scripts/sync-memory.sh`

## Troubleshooting

### Validation Fails

```bash
# Run validation with details
./scripts/validate-memory.sh

# Common fixes:
# - Add missing YAML frontmatter fields
# - Fix observation format: - [tag] content
# - Ensure file has proper structure
```

### Sync Fails

```bash
# Check MCP configuration
cat .mcp.json

# Test sync manually
./scripts/sync-memory.sh

# Check if notes validate
./scripts/validate-memory.sh
```

### Hook Not Running

```bash
# Verify hook is installed
ls -l .git/hooks/post-commit

# Make it executable
chmod +x .git/hooks/post-commit

# Test manually
.git/hooks/post-commit
```

## Contributing

### Adding New Content

1. **Create note**: Use helper scripts
   ```bash
   ./scripts/memory-add-concept.sh "Your Concept"
   ```

2. **Add observations**: Follow templates
   ```bash
   # See OBSERVATION_TEMPLATES.md for tag reference
   - [best-practice] Your observation
   ```

3. **Link concepts**: Add WikiLinks
   ```markdown
   - [concept] Related to [[Other Concept]]
   ```

4. **Validate**: Check formatting
   ```bash
   ./scripts/validate-memory.sh
   ```

5. **Commit**: Git hook handles sync
   ```bash
   git add skogai/
   git commit -m "Add concept note"
   # Hook automatically syncs
   ```

### Updating Existing Notes

1. Edit the markdown file directly
2. Add new observations with appropriate tags
3. Update WikiLinks if structure changed
4. Run validation before committing
5. Commit changes (auto-syncs)

### Creating New Guide Categories

```bash
# Create new category
mkdir skogai/guides/new-category

# Add guide
./scripts/memory-add-guide.sh new-category "First Guide"
```

## FAQ

**Q: How long does adding a note take?**
A: Less than 2 minutes with helper scripts

**Q: What if I don't know which tag to use?**
A: Check `OBSERVATION_TEMPLATES.md` or use the interactive add script

**Q: Can I have multiple tags per observation?**
A: No - use one specific tag per observation. Create multiple observations if needed.

**Q: How do I find related notes?**
A: Use WikiLinks, grep for tags, or browse by directory

**Q: What's the difference between concepts and guides?**
A: Concepts explain "what" (architecture, design). Guides explain "how" (step-by-step instructions).

## Resources

- **Templates**: `skogai/TEMPLATE.md`
- **Observation Reference**: `skogai/OBSERVATION_TEMPLATES.md`
- **Validation**: `scripts/validate-memory.sh`
- **Coverage**: `scripts/generate-coverage-report.sh`
- **GitHub Workflow**: `.github/workflows/sync-knowledge-base.yml`

## Roadmap

Future enhancements:
- [ ] Advanced WikiLink validation
- [ ] Automatic tag suggestions
- [ ] Knowledge graph visualization
- [ ] AI-powered observation generation
- [ ] Integration with documentation sites
- [ ] Advanced MCP semantic search features

---

**Last Updated:** 2025-10-26  
**Notes:** 34 | **Observations:** 1,552 | **WikiLinks:** 109
