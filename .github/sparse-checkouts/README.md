# Sparse Checkout Templates

These templates are used for Git sparse checkouts, allowing you to check out only specific parts of the repository. This is particularly useful for worktree-based workflows where different worktrees focus on different aspects of the project.

## Available Templates

### `default.txt`
Minimal checkout with only the essential root files.
- **Use case**: Quick repository reference, minimal footprint
- **Contains**: README.md, Argcfile.sh

### `docs-only.txt`
All documentation files across the repository.
- **Use case**: Documentation work, writing guides, updating READMEs
- **Contains**: All .md files in root, docs/, skogai/, examples/, and subdirectories

### `database.txt`
Database development and migration work.
- **Use case**: Schema changes, migrations, RLS policies, database testing
- **Contains**: Migrations, seed data, types, tests, config, SQL linting config

### `functions.txt`
Edge Functions (Deno) development.
- **Use case**: Developing, testing, and deploying Supabase Edge Functions
- **Contains**: Functions directory, shared utilities, types, Deno lock file

### `config.txt`
Configuration files only.
- **Use case**: Environment setup, configuration changes, dependency management
- **Contains**: .env.example, config.toml, package.json, lock files, dotfiles

### `github-meta.txt`
GitHub workflows, templates, and CI/CD configuration.
- **Use case**: Workflow development, CI/CD changes, GitHub Actions, worktree setup
- **Contains**: .github/ directory and related CI/CD documentation

## Usage

### Initial Sparse Checkout

```bash
# Clone with sparse checkout enabled
git clone --filter=blob:none --sparse https://github.com/SkogAI/supabase.git
cd supabase

# Set sparse checkout patterns from a template
git sparse-checkout set --stdin < .github/sparse-checkouts/docs-only.txt
```

### Switch Templates

```bash
# Change to a different template
git sparse-checkout set --stdin < .github/sparse-checkouts/database.txt
```

### Combine Templates

```bash
# Combine multiple templates
cat .github/sparse-checkouts/docs-only.txt .github/sparse-checkouts/config.txt | git sparse-checkout set --stdin
```

### With Worktrees

```bash
# Create worktree with specific sparse checkout
git worktree add ../supabase-docs
cd ../supabase-docs
git sparse-checkout set --stdin < .github/sparse-checkouts/docs-only.txt
```

## Design Principle

Each template follows the principle: **Include only 100% necessary files with clear justification**.

- Templates are minimal and focused on specific workflows
- Each file included must have a strong reason to be there
- Avoid overlap between templates unless essential for the use case
- Keep templates maintainable and easy to understand

## Related Documentation

- [CI Worktree Integration](../../docs/CI_WORKTREE_INTEGRATION.md)
- [Worktrees Guide](../../docs/WORKTREES.md)
- [Git sparse-checkout documentation](https://git-scm.com/docs/git-sparse-checkout)
